open QCheck2

(* -- Generators -- *)

let gen_rgb_int = Gen.int_range 0 255

let gen_rgb_triple = Gen.triple gen_rgb_int gen_rgb_int gen_rgb_int

let gen_color_v4 =
  Gen.map (fun (r, g, b) ->
      Spectrum_tools.Convert.Color.of_rgb r g b
    ) gen_rgb_triple

let gen_hsl_triple =
  Gen.triple
    (Gen.float_range 0. 359.99)
    (Gen.float_range 0. 100.)
    (Gen.float_range 0. 100.)

(* -- Properties -- *)

(* rgb_to_ansi256 always returns a code in the valid range 16..255 *)
let prop_ansi256_range =
  Test.make ~name:"rgb_to_ansi256 returns code in 16..255"
    ~count:1000
    gen_color_v4
    (fun color ->
       let code = Spectrum_tools.Convert.Perceptual.rgb_to_ansi256 color in
       code >= 16 && code <= 255)

(* rgb_to_ansi16 always returns a valid ANSI-16 code (30-37 or 90-97) *)
let prop_ansi16_range =
  Test.make ~name:"rgb_to_ansi16 returns valid ANSI-16 code"
    ~count:1000
    gen_color_v4
    (fun color ->
       let code = Spectrum_tools.Convert.Perceptual.rgb_to_ansi16 color in
       (code >= 30 && code <= 37) || (code >= 90 && code <= 97))

(* RGB int -> Gg.v4 -> RGBA round-trip preserves values *)
let prop_rgb_round_trip =
  Test.make ~name:"RGB int -> v4 -> RGBA round-trip preserves values"
    ~count:1000
    ~print:Print.(triple int int int)
    gen_rgb_triple
    (fun (r, g, b) ->
       let open Spectrum_tools.Convert.Color in
       let color = of_rgb r g b in
       let rgba = to_rgba color in
       rgba.r = r && rgba.g = g && rgba.b = b)

(* rgb_to_ansi256 is deterministic *)
let prop_ansi256_deterministic =
  Test.make ~name:"rgb_to_ansi256 is deterministic"
    ~count:500
    gen_color_v4
    (fun color ->
       let code1 = Spectrum_tools.Convert.Perceptual.rgb_to_ansi256 color in
       let code2 = Spectrum_tools.Convert.Perceptual.rgb_to_ansi256 color in
       code1 = code2)

(* rgb_to_ansi16 is deterministic *)
let prop_ansi16_deterministic =
  Test.make ~name:"rgb_to_ansi16 is deterministic"
    ~count:500
    gen_color_v4
    (fun color ->
       let code1 = Spectrum_tools.Convert.Perceptual.rgb_to_ansi16 color in
       let code2 = Spectrum_tools.Convert.Perceptual.rgb_to_ansi16 color in
       code1 = code2)

(* HSL -> Color -> RGBA produces valid 0-255 components *)
let prop_hsl_to_rgba_valid =
  Test.make ~name:"HSL -> Color -> RGBA has valid components (0-255)"
    ~count:1000
    ~print:Print.(triple float float float)
    gen_hsl_triple
    (fun (h, s, l) ->
       let open Spectrum_tools.Convert.Color in
       let color = of_hsl h (s /. 100.) (l /. 100.) in
       let rgba = to_rgba color in
       rgba.r >= 0 && rgba.r <= 255 &&
       rgba.g >= 0 && rgba.g <= 255 &&
       rgba.b >= 0 && rgba.b <= 255)

(* Palette colors are their own nearest match for ansi256 *)
let prop_palette_color_identity_256 =
  let palette = Spectrum_palettes.Terminal.Xterm256.color_list in
  let target_colors = List.filteri (fun i _ -> i >= 16) palette in
  Test.make ~name:"palette colors 16-255 map to themselves via rgb_to_ansi256"
    ~count:240
    (Gen.int_range 0 (List.length target_colors - 1))
    (fun i ->
       let color = List.nth target_colors i in
       let code = Spectrum_tools.Convert.Perceptual.rgb_to_ansi256 color in
       code = i + 16)

let () =
  let qcheck_tests = List.map QCheck_alcotest.to_alcotest [
      prop_ansi256_range;
      prop_ansi16_range;
      prop_rgb_round_trip;
      prop_ansi256_deterministic;
      prop_ansi16_deterministic;
      prop_hsl_to_rgba_valid;
      prop_palette_color_identity_256;
    ] in
  Test_runner.run "Properties (spectrum_tools)" ~junit_filename:"junit-properties-tools.xml" [
    "Color conversion properties", qcheck_tests;
  ]
