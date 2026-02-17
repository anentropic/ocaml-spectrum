(* Comprehensive tests for Terminal palette modules *)
open Alcotest
open Spectrum_palettes.Terminal

(* Test helpers *)

let v4_testable = testable (fun ppf v ->
    let c = Gg.Color.to_srgb v in
    let r = int_of_float (Float.round (255. *. Gg.Color.r c)) in
    let g = int_of_float (Float.round (255. *. Gg.Color.g c)) in
    let b = int_of_float (Float.round (255. *. Gg.Color.b c)) in
    Format.fprintf ppf "RGB(%d,%d,%d)" r g b
  ) ( = )

(* Helper to create Gg color from RGB *)
let rgb r g b = Color.Rgb.(v r g b |> to_gg)

(* ===== Basic Palette Tests ===== *)

let test_basic_of_string_valid () =
  (* Test valid kebab-case conversions *)
  let is_valid name =
    try ignore (Basic.of_string name); true
    with InvalidColorName _ -> false
  in
  Alcotest.(check bool) "basic-black valid" true (is_valid "basic-black");
  Alcotest.(check bool) "basic-red valid" true (is_valid "basic-red");
  Alcotest.(check bool) "basic-green valid" true (is_valid "basic-green");
  Alcotest.(check bool) "basic-yellow valid" true (is_valid "basic-yellow");
  Alcotest.(check bool) "basic-blue valid" true (is_valid "basic-blue");
  Alcotest.(check bool) "basic-magenta valid" true (is_valid "basic-magenta");
  Alcotest.(check bool) "basic-cyan valid" true (is_valid "basic-cyan");
  Alcotest.(check bool) "basic-white valid" true (is_valid "basic-white");
  (* Bright variants *)
  Alcotest.(check bool) "bright-black valid" true (is_valid "bright-black");
  Alcotest.(check bool) "bright-red valid" true (is_valid "bright-red");
  Alcotest.(check bool) "bright-white valid" true (is_valid "bright-white")

let test_basic_of_string_case_insensitive () =
  (* PPX-generated of_string should be case-insensitive *)
  let is_valid name =
    try ignore (Basic.of_string name); true
    with InvalidColorName _ -> false
  in
  Alcotest.(check bool) "Basic-Black (mixed case)" true (is_valid "Basic-Black");
  Alcotest.(check bool) "BASIC-RED (all caps)" true (is_valid "BASIC-RED");
  Alcotest.(check bool) "Bright-White (title case)" true (is_valid "Bright-White")

let test_basic_of_string_invalid () =
  Alcotest.check_raises "invalid color name"
    (InvalidColorName "notacolor")
    (fun () -> ignore (Basic.of_string "notacolor"));

  Alcotest.check_raises "empty string"
    (InvalidColorName "")
    (fun () -> ignore (Basic.of_string ""))

let test_basic_to_code () =
  (* Regular colors: 30-37 *)
  Alcotest.(check int) "basic-black -> 30" 30
    (Basic.to_code (Basic.of_string "basic-black"));
  Alcotest.(check int) "basic-red -> 31" 31
    (Basic.to_code (Basic.of_string "basic-red"));
  Alcotest.(check int) "basic-green -> 32" 32
    (Basic.to_code (Basic.of_string "basic-green"));
  Alcotest.(check int) "basic-white -> 37" 37
    (Basic.to_code (Basic.of_string "basic-white"));

  (* Bright colors: 90-97 *)
  Alcotest.(check int) "bright-black -> 90" 90
    (Basic.to_code (Basic.of_string "bright-black"));
  Alcotest.(check int) "bright-red -> 91" 91
    (Basic.to_code (Basic.of_string "bright-red"));
  Alcotest.(check int) "bright-white -> 97" 97
    (Basic.to_code (Basic.of_string "bright-white"))

let test_basic_to_color () =
  (* Test known RGB values *)
  let basic_black = Basic.to_color (Basic.of_string "basic-black") in
  Alcotest.(check v4_testable) "basic-black is RGB(0,0,0)"
    (rgb 0 0 0) basic_black;

  let basic_red = Basic.to_color (Basic.of_string "basic-red") in
  Alcotest.(check v4_testable) "basic-red is RGB(128,0,0)"
    (rgb 128 0 0) basic_red;

  let basic_green = Basic.to_color (Basic.of_string "basic-green") in
  Alcotest.(check v4_testable) "basic-green is RGB(0,128,0)"
    (rgb 0 128 0) basic_green;

  let bright_white = Basic.to_color (Basic.of_string "bright-white") in
  Alcotest.(check v4_testable) "bright-white is RGB(255,255,255)"
    (rgb 255 255 255) bright_white

