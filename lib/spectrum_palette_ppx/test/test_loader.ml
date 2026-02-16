(* Comprehensive tests for Loader module *)
open Alcotest
open Spectrum_palette_ppx.Loader

(* Test helpers *)

let v4_testable = testable (fun ppf v ->
    let c = Gg.Color.to_srgb v in
    let r = int_of_float (Float.round (255. *. Gg.Color.r c)) in
    let g = int_of_float (Float.round (255. *. Gg.Color.g c)) in
    let b = int_of_float (Float.round (255. *. Gg.Color.b c)) in
    Format.fprintf ppf "RGB(%d,%d,%d)" r g b
  ) ( = )

let rgb r g b = Color.Rgb.(v r g b |> to_gg)

(* Helper to create temporary JSON file *)
let with_temp_json content test_fn =
  let fname = Filename.temp_file "palette_test" ".json" in
  let oc = open_out fname in
  output_string oc content;
  close_out oc;
  try
    let result = test_fn fname in
    Unix.unlink fname;
    result
  with e ->
    Unix.unlink fname;
    raise e

(* ===== Valid JSON Tests ===== *)

let valid_single_color_json = {|[
  {
    "colorId": 32,
    "name": "BasicGreen",
    "rgb": {"r": 0, "g": 128, "b": 0}
  }
]|}

let valid_multiple_colors_json = {|[
  {
    "colorId": 30,
    "name": "BasicBlack",
    "rgb": {"r": 0, "g": 0, "b": 0}
  },
  {
    "colorId": 31,
    "name": "BasicRed",
    "rgb": {"r": 128, "g": 0, "b": 0}
  },
  {
    "colorId": 37,
    "name": "BasicWhite",
    "rgb": {"r": 255, "g": 255, "b": 255}
  }
]|}

let test_load_valid_single () =
  with_temp_json valid_single_color_json (fun fname ->
      let colors = load fname in
      Alcotest.(check int) "loaded 1 color" 1 (List.length colors);
      let color = List.hd colors in
      Alcotest.(check int) "colorId = 32" 32 color.code;
      Alcotest.(check string) "name = BasicGreen" "BasicGreen" color.name;
      Alcotest.(check int) "r = 0" 0 color.r;
      Alcotest.(check int) "g = 128" 128 color.g;
      Alcotest.(check int) "b = 0" 0 color.b
    )

let test_load_valid_multiple () =
  with_temp_json valid_multiple_colors_json (fun fname ->
      let colors = load fname in
      Alcotest.(check int) "loaded 3 colors" 3 (List.length colors);
      (* Check first color *)
      let black = List.nth colors 0 in
      Alcotest.(check int) "black colorId = 30" 30 black.code;
      Alcotest.(check string) "black name" "BasicBlack" black.name;
      (* Check last color *)
      let white = List.nth colors 2 in
      Alcotest.(check int) "white colorId = 37" 37 white.code;
      Alcotest.(check int) "white r = 255" 255 white.r;
      Alcotest.(check int) "white g = 255" 255 white.g;
      Alcotest.(check int) "white b = 255" 255 white.b
    )

let test_load_assoc () =
  with_temp_json valid_multiple_colors_json (fun fname ->
      let assoc_list = load_assoc fname in
      Alcotest.(check int) "assoc list has 3 entries" 3 (List.length assoc_list);
      (* Check that colors are indexed by code *)
      let black = List.assoc 30 assoc_list in
      Alcotest.(check string) "code 30 -> BasicBlack" "BasicBlack" black.name;
      let red = List.assoc 31 assoc_list in
      Alcotest.(check string) "code 31 -> BasicRed" "BasicRed" red.name;
      let white = List.assoc 37 assoc_list in
      Alcotest.(check string) "code 37 -> BasicWhite" "BasicWhite" white.name
    )

let test_color_of_def () =
  let def = { name = "TestRed"; code = 99; r = 255; g = 0; b = 0 } in
  let color = color_of_def def in
  Alcotest.(check v4_testable) "TestRed converts to RGB(255,0,0)"
    (rgb 255 0 0) color;

  let def2 = { name = "TestGreen"; code = 100; r = 0; g = 255; b = 0 } in
  let color2 = color_of_def def2 in
  Alcotest.(check v4_testable) "TestGreen converts to RGB(0,255,0)"
    (rgb 0 255 0) color2;

  let def3 = { name = "TestGray"; code = 101; r = 128; g = 128; b = 128 } in
  let color3 = color_of_def def3 in
  Alcotest.(check v4_testable) "TestGray converts to RGB(128,128,128)"
    (rgb 128 128 128) color3

(* ===== Invalid JSON Tests ===== *)

let missing_colorid_json = {|[
  {
    "name": "Red",
    "rgb": {"r": 255, "g": 0, "b": 0}
  }
]|}

let missing_name_json = {|[
  {
    "colorId": 31,
    "rgb": {"r": 255, "g": 0, "b": 0}
  }
]|}

let missing_rgb_json = {|[
  {
    "colorId": 31,
    "name": "Red"
  }
]|}

let missing_r_json = {|[
  {
    "colorId": 31,
    "name": "Red",
    "rgb": {"g": 0, "b": 0}
  }
]|}

