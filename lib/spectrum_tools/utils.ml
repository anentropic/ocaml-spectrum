(* rounds to nearest, .5 rounds up, -.5 rounds down *)
let int_round n = Float.round n |> int_of_float

let rgb_int_of_srgb_component x =
  (*
  Gg color float values are in sRGB space, we need to convert
  them back into simple RGB. gg only provides method to work on
  whole vector, e.g. we could:
  (Color.gray_tone x |> Gg.Color.to_srgb |> Color.to_rgba).r

  to avoid this we copy some logic from:
  https://github.com/dbuenzli/gg/blob/master/src/gg.ml#L2714
  *)
  let c0 = 0.0031308 in
  let c1 = 12.92 in
  let c2 = 1.055 in
  let c3 = 1. /. 2.4 in
  let c4 = 0.055 in
  let x' = if x <= c0 then c1 *. x else c2 *. (x ** c3) -. c4 in
  int_round (x' *. 255.)

(*
https://observablehq.com/@tmcw/octree-color-quantization

imagine a cube
each 'level' of the index subdivides the parent cube into 8 smaller cubes
(and in 2D you'd have a quadtree based on squares)
so with `level` and `color_index` you can locate 

function getColorIndex(color, level) {
  let index = 0;
  let mask = 0b10000000 >> level;
  if (color.red & mask) index |= 0b100;
  if (color.green & mask) index |= 0b010;
  if (color.blue & mask) index |= 0b001;
  return index;
}

returns: int in range 0..255
*)
let color_index_256 color_v4 level =
  let color = Color.to_rgba color_v4 in
  let index = ref 0 in
  let mask = Int.shift_right 0b10000000 level in
  if (color.r land mask) > 0 then index := !index lor 0b100;
  if (color.g land mask) > 0 then index := !index lor 0b010;
  if (color.b land mask) > 0 then index := !index lor 0b001;
  !index

(*
As per Python itertools.product

However, because tuples always have a fixed length in OCaml,
we are limited to lists which are all the same type, since the
returned products must themselves be homogenous lists
*)
let product pools =
  let result = ref [[]] in
  List.iter (fun pool ->
      result := List.concat_map (fun y ->
          List.map (fun x ->
              List.append x [y]
            ) !result
        ) pool
    ) pools;
  !result

let range ?(from=0) until ?(step=1) =
  let cmp = match step with
    | i when i < 0 -> (>)
    | i when i > 0 -> (<)
    | _ -> raise (Invalid_argument "step must not be zero")
  in
  Seq.unfold (function
        i when cmp i until -> Some (i, i + step) | _ -> None
    ) from
