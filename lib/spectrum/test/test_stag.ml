(* Use explicit True_color serializer to isolate tests from the runtime
   environment (e.g. CI where GITHUB_ACTIONS causes Basic serializer) *)
module Tc_printer : Spectrum.Printer =
  (val Spectrum.Private.make_printer true Spectrum.Private.True_color_Serializer.to_code)

let sprintf_with_stag stag text =
  let b = Buffer.create 512 in
  let ppf = Format.formatter_of_buffer b in
  let reset = Tc_printer.prepare_ppf ppf in
  Format.pp_open_stag ppf stag;
  Format.pp_print_string ppf text;
  Format.pp_close_stag ppf ();
  Format.pp_print_flush ppf ();
  let result = Buffer.contents b in
  Buffer.reset b;
  reset ();
  result

(* Styles *)

let test_bold () =
  let open Spectrum.Stag in
  let result = sprintf_with_stag (stag [Bold]) "hello" in
  Alcotest.(check string) "bold" "\027[0;1mhello\027[0m" result

let test_dim () =
  let open Spectrum.Stag in
  let result = sprintf_with_stag (stag [Dim]) "hello" in
  Alcotest.(check string) "dim" "\027[0;2mhello\027[0m" result

let test_italic () =
  let open Spectrum.Stag in
  let result = sprintf_with_stag (stag [Italic]) "hello" in
  Alcotest.(check string) "italic" "\027[0;3mhello\027[0m" result

let test_underline () =
  let open Spectrum.Stag in
  let result = sprintf_with_stag (stag [Underline]) "hello" in
  Alcotest.(check string) "underline" "\027[0;4mhello\027[0m" result

let test_blink () =
  let open Spectrum.Stag in
  let result = sprintf_with_stag (stag [Blink]) "hello" in
  Alcotest.(check string) "blink" "\027[0;5mhello\027[0m" result

let test_rapid_blink () =
  let open Spectrum.Stag in
  let result = sprintf_with_stag (stag [RapidBlink]) "hello" in
  Alcotest.(check string) "rapid blink" "\027[0;6mhello\027[0m" result

let test_inverse () =
  let open Spectrum.Stag in
  let result = sprintf_with_stag (stag [Inverse]) "hello" in
  Alcotest.(check string) "inverse" "\027[0;7mhello\027[0m" result

let test_hidden () =
  let open Spectrum.Stag in
  let result = sprintf_with_stag (stag [Hidden]) "hello" in
  Alcotest.(check string) "hidden" "\027[0;8mhello\027[0m" result

let test_strikethru () =
  let open Spectrum.Stag in
  let result = sprintf_with_stag (stag [Strikethru]) "hello" in
  Alcotest.(check string) "strikethru" "\027[0;9mhello\027[0m" result

(* Foreground colors *)

let test_fg_named () =
  let open Spectrum.Stag in
  let result = sprintf_with_stag (stag [Fg (Named "red")]) "hello" in
  Alcotest.(check string) "fg named red" "\027[0;38;5;9mhello\027[0m" result

let test_fg_hex_short () =
  let open Spectrum.Stag in
  let result = sprintf_with_stag (stag [Fg (Hex "FC9")]) "hello" in
  Alcotest.(check string) "fg hex short" "\027[0;38;2;255;204;153mhello\027[0m" result

let test_fg_hex_long () =
  let open Spectrum.Stag in
  let result = sprintf_with_stag (stag [Fg (Hex "f0c090")]) "hello" in
  Alcotest.(check string) "fg hex long" "\027[0;38;2;240;192;144mhello\027[0m" result

let test_fg_rgb () =
  let open Spectrum.Stag in
  let result = sprintf_with_stag (stag [Fg (Rgb (9, 21, 231))]) "hello" in
  Alcotest.(check string) "fg rgb" "\027[0;38;2;9;21;231mhello\027[0m" result

let test_fg_hsl () =
  let open Spectrum.Stag in
  let result = sprintf_with_stag (stag [Fg (Hsl (75., 100., 50.))]) "hello" in
  Alcotest.(check string) "fg hsl" "\027[0;38;2;191;255;0mhello\027[0m" result

(* Background colors *)

let test_bg_named () =
  let open Spectrum.Stag in
  let result = sprintf_with_stag (stag [Bg (Named "red")]) "hello" in
  Alcotest.(check string) "bg named red" "\027[0;48;5;9mhello\027[0m" result

let test_bg_hex () =
  let open Spectrum.Stag in
  let result = sprintf_with_stag (stag [Bg (Hex "FC9")]) "hello" in
  Alcotest.(check string) "bg hex" "\027[0;48;2;255;204;153mhello\027[0m" result

let test_bg_rgb () =
  let open Spectrum.Stag in
  let result = sprintf_with_stag (stag [Bg (Rgb (0, 0, 255))]) "hello" in
  Alcotest.(check string) "bg rgb" "\027[0;48;2;0;0;255mhello\027[0m" result

(* Compound tags *)

let test_compound_style_and_fg () =
  let open Spectrum.Stag in
  let result = sprintf_with_stag (stag [Bold; Fg (Named "red")]) "hello" in
  Alcotest.(check string) "bold+fg" "\027[0;1;38;5;9mhello\027[0m" result

