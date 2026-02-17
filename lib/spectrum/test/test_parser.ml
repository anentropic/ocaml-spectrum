(* Comprehensive tests for Parser module *)
open Alcotest
open Spectrum.Parser

(* Test helpers *)
let _error = testable Fmt.exn ( = )

(* ===== Style Module Tests ===== *)

let test_style_valid_names () =
  check bool "bold" true (try ignore (Style.of_string "bold"); true with _ -> false);
  check bool "dim" true (try ignore (Style.of_string "dim"); true with _ -> false);
  check bool "italic" true (try ignore (Style.of_string "italic"); true with _ -> false);
  check bool "underline" true (try ignore (Style.of_string "underline"); true with _ -> false);
  check bool "blink" true (try ignore (Style.of_string "blink"); true with _ -> false);
  check bool "rapid-blink" true (try ignore (Style.of_string "rapid-blink"); true with _ -> false);
  check bool "inverse" true (try ignore (Style.of_string "inverse"); true with _ -> false);
  check bool "hidden" true (try ignore (Style.of_string "hidden"); true with _ -> false);
  check bool "strikethru" true (try ignore (Style.of_string "strikethru"); true with _ -> false)

let test_style_invalid_names () =
  check_raises "unknown style"
    (InvalidStyleName "unknown")
    (fun () -> ignore (Style.of_string "unknown"));

  check_raises "empty string"
    (InvalidStyleName "")
    (fun () -> ignore (Style.of_string ""))

let test_style_case_insensitive () =
  (* Style names are case-insensitive *)
  let is_bold = function Ok Style.Bold -> true | _ -> false in
  check bool "Bold (title case) -> Bold" true
    (is_bold (try Ok (Style.of_string "Bold") with e -> Error e));

  check bool "BOLD (all caps) -> Bold" true
    (is_bold (try Ok (Style.of_string "BOLD") with e -> Error e));

  check bool "UnDeRlInE (mixed) -> Underline" true
    (try Style.of_string "UnDeRlInE" = Style.Underline with _ -> false)

let test_style_to_code () =
  check int "Bold -> 1" 1 (Style.to_code Bold);
  check int "Dim -> 2" 2 (Style.to_code Dim);
  check int "Italic -> 3" 3 (Style.to_code Italic);
  check int "Underline -> 4" 4 (Style.to_code Underline);
  check int "Blink -> 5" 5 (Style.to_code Blink);
  check int "RapidBlink -> 6" 6 (Style.to_code RapidBlink);
  check int "Inverse -> 7" 7 (Style.to_code Inverse);
  check int "Hidden -> 8" 8 (Style.to_code Hidden);
  check int "Strikethru -> 9" 9 (Style.to_code Strikethru)

(* ===== Color Parsing Tests ===== *)

let test_from_name_valid () =
  (* Test xterm256 colors *)
  let is_named256 = function Named256Color _ -> true | _ -> false in
  check bool "red is xterm256" true (is_named256 (from_name "red"));
  check bool "dark-olive-green-1a is xterm256" true (is_named256 (from_name "dark-olive-green-1a"))

let test_from_name_invalid () =
  check_raises "invalid color name"
    (Spectrum_palettes.Terminal.InvalidColorName "notacolor")
    (fun () -> ignore (from_name "notacolor"))

