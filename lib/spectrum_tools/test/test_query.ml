(* Comprehensive tests for Query module *)
open Alcotest
open Spectrum_tools.Query

(* Test helpers *)

let v4_testable = testable (fun ppf v ->
    let c = Gg.Color.to_srgb v in
    let r = int_of_float (Float.round (255. *. Gg.Color.r c)) in
    let g = int_of_float (Float.round (255. *. Gg.Color.g c)) in
    let b = int_of_float (Float.round (255. *. Gg.Color.b c)) in
    Format.fprintf ppf "RGB(%d,%d,%d)" r g b
  ) ( = )

let rgb r g b = Color.Rgb.(v r g b |> to_gg)

(* ===== hex_to_8bit Tests (Pure Function) ===== *)

let test_hex_to_8bit_single_char () =
  (* Single hex char: scales from 0-F to 0-255 *)
  check int "0 -> 0" 0 (Xterm.hex_to_8bit "0");
  check int "F -> 255" 255 (Xterm.hex_to_8bit "F");
  check int "f -> 255 (lowercase)" 255 (Xterm.hex_to_8bit "f");
  check int "C -> 204" 204 (Xterm.hex_to_8bit "C");
  check int "8 -> 136" 136 (Xterm.hex_to_8bit "8")

let test_hex_to_8bit_two_chars () =
  (* Two hex chars: standard 0-FF to 0-255 *)
  check int "00 -> 0" 0 (Xterm.hex_to_8bit "00");
  check int "FF -> 255" 255 (Xterm.hex_to_8bit "FF");
  check int "C3 -> 195" 195 (Xterm.hex_to_8bit "C3");
  check int "80 -> 128" 128 (Xterm.hex_to_8bit "80");
  check int "7F -> 127" 127 (Xterm.hex_to_8bit "7F")

let test_hex_to_8bit_three_chars () =
  (* Three hex chars: scales from 0-FFF to 0-255 *)
  check int "000 -> 0" 0 (Xterm.hex_to_8bit "000");
  check int "FFF -> 255" 255 (Xterm.hex_to_8bit "FFF");
  check int "C3B -> 195" 195 (Xterm.hex_to_8bit "C3B");
  check int "800 -> 128" 128 (Xterm.hex_to_8bit "800")

let test_hex_to_8bit_four_chars () =
  (* Four hex chars: scales from 0-FFFF to 0-255 *)
  check int "0000 -> 0" 0 (Xterm.hex_to_8bit "0000");
  check int "FFFF -> 255" 255 (Xterm.hex_to_8bit "FFFF");
  check int "CCCC -> 204" 204 (Xterm.hex_to_8bit "CCCC");
  check int "C3C3 -> 195" 195 (Xterm.hex_to_8bit "C3C3");
  check int "8000 -> 128" 128 (Xterm.hex_to_8bit "8000")

let test_hex_to_8bit_empty_string () =
  (* Empty string should raise, not crash with division by zero *)
  check_raises "empty string"
    (Invalid_argument "hex_to_8bit: empty string")
    (fun () -> ignore (Xterm.hex_to_8bit ""))

let test_hex_to_8bit_invalid_chars () =
  (* Invalid hex characters should raise Invalid_argument *)
  check_raises "invalid char 'g'"
    (Invalid_argument "hex_to_8bit: invalid hex character 'g' in string \"gg\"")
    (fun () -> ignore (Xterm.hex_to_8bit "gg"));
  check_raises "invalid char 'z'"
    (Invalid_argument "hex_to_8bit: invalid hex character 'z' in string \"xyz\"")
    (fun () -> ignore (Xterm.hex_to_8bit "xyz"));
  check_raises "invalid char '!'"
    (Invalid_argument "hex_to_8bit: invalid hex character '!' in string \"12!@\"")
    (fun () -> ignore (Xterm.hex_to_8bit "12!@"));
  check_raises "invalid char ' '"
    (Invalid_argument "hex_to_8bit: invalid hex character ' ' in string \"FF FF\"")
    (fun () -> ignore (Xterm.hex_to_8bit "FF FF"))