let test_compound_style_fg_bg () =
  let open Spectrum.Stag in
  let result = sprintf_with_stag (stag [Bold; Fg (Named "red"); Bg (Hex "0000FF")]) "hello" in
  Alcotest.(check string) "bold+fg+bg" "\027[0;1;38;5;9;48;2;0;0;255mhello\027[0m" result

(* Nesting *)

let test_nesting () =
  let open Spectrum.Stag in
  let b = Buffer.create 512 in
  let ppf = Format.formatter_of_buffer b in
  let reset = Tc_printer.prepare_ppf ppf in
  Format.pp_open_stag ppf (stag [Fg (Named "red")]);
  Format.pp_print_string ppf "one";
  Format.pp_open_stag ppf (stag [Bold]);
  Format.pp_print_string ppf "two";
  Format.pp_close_stag ppf ();
  Format.pp_print_string ppf "one";
  Format.pp_close_stag ppf ();
  Format.pp_print_flush ppf ();
  let result = Buffer.contents b in
  reset ();
  Alcotest.(check string) "nested stags"
    "\027[0;38;5;9mone\027[0;38;5;9;1mtwo\027[0;38;5;9mone\027[0m" result

(* Mixing stag and string tags *)

let test_mixed_stag_and_string () =
  let b = Buffer.create 512 in
  let ppf = Format.formatter_of_buffer b in
  let reset = Tc_printer.prepare_ppf ppf in
  Format.pp_open_stag ppf (Spectrum.Stag.stag [Spectrum.Stag.Bold]);
  Format.pp_print_string ppf "bold";
  Format.pp_close_stag ppf ();
  Format.pp_open_stag ppf (Format.String_tag "red");
  Format.pp_print_string ppf "red";
  Format.pp_close_stag ppf ();
  Format.pp_print_flush ppf ();
  let result = Buffer.contents b in
  reset ();
  Alcotest.(check string) "stag then string tag"
    "\027[0;1mbold\027[0m\027[0;38;5;9mred\027[0m" result

(* Error handling *)

let test_invalid_color_name () =
  Alcotest.check_raises "invalid color name"
    (Spectrum_palette_ppx.Palette.InvalidColorName "xxx")
    (fun () -> ignore (Spectrum.Stag.stag [Spectrum.Stag.Fg (Spectrum.Stag.Named "xxx")]))

let test_invalid_hex () =
  let caught = ref false in
  (try ignore (Spectrum.Stag.stag [Spectrum.Stag.Fg (Spectrum.Stag.Hex "ZZ")])
   with _ -> caught := true);
  Alcotest.(check bool) "invalid hex raises" true !caught

let test_invalid_rgb_range () =
  Alcotest.check_raises "rgb out of range"
    (Spectrum.Parser.InvalidRgbColor "300")
    (fun () -> ignore (Spectrum.Stag.stag [Spectrum.Stag.Fg (Spectrum.Stag.Rgb (300, 0, 0))]))

let () =
  Test_runner.run "Stag" ~junit_filename:"junit-stag.xml" [
    "Styles", [
      Alcotest.test_case "Bold" `Quick test_bold;
      Alcotest.test_case "Dim" `Quick test_dim;
      Alcotest.test_case "Italic" `Quick test_italic;
      Alcotest.test_case "Underline" `Quick test_underline;
      Alcotest.test_case "Blink" `Quick test_blink;
      Alcotest.test_case "RapidBlink" `Quick test_rapid_blink;
      Alcotest.test_case "Inverse" `Quick test_inverse;
      Alcotest.test_case "Hidden" `Quick test_hidden;
      Alcotest.test_case "Strikethru" `Quick test_strikethru;
    ];
    "Foreground colors", [
      Alcotest.test_case "Named: red" `Quick test_fg_named;
      Alcotest.test_case "Hex short: FC9" `Quick test_fg_hex_short;
      Alcotest.test_case "Hex long: f0c090" `Quick test_fg_hex_long;
      Alcotest.test_case "Rgb: (9, 21, 231)" `Quick test_fg_rgb;
      Alcotest.test_case "Hsl: (75, 100, 50)" `Quick test_fg_hsl;
    ];
    "Background colors", [
      Alcotest.test_case "Named: red" `Quick test_bg_named;
      Alcotest.test_case "Hex: FC9" `Quick test_bg_hex;
      Alcotest.test_case "Rgb: (0, 0, 255)" `Quick test_bg_rgb;
    ];
    "Compound tags", [
      Alcotest.test_case "Bold + Fg" `Quick test_compound_style_and_fg;
      Alcotest.test_case "Bold + Fg + Bg" `Quick test_compound_style_fg_bg;
    ];
    "Nesting", [
      Alcotest.test_case "Nested stags" `Quick test_nesting;
    ];
    "Mixed stag and string tags", [
      Alcotest.test_case "Stag then string tag" `Quick test_mixed_stag_and_string;
    ];
    "Error handling", [
      Alcotest.test_case "Invalid color name" `Quick test_invalid_color_name;
      Alcotest.test_case "Invalid hex" `Quick test_invalid_hex;
      Alcotest.test_case "Invalid RGB range" `Quick test_invalid_rgb_range;
    ];
  ]
