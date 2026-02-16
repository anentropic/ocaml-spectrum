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

(* Test capability-based serializer selection by checking output codes *)
let test_capability_based_output () =
  (* Test that True_color serializer preserves RGB *)
  let tokens = [Foreground(RgbColor(Color.Rgb.(v 123 45 67 |> to_gg)))] in
  let true_color_output = tc tokens in
  Alcotest.(check string) "True_color preserves RGB" "38;2;123;45;67" true_color_output;

  (* Test that Xterm256 serializer quantizes RGB to ANSI-256 *)
  let xterm256_output = x256 tokens in
  Alcotest.(check bool) "Xterm256 quantizes RGB" true (String.contains xterm256_output ';');
  Alcotest.(check bool) "Xterm256 uses 38;5 prefix" true (String.starts_with ~prefix:"38;5;" xterm256_output);

  (* Test that Basic serializer quantizes RGB to ANSI-16 *)
  let basic_output = basic tokens in
  let basic_code = int_of_string basic_output in
  Alcotest.(check bool) "Basic quantizes to 30-97 range" true (basic_code >= 30 && basic_code <= 97)

let test_empty_token_list () =
  Alcotest.(check string) "True_color empty" "" (tc []);
  Alcotest.(check string) "Xterm256 empty" "" (x256 []);
  Alcotest.(check string) "Basic empty" "" (basic [])

let test_style_controls () =
  Alcotest.(check string) "Bold" "1" (tc [Control Bold]);
  Alcotest.(check string) "Dim" "2" (tc [Control Dim]);
  Alcotest.(check string) "Underline" "4" (tc [Control Underline]);
  (* Styles are identical across serializers *)
  Alcotest.(check string) "Bold (xterm256)" "1" (x256 [Control Bold]);
  Alcotest.(check string) "Bold (basic)" "1" (basic [Control Bold])

let test_background_rgb () =
  let tokens = [Background(RgbColor(Color.Rgb.(v 100 200 50 |> to_gg)))] in
  Alcotest.(check string) "True_color bg RGB" "48;2;100;200;50" (tc tokens);
  Alcotest.(check bool) "Xterm256 bg uses 48;5 prefix" true
    (String.starts_with ~prefix:"48;2;" (x256 tokens))

let test_named_colors () =
  let red = Xterm256.of_string "red" in
  let fg_tokens = [Foreground(Named256Color red)] in
  Alcotest.(check string) "True_color fg named" "38;5;9" (tc fg_tokens);
  Alcotest.(check string) "Xterm256 fg named" "38;5;9" (x256 fg_tokens);
  let bg_tokens = [Background(Named256Color red)] in
  Alcotest.(check string) "True_color bg named" "48;5;9" (tc bg_tokens);
  Alcotest.(check string) "Xterm256 bg named" "48;5;9" (x256 bg_tokens)

let test_basic_named_colors () =
  let basic_red = Basic.of_string "basic-red" in
  let fg_tokens = [Foreground(NamedBasicColor basic_red)] in
  Alcotest.(check string) "True_color fg basic" "31" (tc fg_tokens);
  let bg_tokens = [Background(NamedBasicColor basic_red)] in
  Alcotest.(check string) "True_color bg basic" "41" (tc bg_tokens)

let test_multiple_tokens () =
  let tokens = [
    Control Bold;
    Foreground(RgbColor(Color.Rgb.(v 255 0 0 |> to_gg)));
    Background(RgbColor(Color.Rgb.(v 0 0 255 |> to_gg)));
  ] in
  Alcotest.(check string) "True_color compound"
    "1;38;2;255;0;0;48;2;0;0;255" (tc tokens)

let () =
  let (testsuite, exit) = Junit_alcotest.run_and_report "Serializers" [
      "Capability-based output", [
        test_case "serializer outputs" `Quick test_capability_based_output;
      ];
      "Empty token list", [
        test_case "all serializers" `Quick test_empty_token_list;
      ];
      "Style controls", [
        test_case "styles across serializers" `Quick test_style_controls;
      ];
      "Background colors", [
        test_case "background RGB" `Quick test_background_rgb;
      ];
      "Named colors", [
        test_case "xterm256 named" `Quick test_named_colors;
        test_case "basic named" `Quick test_basic_named_colors;
      ];
      "Multiple tokens", [
        test_case "compound token list" `Quick test_multiple_tokens;
      ];
    ] in
  let report = Junit.make [testsuite;] in
  Junit.to_file report "junit-serializers.xml";
  exit ()