let test_hex_to_8bit_scaling_consistency () =
  (* Verify that scaling is consistent across widths *)
  (* C, CC, CCC, CCCC should all give approximately the same value *)
  let c1 = Xterm.hex_to_8bit "C" in
  let c2 = Xterm.hex_to_8bit "CC" in
  let c3 = Xterm.hex_to_8bit "CCC" in
  let c4 = Xterm.hex_to_8bit "CCCC" in

  check int "C ≈ CC" c1 c2;
  check int "CC ≈ CCC" c2 c3;
  check int "CCC ≈ CCCC" c3 c4;

  (* All should be around 204 *)
  check bool "all C's are 204" true
    (c1 = 204 && c2 = 204 && c3 = 204 && c4 = 204)

(* ===== parse_colour Tests (Pure Function) ===== *)

let test_parse_colour_valid () =
  (* Valid rgb: format with 4-char hex values (lowercase) *)
  let result = Xterm.parse_colour "rgb:ffff/0000/0000" in
  match result with
  | Ok color ->
    check v4_testable "rgb:ffff/0000/0000 is red"
      (rgb 255 0 0) color
  | Error _ ->
    fail "Expected Ok, got Error"

let test_parse_colour_valid_green () =
  let result = Xterm.parse_colour "rgb:0000/ffff/0000" in
  match result with
  | Ok color ->
    check v4_testable "rgb:0000/ffff/0000 is green"
      (rgb 0 255 0) color
  | Error _ ->
    fail "Expected Ok, got Error"

let test_parse_colour_valid_blue () =
  let result = Xterm.parse_colour "rgb:0000/0000/ffff" in
  match result with
  | Ok color ->
    check v4_testable "rgb:0000/0000/ffff is blue"
      (rgb 0 0 255) color
  | Error _ ->
    fail "Expected Ok, got Error"

let test_parse_colour_mixed_widths () =
  (* Different hex widths in same string *)
  let result = Xterm.parse_colour "rgb:ff/80/c3" in
  match result with
  | Ok color ->
    check v4_testable "rgb:ff/80/c3 mixes 2-char values"
      (rgb 255 128 195) color
  | Error _ ->
    fail "Expected Ok, got Error"

let test_parse_colour_uppercase () =
  (* Uppercase hex chars return Error (regex only matches lowercase) *)
  let result = Xterm.parse_colour "rgb:FFFF/0000/0000" in
  match result with
  | Error msg ->
    check string "uppercase hex error message"
      "Unrecognised colour string: rgb:FFFF/0000/0000" msg
  | Ok _ ->
    fail "Expected Error, got Ok"

let test_parse_colour_invalid_format () =
  (* Invalid format - missing 'rgb:' prefix *)
  let result = Xterm.parse_colour "FFFF/0000/0000" in
  match result with
  | Error msg ->
    check string "missing prefix error message"
      "Unrecognised colour string: FFFF/0000/0000" msg
  | Ok _ ->
    fail "Expected Error, got Ok"

let test_parse_colour_invalid_separators () =
  (* Invalid separators *)
  let result1 = Xterm.parse_colour "rgb:ffff:0000:0000" in
  (match result1 with
   | Error msg ->
     check string "colon separator error"
       "Unrecognised colour string: rgb:ffff:0000:0000" msg
   | Ok _ ->
     fail "Expected Error for colon separator");

  let result2 = Xterm.parse_colour "rgb:ffff,0000,0000" in
  (match result2 with
   | Error msg ->
     check string "comma separator error"
       "Unrecognised colour string: rgb:ffff,0000,0000" msg
   | Ok _ ->
     fail "Expected Error for comma separator")

let test_parse_colour_invalid_hex () =
  (* Non-hex characters *)
  let result = Xterm.parse_colour "rgb:gggg/0000/0000" in
  match result with
  | Error msg ->
    check string "non-hex char error"
      "Unrecognised colour string: rgb:gggg/0000/0000" msg
  | Ok _ ->
    fail "Expected Error, got Ok"

let test_parse_colour_too_many_chars () =
  (* More than 4 hex chars per component *)
  let result = Xterm.parse_colour "rgb:fffff/0000/0000" in
  match result with
  | Error msg ->
    check string "5 hex chars error"
      "Unrecognised colour string: rgb:fffff/0000/0000" msg
  | Ok _ ->
    fail "Expected Error, got Ok"

