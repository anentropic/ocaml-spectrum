module Basic : Palette.M = struct
  type t =
    | BrightWhite
    | Black

  let of_string = function
    | "bright-white" -> BrightWhite
    | name -> raise @@ Palette.InvalidColorName name

  let to_code = function
    | BrightWhite -> 97

  let to_color = function
    | BrightWhite -> Color.of_rgb 255 255 255

  let color_list = [
    Color.of_rgb 111 111 111;
    Color.of_rgb 222 222 222;
    Color.of_rgb 333 333 333;
  ]
end
