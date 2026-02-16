{
  open Parser
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
  | style as name { Control (Style.of_string name) }

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

  let tag_to_compound_style tag =
    let lexbuf = Lexing.from_string tag in
    try Ok (parse lexbuf)  
    with e -> Error e
}