let test_basic_color_list () =
  Alcotest.(check int) "Basic has 16 colors" 16
    (List.length Basic.color_list);

  (* All colors should be valid Gg.v4 *)
  List.iter (fun color ->
      let c = Gg.Color.to_srgb color in
      Alcotest.(check bool) "valid color values" true
        (Gg.Color.r c >= 0. && Gg.Color.r c <= 1. &&
         Gg.Color.g c >= 0. && Gg.Color.g c <= 1. &&
         Gg.Color.b c >= 0. && Gg.Color.b c <= 1.)
    ) Basic.color_list

let test_basic_nearest_exact () =
  (* When given exact palette color, should return same color *)
  let basic_red = Basic.to_color (Basic.of_string "basic-red") in
  let nearest = Basic.nearest basic_red in
  Alcotest.(check v4_testable) "exact basic-red returns same"
    basic_red nearest

let test_basic_nearest_approximate () =
  (* Test with color close to basic-red (128,0,0) *)
  let dark_red = rgb 130 5 5 in
  let nearest = Basic.nearest dark_red in
  let basic_red = Basic.to_color (Basic.of_string "basic-red") in
  Alcotest.(check v4_testable) "dark red -> basic-red"
    basic_red nearest;

  (* Test with very dark color -> basic-black *)
  let very_dark = rgb 10 10 10 in
  let nearest_dark = Basic.nearest very_dark in
  let basic_black = Basic.to_color (Basic.of_string "basic-black") in
  Alcotest.(check v4_testable) "very dark -> basic-black"
    basic_black nearest_dark

(* ===== Xterm256 Palette Tests ===== *)

let test_xterm256_of_string_valid () =
  (* Test valid kebab-case conversions *)
  let is_valid name =
    try ignore (Xterm256.of_string name); true
    with InvalidColorName _ -> false
  in
  Alcotest.(check bool) "black valid" true (is_valid "black");
  Alcotest.(check bool) "maroon valid" true (is_valid "maroon");
  Alcotest.(check bool) "green valid" true (is_valid "green");
  Alcotest.(check bool) "red valid" true (is_valid "red");
  (* Test a complex disambiguated name *)
  Alcotest.(check bool) "dark-olive-green-1a valid" true
    (is_valid "dark-olive-green-1a")

let test_xterm256_of_string_case_insensitive () =
  (* PPX-generated of_string should be case-insensitive *)
  let is_valid name =
    try ignore (Xterm256.of_string name); true
    with InvalidColorName _ -> false
  in
  Alcotest.(check bool) "Red (title case)" true (is_valid "Red");
  Alcotest.(check bool) "BLACK (all caps)" true (is_valid "BLACK");
  Alcotest.(check bool) "Dark-Olive-Green-1a (mixed case)" true (is_valid "Dark-Olive-Green-1a")

let test_xterm256_of_string_invalid () =
  Alcotest.check_raises "invalid color name"
    (InvalidColorName "notacolor")
    (fun () -> ignore (Xterm256.of_string "notacolor"))

let test_xterm256_to_code () =
  (* Test known code mappings *)
  Alcotest.(check int) "black -> 0" 0
    (Xterm256.to_code (Xterm256.of_string "black"));
  Alcotest.(check int) "maroon -> 1" 1
    (Xterm256.to_code (Xterm256.of_string "maroon"));
  Alcotest.(check int) "green -> 2" 2
    (Xterm256.to_code (Xterm256.of_string "green"));

  (* Test code range - should be 0-255 *)
  List.iter (fun color ->
      let code = Xterm256.to_code (Xterm256.of_string color) in
      Alcotest.(check bool) (Printf.sprintf "%s code in range" color) true
        (code >= 0 && code <= 255)
    ) ["black"; "red"; "green"; "yellow"; "blue"; "fuchsia"; "teal"; "white"]

let test_xterm256_to_color () =
  (* Test known RGB values *)
  let black = Xterm256.to_color (Xterm256.of_string "black") in
  Alcotest.(check v4_testable) "black is RGB(0,0,0)"
    (rgb 0 0 0) black;

  let maroon = Xterm256.to_color (Xterm256.of_string "maroon") in
  Alcotest.(check v4_testable) "maroon is RGB(128,0,0)"
    (rgb 128 0 0) maroon;

  let green = Xterm256.to_color (Xterm256.of_string "green") in
  Alcotest.(check v4_testable) "green is RGB(0,128,0)"
    (rgb 0 128 0) green;

  let white = Xterm256.to_color (Xterm256.of_string "white") in
  Alcotest.(check v4_testable) "white is RGB(255,255,255)"
    (rgb 255 255 255) white

