(* Tests for PPX utility functions *)
open Alcotest
open Spectrum_palette_ppx.Private.Utils

let test_camel_to_kebab () =
  Alcotest.(check string) "BrightWhite" "bright-white" (camel_to_kebab "BrightWhite");
  Alcotest.(check string) "BasicBlack" "basic-black" (camel_to_kebab "BasicBlack");
  Alcotest.(check string) "DarkOliveGreen1a" "dark-olive-green-1a" (camel_to_kebab "DarkOliveGreen1a");
  Alcotest.(check string) "Red" "red" (camel_to_kebab "Red");
  Alcotest.(check string) "RapidBlink" "rapid-blink" (camel_to_kebab "RapidBlink")

let test_camel_to_kebab_numeric_suffix () =
  (* Names with numeric suffixes like Grey0, Grey100 *)
  Alcotest.(check string) "Grey0" "grey-0" (camel_to_kebab "Grey0");
  Alcotest.(check string) "Grey100" "grey-100" (camel_to_kebab "Grey100")

let () =
  Test_runner.run "PPX Utils" ~junit_filename:"junit-ppx-utils.xml" [
    "camel_to_kebab", [
      test_case "common conversions" `Quick test_camel_to_kebab;
      test_case "numeric suffixes" `Quick test_camel_to_kebab_numeric_suffix;
    ];
  ]
