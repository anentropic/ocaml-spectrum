open Alcotest
open Spectrum.Lexer

(* https://dotkay.github.io/2017/09/21/permutations-of-a-list/ *)
let rec insertions_of x lst =
  match lst with
  | [] -> [[x]]
  | h::t -> 
    (x::lst) :: (List.map (fun el -> h::el) (insertions_of x t))
let rec permutations_of lst =
  match lst with
  | [] -> [lst]
  | h::t ->
    List.concat_map (insertions_of h) (permutations_of t)

let test_tag_to_code tag code () =
  let msg = Printf.sprintf "%s -> %s" tag code in
  Alcotest.(check string) msg code (tag_to_code tag)

let make_case value = match value with
  | (label, tag, code) -> test_case label `Quick (test_tag_to_code tag code)

let join_values a b = match a, b with  
  | (("", "", ""), (lb, tb, cb)) -> (lb, tb, cb)
  | ((la, ta, ca), (lb, tb, cb)) -> (la^","^lb, ta^","^tb, cb^";"^ca)

let compound_shuffled cases =
  List.concat_map (
    fun case_values ->
      permutations_of case_values
      |> List.map (fun cv -> List.fold_left join_values ("","","") cv)
      |> List.map make_case) cases


let () =
  let (testsuite, exit) = Junit_alcotest.run_and_report "Lexer" [
      "Styles", [
        test_case "Bold" `Quick (test_tag_to_code "bold" "1");
        test_case "Rapid blink" `Quick (test_tag_to_code "rapid-blink" "5");
      ];
      "Named colors", [
        test_case "Foreground (implicit): red" `Quick (test_tag_to_code "red" "38;5;1");
        test_case "Foreground (explicit): red" `Quick (test_tag_to_code "fg:red" "38;5;1");
        test_case "Background (explicit): red" `Quick (test_tag_to_code "bg:red" "48;5;1");
        test_case "Foreground (implicit): dark-olive-green-1a" `Quick (test_tag_to_code "dark-olive-green-1a" "38;5;191");
        test_case "Foreground (explicit): dark-olive-green-1a" `Quick (test_tag_to_code "fg:dark-olive-green-1a" "38;5;191");
        test_case "Background (explicit): dark-olive-green-1a" `Quick (test_tag_to_code "bg:dark-olive-green-1a" "48;5;191");
      ];
      "Compound from named color", compound_shuffled [
        [("Red", "red", "38;5;1"); ("Underline", "underline", "4")];
        [("Bg Red", "bg:red", "48;5;1"); ("Underline", "underline", "4")];
        [("dark-olive-green-1a", "dark-olive-green-1a", "38;5;191"); ("Bold", "bold", "1")];
        [("Red", "red", "38;5;1");
         ("Underline", "underline", "4");
         ("Bg Red", "bg:red", "48;5;1");
         ("Bold", "bold", "1")];
      ];
      "Hex colors", [
        test_case "Foreground (implicit): fc9" `Quick (test_tag_to_code "#fc9" "38;2;255;204;153");
        test_case "Foreground (explicit): fc9" `Quick (test_tag_to_code "fg:#fc9" "38;2;255;204;153");
        test_case "Background (explicit): fc9" `Quick (test_tag_to_code "bg:#fc9" "48;2;255;204;153");
        test_case "Foreground (implicit): FC9" `Quick (test_tag_to_code "#FC9" "38;2;255;204;153");
        test_case "Foreground (explicit): FC9" `Quick (test_tag_to_code "fg:#FC9" "38;2;255;204;153");
        test_case "Background (explicit): FC9" `Quick (test_tag_to_code "bg:#FC9" "48;2;255;204;153");
        test_case "Foreground (implicit): f0c090" `Quick (test_tag_to_code "#f0c090" "38;2;240;192;144");
        test_case "Foreground (explicit): f0c090" `Quick (test_tag_to_code "fg:#f0c090" "38;2;240;192;144");
        test_case "Background (explicit): f0c090" `Quick (test_tag_to_code "bg:#f0c090" "48;2;240;192;144");
        test_case "Foreground (implicit): F0C090" `Quick (test_tag_to_code "#F0C090" "38;2;240;192;144");
        test_case "Foreground (explicit): F0C090" `Quick (test_tag_to_code "fg:#F0C090" "38;2;240;192;144");
        test_case "Background (explicit): F0C090" `Quick (test_tag_to_code "bg:#F0C090" "48;2;240;192;144");
      ];
      "Compound from hex color", compound_shuffled [
        [("#F00", "#F00", "38;2;255;0;0"); ("Underline", "underline", "4")];
        [("Bg #f0c090", "bg:#f0c090", "48;2;240;192;144"); ("Bold", "bold", "1")];
        [("#F00", "#F00", "38;2;255;0;0");
         ("Underline", "underline", "4");
         ("Bg #f0c090", "bg:#f0c090", "48;2;240;192;144");
         ("Bold", "bold", "1")];
      ];
    ]
  in
  let report = Junit.make [testsuite;] in
  Junit.to_file report "junit-lexer.xml";
  exit ()
