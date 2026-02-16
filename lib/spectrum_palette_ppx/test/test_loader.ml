(* Tests for Loader module *)
open Alcotest

let test_placeholder () =
  (* TODO: Add tests for:
     - JSON loading from palette files
     - Palette definition parsing
     - Color name normalization
  *)
  Alcotest.(check bool) "placeholder" true true

let () =
  let (testsuite, exit) = Junit_alcotest.run_and_report "Loader" [
      "placeholder", [
        test_case "needs tests" `Quick test_placeholder;
      ];
    ] in
  let report = Junit.make [testsuite;] in
  Junit.to_file report "junit-loader.xml";
  exit ()
