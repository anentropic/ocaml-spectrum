(* float division of integers *)
let (//) a b = float_of_int a /. float_of_int b

(* rounds to nearest, .5 rounds up, -.5 rounds down *)
let int_round n = Float.round n |> int_of_float

let clamp min max n = match n with
  | n when n < min -> min
  | n when n > max -> max
  | _ -> n

let map_color f (color : Color.Rgba.t) = (f color.r), (f color.g), (f color.b)

let product3 l l' l'' = 
  List.concat_map (fun e ->
      List.concat_map (fun e' ->
          List.map (fun e'' -> (e, e', e'')) l'') l') l

let max3 a b c = max a (max b c)

module type Showable = sig
  type t
  val pp : Format.formatter -> t -> unit
  val show : t -> string
end

module type OrderedShowable = sig
  include Set.OrderedType
  include Showable with type t := t
end

module ShowableSet = struct
  include Set
  module type S = sig
    include Set.S
  end
  module Make (Ord : OrderedShowable) = struct
    include Set.Make(Ord)
  end
end

module type AdjacencySet = sig
  include ShowableSet.S
  val adjacent_values : t -> elt -> elt list option
  val adjacent_values_exn : t -> elt -> elt list
end

module AdjacencySet_Make (El : OrderedShowable) : AdjacencySet with type elt = El.t = struct
  include ShowableSet.Make(El)

  let adjacent_values set value =
    match split value set with
    | _, true, _ -> Some [value]
    | lt, false, gt -> begin
        match max_elt_opt lt, min_elt_opt gt with
        | Some prev, Some next -> Some [prev; next]
        | _, None -> None  (* value is > all elements *)
        | None, _ -> None  (* value is < all elements *)
      end

  let adjacent_values_exn set value =
    match adjacent_values set value with
    | Some l -> l
    | None -> invalid_arg @@ El.show value
end

module Int' = struct
  include Int
  type t = int [@@deriving show]
end

module IntAdjacencySet = AdjacencySet_Make(Int')


(* ---- UNUSED scratch pad ---- *)

let rgb_int_of_srgb_component x =
  (*
  Gg color float values are in sRGB space, we need to convert
  them back into simple RGB. gg only provides method to work on
  whole vector, e.g. we could:
  (Color.gray_tone x |> Gg.Color.to_srgb |> Color.to_rgba).r

  to avoid this we copy some logic from:
  https://github.com/dbuenzli/gg/blob/master/src/gg.ml#L2714
  *)
  let c0 = 0.0031308
  and c1 = 12.92
  and c2 = 1.055
  and c3 = 1. /. 2.4
  and c4 = 0.055 in
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

(* enumerate all RGB values, as v4 vector colour *)
let rgb_seq ?(rmax=256) ?(gmax=256) ?(bmax=256) =
  Seq.flat_map (fun r ->
      Seq.flat_map (fun g ->
          Seq.map (fun b ->
              Color.of_rgb r g b
            ) (range bmax)
        ) (range gmax)
    ) (range rmax)

(*
  find nearest y, where x=2^y
  could be used to determine the Int.shift_right from a grey_threshold in
  the Chalk rgb_to_ansi256 algorithm 
*)
let power_of_2 x = log (float_of_int x) /. log 2. |> int_of_float
