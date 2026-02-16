(* Comprehensive tests for Palette module *)
open Alcotest
open Spectrum_palette_ppx.Palette

(* Test helpers *)

let v4_testable = testable (fun ppf v ->
    let c = Gg.Color.to_srgb v in
    let r = int_of_float (Float.round (255. *. Gg.Color.r c)) in
    let g = int_of_float (Float.round (255. *. Gg.Color.g c)) in
    let b = int_of_float (Float.round (255. *. Gg.Color.b c)) in
    Format.fprintf ppf "RGB(%d,%d,%d)" r g b
  ) ( = )

let v3_testable = testable Gg.V3.pp Gg.V3.equal

let rgb r g b = Color.Rgb.(v r g b |> to_gg)

(* Small test palette for nearest-color tests *)
let test_palette = [
  rgb 255 0 0;     (* red *)
  rgb 0 255 0;     (* green *)
  rgb 0 0 255;     (* blue *)
  rgb 0 0 0;       (* black *)
  rgb 255 255 255; (* white *)
  rgb 128 128 128; (* gray *)
]

(* ===== LAB Color Space Conversion Tests ===== *)

let test_lab3_of_color () =
  (* Test that lab3_of_color returns Gg.V3 with valid LAB coordinates *)
  let red = rgb 255 0 0 in
  let lab_red = Spectrum_palette_ppx.Palette.lab3_of_color red in

  (* LAB coordinates should be in expected ranges *)
  (* L (lightness): 0-100, a and b: typically -128 to 128 but can exceed for extreme colors *)
  let l = Gg.V3.x lab_red in
  let a = Gg.V3.y lab_red in
  let b = Gg.V3.z lab_red in

  Alcotest.(check bool) "L in range [0,100]" true (l >= 0. && l <= 100.);
  (* a and b can be outside typical range for extreme colors, so just check they're finite *)
  Alcotest.(check bool) "a is finite" true (classify_float a <> FP_nan && classify_float a <> FP_infinite);
  Alcotest.(check bool) "b is finite" true (classify_float b <> FP_nan && classify_float b <> FP_infinite)

let test_lab3_black_vs_white () =
  (* Black should have L close to 0, white close to 100 *)
  let black = rgb 0 0 0 in
  let white = rgb 255 255 255 in
  let lab_black = Spectrum_palette_ppx.Palette.lab3_of_color black in
  let lab_white = Spectrum_palette_ppx.Palette.lab3_of_color white in

  let l_black = Gg.V3.x lab_black in
  let l_white = Gg.V3.x lab_white in

  Alcotest.(check bool) "black L is very low" true (l_black < 10.);
  Alcotest.(check bool) "white L is very high" true (l_white > 90.)

let test_lab3_gray_neutral () =
  (* Gray should have a and b close to 0 (neutral) *)
  let gray = rgb 128 128 128 in
  let lab_gray = Spectrum_palette_ppx.Palette.lab3_of_color gray in

  let a = Gg.V3.y lab_gray in
  let b = Gg.V3.z lab_gray in

  (* Neutral gray should have small a, b values *)
  Alcotest.(check bool) "gray a near 0" true (Float.abs a < 5.);
  Alcotest.(check bool) "gray b near 0" true (Float.abs b < 5.)

(* ===== Nearest-Color Index Tests ===== *)

let test_nearest_index_of_color_list () =
  (* Build index from test palette *)
  let index = nearest_index_of_color_list test_palette in

  (* Verify index works by testing nearest-color lookup *)
  let red = rgb 255 0 0 in
  let nearest = nearest_with_index index red in
  Alcotest.(check v4_testable) "nearest to red is red" red nearest

let test_nearest_with_index_exact () =
  (* Exact matches should return same color *)
  let index = nearest_index_of_color_list test_palette in

  let red = rgb 255 0 0 in
  let nearest_red = nearest_with_index index red in
  Alcotest.(check v4_testable) "exact red returns red"
    red nearest_red;

  let green = rgb 0 255 0 in
  let nearest_green = nearest_with_index index green in
  Alcotest.(check v4_testable) "exact green returns green"
    green nearest_green;

  let blue = rgb 0 0 255 in
  let nearest_blue = nearest_with_index index blue in
  Alcotest.(check v4_testable) "exact blue returns blue"
    blue nearest_blue

let test_nearest_with_index_approximate () =
  let index = nearest_index_of_color_list test_palette in

  (* Dark red (closer to red than black) *)
  let dark_red = rgb 200 50 50 in
  let nearest = nearest_with_index index dark_red in
  let expected_red = rgb 255 0 0 in
  Alcotest.(check v4_testable) "dark red -> red"
    expected_red nearest;

  (* Light cyan (closer to white than blue/green) *)
  let light_cyan = rgb 200 255 255 in
  let nearest2 = nearest_with_index index light_cyan in
  let expected_white = rgb 255 255 255 in
  Alcotest.(check v4_testable) "light cyan -> white"
    expected_white nearest2

let test_nearest_with_index_dark_colors () =
  let index = nearest_index_of_color_list test_palette in

  (* Very dark colors should map to black *)
  let very_dark = rgb 10 10 10 in
  let nearest = nearest_with_index index very_dark in
  let expected_black = rgb 0 0 0 in
  Alcotest.(check v4_testable) "very dark -> black"
    expected_black nearest

(* ===== nearest_of_list Convenience Wrapper Tests ===== *)

let test_nearest_of_list () =
  (* Build nearest function from palette *)
  let nearest = nearest_of_list test_palette in

  (* Test exact match *)
  let red = rgb 255 0 0 in
  let result = nearest red in
  Alcotest.(check v4_testable) "nearest_of_list: exact red"
    red result;

  (* Test approximate match *)
  let orange = rgb 255 128 0 in
  let result2 = nearest orange in
  let expected_red = rgb 255 0 0 in
  Alcotest.(check v4_testable) "nearest_of_list: orange -> red"
    expected_red result2

let test_nearest_of_list_multiple_calls () =
  (* Verify that nearest function can be called multiple times *)
  let nearest = nearest_of_list test_palette in

  let red1 = nearest (rgb 200 0 0) in
  let red2 = nearest (rgb 255 50 50) in
  let expected_red = rgb 255 0 0 in

  Alcotest.(check v4_testable) "first call works" expected_red red1;
  Alcotest.(check v4_testable) "second call works" expected_red red2

(* ===== Perceptual Distance Tests ===== *)

let test_perceptual_distance_red_variants () =
  (* Create palette with red and green *)
  let palette = [rgb 255 0 0; rgb 0 255 0] in
  let nearest = nearest_of_list palette in

  (* Dark red should be closer to red than green (perceptually) *)
  let dark_red = rgb 128 0 0 in
  let result = nearest dark_red in
  let expected_red = rgb 255 0 0 in
  Alcotest.(check v4_testable) "dark red closer to red than green"
    expected_red result;

  (* Orange should be closer to red than green *)
  let orange = rgb 255 128 0 in
  let result2 = nearest orange in
  Alcotest.(check v4_testable) "orange closer to red than green"
    expected_red result2

let test_perceptual_distance_grayscale () =
  (* Create grayscale palette *)
  let palette = [rgb 0 0 0; rgb 128 128 128; rgb 255 255 255] in
  let nearest = nearest_of_list palette in

  (* Dark gray closer to black *)
  let dark_gray = rgb 50 50 50 in
  let result = nearest dark_gray in
  let expected_black = rgb 0 0 0 in
  Alcotest.(check v4_testable) "dark gray -> black"
    expected_black result;

  (* Mid gray closer to gray *)
  let mid_gray = rgb 120 120 120 in
  let result2 = nearest mid_gray in
  let expected_gray = rgb 128 128 128 in
  Alcotest.(check v4_testable) "mid gray -> gray"
    expected_gray result2;

  (* Light gray closer to white *)
  let light_gray = rgb 200 200 200 in
  let result3 = nearest light_gray in
  let expected_white = rgb 255 255 255 in
  Alcotest.(check v4_testable) "light gray -> white"
    expected_white result3

let test_perceptual_distance_blue_variants () =
  (* Blues with different lightness *)
  let palette = [rgb 0 0 128; rgb 0 0 255] in
  let nearest = nearest_of_list palette in

  (* Dark blue closer to navy *)
  let dark_blue = rgb 0 0 100 in
  let result = nearest dark_blue in
  let expected_navy = rgb 0 0 128 in
  Alcotest.(check v4_testable) "dark blue -> navy"
    expected_navy result;

  (* Bright blue closer to blue *)
  let bright_blue = rgb 0 0 220 in
  let result2 = nearest bright_blue in
  let expected_blue = rgb 0 0 255 in
  Alcotest.(check v4_testable) "bright blue -> blue"
    expected_blue result2

(* ===== Test Suite ===== *)

let () =
  let (testsuite, exit) = Junit_alcotest.run_and_report "Palette" [
      "LAB color space conversion", [
        test_case "lab3_of_color returns valid V3" `Quick test_lab3_of_color;
        test_case "black vs white lightness" `Quick test_lab3_black_vs_white;
        test_case "gray is neutral" `Quick test_lab3_gray_neutral;
      ];
      "Nearest-color index building", [
        test_case "nearest_index_of_color_list creates index" `Quick test_nearest_index_of_color_list;
      ];
      "Nearest-color lookup - exact matches", [
        test_case "exact colors return themselves" `Quick test_nearest_with_index_exact;
      ];
      "Nearest-color lookup - approximate", [
        test_case "approximate colors find closest" `Quick test_nearest_with_index_approximate;
        test_case "dark colors map to black" `Quick test_nearest_with_index_dark_colors;
      ];
      "nearest_of_list convenience wrapper", [
        test_case "basic functionality" `Quick test_nearest_of_list;
        test_case "multiple calls work" `Quick test_nearest_of_list_multiple_calls;
      ];
      "Perceptual distance in LAB space", [
        test_case "red variants" `Quick test_perceptual_distance_red_variants;
        test_case "grayscale distance" `Quick test_perceptual_distance_grayscale;
        test_case "blue variants" `Quick test_perceptual_distance_blue_variants;
      ];
    ] in
  let report = Junit.make [testsuite;] in
  Junit.to_file report "junit-palette.xml";
  exit ()
