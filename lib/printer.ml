let stack_to_esc stack =
  "\027["
  ^ (
    Stack.to_seq stack
    |> Seq.filter_map (fun el -> el) (* extract strings, remove Nones *)
    |> List.of_seq
    |> List.rev
    |> String.concat ";"
  )
  ^ "m"

(** prepare the [ppf] as a side-effect, return [original_mark_tags_state] so it can be reset in the [kfprintf] callback *)
let prepare_ppf ppf =
  let stack = Stack.of_seq @@ Seq.return (Some "0") in
  let color_tag_funs : Format.formatter_stag_functions =
    {
      mark_open_stag = (fun stag ->
        let el = match stag with
        | Format.String_tag s -> Some (Lexer.tag_to_code @@ String.lowercase_ascii s)
        | _ -> None (* case not expected *)
        in
        Stack.push el stack;
        stack_to_esc stack
      );
      mark_close_stag = (fun _ ->
        ignore @@ Stack.pop stack;
        stack_to_esc stack
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

let sprintf_into result fmt =
  let ppf = Format.str_formatter in
  let original_mark_tags_state = prepare_ppf ppf in
  Format.kfprintf
    (fun ppf ->
      Format.pp_set_mark_tags ppf original_mark_tags_state;
      result := Format.flush_str_formatter ())
    ppf
    fmt
