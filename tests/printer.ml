open Spectrum.Printer

let test_sprintf_into fmt expected () =
  let msg = Printf.sprintf "%s -> %s" fmt expected in
  let result = ref "" in
  let fmt = Scanf.format_from_string fmt (format_of_string "") in
  let () = sprintf_into result fmt in
  Alcotest.(check string) msg expected !result
    
let test_sprintf_into1 fmt arg1 expected () =
  let msg = Printf.sprintf "%s -> %s" fmt expected in
  let result = ref "" in
  let fmt = Scanf.format_from_string fmt (format_of_string "%s") in
  let () = sprintf_into result fmt arg1 in
  Alcotest.(check string) msg expected !result
    
let () =
  let open Alcotest in
  run "Printer" [
      "Single style", [
          test_case "Bold" `Quick (test_sprintf_into "@{<bold>hello@}" "\027[0;1mhello\027[0m");
          test_case "Bold (case-insensitive)" `Quick (test_sprintf_into "@{<BolD>hello@}" "\027[0;1mhello\027[0m");
          test_case "Rapid blink" `Quick (test_sprintf_into "@{<rapid-blink>hello@}" "\027[0;5mhello\027[0m");
        ];
      "Single colour", [
          test_case "Named (foreground): red" `Quick (test_sprintf_into "@{<red>hello@}" "\027[0;38;5;1mhello\027[0m");
          test_case "Named (foreground): red (case-insensitive)" `Quick (test_sprintf_into "@{<REd>hello@}" "\027[0;38;5;1mhello\027[0m");
          test_case "Hex (foreground): FC9" `Quick (test_sprintf_into "@{<#FC9>hello@}" "\027[0;38;2;255;204;153mhello\027[0m");
          test_case "Hex (foreground): f0c090" `Quick (test_sprintf_into "@{<#f0c090>hello@}" "\027[0;38;2;240;192;144mhello\027[0m");
          test_case "Named (background): red" `Quick (test_sprintf_into "@{<bg:red>hello@}" "\027[0;48;5;1mhello\027[0m");
          test_case "Hex (background): FC9" `Quick (test_sprintf_into "@{<bg:#FC9>hello@}" "\027[0;48;2;255;204;153mhello\027[0m");
          test_case "Hex (background): f0c090" `Quick (test_sprintf_into "@{<bg:#f0c090>hello@}" "\027[0;48;2;240;192;144mhello\027[0m");
        ];
      "Nested", [
          test_case "0-3-0 tag stack" `Quick (test_sprintf_into
            "before@{<red>one@{<bold>two@{<underline>three@}two@}one@}after"
            "before\027[0;38;5;1mone\027[0;38;5;1;1mtwo\027[0;38;5;1;1;4mthree\027[0;38;5;1;1mtwo\027[0;38;5;1mone\027[0mafter");
        ];
      "Format args", [
          test_case "One string arg" `Quick (test_sprintf_into1 "@{<bold>%s@}" "hello" "\027[0;1mhello\027[0m");
        ];
    ]
