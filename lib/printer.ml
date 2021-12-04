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

(* Format.stag is an extensible variant type, we only want to handle Format.String_tag *)
exception UnhandledExtension

let make_printer raise_errors =
  let module M = struct
    (** prepare the [ppf] as a side-effect, return [original_mark_tags_state] so it can be reset in the [kfprintf] callback *)
    let prepare_ppf ppf =
      (* always begin with a reset code *)
      let stack = Stack.of_seq @@ Seq.return "0" in
      (* if error and not raising, we won't output any code (no reset) *)
      let conditionally_raise e stack = match raise_errors with
        | true -> raise e
        | false -> Stack.clear stack
      in
      let collapse stack = match Stack.is_empty stack with
        | true -> ""
        | false -> stack_to_esc stack
      in
      let color_tag_funs : Format.formatter_stag_functions =
        {
          mark_open_stag = (fun stag ->
              let _ = match stag with
                | Format.String_tag s -> begin
                    match Lexer.tag_to_code @@ String.lowercase_ascii s with
                    | Ok s -> Stack.push s stack
                    | Error e -> conditionally_raise e stack
                  end
                | _ -> conditionally_raise UnhandledExtension stack (* case not expected *)
              in
              collapse stack
            );
          mark_close_stag = (fun _ ->
              match Stack.is_empty stack with
              | true -> ""
              | false -> ignore @@ Stack.pop stack; collapse stack
            );
          print_open_stag = (fun _ -> ());
          print_close_stag = (fun _ -> ());
        }
      in
      let original_mark_tags_state = Format.pp_get_mark_tags ppf () in
      Format.pp_set_formatter_stag_functions ppf color_tag_funs;
      Format.pp_set_mark_tags ppf true;
      original_mark_tags_state

    let fprintf ppf fmt =
      let original_mark_tags_state = prepare_ppf ppf in
      Format.kfprintf
        (fun ppf -> Format.pp_set_mark_tags ppf original_mark_tags_state)
        ppf
        fmt

    let printf fmt = fprintf Format.std_formatter fmt

    let eprintf fmt = fprintf Format.err_formatter fmt

    let sprintf_into result fmt =
      let ppf = Format.str_formatter in
      let original_mark_tags_state = prepare_ppf ppf in
      Format.kfprintf
        (fun ppf ->
           Format.pp_set_mark_tags ppf original_mark_tags_state;
           result := Format.flush_str_formatter ())
        ppf
        fmt
  end in
  (module M : Printer)

module Exn = (val (make_printer true) : Printer)

module Noexn = (val (make_printer false) : Printer)

include Exn
