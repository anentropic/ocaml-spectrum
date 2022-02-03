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
  Format.fprintf ppf "@{<green>%s@}\n" "using Format.fprintf 👋";
  reset ();
  Format.fprintf ppf "@{<red>%s@}\n" "after reset ()";
  let reset = prepare_ppf Format.str_formatter in
  let result = Format.sprintf "@{<green>%s@}\n" "Format.sprintf doesn't work" in
  Format.print_string result;
  reset ();
  Format.fprintf ppf "@{<red>%s@}\n" "after reset ()";

  Format.print_flush ();
  print_endline "";

  print_endline "Query xterm colours:";
  let term_colours = Spectrum_tools.Query.Xterm.get_colours Unix.stdin in
  (match term_colours.fg with
   | Ok c -> Printf.printf ">> fg: %s\n" @@ Color.to_hexstring c
   | Error e -> Printf.eprintf ">> fg Error: %s" e
  );
  (match term_colours.bg with
   | Ok c -> Printf.printf ">> bg: %s\n" @@ Color.to_hexstring c
   | Error e -> Printf.eprintf ">> bg Error: %s" e
  );
