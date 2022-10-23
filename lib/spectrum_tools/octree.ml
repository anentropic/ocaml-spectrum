(*
https://cs3110.github.io/textbook/chapters/data/trees.html

https://en.wikipedia.org/wiki/Octree#Application_to_color_quantization

http://delimitry.blogspot.com/2016/02/octree-color-quantizer-in-python.html
shows how to build the palette from an image
in our case we don't need the pixel count

we want a sparse tree?
the important part is the nearest-neighbour search implementation?
https://geidav.wordpress.com/2017/12/02/advanced-octrees-4-finding-neighbor-nodes/

using bit shift we can find the Leaf where our target value should reside
from there we traverse up the tree (in each axis) 

for 256 colors I think we have 7 levels - the 8th level contains everything

so we have a 7-digit octree index to uniquely locate any 24-bit color?

https://geidav.wordpress.com/2014/08/18/advanced-octrees-2-node-representations/#highlighter_76916
each digit only needs 3 bits, 2 ** 3 = 8, i.e. 0 or 1 per axis gives the octant
3 bits * 8 levels = 24 bits

is there a clever translation between RGB 24 bits and octree index 24 bits?

level 1:  0-127 128-255
level 2:  0-63 64-127 128-191 192-255
etc

2. ** 5. = 32
Int.shift_right 31 5;; 0
Int.shift_right 32 5;; 1

with fixed offsets for buckets far from 0

can we just have a hashmap of octree-index to colors in palette?
and the nearest neighbour search is a process of generating adjacent keys to
look up until we find a match?
possibly find the 2-3 nearest and then compare perceptually?

or build the actual tree? allows to ignore nodes with no members
still need to backtrack and check for nearer match in adjacent cells that
weren't in the octree index path of the target value?

https://stackoverflow.com/a/41306992/202168
"For points (leaves), the distance is just the distance of the point from the
search point. For internal nodes (octants), the distance is the smallest
distance from the search point to any point that could possibly be in the
octant" ...this maybe gives us the way to determine which nodes to backtrack
to, i.e. any nodes which could potentially hold a better match than our
nearest-match-by-tree-index
yes, this will do the trick:
https://pqwy.github.io/psq/doc/psq/Psq/module-type-S/index.html
i.e. as we traverse down the tree we add nodes with their min distance as
the priority, when we get to a leaf we add to the queue... maybe now a prior
node now has lowest priority so we explore that ~~

how to find min distance of voxel to point?
https://math.stackexchange.com/a/2133235/181250
our octree is 'axis-aligned'
|x| is abs(x)
their algo requires scaling and shifting so that target octant coords range
from -1 to 1

and if we index in LAB color space? then the true nearest neighbour will
already be the perceptual nearest and no need to compare other values

Gg.Color.to_lab is a V4 -> V4 translation, i.e. floats with 0-1 range

octants per level (start at 1): (2. ** level) ** 3.
*)

module Octree = struct
  type t =
    | Leaf of Gg.V3.t
    | Node of node

  and node = {
    level: int;
    offset: Gg.V3.t;
    x0_y0_z0: t option; (* 0 | 0 0 0 *)
    x0_y0_z1: t option; (* 1 | 0 0 1 *)
    x0_y1_z0: t option; (* 2 | 0 1 0 *)
    x0_y1_z1: t option; (* 3 | 0 1 1 *)
    x1_y0_z0: t option; (* 4 | 1 0 0 *)
    x1_y0_z1: t option; (* 5 | 1 0 1 *)
    x1_y1_z0: t option; (* 6 | 1 1 0 *)
    x1_y1_z1: t option; (* 7 | 1 1 1 *)
  }

  let children node =
    List.filter_map (fun n -> n) [
      node.x0_y0_z0;
      node.x0_y0_z1;
      node.x0_y1_z0;
      node.x0_y1_z1;
      node.x1_y0_z0;
      node.x1_y0_z1;
      node.x1_y1_z0;
      node.x1_y1_z1;
    ]
end

(* always positive (i.e. has no direction) *)
let distance a b = Gg.V3.sub a b |> Gg.V3.norm

(*
  scale and translate p with octant so that octant coords cover -1,-1,-1 to 1,1,1
  (our root octant is natively 0,0,0 to 1,1,1)
*)
let p_to_normalised (octant : Octree.node) p =
  let level = Float.of_int octant.level in
  let scale = Gg.V3.map (fun i -> i *. level *. 2.) in
  let base_offset = Gg.V3.of_tuple (-1., -1., -1.) in
  let offset = scale (Gg.V3.sub base_offset octant.offset) in
  Gg.V3.add (scale p) offset

(* so that we can compare normalised octant distances with p2p distances *)
let d_from_normalised (octant : Octree.node) d =
  let level = Float.of_int octant.level in
  d /. level

(* https://math.stackexchange.com/a/2133235/181250 *)
let octant_min_distance octant p =
  let x, y, z = p_to_normalised octant p |> Gg.V3.map abs_float |> Gg.V3.to_tuple in
  let d =
    if x <= 1. then
      if y <= 1. then
        max 0. (z -. 1.)  (* 0 if p in octant, all other cases return > 0 *)
      else
      if z <= 1. then
        y -. 1.
      else
        sqrt (y -. 1.) ** 2. +. (z -. 1.) ** 2.
    else
    if y <= 1. then
      if z <= 1. then
        x -. 1.
      else
        sqrt ((x -. 1.) ** 2. +. (z -. 1.) ** 2.)
    else
    if z <= 1. then
      sqrt ((x -. 1.) ** 2. +. (y -. 1.) ** 2.)
    else
      sqrt ((x -. 1.) ** 2. +. (y -. 1.) ** 2. +. (z -. 1.) ** 2.)
  in
  d_from_normalised octant d

module K = struct
  type t = Octree.t
  let compare = compare
end
module P = struct
  type t = float
  let compare = compare
end
module PQ = Psq.Make(K)(P)

let octant_offset level i parent_offset =
  let base_offset = 1. /. 2. ** (Float.of_int level) in
  let offset getter mask =
    match i land mask with  (* 0 or 1 *)
    | 0 -> getter parent_offset
    | _ -> getter parent_offset +. base_offset
  in
  Gg.V3.of_tuple ((offset Gg.V3.x 4), (offset Gg.V3.y 2), (offset Gg.V3.z 1))

let rec nearest pq tree p =
  let pq = PQ.add_seq (
      List.map (fun child ->
          match child with
          | Octree.Leaf l -> (child, distance l p)
          | Octree.Node n -> (child, octant_min_distance n p)
        ) @@ Octree.children tree
      |> List.to_seq
    ) pq
  in
  match PQ.pop pq with
  | Some ((tree, _), pq) -> begin
      match tree with
      | Leaf l -> l
      | Node n -> nearest pq n p
    end
  | None -> raise Not_found  (* would mean our tree is empty *)
