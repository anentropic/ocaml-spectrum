open Alcotest
open Spectrum.Lexer

let error = testable Fmt.exn ( = )

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

let test_tag_to_code tag expected () =
  let msg = Printf.sprintf "%s -> %s" tag (Result.value ~default:"None" expected) in
  Alcotest.(check (result string error)) msg expected (tag_to_code tag)

(* takes a list of lists of (label, tag, expected) triples and generates
   a list of test cases from all permutations of the inner lists *)
let compound_tag_permutations cases =
  let make_case value = match value with
    | (label, tag, expected) -> test_case label `Quick (test_tag_to_code tag (Ok expected))
  and join_values a b = match a, b with  
    | (("", "", ""), (lb, tb, eb)) -> (lb, tb, eb)
    | ((la, ta, ea), (lb, tb, eb)) -> (la^","^lb, ta^","^tb, ea^";"^eb)
  in
  List.concat_map (
    fun case_values ->
      permutations_of case_values
      |> List.map (fun cv -> List.fold_left join_values ("","","") cv)
      |> List.map make_case) cases


let () =
  let (testsuite, exit) = Junit_alcotest.run_and_report "Lexer" [
      "Styles", [
        test_case "Bold" `Quick (test_tag_to_code "bold" (Ok "1"));
        test_case "Rapid blink" `Quick (test_tag_to_code "rapid-blink" (Ok "5"));
      ];
      "Named colors", [
        test_case "Foreground (implicit): red" `Quick (test_tag_to_code "red" (Ok "38;5;1"));
        test_case "Foreground (explicit): red" `Quick (test_tag_to_code "fg:red" (Ok "38;5;1"));
        test_case "Background (explicit): red" `Quick (test_tag_to_code "bg:red" (Ok "48;5;1"));
        test_case "Foreground (implicit): dark-olive-green-1a" `Quick (test_tag_to_code "dark-olive-green-1a" (Ok "38;5;191"));
        test_case "Foreground (explicit): dark-olive-green-1a" `Quick (test_tag_to_code "fg:dark-olive-green-1a" (Ok "38;5;191"));
        test_case "Background (explicit): dark-olive-green-1a" `Quick (test_tag_to_code "bg:dark-olive-green-1a" (Ok "48;5;191"));
      ];
      "Compound (manually-defined tests)", [
        (* i.e. not using [compound_tag_permutations] *)
        test_case "red, bold, bg yellow" `Quick (test_tag_to_code "red,bold,bg:yellow" (Ok "38;5;1;1;48;5;3"));
        test_case "ignores whitespace" `Quick (test_tag_to_code "red,  bold  ,\tbg:yellow" (Ok "38;5;1;1;48;5;3"));
      ];
      "Compound tags from named colors", compound_tag_permutations [
        [("Red", "red", "38;5;1"); ("Underline", "underline", "4")];
        [("Bg Red", "bg:red", "48;5;1"); ("Underline", "underline", "4")];
        [("dark-olive-green-1a", "dark-olive-green-1a", "38;5;191"); ("Bold", "bold", "1")];
        [("Red", "red", "38;5;1");
         ("Underline", "underline", "4");
         ("Bg Red", "bg:red", "48;5;1");
         ("Bold", "bold", "1")];
      ];
      "Hex colors", [
        test_case "Foreground (implicit): fc9" `Quick (test_tag_to_code "#fc9" (Ok "38;2;255;204;153"));
        test_case "Foreground (explicit): fc9" `Quick (test_tag_to_code "fg:#fc9" (Ok "38;2;255;204;153"));
        test_case "Background (explicit): fc9" `Quick (test_tag_to_code "bg:#fc9" (Ok "48;2;255;204;153"));
        test_case "Foreground (implicit): FC9" `Quick (test_tag_to_code "#FC9" (Ok "38;2;255;204;153"));
        test_case "Foreground (explicit): FC9" `Quick (test_tag_to_code "fg:#FC9" (Ok "38;2;255;204;153"));
        test_case "Background (explicit): FC9" `Quick (test_tag_to_code "bg:#FC9" (Ok "48;2;255;204;153"));
        test_case "Foreground (implicit): f0c090" `Quick (test_tag_to_code "#f0c090" (Ok "38;2;240;192;144"));
        test_case "Foreground (explicit): f0c090" `Quick (test_tag_to_code "fg:#f0c090" (Ok "38;2;240;192;144"));
        test_case "Background (explicit): f0c090" `Quick (test_tag_to_code "bg:#f0c090" (Ok "48;2;240;192;144"));
        test_case "Foreground (implicit): F0C090" `Quick (test_tag_to_code "#F0C090" (Ok "38;2;240;192;144"));
        test_case "Foreground (explicit): F0C090" `Quick (test_tag_to_code "fg:#F0C090" (Ok "38;2;240;192;144"));
        test_case "Background (explicit): F0C090" `Quick (test_tag_to_code "bg:#F0C090" (Ok "48;2;240;192;144"));
      ];
      "Compound tags from hex colors", compound_tag_permutations [
        [("#F00", "#F00", "38;2;255;0;0"); ("Underline", "underline", "4")];
        [("Bg #f0c090", "bg:#f0c090", "48;2;240;192;144"); ("Bold", "bold", "1")];
        [("#F00", "#F00", "38;2;255;0;0");
         ("Underline", "underline", "4");
         ("Bg #f0c090", "bg:#f0c090", "48;2;240;192;144");
         ("Bold", "bold", "1")];
      ];
      (* Ok of these are a bit unintuitive due to the way they get parsed *)
      "Invalid tags", [
        test_case "Invalid color name (fg implicit)" `Quick (test_tag_to_code "xxx" (Error (InvalidColorName "xxx")));
        test_case "Invalid color name (fg)" `Quick (test_tag_to_code "fg:xxx" (Error (InvalidColorName "xxx")));
        test_case "Invalid color name (bg)" `Quick (test_tag_to_code "bg:xxx" (Error (InvalidColorName "xxx")));
        test_case "Invalid color name" `Quick (test_tag_to_code "xxx" (Error (InvalidColorName "xxx")));
        test_case "Invalid tag (not matched as hex)" `Quick (test_tag_to_code "#ab" (Error (InvalidTag "Unexpected char: #")));
        test_case "Invalid color name (not matched as hex)" `Quick (test_tag_to_code "fg:#ab" (Error (InvalidColorName "fg")));
        (* note that the valid segment of compound tag is not preserved, the tag returns an error *)
        test_case "Invalid tag (not matched as hex, in compound tag)" `Quick (test_tag_to_code "bold,#ab" (Error (InvalidTag "Unexpected char: #")));
        test_case "Invalid color name (in compound tag)" `Quick (test_tag_to_code "bold,xxx" (Error (InvalidColorName "xxx")));
      ];
    ]
  in
  let report = Junit.make [testsuite;] in
  Junit.to_file report "junit-lexer.xml";
  exit ()
