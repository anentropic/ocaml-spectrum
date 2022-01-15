module Capabilities = Capabilities
module Lexer = Lexer

module type Shortcuts = sig
  (** equivalent to [Format.printf] *)
  val printf : ('a, Format.formatter, unit, unit) format4 -> 'a

  (** equivalent to [Format.eprintf] *)
  val eprintf : ('a, Format.formatter, unit, unit) format4 -> 'a

  (** equivalent to [Format.sprintf] *)
  val sprintf : ('a, Format.formatter, unit, string) format4 -> 'a
end

module type Printer = sig
  val prepare_ppf : Format.formatter -> unit -> unit

  module Simple : Shortcuts
end

let stack_to_esc stack =
  "\027["
  ^ (
    Stack.to_seq stack
    |> List.of_seq
    |> List.rev
    |> String.concat ";"
  )
  ^ "m"

let make_printer raise_errors =
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
      let conditionally_raise e stack = match raise_errors with
        | true -> reset (); raise e
        | false -> Stack.clear stack
      in
      let materialise stack = match Stack.is_empty stack with
        | true -> ""
        | false -> stack_to_esc stack
      in
      (*
        Rather than trying to turn on/off individual styles as
        tags are opened and closed it is easier (and probably more
        reliable) to just output the whole style stack at each
        transition. To ensure accurate rendering the first element
        in the stack is always the 'reset' code.
        See:
        https://en.wikipedia.org/wiki/ANSI_escape_code#SGR_(Select_Graphic_Rendition)_parameters
      *)
      let stack = Stack.of_seq @@ Seq.return "0" in
      let mark_open_stag stag =
        let _ = match stag with
          | Format.String_tag s -> begin
              match Lexer.tag_to_code @@ String.lowercase_ascii s with
              | Ok s -> Stack.push s stack
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
      these methods expose a handy one-shot interface that does not
      require explicitly configuring a ppf beforehand, at the cost of
      being less efficient if you have a program making many styled
      print calls to the same ppf
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

module Exn = (val (make_printer true) : Printer)

module Noexn = (val (make_printer false) : Printer)

include Noexn
