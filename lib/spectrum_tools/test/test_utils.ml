(* Comprehensive tests for Utils module *)
open Alcotest
open Spectrum_tools.Private.Utils

(* Test helpers *)

(* Reuse v4_testable pattern from test_convert.ml *)
let v4_testable = testable (fun ppf v ->
    let c = to_rgba v in
    Format.fprintf ppf "RGB(%d,%d,%d)" c.Rgba.r c.Rgba.g c.Rgba.b
  ) ( = )

let rgba_testable = testable (fun ppf rgba ->
    Format.fprintf ppf "RGBA(%d,%d,%d,%.2f)"
      rgba.Rgba.r rgba.Rgba.g rgba.Rgba.b rgba.Rgba.a
  ) (fun a b ->
    a.Rgba.r = b.Rgba.r &&
    a.Rgba.g = b.Rgba.g &&
    a.Rgba.b = b.Rgba.b &&
    Float.abs (a.Rgba.a -. b.Rgba.a) < 0.01
  )

let rgba'_testable = testable (fun ppf rgba' ->
    Format.fprintf ppf "RGBA'(%.3f,%.3f,%.3f,%.2f)"
      rgba'.Rgba'.r rgba'.Rgba'.g rgba'.Rgba'.b rgba'.Rgba'.a
  ) (fun a b ->
    Float.abs (a.Rgba'.r -. b.Rgba'.r) < 0.01 &&
    Float.abs (a.Rgba'.g -. b.Rgba'.g) < 0.01 &&
    Float.abs (a.Rgba'.b -. b.Rgba'.b) < 0.01 &&
    Float.abs (a.Rgba'.a -. b.Rgba'.a) < 0.01
  )

(* Common test colors *)
let red_gg = Color.Rgb.(v 255 0 0 |> to_gg)
let green_gg = Color.Rgb.(v 0 255 0 |> to_gg)
let blue_gg = Color.Rgb.(v 0 0 255 |> to_gg)
let black_gg = Color.Rgb.(v 0 0 0 |> to_gg)
let white_gg = Color.Rgb.(v 255 255 255 |> to_gg)
let gray_gg = Color.Rgb.(v 128 128 128 |> to_gg)

(* ===== Math Utilities Tests ===== *)

