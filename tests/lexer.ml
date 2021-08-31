open Spectrum.Lexer

let test_tag_to_code tag code () =
  let msg = Printf.sprintf "%s -> %s" tag code in
  Alcotest.(check string) msg code (tag_to_code tag)
    
let () =
  let open Alcotest in
  run "Lexer" [
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
    ]