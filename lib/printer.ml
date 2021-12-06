module type Printer = sig
  (** equivalent to [Format.fprintf] *)
  val fprintf :
    Format.formatter -> ('a, Format.formatter, unit, unit) format4 -> 'a

  (** equivalent to [Format.printf] *)
  val printf : ('a, Format.formatter, unit, unit) format4 -> 'a

  (** equivalent to [Format.eprintf] *)
  val eprintf : ('a, Format.formatter, unit, unit) format4 -> 'a

  (** substitute for [Format.sprintf], first arg will be updated with what would normally be return value from [sprintf] *)
  val sprintf_into :
    string ref -> ('a, Format.formatter, unit, unit) format4 -> 'a
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
      let reset ppf = 
        Format.pp_set_mark_tags ppf original_mark_tags_state;
        Format.pp_set_formatter_stag_functions ppf (original_stag_functions);
      in
      (* if error and not raising, we won't output any code (no reset) *)
      let conditionally_raise e stack = match raise_errors with
        | true -> reset ppf; raise e
        | false -> Stack.clear stack
      in
      let collapse stack = match Stack.is_empty stack with
        | true -> ""
        | false -> stack_to_esc stack
      in
      (* open/close tag output will start/end with a reset code *)
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
        collapse stack
      in
      let mark_close_stag _ =
        match Stack.is_empty stack with
        | true -> ""
        | false -> ignore @@ Stack.pop stack; collapse stack
      in
      let color_tag_funs = { original_stag_functions with mark_open_stag; mark_close_stag } in
      Format.pp_set_formatter_stag_functions ppf color_tag_funs;
      Format.pp_set_mark_tags ppf true;
      reset

    let fprintf ppf fmt =
      let reset = prepare_ppf ppf in
      Format.kfprintf reset ppf fmt

    let printf fmt = fprintf Format.std_formatter fmt

    let eprintf fmt = fprintf Format.err_formatter fmt

    let sprintf_into result fmt =
      let ppf = Format.str_formatter in
      let reset = prepare_ppf ppf in
      Format.kfprintf
        (fun ppf ->
           reset ppf;
           result := Format.flush_str_formatter ())
        ppf
        fmt
  end in
  (module M : Printer)

module Exn = (val (make_printer true) : Printer)

module Noexn = (val (make_printer false) : Printer)

include Exn
