(*
  Tests for capability-based serializer selection.

  Tests verify that serializers correctly quantize RGB colors based on
  terminal capabilities (True color, ANSI-256, or ANSI-16).
*)

open Alcotest
open Spectrum.Parser

let tc = Spectrum.Private.True_color_Serializer.to_code
let x256 = Spectrum.Private.Xterm256_Serializer.to_code
let basic = Spectrum.Private.Basic_Serializer.to_code

let is_valid_fg_code c = (c >= 30 && c <= 37) || (c >= 90 && c <= 97)
let is_valid_bg_code c = (c >= 40 && c <= 47) || (c >= 100 && c <= 107)

(* Test capability-based serializer selection by checking output codes *)
let test_capability_based_output () =
  let tokens = [Foreground(RgbColor(Color.Rgb.(v 123 45 67 |> to_gg)))] in
  (* True_color serializer preserves RGB *)
  check string "True_color preserves RGB" "38;2;123;45;67" (tc tokens);
  (* Xterm256 serializer quantizes RGB to ANSI-256 *)
  let xterm256_output = x256 tokens in
  check bool "Xterm256 uses 38;5 prefix" true
    (String.starts_with ~prefix:"38;5;" xterm256_output);
  (* Basic serializer quantizes RGB to ANSI-16 *)
  let basic_output = basic tokens in
  let basic_code = int_of_string basic_output in
  check bool "Basic quantizes to valid fg code" true
    (is_valid_fg_code basic_code)

let test_empty_token_list () =
  check string "True_color empty" "" (tc []);
  check string "Xterm256 empty" "" (x256 []);
  check string "Basic empty" "" (basic [])

let test_style_controls () =
  check string "Bold" "1" (tc [Control Bold]);
  check string "Dim" "2" (tc [Control Dim]);
  check string "Underline" "4" (tc [Control Underline]);
  (* Styles are identical across serializers *)
  check string "Bold (xterm256)" "1" (x256 [Control Bold]);
  check string "Bold (basic)" "1" (basic [Control Bold])

let test_foreground_rgb () =
  let tokens = [Foreground(RgbColor(Color.Rgb.(v 100 200 50 |> to_gg)))] in
  check string "True_color fg RGB" "38;2;100;200;50" (tc tokens);
  check bool "Xterm256 fg uses 38;5 prefix" true
    (String.starts_with ~prefix:"38;5;" (x256 tokens));
  let basic_code = int_of_string (basic tokens) in
  check bool "Basic fg uses valid fg code" true (is_valid_fg_code basic_code)

let test_background_rgb () =
  let tokens = [Background(RgbColor(Color.Rgb.(v 100 200 50 |> to_gg)))] in
  check string "True_color bg RGB" "48;2;100;200;50" (tc tokens);
  check bool "Xterm256 bg uses 48;5 prefix" true
    (String.starts_with ~prefix:"48;5;" (x256 tokens));
  let basic_code = int_of_string (basic tokens) in
  check bool "Basic bg uses valid bg code" true (is_valid_bg_code basic_code)

let test_named_256_colors () =
  let red = Xterm256.of_string "red" in
  let fg_tokens = [Foreground(Named256Color red)] in
  check string "True_color fg named256" "38;5;9" (tc fg_tokens);
  check string "Xterm256 fg named256" "38;5;9" (x256 fg_tokens);
  (* Basic serializer quantizes xterm256 names to ANSI-16 codes *)
  let basic_fg_code = int_of_string (basic fg_tokens) in
  check bool "Basic fg named256 valid code" true
    (is_valid_fg_code basic_fg_code);
  let bg_tokens = [Background(Named256Color red)] in
  check string "True_color bg named256" "48;5;9" (tc bg_tokens);
  check string "Xterm256 bg named256" "48;5;9" (x256 bg_tokens);
  let basic_bg_code = int_of_string (basic bg_tokens) in
  check bool "Basic bg named256 valid code" true
    (is_valid_bg_code basic_bg_code)

let test_basic_named_colors () =
  let basic_red = Basic.of_string "basic-red" in
  let fg_tokens = [Foreground(NamedBasicColor basic_red)] in
  (* NamedBasicColor passes through unchanged in all serializers *)
  check string "True_color fg basic" "31" (tc fg_tokens);
  check string "Xterm256 fg basic" "31" (x256 fg_tokens);
  check string "Basic fg basic" "31" (basic fg_tokens);
  let bg_tokens = [Background(NamedBasicColor basic_red)] in
  check string "True_color bg basic" "41" (tc bg_tokens);
  check string "Xterm256 bg basic" "41" (x256 bg_tokens);
  check string "Basic bg basic" "41" (basic bg_tokens)

let test_multiple_tokens () =
  let tokens = [
    Control Bold;
    Foreground(RgbColor(Color.Rgb.(v 255 0 0 |> to_gg)));
    Background(RgbColor(Color.Rgb.(v 0 0 255 |> to_gg)));
  ] in
  check string "True_color compound"
    "1;38;2;255;0;0;48;2;0;0;255" (tc tokens);
  (* Xterm256: structure is "1;38;5;N;48;5;N" *)
  let x256_parts = String.split_on_char ';' (x256 tokens) in
  check int "Xterm256 compound has 7 parts" 7 (List.length x256_parts);
  check string "Xterm256 compound bold" "1" (List.nth x256_parts 0);
  check string "Xterm256 compound fg escape" "38" (List.nth x256_parts 1);
  check string "Xterm256 compound fg mode" "5" (List.nth x256_parts 2);
  check string "Xterm256 compound bg escape" "48" (List.nth x256_parts 4);
  check string "Xterm256 compound bg mode" "5" (List.nth x256_parts 5);
  (* Basic: structure is "1;FG;BG" with valid ANSI-16 codes *)
  let basic_parts = String.split_on_char ';' (basic tokens) in
  check int "Basic compound has 3 parts" 3 (List.length basic_parts);
  check string "Basic compound bold" "1" (List.nth basic_parts 0);
  let basic_fg = int_of_string (List.nth basic_parts 1) in
  check bool "Basic compound fg valid" true (is_valid_fg_code basic_fg);
  let basic_bg = int_of_string (List.nth basic_parts 2) in
  check bool "Basic compound bg valid" true (is_valid_bg_code basic_bg)

let () =
  Test_runner.run "Serializers" ~junit_filename:"junit-serializers.xml" [
    "Capability-based output", [
      test_case "serializer outputs" `Quick test_capability_based_output;
    ];
    "Empty token list", [
      test_case "all serializers" `Quick test_empty_token_list;
    ];
    "Style controls", [
      test_case "styles across serializers" `Quick test_style_controls;
    ];
    "Foreground colors", [
      test_case "foreground RGB" `Quick test_foreground_rgb;
    ];
    "Background colors", [
      test_case "background RGB" `Quick test_background_rgb;
    ];
    "Named colors", [
      test_case "xterm256 named" `Quick test_named_256_colors;
      test_case "basic named" `Quick test_basic_named_colors;
    ];
    "Multiple tokens", [
      test_case "compound token list" `Quick test_multiple_tokens;
    ];
  ]
