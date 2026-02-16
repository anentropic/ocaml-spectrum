module type Meta = sig
  val prefix : string
  val simple : bool
end

let meta prefix simple = (module struct
  let prefix = prefix
  let simple = simple
end : Meta)

module Make (P : Spectrum.Printer) (M : Meta) = struct
  let test_sprintf raw_fmt expected () =
    let result = if M.simple then
        let fmt = Scanf.format_from_string raw_fmt (format_of_string "") in
        P.Simple.sprintf fmt
      else
        let b = Buffer.create 512 in
        let ppf = Format.formatter_of_buffer b in
        let reset = P.prepare_ppf ppf in
        let fmt = Scanf.format_from_string raw_fmt (format_of_string "") in
        ignore @@ Format.fprintf ppf fmt;
        Format.pp_print_flush ppf ();
        let result = Buffer.contents b in
        Buffer.reset b;
        reset ();
        result
    in
    let msg = Printf.sprintf "%s -> %s | %s" raw_fmt (String.escaped expected) (String.escaped result) in
    Alcotest.(check string) msg expected result

  let test_sprintf1 raw_fmt arg1 expected () =
    let result = if M.simple then
        let fmt = Scanf.format_from_string raw_fmt (format_of_string "%s") in
        P.Simple.sprintf fmt arg1
      else
        let b = Buffer.create 512 in
        let ppf = Format.formatter_of_buffer b in
        let reset = P.prepare_ppf ppf in
        let fmt = Scanf.format_from_string raw_fmt (format_of_string "%s") in
        ignore @@ Format.fprintf ppf fmt arg1;
        Format.pp_print_flush ppf ();
        let result = Buffer.contents b in
        Buffer.reset b;
        reset ();
        result
    in
    let msg = Printf.sprintf "%s -> %s | %s" raw_fmt (String.escaped expected) (String.escaped result) in
    Alcotest.(check string) msg expected result

  let get_common_tests =
    let open Alcotest in
    [
      Printf.sprintf "%s: Single style" M.prefix, [
        test_case "Bold" `Quick (test_sprintf "@{<bold>hello@}" "\027[0;1mhello\027[0m");
        test_case "Bold (case-insensitive)" `Quick (test_sprintf "@{<BolD>hello@}" "\027[0;1mhello\027[0m");
        test_case "Rapid blink" `Quick (test_sprintf "@{<rapid-blink>hello@}" "\027[0;6mhello\027[0m");
      ];
      Printf.sprintf "%s: Single colour" M.prefix, [
        test_case "Named (foreground): red" `Quick (test_sprintf "@{<red>hello@}" "\027[0;38;5;9mhello\027[0m");
        test_case "Named (foreground): red (case-insensitive)" `Quick (test_sprintf "@{<REd>hello@}" "\027[0;38;5;9mhello\027[0m");
        test_case "Hex (foreground): FC9" `Quick (test_sprintf "@{<#FC9>hello@}" "\027[0;38;2;255;204;153mhello\027[0m");
        test_case "Hex (foreground): f0c090" `Quick (test_sprintf "@{<#f0c090>hello@}" "\027[0;38;2;240;192;144mhello\027[0m");
        test_case "Named (background): red" `Quick (test_sprintf "@{<bg:red>hello@}" "\027[0;48;5;9mhello\027[0m");
        test_case "Hex (background): FC9" `Quick (test_sprintf "@{<bg:#FC9>hello@}" "\027[0;48;2;255;204;153mhello\027[0m");
        test_case "Hex (background): f0c090" `Quick (test_sprintf "@{<bg:#f0c090>hello@}" "\027[0;48;2;240;192;144mhello\027[0m");
        test_case "rgb(9, 21, 231)" `Quick (test_sprintf "@{<rgb(9 21 231)>hello@}" "\027[0;38;2;9;21;231mhello\027[0m");
        test_case "hsl(75 100 50)" `Quick (test_sprintf "@{<hsl(75 100 50)>hello@}" "\027[0;38;2;191;255;0mhello\027[0m");
        test_case "hsl(75 100% 50%)" `Quick (test_sprintf "@{<hsl(75 100%% 50%%)>hello@}" "\027[0;38;2;191;255;0mhello\027[0m");
      ];
      Printf.sprintf "%s: Nested" M.prefix, [
        test_case "0-3-0 tag stack" `Quick (
          test_sprintf
            "before@{<red>one@{<bold>two@{<underline>three@}two@}one@}after"
            "before\027[0;38;5;9mone\027[0;38;5;9;1mtwo\027[0;38;5;9;1;4mthree\027[0;38;5;9;1mtwo\027[0;38;5;9mone\027[0mafter"
        );
        test_case "0-5-0 deep nesting" `Quick (
          test_sprintf
            "@{<red>a@{<bold>b@{<underline>c@{<italic>d@{<dim>e@}d@}c@}b@}a@}"
            "\027[0;38;5;9ma\027[0;38;5;9;1mb\027[0;38;5;9;1;4mc\027[0;38;5;9;1;4;3md\027[0;38;5;9;1;4;3;2me\027[0;38;5;9;1;4;3md\027[0;38;5;9;1;4mc\027[0;38;5;9;1mb\027[0;38;5;9ma\027[0m"
        );
      ];
      Printf.sprintf "%s: Format args" M.prefix, [
        test_case "One string arg" `Quick (test_sprintf1 "@{<bold>%s@}" "hello" "\027[0;1mhello\027[0m");
      ];
    ]
