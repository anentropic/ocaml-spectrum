(* Tests for Parser module *)
open Alcotest

let test_placeholder () =
  (* TODO: Add tests for Style module, color parsing, compound_of_tokens *)
  Alcotest.(check bool) "placeholder" true true

let () =
  let (testsuite, exit) = Junit_alcotest.run_and_report "Parser" [
      "placeholder", [
        test_case "needs tests" `Quick test_placeholder;
      ];
    ] in
  let report = Junit.make [testsuite;] in
  Junit.to_file report "junit-parser.xml";
  exit ()
