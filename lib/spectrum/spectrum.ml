module Capabilities = Capabilities
module Lexer = Lexer
module Parser = Parser

module type Printer = Spectrum_intf.Printer

let stack_to_esc stack =
  "\027["
  ^ (
    Stack.to_seq stack
    |> List.of_seq
    |> List.rev
    |> String.concat ";"
  )
  ^ "m"

module type Serializer = sig
  val to_code : Parser.token list -> string
end

(*
  TODO:
  functor-ise these so that the Xterm256 (and Basic?) modules are
  configurable, along with the quantizer (i.e. Perceptual or whatever)
  i.e. could use custom palettes

  for 16 <-> 256 transformations we could build a translator for any
  two Palette modules via ppx, which could brute-force the best matches
  at compile time

  for arbitrary RGB -> palette color we need a runtime method since
  the heuristic shortcuts below won't work for abitrary palettes
  (although how useful is a palette which deviates far from Xterm?
  ...is it still useful to effectively map our RGB -> Xterm -> custom?)

  if we later need an acceleration index for arbitrary palettes,
  prefer integrating the external `oktree` package rather than keeping
  indexing research/prototypes in this repository.
*)
module True_color_Serializer : Serializer = struct
  let to_code tokens =
    let open Parser in
    List.map (function
        | Control s -> string_of_int @@ Style.to_code s
        | Foreground NamedBasicColor c -> string_of_int @@ Basic.to_code c
        | Foreground Named256Color c -> "38;5;" ^ string_of_int @@ Xterm256.to_code c
        | Foreground RgbColor c -> "38;2;" ^ Rgb.to_code c
        | Background NamedBasicColor c -> string_of_int @@ Basic.to_code c + 10
        | Background Named256Color c -> "48;5;" ^ string_of_int @@ Xterm256.to_code c
        | Background RgbColor c -> "48;2;" ^ Rgb.to_code c
      ) tokens
    |> String.concat ";"
end

module Xterm256_Serializer : Serializer = struct
  let to_code tokens =
    let open Parser in
    let quantized = Spectrum_tools.Convert.Perceptual.rgb_to_ansi256 in
    List.map (function
        | Control s -> string_of_int @@ Style.to_code s
        | Foreground NamedBasicColor c -> string_of_int @@ Basic.to_code c
        | Foreground Named256Color c -> "38;5;" ^ string_of_int @@ Xterm256.to_code c
        | Foreground RgbColor c -> "38;5;" ^ string_of_int @@ quantized c
        | Background NamedBasicColor c -> string_of_int @@ Basic.to_code c + 10
        | Background Named256Color c -> "48;5;" ^ string_of_int @@ Xterm256.to_code c
        | Background RgbColor c -> "48;2;" ^ string_of_int @@ quantized c
      ) tokens
    |> String.concat ";"
end

module Basic_Serializer : Serializer = struct
  let to_code tokens =
    let open Parser in
    let quantized = Spectrum_tools.Convert.Perceptual.rgb_to_ansi16 in
    List.map (function
        | Control s -> string_of_int @@ Style.to_code s
        | Foreground NamedBasicColor c -> string_of_int @@ Basic.to_code c
        | Foreground Named256Color c -> Xterm256.to_color c |> quantized |> string_of_int
        | Foreground RgbColor c -> string_of_int @@ quantized c
        | Background NamedBasicColor c -> string_of_int @@ Basic.to_code c + 10
        | Background Named256Color c -> Xterm256.to_color c |> quantized |> (+) 10 |> string_of_int
        | Background RgbColor c -> string_of_int @@ quantized c + 10
      ) tokens
    |> String.concat ";"
end

