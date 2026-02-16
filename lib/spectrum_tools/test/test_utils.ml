(* Tests for Utils module *)
open Alcotest

let test_placeholder () =
  (* TODO: Add tests for:
     - Rgba and Rgba' type conversions
     - to_rgba, to_rgba', of_rgb
     - map_color, map_color', map3, product3
     - Utility functions: //, int_round, clamp, min3, max3
  *)
  Alcotest.(check bool) "placeholder" true true

let () =
  let (testsuite, exit) = Junit_alcotest.run_and_report "Utils" [
      "placeholder", [
        test_case "needs tests" `Quick test_placeholder;
      ];
    ] in
  let report = Junit.make [testsuite;] in
  Junit.to_file report "junit-utils.xml";
  exit ()
