exception InvalidStyleName of string
exception InvalidColorName of string

module Basic = Spectrum_palettes.Terminal.Basic
module Xterm256 = Spectrum_palettes.Terminal.Xterm256

module Style = struct
  type t =
    | Bold
    | Dim
    | Italic
    | Underline
    | Blink
    | RapidBlink
    | Inverse
    | Hidden
    | Strikethru

  (*
    see: https://en.wikipedia.org/wiki/ANSI_escape_code#SGR_(Select_Graphic_Rendition)_parameters
  *)
  let of_string s =
    match String.lowercase_ascii s with
    | "bold" -> Bold
    | "dim" -> Dim
    | "italic" -> Italic
    | "underline" -> Underline
    | "blink" -> Blink
    | "rapid-blink"-> RapidBlink
    | "inverse" -> Inverse
    | "hidden" -> Hidden
    | "strikethru" -> Strikethru
    | name -> raise @@ InvalidStyleName name

  let to_code = function
    | Bold -> 1
    | Dim -> 2
    | Italic -> 3
    | Underline -> 4
    | Blink -> 5
    | RapidBlink-> 6
    | Inverse -> 7
    | Hidden -> 8
    | Strikethru -> 9
end

type rgba = { r : int; g : int; b : int; a : float }

let rgba_of_color color =
  let c = Gg.Color.to_srgb color in
  {
    r = int_of_float (Float.round (255. *. Gg.Color.r c));
    g = int_of_float (Float.round (255. *. Gg.Color.g c));
    b = int_of_float (Float.round (255. *. Gg.Color.b c));
    a = Gg.Color.a c;
  }


module Rgb = struct
  let to_code color =
    let c = rgba_of_color color in
    (string_of_int c.r) ^ ";"
    ^ (string_of_int c.g) ^ ";"
    ^ (string_of_int c.b)
end

type color_def =
  | NamedBasicColor of Basic.t
  | Named256Color of Xterm256.t
  | RgbColor of Gg.v4

let rgbcolor c = RgbColor c

type token =
  | Foreground of color_def
  | Background of color_def
  | Control of Style.t

exception InvalidTag of string
exception InvalidHexColor of string
exception InvalidRgbColor of string
exception InvalidPercentage of string
exception InvalidQualifier of string
exception Eof

(*
  Will use the xterm-256 color names by default, falling back to Basic
  Note that Basic names have been prefixed to disambiguate
*)
let from_name name =
  try Named256Color (Xterm256.of_string name)
  with Spectrum_palettes.Terminal.InvalidColorName _ -> NamedBasicColor (Basic.of_string name)

let from_hex hex =
  match Color.of_hexstring hex with
  | Some color -> color |> rgbcolor
  | None -> raise @@ InvalidHexColor hex  (* unreachable *)

let parse_int_256 s =
  match int_of_string s with
  | i when i >= 0 && i < 256 -> i
  | _ -> raise @@ InvalidRgbColor s

let from_rgb r g b =
  let r = parse_int_256 r in
  let g = parse_int_256 g in
  let b = parse_int_256 b in
  Color.Rgb.(v r g b |> to_gg)
  |> rgbcolor

let parse_float_percent s =
  match float_of_string s with
  | i when i >= 0. && i <= 100. -> i
  | _ -> raise @@ InvalidPercentage s

let from_hsl h s l =
  let h = float_of_string h in
  let s = parse_float_percent s /. 100. in
  let l = parse_float_percent l /. 100. in
  Color.Hsl.(v h s l |> to_gg)
  |> rgbcolor

let qualified q color =
  match q with
  | Some "bg" -> Background color
  | Some "fg" -> Foreground color
  | None -> Foreground color
  | Some q -> raise @@ InvalidQualifier q  (* unreachable *)

let qualified_color_from_name q name = from_name name |> qualified q
let qualified_color_from_hex q hex = from_hex hex |> qualified q
let qualified_color_from_rgb q r g b = from_rgb r g b |> qualified q
let qualified_color_from_hsl q h s l = from_hsl h s l |> qualified q

type compound_tag = {
  bold : bool;
  dim : bool;
  italic : bool;
  underline : bool;
  blink : bool;
  rapid_blink : bool;
  inverse : bool;
  hidden : bool;
  strikethru : bool;
  fg_color : color_def option;
  bg_color : color_def option;
}

let compound_of_tokens tokens =
  let bold = ref false
  and dim = ref false
  and italic = ref false
  and underline = ref false
  and blink = ref false
  and rapid_blink = ref false
  and inverse = ref false
  and hidden = ref false
  and strikethru = ref false
  and fg_color = ref None
  and bg_color = ref None
  in
  List.iter (
    function
    | Control Bold -> bold := true
    | Control Dim -> dim := true
    | Control Italic -> italic := true
    | Control Underline -> underline := true
    | Control Blink -> blink := true
    | Control RapidBlink -> rapid_blink := true
    | Control Inverse -> inverse := true
    | Control Hidden -> hidden := true
    | Control Strikethru -> strikethru := true
    | Foreground c -> fg_color := Some c
    | Background c -> bg_color := Some c
  ) tokens;
  {
    bold = !bold;
    dim = !dim;
    italic = !italic;
    underline = !underline;
    blink = !blink;
    rapid_blink = !rapid_blink;
    inverse = !inverse;
    hidden = !hidden;
    strikethru = !strikethru;
    fg_color = !fg_color;
    bg_color = !bg_color;
  }
