(* float division of integers *)
let (//) a b = float_of_int a /. float_of_int b

(* rounds to nearest, .5 rounds up, -.5 rounds down *)
let int_round n = Float.round n |> int_of_float

let clamp min max n =
  match n with
  | n when n < min -> min
  | n when n > max -> max
  | _ -> n

module Rgba = struct
  type t = { r : int; g : int; b : int; a : float }
end

module Rgba' = struct
  type t = { r : float; g : float; b : float; a : float }
end

let to_rgba color =
  let c = Gg.Color.to_srgb color in
  {
    Rgba.r = int_of_float (Float.round (255. *. Gg.Color.r c));
    g = int_of_float (Float.round (255. *. Gg.Color.g c));
    b = int_of_float (Float.round (255. *. Gg.Color.b c));
    a = Gg.Color.a c;
  }

let to_rgba' color =
  let c = Gg.Color.to_srgb color in
  {
    Rgba'.r = Gg.Color.r c;
    g = Gg.Color.g c;
    b = Gg.Color.b c;
    a = Gg.Color.a c;
  }

let of_rgb r g b = Color.Rgb.(v r g b |> to_gg)

(** apply [f] to each component of [color] *)
let map_color f (color : Rgba.t) = (f color.r), (f color.g), (f color.b)
let map_color' f (color : Rgba'.t) = (f color.r), (f color.g), (f color.b)

let map3 f (a, b, c) = (f a), (f b), (f c)

let product3 l l' l'' = 
  List.concat_map (fun e ->
      List.concat_map (fun e' ->
          List.map (fun e'' -> (e, e', e'')) l'') l') l

let min3 a b c = min a (min b c)
let max3 a b c = max a (max b c)

let min_fold l = List.fold_left min (List.hd l) (List.tl l)
let max_fold l = List.fold_left max (List.hd l) (List.tl l)

(*
  Find nearest y, where x=2^y
  could be used to determine the Int.shift_right from a grey_threshold in
  the Chalk rgb_to_ansi256 algorithm

  the general solution is: y = log x / log 2 (for 2^y)
  let nearest_sqrt x = log (float_of_int x) /. log 2. |> int_of_float

  e.g. nearest_sqrt 17 -> 4

  ...on reflection, this is the same as:
  sqrt (float_of_int x) |> Float.floor |> int_of_float

  (with that method you could use round instead of floor for different result)

  they are both super fast, but the sqrt method is ~50% faster:
    log method:  1.33 WALL ( 1.32 usr +  0.02 sys =  1.33 CPU) @ 74977862.79/s (n=100000000)
   sqrt method:  0.83 WALL ( 0.83 usr +  0.00 sys =  0.83 CPU) @ 120053063.45/s (n=100000000)
  sqrt rounded:  0.85 WALL ( 0.84 usr +  0.01 sys =  0.84 CPU) @ 118393635.16/s (n=100000000)
*)
let nearest_sqrt x = sqrt (float_of_int x) |> Float.floor |> int_of_float
let nearest_sqrt' x = sqrt (float_of_int x) |> Float.round |> int_of_float

module type Showable = sig
  type t
  val pp : Format.formatter -> t -> unit
  val show : t -> string
end

module type OrderedShowable = sig
  include Set.OrderedType
  include Showable with type t := t
end

(* an ordered set of 'showable' elements *)
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

  (*
    from an ordered set of values, return a list of those which are 'adjacent'
    to the target value i.e. the ones immediately higher and lower
  *)
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

(* a 'showable' Int *)
module Int' = struct
  include Int
  type t = int [@@deriving show]
end

module IntAdjacencySet = AdjacencySet_Make(Int')

(*
https://cs3110.github.io/textbook/chapters/ds/memoization.html#memoization-using-higher-order-functions
*)
let memoise f =
  let table = Hashtbl.create 16 in
  let inner arg =
    match Hashtbl.find_opt table arg with
    | Some result -> result
    | None ->
      let result = f arg in
      Hashtbl.add table arg result;
      result
  in
  inner

(* ---- UNUSED scratch pad ---- *)

let rgb_int_of_srgb_component x =
  (*
  Gg color float values are in sRGB space, we need to convert
  them back into simple RGB. Gg only provides method to work on
  whole vector, e.g. we could:
  (Color.gray_tone x |> to_rgba).r

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

NOTE: not a 'real' octree, this is a simplification that only works
for a 256-colour palette which evenly divides the space
(commonly used 256 color palettes do not do this so it can give bad results)
*)
let color_index_256 color_v4 level =
  let color = to_rgba color_v4
  and index = ref 0
  and mask = Int.shift_right 0b10000000 level
  in
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

let product2 a b =
  List.concat_map (fun x ->
      List.map (fun y -> x, y) b
    ) a

let range ?(from=0) until ?(step=1) =
  let (><) =
    match step with
    | i when i < 0 -> (>)
    | i when i > 0 -> (<)
    | _ -> raise (Invalid_argument "step must not be zero")
  in
  Seq.unfold (function
        i when i >< until -> Some (i, i + step) | _ -> None
    ) from

(* enumerate all RGB values, as v4 vector colour *)
let rgb_seq ?(rmax=256) ?(gmax=256) ?(bmax=256) =
  Seq.flat_map (fun r ->
      Seq.flat_map (fun g ->
          Seq.map (fun b ->
              of_rgb r g b
            ) (range bmax)
        ) (range gmax)
    ) (range rmax)


(* from Core Stdio, will be in 4.14 stdlib *)
let fold_lines channel ~init ~f =
  let rec loop acc =
    let line = try Some (input_line channel)
      with End_of_file -> None
    in
    match line with
    | Some line -> loop (f acc line)
    | None -> acc
  in
  loop init

let input_lines channel =
  List.rev
    (fold_lines channel ~init:[] ~f:(fun lines line -> line :: lines))

exception Errored of int
exception Stopped of int
exception Signaled of int

let run cmd =
  let in_ch = Unix.open_process_in cmd in
  let lines = input_lines in_ch in
  match Unix.close_process_in in_ch with
  | Unix.WEXITED 0 -> lines
  | Unix.WEXITED e -> raise @@ Errored e
  | Unix.WSIGNALED s -> raise @@ Signaled s
  | Unix.WSTOPPED s -> raise @@ Stopped s

let p_to_string p =
  (*
    alternatively:
    Gg.V3.pp Format.std_formatter p;;
  *)
  Printf.sprintf "V3(x: %s, y: %s, z: %s)"
    (Gg.V3.x p |> Float.to_string)
    (Gg.V3.y p |> Float.to_string)
    (Gg.V3.z p |> Float.to_string)