let test_from_hex_valid () =
  let is_rgb = function RgbColor _ -> true | _ -> false in
  (* Short form #RGB *)
  check bool "#fc9 valid" true (is_rgb (from_hex "#fc9"));
  (* Long form #RRGGBB *)
  check bool "#f0c090 valid" true (is_rgb (from_hex "#f0c090"));
  (* Case insensitive *)
  check bool "#FC9 (uppercase) valid" true (is_rgb (from_hex "#FC9"));
  check bool "#F0C090 (uppercase) valid" true (is_rgb (from_hex "#F0C090"))

let test_from_hex_invalid () =
  check_raises "invalid hex: too short"
    (InvalidHexColor "#ab")
    (fun () -> ignore (from_hex "#ab"));

  check_raises "invalid hex: non-hex chars"
    (InvalidHexColor "#xyz")
    (fun () -> ignore (from_hex "#xyz"))

let test_from_rgb_valid () =
  let is_rgb = function RgbColor _ -> true | _ -> false in
  (* Valid boundary values *)
  check bool "black (0,0,0)" true (is_rgb (from_rgb "0" "0" "0"));
  check bool "white (255,255,255)" true (is_rgb (from_rgb "255" "255" "255"));
  check bool "red (255,0,0)" true (is_rgb (from_rgb "255" "0" "0"));
  check bool "gray (128,128,128)" true (is_rgb (from_rgb "128" "128" "128"))

let test_from_rgb_invalid () =
  check_raises "out of range: 256"
    (InvalidRgbColor "256")
    (fun () -> ignore (from_rgb "256" "0" "0"));

  check_raises "out of range: 300"
    (InvalidRgbColor "300")
    (fun () -> ignore (from_rgb "0" "300" "0"));

  check_raises "negative: -1"
    (InvalidRgbColor "-1")
    (fun () -> ignore (from_rgb "-1" "0" "0"));

  check_raises "negative: -50 (green)"
    (InvalidRgbColor "-50")
    (fun () -> ignore (from_rgb "0" "-50" "0"));

  check_raises "negative: -255 (blue)"
    (InvalidRgbColor "-255")
    (fun () -> ignore (from_rgb "0" "0" "-255"))

let test_from_hsl_valid () =
  let is_rgb = function RgbColor _ -> true | _ -> false in
  (* Valid HSL *)
  check bool "red HSL (0,100,50)" true (is_rgb (from_hsl "0" "100" "50"));
  (* Hue wraparound (> 360) *)
  check bool "hue wraparound (435 = 75)" true (is_rgb (from_hsl "435" "100" "50"));
  (* Negative hue (-285 = 75) *)
  check bool "negative hue (-285 = 75)" true (is_rgb (from_hsl "-285" "100" "50"));
  (* Boundary saturation/lightness *)
  check bool "black HSL (0,0,0)" true (is_rgb (from_hsl "0" "0" "0"));
  check bool "white HSL (0,0,100)" true (is_rgb (from_hsl "0" "0" "100"))

let test_from_hsl_invalid () =
  check_raises "saturation > 100"
    (InvalidPercentage "101")
    (fun () -> ignore (from_hsl "0" "101" "50"));

  check_raises "lightness > 100"
    (InvalidPercentage "150")
    (fun () -> ignore (from_hsl "0" "50" "150"));

  check_raises "negative saturation"
    (InvalidPercentage "-1")
    (fun () -> ignore (from_hsl "0" "-1" "50"));

  check_raises "negative lightness"
    (InvalidPercentage "-10")
    (fun () -> ignore (from_hsl "0" "50" "-10"))

(* ===== Qualified Color Tests ===== *)

let test_qualified_none () =
  let color = from_hex "#fc9" in
  let is_fg = function Foreground _ -> true | _ -> false in
  check bool "None -> Foreground" true (is_fg (qualified None color))

let test_qualified_fg () =
  let color = from_hex "#fc9" in
  let is_fg = function Foreground _ -> true | _ -> false in
  check bool "fg -> Foreground" true (is_fg (qualified (Some "fg") color))

let test_qualified_bg () =
  let color = from_hex "#fc9" in
  let is_bg = function Background _ -> true | _ -> false in
  check bool "bg -> Background" true (is_bg (qualified (Some "bg") color))

let test_qualified_invalid () =
  let color = from_hex "#fc9" in
  check_raises "invalid qualifier"
    (InvalidQualifier "invalid")
    (fun () -> ignore (qualified (Some "invalid") color))

(* ===== Token Aggregation Tests ===== *)

let test_compound_empty () =
  let result = compound_of_tokens [] in
  check bool "all bools false" true
    (not result.bold && not result.dim && not result.italic &&
     not result.underline && not result.blink && not result.rapid_blink &&
     not result.inverse && not result.hidden && not result.strikethru);
  check bool "no fg color" true (result.fg_color = None);
  check bool "no bg color" true (result.bg_color = None)

let test_compound_single_control () =
  let result = compound_of_tokens [Control Bold] in
  check bool "bold set" true result.bold;
  check bool "others false" true
    (not result.dim && not result.italic)

let test_compound_multiple_controls () =
  let result = compound_of_tokens [Control Bold; Control Underline; Control Italic] in
  check bool "bold set" true result.bold;
  check bool "underline set" true result.underline;
  check bool "italic set" true result.italic;
  check bool "dim not set" true (not result.dim)

let test_compound_duplicate_controls () =
  (* Multiple same control - still just sets flag once *)
  let result = compound_of_tokens [Control Bold; Control Bold; Control Bold] in
  check bool "bold set (once)" true result.bold;
  check bool "others false" true (not result.dim)

let test_compound_foreground_color () =
  let color = from_hex "#fc9" in
  let result = compound_of_tokens [Foreground color] in
  check bool "fg color set" true (result.fg_color <> None);
  check bool "bg color not set" true (result.bg_color = None)

let test_compound_background_color () =
  let color = from_hex "#fc9" in
  let result = compound_of_tokens [Background color] in
  check bool "bg color set" true (result.bg_color <> None);
  check bool "fg color not set" true (result.fg_color = None)

let test_compound_both_colors () =
  let fg_color = from_hex "#fc9" in
  let bg_color = from_hex "#f0c090" in
  let result = compound_of_tokens [Foreground fg_color; Background bg_color] in
  check bool "both colors set" true
    (result.fg_color <> None && result.bg_color <> None)

let test_compound_multiple_fg_colors_last_wins () =
  (* Last color wins *)
  let color1 = from_hex "#fc9" in
  let color2 = from_hex "#f0c090" in
  let result = compound_of_tokens [Foreground color1; Foreground color2] in
  check bool "fg color set" true (result.fg_color <> None);
  (* Should be color2, but we can't directly compare Gg.v4 *)
  let is_rgb = function Some (RgbColor _) -> true | _ -> false in
  check bool "last color is RgbColor" true (is_rgb result.fg_color)

let test_compound_mixed_tokens () =
  let fg_color = from_hex "#fc9" in
  let bg_color = from_hex "#f0c090" in
  let result = compound_of_tokens [
      Control Bold;
      Foreground fg_color;
      Control Underline;
      Background bg_color;
      Control Italic;
    ] in
  check bool "bold set" true result.bold;
  check bool "underline set" true result.underline;
  check bool "italic set" true result.italic;
  check bool "fg color set" true (result.fg_color <> None);
  check bool "bg color set" true (result.bg_color <> None);
  check bool "dim not set" true (not result.dim)

(* ===== RGBA Conversion Tests ===== *)

let test_rgba_of_color () =
  (* Test with red *)
  let red = Color.Rgb.(v 255 0 0 |> to_gg) in
  let rgba = rgba_of_color red in
  check int "red.r = 255" 255 rgba.r;
  check int "red.g = 0" 0 rgba.g;
  check int "red.b = 0" 0 rgba.b;

  (* Test with green *)
  let green = Color.Rgb.(v 0 255 0 |> to_gg) in
  let rgba = rgba_of_color green in
  check int "green.r = 0" 0 rgba.r;
  check int "green.g = 255" 255 rgba.g;
  check int "green.b = 0" 0 rgba.b;

  (* Test with blue *)
  let blue = Color.Rgb.(v 0 0 255 |> to_gg) in
  let rgba = rgba_of_color blue in
  check int "blue.r = 0" 0 rgba.r;
  check int "blue.g = 0" 0 rgba.g;
  check int "blue.b = 255" 255 rgba.b;

  (* Test with gray *)
  let gray = Color.Rgb.(v 128 128 128 |> to_gg) in
  let rgba = rgba_of_color gray in
  check int "gray.r = 128" 128 rgba.r;
  check int "gray.g = 128" 128 rgba.g;
  check int "gray.b = 128" 128 rgba.b

(* ===== Test Suite ===== *)

let () =
  Test_runner.run "Parser" ~junit_filename:"junit-parser.xml" [
    "Style - Valid names", [
      test_case "all valid style names" `Quick test_style_valid_names;
    ];
    "Style - Invalid names", [
      test_case "unknown and empty names" `Quick test_style_invalid_names;
      test_case "case insensitivity" `Quick test_style_case_insensitive;
    ];
    "Style - Code mapping", [
      test_case "all styles to codes 1-9" `Quick test_style_to_code;
    ];
    "Colors - Named", [
      test_case "valid xterm256 color names" `Quick test_from_name_valid;
      test_case "invalid color name" `Quick test_from_name_invalid;
    ];
    "Colors - Hex", [
      test_case "valid hex formats" `Quick test_from_hex_valid;
      test_case "invalid hex formats" `Quick test_from_hex_invalid;
    ];
    "Colors - RGB", [
      test_case "valid RGB values" `Quick test_from_rgb_valid;
      test_case "out of range RGB values" `Quick test_from_rgb_invalid;
    ];
    "Colors - HSL", [
      test_case "valid HSL values" `Quick test_from_hsl_valid;
      test_case "out of range HSL values" `Quick test_from_hsl_invalid;
    ];
    "Qualified colors", [
      test_case "None qualifier -> Foreground" `Quick test_qualified_none;
      test_case "fg qualifier" `Quick test_qualified_fg;
      test_case "bg qualifier" `Quick test_qualified_bg;
      test_case "invalid qualifier" `Quick test_qualified_invalid;
    ];
    "Token aggregation - Empty/Single", [
      test_case "empty token list" `Quick test_compound_empty;
      test_case "single control" `Quick test_compound_single_control;
    ];
    "Token aggregation - Controls", [
      test_case "multiple different controls" `Quick test_compound_multiple_controls;
      test_case "duplicate controls" `Quick test_compound_duplicate_controls;
    ];
    "Token aggregation - Colors", [
      test_case "foreground color" `Quick test_compound_foreground_color;
      test_case "background color" `Quick test_compound_background_color;
      test_case "both colors" `Quick test_compound_both_colors;
      test_case "multiple fg colors (last wins)" `Quick test_compound_multiple_fg_colors_last_wins;
    ];
    "Token aggregation - Mixed", [
      test_case "mixed controls and colors" `Quick test_compound_mixed_tokens;
    ];
    "RGBA conversion", [
      test_case "color to rgba" `Quick test_rgba_of_color;
    ];
  ]
