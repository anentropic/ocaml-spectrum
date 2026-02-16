(*
  Tests for capability-based serializer selection.

  Tests verify that serializers correctly quantize RGB colors based on
  terminal capabilities (True color, ANSI-256, or ANSI-16).
*)

open Alcotest

(* Test capability-based serializer selection by checking output codes *)
let test_capability_based_output () =
  (* Test that True_color serializer preserves RGB *)
  let tokens = [Spectrum.Parser.Foreground(Spectrum.Parser.RgbColor(Color.Rgb.(v 123 45 67 |> to_gg)))] in
  let true_color_output = Spectrum.Private.True_color_Serializer.to_code tokens in
  Alcotest.(check string) "True_color preserves RGB" "38;2;123;45;67" true_color_output;

  (* Test that Xterm256 serializer quantizes RGB to ANSI-256 *)
  let xterm256_output = Spectrum.Private.Xterm256_Serializer.to_code tokens in
  Alcotest.(check bool) "Xterm256 quantizes RGB" true (String.contains xterm256_output ';');
  Alcotest.(check bool) "Xterm256 uses 38;5 prefix" true (String.starts_with ~prefix:"38;5;" xterm256_output);

  (* Test that Basic serializer quantizes RGB to ANSI-16 *)
  let basic_output = Spectrum.Private.Basic_Serializer.to_code tokens in
  let basic_code = int_of_string basic_output in
  Alcotest.(check bool) "Basic quantizes to 30-97 range" true (basic_code >= 30 && basic_code <= 97)

let () =
  let (testsuite, exit) = Junit_alcotest.run_and_report "Serializers" [
      "Capability-based output", [
        test_case "serializer outputs" `Quick test_capability_based_output;
      ];
    ] in
  let report = Junit.make [testsuite;] in
  Junit.to_file report "junit-serializers.xml";
  exit ()