let test_xterm256_color_list () =
  Alcotest.(check int) "Xterm256 has 256 colors" 256
    (List.length Xterm256.color_list);

  (* All colors should be valid Gg.v4 *)
  List.iter (fun color ->
      let c = Gg.Color.to_srgb color in
      Alcotest.(check bool) "valid color values" true
        (Gg.Color.r c >= 0. && Gg.Color.r c <= 1. &&
         Gg.Color.g c >= 0. && Gg.Color.g c <= 1. &&
         Gg.Color.b c >= 0. && Gg.Color.b c <= 1.)
    ) Xterm256.color_list

let test_xterm256_nearest_exact () =
  (* When given exact palette color, should return same color *)
  let red = Xterm256.to_color (Xterm256.of_string "red") in
  let nearest = Xterm256.nearest red in
  Alcotest.(check v4_testable) "exact red returns same"
    red nearest

let test_xterm256_nearest_approximate () =
  (* Test with color between palette values *)
  let orange_ish = rgb 255 128 0 in
  let nearest = Xterm256.nearest orange_ish in
  (* Should be close to an orange/yellow color in palette *)
  let c = Gg.Color.to_srgb nearest in
  let r = int_of_float (Float.round (255. *. Gg.Color.r c)) in
  let g = int_of_float (Float.round (255. *. Gg.Color.g c)) in
  Alcotest.(check bool) "orange-ish has high red" true (r > 200);
  Alcotest.(check bool) "orange-ish has medium-high green" true (g > 100);

  (* Test with very dark color -> should map to very dark palette color *)
  let very_dark = rgb 5 5 5 in
  let nearest_dark = Xterm256.nearest very_dark in
  let c = Gg.Color.to_srgb nearest_dark in
  let r = int_of_float (Float.round (255. *. Gg.Color.r c)) in
  let g = int_of_float (Float.round (255. *. Gg.Color.g c)) in
  let b = int_of_float (Float.round (255. *. Gg.Color.b c)) in
  (* Should map to a very dark color (all components < 20) *)
  Alcotest.(check bool) "very dark maps to dark color" true
    (r < 20 && g < 20 && b < 20)

let test_xterm256_nearest_grayscale () =
  (* Xterm256 has a grayscale ramp - test it works *)
  let gray50 = rgb 128 128 128 in
  let nearest = Xterm256.nearest gray50 in
  let c = Gg.Color.to_srgb nearest in
  let r = int_of_float (Float.round (255. *. Gg.Color.r c)) in
  let g = int_of_float (Float.round (255. *. Gg.Color.g c)) in
  let b = int_of_float (Float.round (255. *. Gg.Color.b c)) in
  (* Should map to a neutral gray (r ≈ g ≈ b) *)
  Alcotest.(check bool) "gray maps to neutral color" true
    (abs (r - g) < 30 && abs (g - b) < 30 && abs (r - b) < 30)

(* ===== Test Suite ===== *)

let () =
  Test_runner.run "Terminal" ~junit_filename:"junit-terminal.xml" [
    "Basic - String conversion", [
      test_case "valid color names" `Quick test_basic_of_string_valid;
      test_case "case-insensitive lookup" `Quick test_basic_of_string_case_insensitive;
      test_case "invalid color names" `Quick test_basic_of_string_invalid;
    ];
    "Basic - Code mapping", [
      test_case "to_code for all colors" `Quick test_basic_to_code;
    ];
    "Basic - Color conversion", [
      test_case "to_color returns correct RGB" `Quick test_basic_to_color;
    ];
    "Basic - Color list", [
      test_case "color_list has 16 valid colors" `Quick test_basic_color_list;
    ];
    "Basic - Nearest color", [
      test_case "exact match returns same" `Quick test_basic_nearest_exact;
      test_case "approximate match finds closest" `Quick test_basic_nearest_approximate;
    ];
    "Xterm256 - String conversion", [
      test_case "valid color names" `Quick test_xterm256_of_string_valid;
      test_case "case-insensitive lookup" `Quick test_xterm256_of_string_case_insensitive;
      test_case "invalid color names" `Quick test_xterm256_of_string_invalid;
    ];
    "Xterm256 - Code mapping", [
      test_case "to_code for sample colors" `Quick test_xterm256_to_code;
    ];
    "Xterm256 - Color conversion", [
      test_case "to_color returns correct RGB" `Quick test_xterm256_to_color;
    ];
    "Xterm256 - Color list", [
      test_case "color_list has 256 valid colors" `Quick test_xterm256_color_list;
    ];
    "Xterm256 - Nearest color", [
      test_case "exact match returns same" `Quick test_xterm256_nearest_exact;
      test_case "approximate match finds closest" `Quick test_xterm256_nearest_approximate;
      test_case "grayscale mapping" `Quick test_xterm256_nearest_grayscale;
    ];
  ]