let missing_g_json = {|[
  {
    "colorId": 31,
    "name": "Red",
    "rgb": {"r": 255, "b": 0}
  }
]|}

let missing_b_json = {|[
  {
    "colorId": 31,
    "name": "Red",
    "rgb": {"r": 255, "g": 0}
  }
]|}

let invalid_colorid_type_json = {|[
  {
    "colorId": "thirty-one",
    "name": "Red",
    "rgb": {"r": 255, "g": 0, "b": 0}
  }
]|}

let invalid_name_type_json = {|[
  {
    "colorId": 31,
    "name": 123,
    "rgb": {"r": 255, "g": 0, "b": 0}
  }
]|}

let invalid_rgb_type_json = {|[
  {
    "colorId": 31,
    "name": "Red",
    "rgb": [255, 0, 0]
  }
]|}

let invalid_r_type_json = {|[
  {
    "colorId": 31,
    "name": "Red",
    "rgb": {"r": "red", "g": 0, "b": 0}
  }
]|}

let not_array_json = {|{
  "colorId": 31,
  "name": "Red",
  "rgb": {"r": 255, "g": 0, "b": 0}
}|}

let test_load_missing_colorid () =
  Alcotest.check_raises "missing colorId"
    Not_found
    (fun () ->
       with_temp_json missing_colorid_json (fun fname ->
           ignore (load fname)
         )
    )

let test_load_missing_name () =
  Alcotest.check_raises "missing name"
    Not_found
    (fun () ->
       with_temp_json missing_name_json (fun fname ->
           ignore (load fname)
         )
    )

let test_load_missing_rgb () =
  Alcotest.check_raises "missing rgb"
    Not_found
    (fun () ->
       with_temp_json missing_rgb_json (fun fname ->
           ignore (load fname)
         )
    )

let test_load_missing_r () =
  Alcotest.check_raises "missing r in rgb"
    Not_found
    (fun () ->
       with_temp_json missing_r_json (fun fname ->
           ignore (load fname)
         )
    )

let test_load_missing_g () =
  Alcotest.check_raises "missing g in rgb"
    Not_found
    (fun () ->
       with_temp_json missing_g_json (fun fname ->
           ignore (load fname)
         )
    )

let test_load_missing_b () =
  Alcotest.check_raises "missing b in rgb"
    Not_found
    (fun () ->
       with_temp_json missing_b_json (fun fname ->
           ignore (load fname)
         )
    )

let test_load_invalid_colorid_type () =
  Alcotest.check_raises "colorId wrong type"
    (Failure "Invalid json data")
    (fun () ->
       with_temp_json invalid_colorid_type_json (fun fname ->
           ignore (load fname)
         )
    )

let test_load_invalid_name_type () =
  Alcotest.check_raises "name wrong type"
    (Failure "Invalid json data")
    (fun () ->
       with_temp_json invalid_name_type_json (fun fname ->
           ignore (load fname)
         )
    )

let test_load_invalid_rgb_type () =
  Alcotest.check_raises "rgb wrong type (array instead of object)"
    (Failure "Invalid json data")
    (fun () ->
       with_temp_json invalid_rgb_type_json (fun fname ->
           ignore (load fname)
         )
    )

let test_load_invalid_r_type () =
  Alcotest.check_raises "r wrong type"
    (Failure "Invalid json data")
    (fun () ->
       with_temp_json invalid_r_type_json (fun fname ->
           ignore (load fname)
         )
    )

let test_load_not_array () =
  Alcotest.check_raises "top-level not array"
    (Failure "Invalid json data")
    (fun () ->
       with_temp_json not_array_json (fun fname ->
           ignore (load fname)
         )
    )

(* ===== Test Suite ===== *)

let () =
  let (testsuite, exit) = Junit_alcotest.run_and_report "Loader" [
      "Valid JSON - load", [
        test_case "single color" `Quick test_load_valid_single;
        test_case "multiple colors" `Quick test_load_valid_multiple;
      ];
      "Valid JSON - load_assoc", [
        test_case "colors indexed by code" `Quick test_load_assoc;
      ];
      "Valid JSON - color_of_def", [
        test_case "color definition conversion" `Quick test_color_of_def;
      ];
      "Invalid JSON - missing fields", [
        test_case "missing colorId" `Quick test_load_missing_colorid;
        test_case "missing name" `Quick test_load_missing_name;
        test_case "missing rgb" `Quick test_load_missing_rgb;
        test_case "missing r in rgb" `Quick test_load_missing_r;
        test_case "missing g in rgb" `Quick test_load_missing_g;
        test_case "missing b in rgb" `Quick test_load_missing_b;
      ];
      "Invalid JSON - wrong types", [
        test_case "colorId wrong type" `Quick test_load_invalid_colorid_type;
        test_case "name wrong type" `Quick test_load_invalid_name_type;
        test_case "rgb wrong type" `Quick test_load_invalid_rgb_type;
        test_case "r wrong type" `Quick test_load_invalid_r_type;
      ];
      "Invalid JSON - structure", [
        test_case "not an array" `Quick test_load_not_array;
      ];
    ] in
  let report = Junit.make [testsuite;] in
  Junit.to_file report "junit-loader.xml";
  exit ()
