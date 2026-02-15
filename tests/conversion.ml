(*
  Integration tests for color conversion and capability-based downsampling.

  Tests verify that RGB colors are correctly quantized to ANSI-256 or ANSI-16
  when terminal capabilities are limited.
*)

open Alcotest
open Spectrum_tools.Convert

let v4_testable = testable (fun ppf v ->
    let open Spectrum_tools.Utils in
    let c = to_rgba v in
    Format.fprintf ppf "RGB(%d,%d,%d)" c.r c.g c.b
  ) ( = )

(* Test RGB to ANSI-256 conversion with Perceptual algorithm *)
let test_rgb_to_ansi256 () =
  (* Test pure colors *)
  let red = Color.Rgb.(v 255 0 0 |> to_gg) in
  Alcotest.(check int) "pure red -> ANSI 196" 196 (Perceptual.rgb_to_ansi256 red);

  let green = Color.Rgb.(v 0 255 0 |> to_gg) in
  Alcotest.(check int) "pure green -> ANSI 46" 46 (Perceptual.rgb_to_ansi256 green);

  let blue = Color.Rgb.(v 0 0 255 |> to_gg) in
  Alcotest.(check int) "pure blue -> ANSI 21" 21 (Perceptual.rgb_to_ansi256 blue);

  (* Test greys *)
  let black = Color.Rgb.(v 0 0 0 |> to_gg) in
  Alcotest.(check int) "black -> ANSI 16" 16 (Perceptual.rgb_to_ansi256 black);

  let mid_gray = Color.Rgb.(v 128 128 128 |> to_gg) in
  let gray_code = Perceptual.rgb_to_ansi256 mid_gray in
  Alcotest.(check bool) "mid gray in grey range" true (gray_code >= 232 && gray_code <= 255);

  let white = Color.Rgb.(v 255 255 255 |> to_gg) in
  Alcotest.(check int) "white -> ANSI 231" 231 (Perceptual.rgb_to_ansi256 white);

  (* Test a specific color cube entry *)
  let color = Color.Rgb.(v 95 135 215 |> to_gg) in
  let code = Perceptual.rgb_to_ansi256 color in
  Alcotest.(check bool) "color in cube range" true (code >= 16 && code <= 231)

(* Test RGB to ANSI-16 conversion with Perceptual algorithm *)
let test_rgb_to_ansi16 () =
  (* Test that primary colors map to correct ANSI-16 codes *)
  let red = Color.Rgb.(v 255 0 0 |> to_gg) in
  let red_code = Perceptual.rgb_to_ansi16 red in
  Alcotest.(check bool) "red maps to ANSI-16 red range" true (red_code >= 31 && red_code <= 91);

  let green = Color.Rgb.(v 0 255 0 |> to_gg) in
  let green_code = Perceptual.rgb_to_ansi16 green in
  Alcotest.(check bool) "green maps to ANSI-16 green range" true (green_code >= 32 && green_code <= 92);

  let blue = Color.Rgb.(v 0 0 255 |> to_gg) in
  let blue_code = Perceptual.rgb_to_ansi16 blue in
  Alcotest.(check bool) "blue maps to ANSI-16 blue range" true (blue_code >= 34 && blue_code <= 94);

  (* Test black and white *)
  let black = Color.Rgb.(v 0 0 0 |> to_gg) in
  Alcotest.(check int) "black -> ANSI 30" 30 (Perceptual.rgb_to_ansi16 black);

  let white = Color.Rgb.(v 255 255 255 |> to_gg) in
  Alcotest.(check int) "white -> ANSI 97" 97 (Perceptual.rgb_to_ansi16 white)

(* Test capability-based serializer selection by checking output codes *)
let test_capability_based_output () =
  (* Test that True_color serializer preserves RGB *)
  let tokens = [Spectrum.Parser.Foreground(Spectrum.Parser.RgbColor(Color.Rgb.(v 123 45 67 |> to_gg)))] in
  let true_color_output = Spectrum.True_color_Serializer.to_code tokens in
  Alcotest.(check string) "True_color preserves RGB" "38;2;123;45;67" true_color_output;

  (* Test that Xterm256 serializer quantizes RGB to ANSI-256 *)
  let xterm256_output = Spectrum.Xterm256_Serializer.to_code tokens in
  Alcotest.(check bool) "Xterm256 quantizes RGB" true (String.contains xterm256_output ';');
  Alcotest.(check bool) "Xterm256 uses 38;5 prefix" true (String.starts_with ~prefix:"38;5;" xterm256_output);

  (* Test that Basic serializer quantizes RGB to ANSI-16 *)
  let basic_output = Spectrum.Basic_Serializer.to_code tokens in
  let basic_code = int_of_string basic_output in
  Alcotest.(check bool) "Basic quantizes to 30-97 range" true (basic_code >= 30 && basic_code <= 97)

(* Test edge cases: color cube boundaries *)
let test_color_cube_boundaries () =
  (* Test colors at the edges of xterm-256 color cube *)
  let min_color = Color.Rgb.(v 0 0 0 |> to_gg) in
  let min_code = Perceptual.rgb_to_ansi256 min_color in
  Alcotest.(check bool) "minimum color in valid range" true (min_code >= 0 && min_code <= 255);

  let max_color = Color.Rgb.(v 255 255 255 |> to_gg) in
  let max_code = Perceptual.rgb_to_ansi256 max_color in
  Alcotest.(check bool) "maximum color in valid range" true (max_code >= 0 && max_code <= 255);

  (* Test quantization of values between color cube entries *)
  let between = Color.Rgb.(v 100 150 200 |> to_gg) in
  let between_code = Perceptual.rgb_to_ansi256 between in
  Alcotest.(check bool) "in-between color quantized to valid code" true (between_code >= 16 && between_code <= 231)

let () =
  let (testsuite, exit) = Junit_alcotest.run_and_report "Conversion" [
      "RGB to ANSI-256", [
        test_case "rgb_to_ansi256 basic colors" `Quick test_rgb_to_ansi256;
        test_case "color cube boundaries" `Quick test_color_cube_boundaries;
      ];
      "RGB to ANSI-16", [
        test_case "rgb_to_ansi16 basic colors" `Quick test_rgb_to_ansi16;
      ];
      "Capability-based output", [
        test_case "serializer outputs" `Quick test_capability_based_output;
      ];
    ] in
  let report = Junit.make [testsuite;] in
  Junit.to_file report "junit-conversion.xml";
  exit ()