(* ===== Terminal I/O Tests (Conditional) ===== *)

let test_query_non_tty () =
  (* Test that query properly returns error for non-TTY file descriptors *)
  (* We can safely test this without a TTY by using a pipe *)
  let read_fd, write_fd = Unix.pipe () in
  Fun.protect
    ~finally:(fun () -> Unix.close read_fd; Unix.close write_fd)
    (fun () ->
       let result = Xterm.query read_fd "10" in
       let is_error = function Error _ -> true | Ok _ -> false in
       check bool "non-TTY returns error" true (is_error result)
    )

let test_set_raw_non_tty () =
  (* Test that set_raw raises for non-TTY *)
  let read_fd, write_fd = Unix.pipe () in
  Fun.protect
    ~finally:(fun () -> Unix.close read_fd; Unix.close write_fd)
    (fun () ->
       check_raises "set_raw on non-TTY"
         (Unix.Unix_error (Unix.ENOTTY, "tcgetattr", ""))
         (fun () -> Xterm.set_raw read_fd)
    )

let test_get_colours_non_tty () =
  (* Test that get_colours returns errors for non-TTY *)
  let read_fd, write_fd = Unix.pipe () in
  Fun.protect
    ~finally:(fun () -> Unix.close read_fd; Unix.close write_fd)
    (fun () ->
       let result = Xterm.get_colours read_fd in
       let is_error = function Error _ -> true | Ok _ -> false in
       check bool "fg is error" true (is_error result.fg);
       check bool "bg is error" true (is_error result.bg)
    )

(* Note: We intentionally do NOT test actual TTY interaction because:
   1. It requires a real terminal (not available in CI)
   2. It would be flaky (depends on terminal state)
   3. The non-TTY error paths are more important to verify
   4. Manual testing with a real terminal is better for TTY functionality *)

(* ===== Test Suite ===== *)

let () =
  Test_runner.run "Query" ~junit_filename:"junit-query.xml" [
    "hex_to_8bit - Single char", [
      test_case "0-F scaling" `Quick test_hex_to_8bit_single_char;
    ];
    "hex_to_8bit - Two chars", [
      test_case "00-FF standard" `Quick test_hex_to_8bit_two_chars;
    ];
    "hex_to_8bit - Three chars", [
      test_case "000-FFF scaling" `Quick test_hex_to_8bit_three_chars;
    ];
    "hex_to_8bit - Four chars", [
      test_case "0000-FFFF scaling" `Quick test_hex_to_8bit_four_chars;
    ];
    "hex_to_8bit - Edge cases", [
      test_case "empty string raises" `Quick test_hex_to_8bit_empty_string;
      test_case "invalid hex chars raise" `Quick test_hex_to_8bit_invalid_chars;
    ];
    "hex_to_8bit - Scaling consistency", [
      test_case "same value different widths" `Quick test_hex_to_8bit_scaling_consistency;
    ];
    "parse_colour - Valid formats", [
      test_case "red" `Quick test_parse_colour_valid;
      test_case "green" `Quick test_parse_colour_valid_green;
      test_case "blue" `Quick test_parse_colour_valid_blue;
      test_case "mixed widths" `Quick test_parse_colour_mixed_widths;
      test_case "uppercase hex rejected" `Quick test_parse_colour_uppercase;
    ];
    "parse_colour - Invalid formats", [
      test_case "missing prefix" `Quick test_parse_colour_invalid_format;
      test_case "wrong separators" `Quick test_parse_colour_invalid_separators;
      test_case "non-hex chars" `Quick test_parse_colour_invalid_hex;
      test_case "too many chars" `Quick test_parse_colour_too_many_chars;
    ];
    "Terminal I/O - Error handling", [
      test_case "query on non-TTY" `Quick test_query_non_tty;
      test_case "set_raw on non-TTY" `Quick test_set_raw_non_tty;
      test_case "get_colours on non-TTY" `Quick test_get_colours_non_tty;
    ];
  ]
