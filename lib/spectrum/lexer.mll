{
  exception InvalidTag of string
  exception InvalidStyleName of string
  exception InvalidColorName of string
  exception InvalidHexColor of string
  exception InvalidRgbColor of string
  exception InvalidPercentage of string
  exception InvalidQualifier of string
  exception Eof

  let name_to_ansi_style = function
    | "bold" -> "1"
    | "dim" -> "2"
    | "italic" -> "3"
    | "underline" -> "4"
    | "blink" -> "5"
    | "rapid-blink"-> "5"
    | "inverse" -> "7"
    | "hidden" -> "8"
    | "strikethru" -> "9"
    | name -> raise @@ InvalidStyleName name

  (* see: https://www.ditig.com/256-colors-cheat-sheet *)
  let name_to_xterm_color = function
    | "black" -> "0"
    | "maroon" -> "1"
    | "green" -> "2"
    | "olive" -> "3"
    | "navy" -> "4"
    | "purple" -> "5"
    | "teal" -> "6"
    | "silver" -> "7"
    | "grey" -> "8"
    | "red" -> "9"
    | "lime" -> "10"
    | "yellow" -> "11"
    | "blue" -> "12"
    | "fuchsia" -> "13"
    | "aqua" -> "14"
    | "white" -> "15"
    | "grey-0" -> "16"
    | "navy-blue" -> "17"
    | "dark-blue" -> "18"
    | "blue-3a" -> "19"
    | "blue-3b" -> "20"
    | "blue-1" -> "21"
    | "dark-green" -> "22"
    | "deep-sky-blue-4a" -> "23"
    | "deep-sky-blue-4b" -> "24"
    | "deep-sky-blue-4c" -> "25"
    | "dodger-blue-3" -> "26"
    | "dodger-blue-2" -> "27"
    | "green-4" -> "28"
    | "spring-green-4" -> "29"
    | "turquoise-4" -> "30"
    | "deep-sky-blue-3a" -> "31"
    | "deep-sky-blue-3b" -> "32"
    | "dodger-blue-1" -> "33"
    | "green-3a" -> "34"
    | "spring-green-3a" -> "35"
    | "dark-cyan" -> "36"
    | "light-sea-green" -> "37"
    | "deep-sky-blue-2" -> "38"
    | "deep-sky-blue-1" -> "39"
    | "green-3b" -> "40"
    | "spring-green-3b" -> "41"
    | "spring-green-2a" -> "42"
    | "cyan-3" -> "43"
    | "dark-turquoise" -> "44"
    | "turquoise-2" -> "45"
    | "green-1" -> "46"
    | "spring-green-2b" -> "47"
    | "spring-green-1" -> "48"
    | "medium-spring-green" -> "49"
    | "cyan-2" -> "50"
    | "cyan-1" -> "51"
    | "dark-red-1" -> "52"
    | "deep-pink-4a" -> "53"
    | "purple-4a" -> "54"
    | "purple-4b" -> "55"
    | "purple-3" -> "56"
    | "blue-violet" -> "57"
    | "orange-4a" -> "58"
    | "grey-37" -> "59"
    | "medium-purple-4" -> "60"
    | "slate-blue-3a" -> "61"
    | "slate-blue-3b" -> "62"
    | "royal-blue-1" -> "63"
    | "chartreuse-4" -> "64"
    | "dark-sea-green-4a" -> "65"
    | "pale-turquoise-4" -> "66"
    | "steel-blue" -> "67"
    | "steel-blue-3" -> "68"
    | "cornflower-blue" -> "69"
    | "chartreuse-3a" -> "70"
    | "dark-sea-green-4b" -> "71"
    | "cadet-blue-2" -> "72"
    | "cadet-blue-1" -> "73"
    | "sky-blue-3" -> "74"
    | "steel-blue-1a" -> "75"
    | "chartreuse-3b" -> "76"
    | "pale-green-3a" -> "77"
    | "sea-green-3" -> "78"
    | "aquamarine-3" -> "79"
    | "medium-turquoise" -> "80"
    | "steel-blue-1b" -> "81"
    | "chartreuse-2a" -> "82"
    | "sea-green-2" -> "83"
    | "sea-green-1a" -> "84"
    | "sea-green-1b" -> "85"
    | "aquamarine-1a" -> "86"
    | "dark-slate-gray-2" -> "87"
    | "dark-red-2" -> "88"
    | "deep-pink-4b" -> "89"
    | "dark-magenta-1" -> "90"
    | "dark-magenta-2" -> "91"
    | "dark-violet-1a" -> "92"
    | "purple-1a" -> "93"
    | "orange-4b" -> "94"
    | "light-pink-4" -> "95"
    | "plum-4" -> "96"
    | "medium-purple-3a" -> "97"
    | "medium-purple-3b" -> "98"
    | "slate-blue-1" -> "99"
    | "yellow-4a" -> "100"
    | "wheat-4" -> "101"
    | "grey-53" -> "102"
    | "light-slate-grey" -> "103"
    | "medium-purple" -> "104"
    | "light-slate-blue" -> "105"
    | "yellow-4b" -> "106"
    | "dark-olive-green-3a" -> "107"
    | "dark-green-sea" -> "108"
    | "light-sky-blue-3a" -> "109"
    | "light-sky-blue-3b" -> "110"
    | "sky-blue-2" -> "111"
    | "chartreuse-2b" -> "112"
    | "dark-olive-green-3b" -> "113"
    | "pale-green-3b" -> "114"
    | "dark-sea-green-3a" -> "115"
    | "dark-slate-gray-3" -> "116"
    | "sky-blue-1" -> "117"
    | "chartreuse-1" -> "118"
    | "light-green-2" -> "119"
    | "light-green-3" -> "120"
    | "pale-green-1a" -> "121"
    | "aquamarine-1b" -> "122"
    | "dark-slate-gray-1" -> "123"
    | "red-3a" -> "124"
    | "deep-pink-4c" -> "125"
    | "medium-violet-red" -> "126"
    | "magenta-3a" -> "127"
    | "dark-violet-1b" -> "128"
    | "purple-1b" -> "129"
    | "dark-orange-3a" -> "130"
    | "indian-red-1a" -> "131"
    | "hot-pink-3a" -> "132"
    | "medium-orchid-3" -> "133"
    | "medium-orchid" -> "134"
    | "medium-purple-2a" -> "135"
    | "dark-goldenrod" -> "136"
    | "light-salmon-3a" -> "137"
    | "rosy-brown" -> "138"
    | "grey-63" -> "139"
    | "medium-purple-2b" -> "140"
    | "medium-purple-1" -> "141"
    | "gold-3a" -> "142"
    | "dark-khaki" -> "143"
    | "navajo-white-3" -> "144"
    | "grey-69" -> "145"
    | "light-steel-blue-3" -> "146"
    | "light-steel-blue" -> "147"
    | "yellow-3a" -> "148"
    | "dark-olive-green-3" -> "149"
    | "dark-sea-green-3b" -> "150"
    | "dark-sea-green-2" -> "151"
    | "light-cyan-3" -> "152"
    | "light-sky-blue-1" -> "153"
    | "green-yellow" -> "154"
    | "dark-olive-green-2" -> "155"
    | "pale-green-1b" -> "156"
    | "dark-sea-green-5b" -> "157"
    | "dark-sea-green-5a" -> "158"
    | "pale-turquoise-1" -> "159"
    | "red-3b" -> "160"
    | "deep-pink-3a" -> "161"
    | "deep-pink-3b" -> "162"
    | "magenta-3b" -> "163"
    | "magenta-3c" -> "164"
    | "magenta-2a" -> "165"
    | "dark-orange-3b" -> "166"
    | "indian-red-1b" -> "167"
    | "hot-pink-3b" -> "168"
    | "hot-pink-2" -> "169"
    | "orchid" -> "170"
    | "medium-orchid-1a" -> "171"
    | "orange-3" -> "172"
    | "light-salmon-3b" -> "173"
    | "light-pink-3" -> "174"
    | "pink-3" -> "175"
    | "plum-3" -> "176"
    | "violet" -> "177"
    | "gold-3b" -> "178"
    | "light-goldenrod-3" -> "179"
    | "tan" -> "180"
    | "misty-rose-3" -> "181"
    | "thistle-3" -> "182"
    | "plum-2" -> "183"
    | "yellow-3b" -> "184"
    | "khaki-3" -> "185"
    | "light-goldenrod-2a" -> "186"
    | "light-yellow-3" -> "187"
    | "grey-84" -> "188"
    | "light-steel-blue-1" -> "189"
    | "yellow-2" -> "190"
    | "dark-olive-green-1a" -> "191"
    | "dark-olive-green-1b" -> "192"
    | "dark-sea-green-1" -> "193"
    | "honeydew-2" -> "194"
    | "light-cyan-1" -> "195"
    | "red-1" -> "196"
    | "deep-pink-2" -> "197"
    | "deep-pink-1a" -> "198"
    | "deep-pink-1b" -> "199"
    | "magenta-2b" -> "200"
    | "magenta-1" -> "201"
    | "orange-red-1" -> "202"
    | "indian-red-1c" -> "203"
    | "indian-red-1d" -> "204"
    | "hot-pink-1a" -> "205"
    | "hot-pink-1b" -> "206"
    | "medium-orchid-1b" -> "207"
    | "dark-orange" -> "208"
    | "salmon-1" -> "209"
    | "light-coral" -> "210"
    | "pale-violet-red-1" -> "211"
    | "orchid-2" -> "212"
    | "orchid-1" -> "213"
    | "orange-1" -> "214"
    | "sandy-brown" -> "215"
    | "light-salmon-1" -> "216"
    | "light-pink-1" -> "217"
    | "pink-1" -> "218"
    | "plum-1" -> "219"
    | "gold-1" -> "220"
    | "light-goldenrod-2b" -> "221"
    | "light-goldenrod-2c" -> "222"
    | "navajo-white-1" -> "223"
    | "misty-rose1" -> "224"
    | "thistle-1" -> "225"
    | "yellow-1" -> "226"
    | "light-goldenrod-1" -> "227"
    | "khaki-1" -> "228"
    | "wheat-1" -> "229"
    | "cornsilk-1" -> "230"
    | "grey-100" -> "231"
    | "grey-3" -> "232"
    | "grey-7" -> "233"
    | "grey-11" -> "234"
    | "grey-15" -> "235"
    | "grey-19" -> "236"
    | "grey-23" -> "237"
    | "grey-27" -> "238"
    | "grey-30" -> "239"
    | "grey-35" -> "240"
    | "grey-39" -> "241"
    | "grey-42" -> "242"
    | "grey-46" -> "243"
    | "grey-50" -> "244"
    | "grey-54" -> "245"
    | "grey-58" -> "246"
    | "grey-62" -> "247"
    | "grey-66" -> "248"
    | "grey-70" -> "249"
    | "grey-74" -> "250"
    | "grey-78" -> "251"
    | "grey-82" -> "252"
    | "grey-85" -> "253"
    | "grey-89" -> "254"
    | "grey-93" -> "255"
    | name -> raise @@ InvalidColorName name

  let fg_from_name name = "38;5;" ^ name_to_xterm_color name
  let bg_from_name name = "48;5;" ^ name_to_xterm_color name

  let from_hex hex =
    match Color.of_hexstring hex with
    | Some color ->
        let c = Color.to_rgba color in
        Printf.sprintf "%i;%i;%i" c.r c.g c.b
    | None -> raise @@ InvalidHexColor hex  (* unreachable *)

  let fg_from_hex hex = "38;2;" ^ from_hex hex
  let bg_from_hex hex = "48;2;" ^ from_hex hex

  let parse_int_256 s =
    match int_of_string s with
    | i when i < 256 -> i
    | _ -> raise @@ InvalidRgbColor s

  let from_rgb r g b =
    let r = parse_int_256 r in
    let g = parse_int_256 g in
    let b = parse_int_256 b in
    Printf.sprintf "%i;%i;%i" r g b

  let fg_from_rgb r g b = "38;2;" ^ from_rgb r g b
  let bg_from_rgb r g b = "48;2;" ^ from_rgb r g b

  let parse_float_percent s =
    match float_of_string s with
    | i when i <= 100. -> i
    | _ -> raise @@ InvalidPercentage s

  let from_hsl h s l =
    let h = float_of_string h in
    let s = parse_float_percent s /. 100. in
    let l = parse_float_percent l /. 100. in
    let color = Color.of_hsl h s l |> Color.to_rgba in
    Printf.sprintf "%i;%i;%i" color.r color.g color.b

  let fg_from_hsl h s l = "38;2;" ^ from_hsl h s l
  let bg_from_hsl h s l = "48;2;" ^ from_hsl h s l

  let qualified f_bg f_fg = function
    | Some "bg" -> f_bg
    | Some "fg" -> f_fg
    | None -> f_fg
    | Some q -> raise @@ InvalidQualifier q  (* unreachable *)

  let qualified_color_from_name = qualified bg_from_name fg_from_name
  let qualified_color_from_hex = qualified bg_from_hex fg_from_hex
  let qualified_color_from_rgb = qualified bg_from_rgb fg_from_rgb
  let qualified_color_from_hsl = qualified bg_from_hsl fg_from_hsl
}

let alpha = ['a'-'z' 'A'-'Z']
let num = ['0'-'9']
let alphanum = alpha | num

let identifier = alpha (alphanum | '-')*

let hex = ['0'-'9' 'a'-'f' 'A'-'F']
let hexcode = ((hex hex hex) | (hex hex hex hex hex hex))

let qualifier = ("fg" | "bg")

let style = ("bold" | "dim" | "italic" | "underline" | "blink" | "rapid-blink" | "inverse" | "hidden" | "strikethru")

let whitespace = [' ' '\t']

let int = num+
let float = (int "."?) | (int? "." int)

let sep = ("," | " ") whitespace*

let rgb = ['r' 'R'] ['g' 'G'] ['b' 'B']
let hsl = ['h' 'H'] ['s' 'S'] ['l' 'L']

rule to_code = parse
  (* ANSI style codes *)
  | style as name { name_to_ansi_style name }

  (* CSS-style hex colours *)
  | ((qualifier as q)  ":")? ("#" hexcode as hex) {
      qualified_color_from_hex q hex
    }
  (* CSS-style rgb colours *)
  | ((qualifier as q)  ":")? (rgb "(" (int as r) sep (int as g) sep (int as b) ")") {
      qualified_color_from_rgb q r g b
    }
  (* CSS-style hsl colours *)
  | ((qualifier as q)  ":")? (hsl "(" (("-"? int) as h) sep (int as s) "%"? sep (int as l) "%"? ")") {
      qualified_color_from_hsl q h s l
    }
  (* xterm 256 colour names *)
  | ((qualifier as q)  ":")? (identifier as name) {
      qualified_color_from_name q name
    }

  | whitespace* ","? whitespace*     { to_code lexbuf }

  | _ as c	{ raise (InvalidTag (Printf.sprintf "Unexpected char: %c" c)) }
  | eof			{ raise Eof }

{
  let parse_one lexbuf =
    try Some (to_code lexbuf)
    with Eof -> None

  let rec parse lexbuf =
    match parse_one lexbuf with
    | Some code -> code :: parse lexbuf
    | None -> []

  let tag_to_code tag =
    let lexbuf = Lexing.from_string tag in
    try Ok (String.concat ";" @@ parse lexbuf)  
    with e -> Error e
}