end

(* Create printers with explicit True_color serializer to isolate tests
   from the runtime environment (e.g. CI where GITHUB_ACTIONS is set
   would otherwise cause Basic serializer to be selected) *)
module Tc_exn : Spectrum.Printer =
  (val Spectrum.Private.make_printer true Spectrum.Private.True_color_Serializer.to_code)
module Tc_noexn : Spectrum.Printer =
  (val Spectrum.Private.make_printer false Spectrum.Private.True_color_Serializer.to_code)

module Exn_simple = Make (Tc_exn) (val meta "Exn Simple" true)
module Exn_format = Make (Tc_exn) (val meta "Exn Format" false)
module Noexn_simple = Make (Tc_noexn) (val meta "Noexn Simple" true)
module Noexn_format = Make (Tc_noexn) (val meta "Noexn Format" false)

let test_sprintf_raises fmt exc () =
  let open Spectrum.Exn in
  let msg = Printf.sprintf "%s -> %s" fmt (Printexc.to_string exc) in
  Alcotest.(check_raises msg exc (fun () ->
      let fmt = Scanf.format_from_string fmt (format_of_string "") in
      ignore @@ (Simple.sprintf fmt)
    ))

let get_invalid_tag_tests_exn =
  let open Alcotest in
  let open Spectrum_palette_ppx.Palette in
  [
    "Exn: Invalid tags", [
      test_case "Invalid color name (fg implicit)" `Quick (test_sprintf_raises "@{<xxx>hello@}" (InvalidColorName "xxx"));
      test_case "Invalid color name (fg)" `Quick (test_sprintf_raises "@{<fg:xxx>hello@}" (InvalidColorName "xxx"));
      test_case "Invalid color name (bg)" `Quick (test_sprintf_raises "@{<bg:xxx>hello@}" (InvalidColorName "xxx"));
      test_case "Invalid color name" `Quick (test_sprintf_raises "@{<xxx>hello@}" (InvalidColorName "xxx"));
      test_case "Invalid tag (not matched as hex)" `Quick (test_sprintf_raises "@{<#ab>hello@}" (Spectrum.Parser.InvalidTag "Unexpected char: #"));
      test_case "Invalid color name (not matched as hex)" `Quick (test_sprintf_raises "@{<fg:#ab>hello@}" (InvalidColorName "fg"));
      (* note that the valid segment of compound tag is not preserved, the tag returns an error *)
      test_case "Invalid tag (not matched as hex, in compound tag)" `Quick (test_sprintf_raises "@{<bold,#ab> hello@}" (Spectrum.Parser.InvalidTag "Unexpected char: #"));
      test_case "Invalid color name (in compound tag)" `Quick (test_sprintf_raises "@{<bold,xxx>hello@}" (InvalidColorName "xxx"));
    ];
  ]

let get_invalid_tag_tests_noexn =
  let open Alcotest in
  let open Noexn_simple in
  [
    "Noexn: Invalid tags", [
      test_case "Invalid color name (fg implicit)" `Quick (test_sprintf "@{<xxx>hello@}" "hello");
      test_case "Invalid color name (fg)" `Quick (test_sprintf "@{<fg:xxx>hello@}" "hello");
      test_case "Invalid color name (bg)" `Quick (test_sprintf "@{<bg:xxx>hello@}" "hello");
      test_case "Invalid color name" `Quick (test_sprintf "@{<xxx>hello@}" "hello");
      test_case "Invalid tag (not matched as hex)" `Quick (test_sprintf "@{<#ab>hello@}" "hello");
      test_case "Invalid color name (not matched as hex)" `Quick (test_sprintf "@{<fg:#ab>hello@}" "hello");
      (* note that the valid segment of compound tag is not preserved, the whole tag was invalid *)
      test_case "Invalid tag (not matched as hex, in compound tag)" `Quick (test_sprintf "@{<bold,#ab>hello@}" "hello");
      test_case "Invalid color name (in compound tag)" `Quick (test_sprintf "@{<bold,xxx>hello@}" "hello");
      (* after invalid tag in noexn mode, the stack is cleared so the "0" reset
         prefix is lost; subsequent valid tags work but without the reset prefix *)
      test_case "Recovery after invalid tag" `Quick (test_sprintf "@{<xxx>bad@}@{<bold>good@}" "bad\027[1mgood");
    ];
  ]

let () =
  let common_tests_exn_simple = Exn_simple.get_common_tests in
  let common_tests_noexn_simple = Noexn_simple.get_common_tests in
  let common_tests_exn_format = Exn_format.get_common_tests in
  let common_tests_noexn_format = Noexn_format.get_common_tests in
  let invalid_tag_tests_exn = get_invalid_tag_tests_exn in
  let invalid_tag_tests_noexn = get_invalid_tag_tests_noexn in
  let tests = List.concat [
      common_tests_exn_simple;
      common_tests_noexn_simple;
      common_tests_exn_format;
      common_tests_noexn_format;
      invalid_tag_tests_exn;
      invalid_tag_tests_noexn;
    ] in
  let (testsuite, exit) = Junit_alcotest.run_and_report "Printer" (tests) in
  let report = Junit.make [testsuite;] in
  Junit.to_file report "junit-printer.xml";
  exit ()
