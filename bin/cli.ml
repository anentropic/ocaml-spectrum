(*
 a quick demo to sanity-check our efforts are actually visible...
 dune exec -- ./bin/cli.exe
*)
let () =
  let open Spectrum in
  let ppf = Format.std_formatter in
  Format.fprintf ppf "@{<yellow>%s@}\n" "before";
  Simple.printf "@{<green>%s@}\n" "Hello world 👋";
  Simple.printf "@{<green,bold,yellow>%s@} (last specified wins)\n" "Redundant fg color in compound tag";
  let result = Simple.sprintf
      "%s @{<fg:light-steel-blue>@{<bold>Hello @{<underline>there@} you@} again @{<strikethru>mate@}@} @{<bg:red,#FFd833>warning@} post\n"
      "pre" in
  Format.print_string result;
  Format.fprintf ppf "@{<red>%s@}\n" "after";
  let reset = prepare_ppf ppf in
  Format.fprintf ppf "@{<green>%s@}\n" "Hello world 👋";
  reset ();