let make_printer raise_errors to_code =
  let module M = struct
    (** prepare the [ppf] as a side-effect, return [reset] to restore
        original state in the [kfprintf] callback *)
    let prepare_ppf ppf =
      let original_stag_functions = Format.pp_get_formatter_stag_functions ppf () in
      let original_mark_tags_state = Format.pp_get_mark_tags ppf () in
      let reset () =
        Format.pp_print_flush ppf ();
        Format.pp_set_mark_tags ppf original_mark_tags_state;
        Format.pp_set_formatter_stag_functions ppf (original_stag_functions);
      in
      (* if error and not raising, we won't output any codes for the open stag *)
      let conditionally_raise e stack =
        match raise_errors with
        | true -> reset (); raise e
        | false -> Stack.clear stack
      in
      let materialise stack =
        match Stack.is_empty stack with
        | true -> ""
        | false -> stack_to_esc stack
      in
      (*
        Rather than trying to turn on/off individual styles as tags are opened
        and closed it is easier (and probably more reliable) to just output
        the whole style stack at each transition. To ensure accurate rendering
        the first element in the stack is always the 'reset' code.
        See:
        https://en.wikipedia.org/wiki/ANSI_escape_code#SGR_(Select_Graphic_Rendition)_parameters
      *)
      let stack = Stack.of_seq @@ Seq.return "0" in
      let mark_open_stag stag =
        let _ =
          match stag with
          | Format.String_tag s -> begin
              match Lexer.tag_to_compound_style @@ String.lowercase_ascii s with
              | Ok c -> Stack.push (to_code c) stack
              | Error e -> conditionally_raise e stack
            end
          | _ -> ignore @@ original_stag_functions.mark_open_stag stag
        in
        materialise stack
      in
      let mark_close_stag _ =
        match Stack.is_empty stack with
        | true -> ""
        | false -> ignore @@ Stack.pop stack; materialise stack
      in
      let color_tag_funs = { original_stag_functions with mark_open_stag; mark_close_stag } in
      Format.pp_set_formatter_stag_functions ppf color_tag_funs;
      Format.pp_set_mark_tags ppf true;
      reset

    (*
      these methods expose a handy one-shot interface that does not require
      explicitly configuring a ppf beforehand, at the cost of being less
      efficient if you have a program making many styled print calls to the
      same ppf
    *)
    module Simple = struct
      let fprintf (ppf : Format.formatter) fmt =
        let reset = prepare_ppf ppf in
        Format.kfprintf (fun _ -> reset ()) ppf fmt

      let printf fmt = fprintf Format.std_formatter fmt

      let eprintf fmt = fprintf Format.err_formatter fmt

      let flush_buffer_formatter buf ppf =
        Format.pp_print_flush ppf ();
        let s = Buffer.contents buf in
        Buffer.reset buf;
        s

      let sprintf fmt =
        let b = Buffer.create 512 in
        let ppf = Format.formatter_of_buffer b in
        let reset = prepare_ppf ppf in
        Format.kfprintf
          (fun ppf ->
             let result = flush_buffer_formatter b ppf in
             reset ();
             result)
          ppf
          fmt
    end
  end in
  (module M : Printer)

(*
  Select the appropriate serializer based on terminal capability detection.

  For Unsupported, we still emit Basic ANSI codes rather than stripping all
  formatting - this allows colors to work in terminals that support them even
  if not detected, while degrading gracefully in truly unsupported environments.
  To fully disable colors, users should avoid calling Spectrum in the first place
  or check Capabilities.supported_color_levels themselves.
*)
let select_serializer () =
  let open Capabilities in
  let levels = supported_color_levels () in
  (* Use stdout capability for selecting serializer *)
  match levels.stdout with
  | True_color -> True_color_Serializer.to_code
  | Eight_bit -> Xterm256_Serializer.to_code
  | Basic -> Basic_Serializer.to_code
  | Unsupported -> Basic_Serializer.to_code

module Exn = (val (make_printer true (select_serializer ())) : Printer)

module Noexn = (val (make_printer false (select_serializer ())) : Printer)

include Noexn

(** Expose serializers for testing purposes under Private module *)
module Private = struct
  module True_color_Serializer = True_color_Serializer
  module Xterm256_Serializer = Xterm256_Serializer
  module Basic_Serializer = Basic_Serializer
end