let test_float_div () =
  Alcotest.(check (float 0.001)) "10 // 4 = 2.5" 2.5 (10 // 4);
  Alcotest.(check (float 0.001)) "1 // 3 = 0.333..." 0.333 (1 // 3);
  Alcotest.(check (float 0.001)) "255 // 2 = 127.5" 127.5 (255 // 2);
  Alcotest.(check (float 0.001)) "0 // 1 = 0.0" 0.0 (0 // 1)

let test_int_round () =
  (* Standard rounding: .5 rounds up, -.5 rounds down (away from zero) *)
  Alcotest.(check int) "0.5 -> 1" 1 (int_round 0.5);
  Alcotest.(check int) "1.5 -> 2" 2 (int_round 1.5);
  Alcotest.(check int) "2.5 -> 3" 3 (int_round 2.5);
  Alcotest.(check int) "3.5 -> 4" 4 (int_round 3.5);
  (* Negative rounding (away from zero) *)
  Alcotest.(check int) "-0.5 -> -1" (-1) (int_round (-0.5));
  Alcotest.(check int) "-1.5 -> -2" (-2) (int_round (-1.5));
  Alcotest.(check int) "-2.5 -> -3" (-3) (int_round (-2.5));
  (* Regular rounding *)
  Alcotest.(check int) "1.4 -> 1" 1 (int_round 1.4);
  Alcotest.(check int) "1.6 -> 2" 2 (int_round 1.6);
  Alcotest.(check int) "-1.4 -> -1" (-1) (int_round (-1.4));
  Alcotest.(check int) "-1.6 -> -2" (-2) (int_round (-1.6))

let test_clamp () =
  (* Within range *)
  Alcotest.(check int) "clamp 0 10 5 = 5" 5 (clamp 0 10 5);
  (* Below min *)
  Alcotest.(check int) "clamp 0 10 (-5) = 0" 0 (clamp 0 10 (-5));
  (* Above max *)
  Alcotest.(check int) "clamp 0 10 15 = 10" 10 (clamp 0 10 15);
  (* At boundaries *)
  Alcotest.(check int) "clamp 0 255 0 = 0" 0 (clamp 0 255 0);
  Alcotest.(check int) "clamp 0 255 255 = 255" 255 (clamp 0 255 255)

let test_min3_max3 () =
  Alcotest.(check int) "min3 5 3 7 = 3" 3 (min3 5 3 7);
  Alcotest.(check int) "min3 10 10 10 = 10" 10 (min3 10 10 10);
  Alcotest.(check int) "max3 5 3 7 = 7" 7 (max3 5 3 7);
  Alcotest.(check int) "max3 10 10 10 = 10" 10 (max3 10 10 10);
  Alcotest.(check int) "min3 (-5) 0 5 = -5" (-5) (min3 (-5) 0 5);
  Alcotest.(check int) "max3 (-5) 0 5 = 5" 5 (max3 (-5) 0 5)

let test_nearest_sqrt () =
  (* Floor-based sqrt *)
  Alcotest.(check int) "nearest_sqrt 16 = 4" 4 (nearest_sqrt 16);
  Alcotest.(check int) "nearest_sqrt 17 = 4" 4 (nearest_sqrt 17);
  Alcotest.(check int) "nearest_sqrt 25 = 5" 5 (nearest_sqrt 25);
  Alcotest.(check int) "nearest_sqrt 4 = 2" 2 (nearest_sqrt 4);
  Alcotest.(check int) "nearest_sqrt 1 = 1" 1 (nearest_sqrt 1);
  (* Round-based sqrt *)
  Alcotest.(check int) "nearest_sqrt' 16 = 4" 4 (nearest_sqrt' 16);
  Alcotest.(check int) "nearest_sqrt' 17 = 4" 4 (nearest_sqrt' 17);
  Alcotest.(check int) "nearest_sqrt' 18 = 4" 4 (nearest_sqrt' 18);
  Alcotest.(check int) "nearest_sqrt' 19 = 4" 4 (nearest_sqrt' 19);
  Alcotest.(check int) "nearest_sqrt' 20 = 4" 4 (nearest_sqrt' 20);
  Alcotest.(check int) "nearest_sqrt' 21 = 5" 5 (nearest_sqrt' 21)

let test_min_max_fold () =
  (* Test with non-empty lists *)
  Alcotest.(check Alcotest.(option int)) "min_fold [3;1;4;1;5] = Some 1"
    (Some 1) (min_fold [3; 1; 4; 1; 5]);
  Alcotest.(check Alcotest.(option int)) "max_fold [3;1;4;1;5] = Some 5"
    (Some 5) (max_fold [3; 1; 4; 1; 5]);

  (* Test with single element *)
  Alcotest.(check Alcotest.(option int)) "min_fold [42] = Some 42"
    (Some 42) (min_fold [42]);
  Alcotest.(check Alcotest.(option int)) "max_fold [42] = Some 42"
    (Some 42) (max_fold [42]);

  (* Test with empty list - now returns None instead of crashing *)
  Alcotest.(check Alcotest.(option int)) "min_fold [] = None"
    None (min_fold []);
  Alcotest.(check Alcotest.(option int)) "max_fold [] = None"
    None (max_fold [])

(* ===== Color Conversion Tests ===== *)

let test_to_rgba () =
  let red = to_rgba red_gg in
  Alcotest.(check rgba_testable) "red to_rgba"
    { Rgba.r = 255; g = 0; b = 0; a = 1.0 } red;

  let green = to_rgba green_gg in
  Alcotest.(check rgba_testable) "green to_rgba"
    { Rgba.r = 0; g = 255; b = 0; a = 1.0 } green;

  let blue = to_rgba blue_gg in
  Alcotest.(check rgba_testable) "blue to_rgba"
    { Rgba.r = 0; g = 0; b = 255; a = 1.0 } blue;

  let black = to_rgba black_gg in
  Alcotest.(check rgba_testable) "black to_rgba"
    { Rgba.r = 0; g = 0; b = 0; a = 1.0 } black;

  let white = to_rgba white_gg in
  Alcotest.(check rgba_testable) "white to_rgba"
    { Rgba.r = 255; g = 255; b = 255; a = 1.0 } white;

  let gray = to_rgba gray_gg in
  Alcotest.(check rgba_testable) "gray to_rgba"
    { Rgba.r = 128; g = 128; b = 128; a = 1.0 } gray

let test_to_rgba' () =
  let red = to_rgba' red_gg in
  Alcotest.(check rgba'_testable) "red to_rgba'"
    { Rgba'.r = 1.0; g = 0.0; b = 0.0; a = 1.0 } red;

  let black = to_rgba' black_gg in
  Alcotest.(check rgba'_testable) "black to_rgba'"
    { Rgba'.r = 0.0; g = 0.0; b = 0.0; a = 1.0 } black;

  let white = to_rgba' white_gg in
  Alcotest.(check rgba'_testable) "white to_rgba'"
    { Rgba'.r = 1.0; g = 1.0; b = 1.0; a = 1.0 } white

let test_of_rgb () =
  let red = of_rgb 255 0 0 in
  Alcotest.(check v4_testable) "of_rgb 255 0 0" red_gg red;

  let green = of_rgb 0 255 0 in
  Alcotest.(check v4_testable) "of_rgb 0 255 0" green_gg green;

  let blue = of_rgb 0 0 255 in
  Alcotest.(check v4_testable) "of_rgb 0 0 255" blue_gg blue;

  let gray = of_rgb 128 128 128 in
  Alcotest.(check v4_testable) "of_rgb 128 128 128" gray_gg gray

let test_of_rgb_to_rgba_roundtrip () =
  (* Verify roundtrip: RGB -> Gg -> RGBA -> matches original *)
  let test_color r g b =
    let gg_color = of_rgb r g b in
    let rgba = to_rgba gg_color in
    Alcotest.(check int) (Printf.sprintf "r=%d" r) r rgba.Rgba.r;
    Alcotest.(check int) (Printf.sprintf "g=%d" g) g rgba.Rgba.g;
    Alcotest.(check int) (Printf.sprintf "b=%d" b) b rgba.Rgba.b
  in
  test_color 255 0 0;
  test_color 0 255 0;
  test_color 0 0 255;
  test_color 128 128 128;
  test_color 64 192 32

let test_map_color () =
  let red_rgba = to_rgba red_gg in
  let doubled = map_color (fun x -> x * 2) red_rgba in
  Alcotest.(check (triple int int int)) "map (*2) on red"
    (510, 0, 0) doubled;

  let gray_rgba = to_rgba gray_gg in
  let halved = map_color (fun x -> x / 2) gray_rgba in
  Alcotest.(check (triple int int int)) "map (/2) on gray"
    (64, 64, 64) halved

let test_map_color' () =
  let red_rgba' = to_rgba' red_gg in
  let doubled = map_color' (fun x -> x *. 2.0) red_rgba' in
  Alcotest.(check (triple (float 0.01) (float 0.01) (float 0.01)))
    "map' (*2.0) on red" (2.0, 0.0, 0.0) doubled;

  let white_rgba' = to_rgba' white_gg in
  let halved = map_color' (fun x -> x /. 2.0) white_rgba' in
  Alcotest.(check (triple (float 0.01) (float 0.01) (float 0.01)))
    "map' (/2.0) on white" (0.5, 0.5, 0.5) halved

let test_map3 () =
  let result = map3 (fun x -> x * 2) (1, 2, 3) in
  Alcotest.(check (triple int int int)) "map3 (*2) on (1,2,3)"
    (2, 4, 6) result;

  let result2 = map3 (fun x -> x + 10) (5, 10, 15) in
  Alcotest.(check (triple int int int)) "map3 (+10) on (5,10,15)"
    (15, 20, 25) result2

(* ===== List Utilities Tests ===== *)

let test_product3 () =
  let result = product3 [1; 2] [3; 4] [5; 6] in
  let expected = [
    (1, 3, 5); (1, 3, 6); (1, 4, 5); (1, 4, 6);
    (2, 3, 5); (2, 3, 6); (2, 4, 5); (2, 4, 6);
  ] in
  Alcotest.(check (list (triple int int int))) "product3 [1;2] [3;4] [5;6]"
    expected result;

  (* Single element lists *)
  let result2 = product3 [1] [2] [3] in
  Alcotest.(check (list (triple int int int))) "product3 single elements"
    [(1, 2, 3)] result2;

  (* Empty list produces empty result *)
  let result3 = product3 [] [1] [2] in
  Alcotest.(check (list (triple int int int))) "product3 with empty list"
    [] result3

let test_range () =
  (* Basic range *)
  let r1 = range 5 |> List.of_seq in
  Alcotest.(check (list int)) "range 5" [0; 1; 2; 3; 4] r1;

  (* Range with from *)
  let r2 = range ~from:3 7 |> List.of_seq in
  Alcotest.(check (list int)) "range ~from:3 7" [3; 4; 5; 6] r2;

  (* Range with step *)
  let r3 = range ~step:2 10 |> List.of_seq in
  Alcotest.(check (list int)) "range ~step:2 10" [0; 2; 4; 6; 8] r3;

  (* Range with negative step *)
  let r4 = range ~from:10 ~step:(-2) 0 |> List.of_seq in
  Alcotest.(check (list int)) "range ~from:10 ~step:(-2) 0" [10; 8; 6; 4; 2] r4;

  (* Range with from and step *)
  let r5 = range ~from:5 ~step:3 15 |> List.of_seq in
  Alcotest.(check (list int)) "range ~from:5 ~step:3 15" [5; 8; 11; 14] r5;

  (* Empty range (from >= until with positive step) *)
  let r6 = range ~from:5 3 |> List.of_seq in
  Alcotest.(check (list int)) "range ~from:5 3 (empty)" [] r6

let test_range_invalid_step () =
  Alcotest.check_raises "range with step=0"
    (Invalid_argument "step must not be zero")
    (fun () -> ignore (range ~step:0 10 |> List.of_seq))

(* ===== AdjacencySet Tests ===== *)

let test_adjacent_values () =
  let open IntAdjacencySet in
  let set = of_list [10; 20; 30; 40; 50] in

  (* Value in set -> returns itself *)
  let result1 = adjacent_values set 30 in
  Alcotest.(check (option (list int))) "30 in set" (Some [30]) result1;

  (* Value between elements -> returns neighbors *)
  let result2 = adjacent_values set 25 in
  Alcotest.(check (option (list int))) "25 between 20 and 30"
    (Some [20; 30]) result2;

  (* Value between elements (another) *)
  let result3 = adjacent_values set 35 in
  Alcotest.(check (option (list int))) "35 between 30 and 40"
    (Some [30; 40]) result3;

  (* Value below all -> None *)
  let result4 = adjacent_values set 5 in
  Alcotest.(check (option (list int))) "5 below all" None result4;

  (* Value above all -> None *)
  let result5 = adjacent_values set 60 in
  Alcotest.(check (option (list int))) "60 above all" None result5

let test_adjacent_values_exn () =
  let open IntAdjacencySet in
  let set = of_list [10; 20; 30; 40; 50] in

  (* Valid value *)
  let result = adjacent_values_exn set 25 in
  Alcotest.(check (list int)) "25 between 20 and 30" [20; 30] result;

  (* Invalid value (below all) -> raises *)
  Alcotest.check_raises "5 below all raises"
    (Invalid_argument "5")
    (fun () -> ignore (adjacent_values_exn set 5));

  (* Invalid value (above all) -> raises *)
  Alcotest.check_raises "60 above all raises"
    (Invalid_argument "60")
    (fun () -> ignore (adjacent_values_exn set 60))

(* ===== Memoization Tests ===== *)

let test_memoise () =
  (* Track how many times expensive function is called *)
  let call_count = ref 0 in
  let expensive_fn x =
    incr call_count;
    x * x
  in
  let memoised = memoise expensive_fn in

  (* First call: computes *)
  let result1 = memoised 5 in
  Alcotest.(check int) "memoised 5 = 25" 25 result1;
  Alcotest.(check int) "called once" 1 !call_count;

  (* Second call with same arg: uses cache *)
  let result2 = memoised 5 in
  Alcotest.(check int) "memoised 5 = 25 (cached)" 25 result2;
  Alcotest.(check int) "still called once" 1 !call_count;

  (* Call with different arg: computes again *)
  let result3 = memoised 7 in
  Alcotest.(check int) "memoised 7 = 49" 49 result3;
  Alcotest.(check int) "called twice" 2 !call_count;

  (* Call with first arg again: still cached *)
  let result4 = memoised 5 in
  Alcotest.(check int) "memoised 5 = 25 (still cached)" 25 result4;
  Alcotest.(check int) "still called twice" 2 !call_count

(* ===== Test Suite ===== *)

let () =
  let (testsuite, exit) = Junit_alcotest.run_and_report "Utils" [
      "Math - Float division", [
        test_case "integer float division (//)" `Quick test_float_div;
      ];
      "Math - Rounding", [
        test_case "int_round (banker's rounding)" `Quick test_int_round;
      ];
      "Math - Clamping and min/max", [
        test_case "clamp to range" `Quick test_clamp;
        test_case "min3/max3" `Quick test_min3_max3;
        test_case "min_fold/max_fold (option-based)" `Quick test_min_max_fold;
      ];
      "Math - Square root approximation", [
        test_case "nearest_sqrt and nearest_sqrt'" `Quick test_nearest_sqrt;
      ];
      "Color - to_rgba (Gg -> int RGBA)", [
        test_case "primary colors and grayscale" `Quick test_to_rgba;
      ];
      "Color - to_rgba' (Gg -> float RGBA)", [
        test_case "primary colors to float" `Quick test_to_rgba';
      ];
      "Color - of_rgb (int RGB -> Gg)", [
        test_case "construct from RGB values" `Quick test_of_rgb;
      ];
      "Color - Roundtrip conversions", [
        test_case "RGB -> Gg -> RGBA preserves values" `Quick test_of_rgb_to_rgba_roundtrip;
      ];
      "Color - Component mapping", [
        test_case "map_color on int RGBA" `Quick test_map_color;
        test_case "map_color' on float RGBA" `Quick test_map_color';
        test_case "map3 on triples" `Quick test_map3;
      ];
      "List - Cartesian product", [
        test_case "product3 of three lists" `Quick test_product3;
      ];
      "List - Range sequences", [
        test_case "range with various parameters" `Quick test_range;
        test_case "range with invalid step=0" `Quick test_range_invalid_step;
      ];
      "AdjacencySet - Finding neighbors", [
        test_case "adjacent_values returns neighbors or value" `Quick test_adjacent_values;
        test_case "adjacent_values_exn raises on out-of-bounds" `Quick test_adjacent_values_exn;
      ];
      "Memoization", [
        test_case "memoise caches function results" `Quick test_memoise;
      ];
    ] in
  let report = Junit.make [testsuite;] in
  Junit.to_file report "junit-utils.xml";
  exit ()
