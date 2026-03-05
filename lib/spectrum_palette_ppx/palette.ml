module type M = sig
  type t  (* variant of colour names *)

  val of_string : string -> t

  val to_code : t -> int

  val to_color : t -> Gg.v4

  val color_list : Gg.v4 list

  val nearest : Gg.v4 -> Gg.v4
end

exception InvalidColorName of string

module Okt = Oktree.Make (Gg.V3)

(*
  Runtime index used by generated palette modules for fast nearest-color lookup.

  We index colors in LAB space (L-star, a-star, b-star) because Euclidean distance there is
  a much better approximation of perceptual difference than Euclidean RGB.

  The octree stores only 3D LAB points, so we keep a reverse lookup map from
  each LAB point tuple back to its original RGBA color value.
*)
type nearest_index = {
  tree : Okt.t;
  by_lab : ((float * float * float), Gg.v4) Hashtbl.t;
}

(*
  Convert an RGBA color to the 3 LAB coordinates used for nearest-neighbor
  search. Alpha is intentionally ignored in the distance metric.
*)
let lab3_of_color color =
  let lab = Gg.Color.to_lab color in
  Gg.V3.v (Gg.V4.x lab) (Gg.V4.y lab) (Gg.V4.z lab)

(*
  Build the nearest-neighbor index (oktree + RGB:LAB map) once from a palette color list.

  - [points] is the LAB point cloud used to build the octree.
  - [by_lab] lets us recover the exact palette color after octree nearest
    returns a LAB point.
*)
let nearest_index_of_color_list ?leaf_size color_list =
  let by_lab = Hashtbl.create (List.length color_list) in
  let points =
    List.map
      (fun color ->
         let lab = lab3_of_color color in
         Hashtbl.replace by_lab (Gg.V3.to_tuple lab) color;
         lab)
      color_list
  in
  let tree = Okt.of_list ?leaf_size points in
  { tree; by_lab }

(*
  Query path:
  1. project target color to LAB
  2. find nearest LAB point in octree
  3. map that point back to the original palette color
*)
let nearest_with_index index target =
  let nearest_lab = Okt.nearest index.tree (lab3_of_color target) in
  Hashtbl.find index.by_lab (Gg.V3.to_tuple nearest_lab)

(* Precompute index once, return a reusable nearest lookup function. *)
let nearest_of_list ?leaf_size color_list =
  let index = nearest_index_of_color_list ?leaf_size color_list in
  fun target -> nearest_with_index index target
