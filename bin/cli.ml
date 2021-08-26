let tag_to_code tag =
  let lexbuf = Lexing.from_string tag in
  Spectrum.Lexer.read lexbuf

let stack_to_esc stack =
  "\027["
  ^ (String.concat ";" @@ List.rev @@ List.of_seq @@ Stack.to_seq stack)
  ^ "m"

let pp_colorized ppf fmt =
  let stack = Stack.of_seq @@ Seq.return "0" in
  let color_tag_funs : Format.formatter_stag_functions =
    {
      mark_open_stag = (fun stag ->
        match stag with
        | Format.String_tag s -> begin
          let eseq = tag_to_code @@ String.lowercase_ascii s in
          Stack.push eseq stack;
          stack_to_esc stack
        end
        | _ -> "");
      mark_close_stag = (fun _ ->
        ignore @@ Stack.pop stack;
        stack_to_esc stack);
      print_open_stag = (fun _ -> ());
      print_close_stag = (fun _ -> ());
    }
  in
  Format.pp_set_formatter_stag_functions ppf color_tag_funs;
  let mark_tags = Format.pp_get_mark_tags ppf () in
  Format.pp_set_mark_tags ppf true;
  Format.kfprintf (fun ppf -> Format.pp_set_mark_tags ppf mark_tags)
  ppf fmt

let () =
  Format.printf "...\n";
  pp_colorized
    Format.std_formatter
    "@{<fg:light-steel-blue>@{<bold>Hello @{<underline>there@} you@} again @{<strikethru>mate@}@} @{<bg:red>@{<#FFd833>warning@}@}\n";
  Format.printf "...\n";
