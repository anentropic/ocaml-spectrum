open QCheck2

(* -- Generators -- *)

let gen_style_name = Gen.oneof_list [
    "bold"; "dim"; "italic"; "underline"; "blink";
    "rapid-blink"; "inverse"; "hidden"; "strikethru"
  ]

(* Generate a random casing of a string *)
let gen_random_case s =
  Gen.map (fun bits ->
      String.mapi (fun i c ->
          if bits land (1 lsl (i mod 30)) <> 0 then Char.uppercase_ascii c
          else c
        ) s
    ) Gen.int

let gen_style_random_case =
  Gen.bind gen_style_name gen_random_case

let gen_hex_digit = Gen.map (fun i -> "0123456789abcdef".[i]) (Gen.int_range 0 15)

let gen_hex6 =
  Gen.map (fun (a, (b, (c, (d, (e, f))))) ->
      Printf.sprintf "%c%c%c%c%c%c" a b c d e f
    ) (Gen.pair gen_hex_digit
         (Gen.pair gen_hex_digit
            (Gen.pair gen_hex_digit
               (Gen.pair gen_hex_digit
                  (Gen.pair gen_hex_digit gen_hex_digit)))))

let gen_rgb_int = Gen.int_range 0 255

let gen_rgb_triple = Gen.triple gen_rgb_int gen_rgb_int gen_rgb_int

(* -- Properties -- *)

(* Style.of_string is case-insensitive *)
let prop_style_case_insensitive =
  Test.make ~name:"Style.of_string is case-insensitive"
    ~count:200
    ~print:Print.string
    gen_style_random_case
    (fun name ->
       let open Spectrum.Parser.Style in
       let lower = of_string (String.lowercase_ascii name) in
       let upper = of_string (String.uppercase_ascii name) in
       let mixed = of_string name in
       lower = upper && upper = mixed)

(* Compound tag order independence: "style,rgb(...)" = "rgb(...),style" *)
let prop_compound_order_independent =
  Test.make ~name:"compound tag: style,color order independent"
    ~count:300
    ~print:Print.(pair string (triple int int int))
    (Gen.pair gen_style_name gen_rgb_triple)
    (fun (style, (r, g, b)) ->
       let color = Printf.sprintf "rgb(%d %d %d)" r g b in
       let tag1 = Printf.sprintf "%s,%s" style color in
       let tag2 = Printf.sprintf "%s,%s" color style in
       let r1 = Spectrum.Lexer.tag_to_compound_style tag1 in
       let r2 = Spectrum.Lexer.tag_to_compound_style tag2 in
       match r1, r2 with
       | Ok tokens1, Ok tokens2 ->
         let c1 = Spectrum.Parser.compound_of_tokens tokens1 in
         let c2 = Spectrum.Parser.compound_of_tokens tokens2 in
         c1 = c2
       | _ -> false)

(* Hex tags always parse successfully with valid hex digits *)
let prop_hex_always_parses =
  Test.make ~name:"valid 6-digit hex tags always parse"
    ~count:300
    ~print:Print.string
    gen_hex6
    (fun hex ->
       let tag = "#" ^ hex in
       match Spectrum.Lexer.tag_to_compound_style tag with
       | Ok tokens -> List.length tokens = 1
       | Error _ -> false)

(* FORCE_COLOR monotonicity: higher value -> higher or equal color level *)
let prop_force_color_monotonic =
  let open Spectrum.Capabilities in
  Test.make ~name:"FORCE_COLOR: values 0->1->2->3 give non-decreasing levels"
    ~count:10
    (Gen.return ())
    (fun () ->
       let level_of fc_val =
         let env_map = StrMap.(empty |> add "FORCE_COLOR" fc_val) in
         let module Env = (val env_provider_of_map env_map) in
         let module OsInfo = (val os_info_provider false (Some "")) in
         let module C = Make(Env)(OsInfo) in
         C.supported_color_level false
       in
       let to_int = function
         | Unsupported -> 0 | Basic -> 1 | Eight_bit -> 2 | True_color -> 3
       in
       let levels = List.map (fun v -> to_int (level_of v)) ["0"; "1"; "2"; "3"] in
       let rec is_monotonic = function
         | [] | [_] -> true
         | a :: b :: rest -> a <= b && is_monotonic (b :: rest)
       in
       is_monotonic levels)

(* Non-TTY without FORCE_COLOR returns Unsupported regardless of env vars *)
let prop_non_tty_without_force =
  let open Spectrum.Capabilities in
  let gen_env_pair = Gen.pair
      (Gen.oneof_list ["COLORTERM"; "TERM"; "TERM_PROGRAM"])
      (Gen.oneof_list ["truecolor"; "xterm-256color"; "xterm"; "iTerm.app"])
  in
  Test.make ~name:"non-TTY without FORCE_COLOR returns Unsupported"
    ~count:100
    ~print:Print.(pair string string)
    gen_env_pair
    (fun (key, value) ->
       let env_map = StrMap.(empty |> add key value) in
       let module Env = (val env_provider_of_map env_map) in
       let module OsInfo = (val os_info_provider false (Some "")) in
       let module C = Make(Env)(OsInfo) in
       C.supported_color_level false = Unsupported)

(* Stag round-trip: stag produces same ANSI output as equivalent string tag *)
let prop_stag_matches_string_tag =
  let module Tc_printer : Spectrum.Printer =
    (val Spectrum.Private.make_printer true Spectrum.Private.True_color_Serializer.to_code)
  in
  let sprintf_stag stag text =
    let b = Buffer.create 256 in
    let ppf = Format.formatter_of_buffer b in
    let reset = Tc_printer.prepare_ppf ppf in
    Format.pp_open_stag ppf stag;
    Format.pp_print_string ppf text;
    Format.pp_close_stag ppf ();
    Format.pp_print_flush ppf ();
    let result = Buffer.contents b in
    Buffer.reset b;
    reset ();
    result
  in
  let sprintf_string_tag tag text =
    let b = Buffer.create 256 in
    let ppf = Format.formatter_of_buffer b in
    let reset = Tc_printer.prepare_ppf ppf in
    let fmt = Scanf.format_from_string
        (Printf.sprintf "@{<%s>%%s@}" tag) (format_of_string "%s") in
    Format.fprintf ppf fmt text;
    Format.pp_print_flush ppf ();
    let result = Buffer.contents b in
    Buffer.reset b;
    reset ();
    result
  in
  Test.make ~name:"Stag produces same output as equivalent string tag"
    ~count:200
    ~print:Print.(triple int int int)
    gen_rgb_triple
    (fun (r, g, b) ->
       let open Spectrum.Stag in
       let stag_result = sprintf_stag (stag [Fg (Rgb (r, g, b))]) "x" in
       let string_tag = Printf.sprintf "rgb(%d %d %d)" r g b in
       let string_result = sprintf_string_tag string_tag "x" in
       stag_result = string_result)

let () =
  let qcheck_tests = List.map QCheck_alcotest.to_alcotest [
      prop_style_case_insensitive;
      prop_compound_order_independent;
      prop_hex_always_parses;
      prop_force_color_monotonic;
      prop_non_tty_without_force;
      prop_stag_matches_string_tag;
    ] in
  Test_runner.run "Properties (spectrum)" ~junit_filename:"junit-properties-spectrum.xml" [
    "Parser/Lexer properties", qcheck_tests;
  ]
