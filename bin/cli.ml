(* a quick demo to sanity-check our efforts are actually visible... *)
let () =
  let ppf = Format.std_formatter in
  Format.fprintf ppf "@{<yellow>%s@}\n" "before";
  Spectrum.Printer.printf "@{<green>%s@}\n" "Hello world 👋";
  Spectrum.Printer.printf "@{<green,bold,yellow>%s@} (last specified wins)\n" "Redundant fg color in compound tag";
  let result = ref "" in
  Spectrum.Printer.sprintf_into
    result
    "%s @{<fg:light-steel-blue>@{<bold>Hello @{<underline>there@} you@} again @{<strikethru>mate@}@} @{<bg:red,#FFd833>warning@} post\n"
    "pre";
  Format.print_string !result;
  Format.fprintf ppf "@{<red>%s@}\n" "after";
