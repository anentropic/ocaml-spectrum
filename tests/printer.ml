module type Meta = sig
  val prefix : string
end

let meta prefix = (module struct
  let prefix = prefix
end : Meta)

module Make (P : Spectrum.Printer.Printer) (M : Meta) = struct
  let test_sprintf_into raw_fmt expected () =
    let fmt = Scanf.format_from_string raw_fmt (format_of_string "") in
    let result = ref "" in
    let () = P.sprintf_into result fmt in
    let msg = Printf.sprintf "%s -> %s | %s" raw_fmt (String.escaped expected) (String.escaped !result) in
    Alcotest.(check string) msg expected !result

  let test_sprintf_into1 raw_fmt arg1 expected () =
    let fmt = Scanf.format_from_string raw_fmt (format_of_string "%s") in
    let result = ref "" in
    let () = P.sprintf_into result fmt arg1 in
    let msg = Printf.sprintf "%s -> %s | %s" raw_fmt (String.escaped expected) (String.escaped !result) in
    Alcotest.(check string) msg expected !result

  let get_common_tests =
    let open Alcotest in
    [
      Printf.sprintf "%s: Single style" M.prefix, [
        test_case "Bold" `Quick (test_sprintf_into "@{<bold>hello@}" "\027[0;1mhello\027[0m");
        test_case "Bold (case-insensitive)" `Quick (test_sprintf_into "@{<BolD>hello@}" "\027[0;1mhello\027[0m");
        test_case "Rapid blink" `Quick (test_sprintf_into "@{<rapid-blink>hello@}" "\027[0;5mhello\027[0m");
      ];
      Printf.sprintf "%s: Single colour" M.prefix, [
        test_case "Named (foreground): red" `Quick (test_sprintf_into "@{<red>hello@}" "\027[0;38;5;1mhello\027[0m");
        test_case "Named (foreground): red (case-insensitive)" `Quick (test_sprintf_into "@{<REd>hello@}" "\027[0;38;5;1mhello\027[0m");
        test_case "Hex (foreground): FC9" `Quick (test_sprintf_into "@{<#FC9>hello@}" "\027[0;38;2;255;204;153mhello\027[0m");
        test_case "Hex (foreground): f0c090" `Quick (test_sprintf_into "@{<#f0c090>hello@}" "\027[0;38;2;240;192;144mhello\027[0m");
        test_case "Named (background): red" `Quick (test_sprintf_into "@{<bg:red>hello@}" "\027[0;48;5;1mhello\027[0m");
        test_case "Hex (background): FC9" `Quick (test_sprintf_into "@{<bg:#FC9>hello@}" "\027[0;48;2;255;204;153mhello\027[0m");
        test_case "Hex (background): f0c090" `Quick (test_sprintf_into "@{<bg:#f0c090>hello@}" "\027[0;48;2;240;192;144mhello\027[0m");
      ];
      Printf.sprintf "%s: Nested" M.prefix, [
        test_case "0-3-0 tag stack" `Quick (
          test_sprintf_into
            "before@{<red>one@{<bold>two@{<underline>three@}two@}one@}after"
            "before\027[0;38;5;1mone\027[0;38;5;1;1mtwo\027[0;38;5;1;1;4mthree\027[0;38;5;1;1mtwo\027[0;38;5;1mone\027[0mafter"
        );
      ];
      Printf.sprintf "%s: Format args" M.prefix, [
        test_case "One string arg" `Quick (test_sprintf_into1 "@{<bold>%s@}" "hello" "\027[0;1mhello\027[0m");
      ];
    ]
end

module Exn = Make (Spectrum.Printer) (val meta "Exn")
module Noexn = Make (Spectrum.Printer.Noexn) (val meta "Noexn")

let test_sprintf_into_raises fmt exc () =
  let open Spectrum.Printer in
  let msg = Printf.sprintf "%s -> %s" fmt (Printexc.to_string exc) in
  Alcotest.(check_raises msg exc (fun () ->
      let result = ref "" in
      let fmt = Scanf.format_from_string fmt (format_of_string "") in
      ignore @@ (sprintf_into result fmt)
    ))

let get_invalid_tag_tests_exn =
  let open Alcotest in
  let open Spectrum.Lexer in
  [
    "Exn: Invalid tags", [
      test_case "Invalid color name (fg implicit)" `Quick (test_sprintf_into_raises "@{<xxx>hello@}" (InvalidColorName "xxx"));
      test_case "Invalid color name (fg)" `Quick (test_sprintf_into_raises "@{<fg:xxx>hello@}" (InvalidColorName "xxx"));
      test_case "Invalid color name (bg)" `Quick (test_sprintf_into_raises "@{<bg:xxx>hello@}" (InvalidColorName "xxx"));
      test_case "Invalid color name" `Quick (test_sprintf_into_raises "@{<xxx>hello@}" (InvalidColorName "xxx"));
      test_case "Invalid tag (not matched as hex)" `Quick (test_sprintf_into_raises "@{<#ab>hello@}" (InvalidTag "Unexpected char: #"));
      test_case "Invalid color name (not matched as hex)" `Quick (test_sprintf_into_raises "@{<fg:#ab>hello@}" (InvalidColorName "fg"));
      (* note that the valid segment of compound tag is not preserved, the tag returns an error *)
      test_case "Invalid tag (not matched as hex, in compound tag)" `Quick (test_sprintf_into_raises "@{<bold,#ab> hello@}" (InvalidTag "Unexpected char: #"));
      test_case "Invalid color name (in compound tag)" `Quick (test_sprintf_into_raises "@{<bold,xxx>hello@}" (InvalidColorName "xxx"));
    ];
  ]

let get_invalid_tag_tests_noexn =
  let open Alcotest in
  let open Noexn in
  [
    "Noexn: Invalid tags", [
      test_case "Invalid color name (fg implicit)" `Quick (test_sprintf_into "@{<xxx>hello@}" "hello");
      test_case "Invalid color name (fg)" `Quick (test_sprintf_into "@{<fg:xxx>hello@}" "hello");
      test_case "Invalid color name (bg)" `Quick (test_sprintf_into "@{<bg:xxx>hello@}" "hello");
      test_case "Invalid color name" `Quick (test_sprintf_into "@{<xxx>hello@}" "hello");
      test_case "Invalid tag (not matched as hex)" `Quick (test_sprintf_into "@{<#ab>hello@}" "hello");
      test_case "Invalid color name (not matched as hex)" `Quick (test_sprintf_into "@{<fg:#ab>hello@}" "hello");
      (* note that the valid segment of compound tag is not preserved, the whole tag was invalid *)
      test_case "Invalid tag (not matched as hex, in compound tag)" `Quick (test_sprintf_into "@{<bold,#ab>hello@}" "hello");
      test_case "Invalid color name (in compound tag)" `Quick (test_sprintf_into "@{<bold,xxx>hello@}" "hello");
    ];
  ]

let () =
  let common_tests_exn = Exn.get_common_tests in
  let common_tests_noexn = Noexn.get_common_tests in
  let invalid_tag_tests_exn = get_invalid_tag_tests_exn in
  let invalid_tag_tests_noexn = get_invalid_tag_tests_noexn in
  let tests = List.concat [
      common_tests_exn;
      common_tests_noexn;
      invalid_tag_tests_exn;
      invalid_tag_tests_noexn;
    ] in
  let (testsuite, exit) = Junit_alcotest.run_and_report "Printer" (tests) in
  let report = Junit.make [testsuite;] in
  Junit.to_file report "junit-printer.xml";
  exit ()
