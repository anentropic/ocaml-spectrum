open Utils

let (//) a b = float_of_int a /. float_of_int b

(*
  the xterm 256 color palette is organised such that:

    0-15: the basic 'system' colours, RGB values of 0, 128, 255
      plus an extra grey of 192,192,192
    16-231: non-grey colours, RGB values of 0, 95, 135, 175, 215, 255
      so intervals of 40 with darkest interval missing and all offset +15
    232-255: greys in intervals of 10, offset and truncated to 8..238

  the non-grey colours are organised into 'rows', with the six values of
  the B component as columns - the rows start with R:0 and G:0,
  incrementing G for the current R before incrementing R.
  starting at 16: 0,0,0

  the 16 basic colours are organised as:
    0: 0,0,0
    1-6: combinations of 0,128
    7: 192,192,192
    8: 128,128,128
    9-14: combinations of 0,255 (symmetrical to 1-6)
    15: 255,255,255
*)

(*
  returns ANSI code of approximate nearest xterm 256 palette color
  for the given RGB color value.

  This is the same algorithm used by Chalk.js, coming from:
  https://github.com/Qix-/color-convert/blob/master/conversions.js#L546

  Problem:
    (color.r // 255 *. 5.)

  ...this treats the colour range as if it is evenly divided, but the
  target values 0,95,135,175,215,255 are skewed towards the bright end

  this explains why it gives:
      rgb_to_ansi256([80, 80, 200]) -> 104  // rgb(135, 135, 215)
  despite the original R value 80 is closer to a target of 95

  Also note that in some cases there may be one of the 16 basic colors
  that is a closer match, but this will never return them.
*)
let rgb_to_ansi256 color_v4 =
  let color = Color.to_rgba color_v4 in
  (*
    The `>> 4` rshift sorts values into buckets of 16 width...
    but of course some values which are adjacent will sort into
    different buckets and won't be recognised as grey-like
    ...this probably doesn't matter much since there are also
    some pure greys in the general colours range
  *)
  if (
    (Int.shift_right color.r 4) == (Int.shift_right color.g 4) &&
    (Int.shift_right color.g 4) == (Int.shift_right color.b 4)
  ) then
    (*
      special case for grey-like colours
      the 232-255 code range is a 24 grey scale so we can get a closer match
    *)
    if color.r < 8 then
      16  (* black *)
    else if color.r > 248 then
      231 (* white *)
    else
      int_round ((color.r - 8) // 247 *. 24.) + 232
  else
    (* general colours *)
    16
    + int_round (color.r // 255 *. 5.) * 36
    + int_round (color.g // 255 *. 5.) * 6
    + int_round (color.b // 255 *. 5.)

(*
  Numerically we should sort into buckets of the half-way points, i.e.
  0-47    (0)
  48-114  (95)
  115-154 (135)
  155-194 (175)
  195-234 (215)
  235-255 (255)

  TODO: in theory binary search is faster, not really worth it for 6 values

  returns the ansi code 'column' index of an ansi256 color value
*)
let quantize_256 i =
  if i < 48 then 0
  else if i < 115 then 1
  else if i < 155 then 2
  else if i < 195 then 3
  else if i < 235 then 4
  else 5

(*
  a measure of the "un-grey-ness" of [colour]
  returns a value in range 0..255, where 0 is pure grey

  measures overall colour channel dissimilarity rather than
  sorting into buckets
*)
let rgb_component_range (color : Color.Rgba.t) =
  List.fold_left max 0 [
    abs (color.r - color.g);
    abs (color.r - color.b);
    abs (color.g - color.b);
  ]

let ansi256_rgb_to_code r g b = 16 + (r * 36) + (g * 6) + b

let ansi_grey_code r =
  if r < 8 then
    16  (* black *)
  else if r > 248 then
    231 (* white *)
  else
    int_round ((r - 8) // 247 *. 24.) + 232

(*
  Attempts to fix the problems with the JS algorithm
  and give a more accurate mapping, but is it slower?
*)
let rgb_to_ansi256_improved ?(grey_threshold=30) color_v4  =
  let color = Color.to_rgba color_v4 in
  if rgb_component_range color < grey_threshold then
    (*
      special case for grey-like colours
      the 232-255 code range is a 24 grey scale so we can get a closer match
    *)
    let avg = int_round ((color.r + color.g + color.b) // 3) in
    ansi_grey_code avg
  else
    (* general colours *)
    ansi256_rgb_to_code (quantize_256 color.r) (quantize_256 color.g) (quantize_256 color.b)

(*
  https://stackoverflow.com/a/1678481/202168
  This is the euclidian distance in LAB space
*)
let perceptual_distance rgb_a rgb_b =
  Gg.V4.sub (Gg.Color.to_lab rgb_a) (Gg.Color.to_lab rgb_b)
  |> Gg.V4.norm

let product3 l l' l'' = 
  List.concat_map (fun e ->
      List.concat_map (fun e' ->
          List.map (fun e'' -> (e, e', e'')) l'') l') l

(* 0, 95, 135, 175, 215, 255 *)
let adjacent_ansi256_components i =
  match i with
  | 0|95|135|175|215|255 -> [i]
  | _ ->
    if i < 95 then [0; 95]
    else if i < 135 then [95; 135]
    else if i < 175 then [135; 175]
    else if i < 215 then [175; 215]
    else [215; 255]

let adjacent_ansi256_colors color_v4 =
  let color = Color.to_rgba color_v4 in
  let rgb_tuples = product3
      (adjacent_ansi256_components color.r)
      (adjacent_ansi256_components color.g)
      (adjacent_ansi256_components color.b)
  in
  List.map (fun (r, g, b) -> Color.of_rgb r g b) rgb_tuples

let ansi256_component_to_column = function
  | 0 -> 0
  | 95 -> 1
  | 135 -> 2
  | 175 -> 3
  | 215 -> 4
  | 255 -> 5
  | i -> raise (Failure (Printf.sprintf "Invalid value: %d" i))

let rgb_to_ansi256_perceptual color_v4 =
  let color = Color.to_rgba color_v4 in
  if rgb_component_range color < 16 then
    (*
      special case for grey-like colours
      the 232-255 code range is a 24 grey scale so we can get a closer match
      TODO: these should be inserted as candidates rather than separate logic
    *)
    let avg = int_round ((color.r + color.g + color.b) // 3) in
    ansi_grey_code avg
  else
    (* general colours *)
    let init = (255., Color.black) in
    let candidate_distances = List.map (fun candidate ->
        let distance = perceptual_distance color_v4 candidate in
        (distance, candidate)
      ) @@ adjacent_ansi256_colors color_v4
    in
    let (_, candidate) = List.fold_left min init candidate_distances in
    let color = Color.to_rgba candidate in
    ansi256_rgb_to_code
      (ansi256_component_to_column color.r)
      (ansi256_component_to_column color.g)
      (ansi256_component_to_column color.b)

let rgb_seq ?(rmax=256) ?(gmax=256) ?(bmax=256) =
  Seq.flat_map (fun r ->
      Seq.flat_map (fun g ->
          Seq.map (fun b ->
              Color.of_rgb r g b
            ) (range bmax)
        ) (range gmax)
    ) (range rmax)

let v4_of_ansi_color (def : Defs.ansi_color) = Color.of_rgb def.r def.g def.b

let get_defs () = Defs.load_assoc @@ Sys.getcwd () ^ "/lib/spectrum_tools/256-colors.json"

let find_crossovers ?(rmax=256) ?(gmax=256) ?(bmax=256) () =
  let src = rgb_seq ~rmax ~gmax ~bmax in
  let defs = get_defs () in
  let prev_r = ref 0 in
  let prev_g = ref 0 in
  let prev_b = ref 0 in
  Seq.iter (fun color_v4 ->
      let color = Color.to_rgba color_v4 in
      let quantized =
        List.assoc (rgb_to_ansi256_perceptual color_v4) defs
        |> v4_of_ansi_color
        |> Color.to_rgba
      in
      if !prev_r <> quantized.r || !prev_g <> quantized.g || !prev_b <> quantized.b then
        Printf.printf
          "R:%d G:%d B:%d\t --> R:%d G:%d B:%d\n"
          color.r
          color.g
          color.b
          quantized.r
          quantized.g
          quantized.b;
      prev_r := quantized.r;
      prev_g := quantized.g;
      prev_b := quantized.b;
      ()
    ) src

let compare_method f r g b =
  let open Spectrum in
  let color_v4 = Color.of_rgb r g b in
  let color = Color.to_rgba color_v4 in
  let quantized_v4 = List.assoc (f color_v4) (get_defs ()) |> v4_of_ansi_color in
  let quantized = Color.to_rgba quantized_v4 in
  let og_tag = Printf.sprintf "@{<%s>" @@ Color.to_hexstring color_v4 in
  let qz_tag = Printf.sprintf "@{<%s>" @@ Color.to_hexstring quantized_v4 in
  let raw_fmt = og_tag ^ "(R:%d G:%d B:%d)@}\t --> " ^ qz_tag ^ "(R:%d G:%d B:%d)@}\n" in
  let fmt = Scanf.format_from_string raw_fmt (format_of_string "%d %d %d %d %d  %d") in
  Simple.printf
    fmt
    color.r
    color.g
    color.b
    quantized.r
    quantized.g
    quantized.b;
