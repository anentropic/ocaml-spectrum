module type M = sig
  (* variant of colour names *)
  type t

  val of_string : string -> t

  val to_code : t -> int

  val to_color : t -> Gg.v4

  val color_list : Gg.v4 list
end

exception InvalidColorName of string
