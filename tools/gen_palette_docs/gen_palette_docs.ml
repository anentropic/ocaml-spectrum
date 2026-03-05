(* Generates .mld documentation pages from palette JSON definitions.

   Reads the same JSON format used by the [%palette] PPX and outputs odoc
   markup with a table of all colors. Invoked at build time by dune rules
   so the JSON files remain the single source of truth. *)

(* ---- camel_to_kebab, replicated from spectrum_palette_ppx/utils.ml ---- *)

let regex_findall ~rex ?(i = 0) s =
  let unfolder last_r =
    try
      let (l, r) = Re.Group.offset (Re.exec ~pos:last_r rex s) i in
      let outval = String.sub s l (r - l) in
      Some (outval, r)
    with Not_found -> None
  in
  List.of_seq @@ Seq.unfold unfolder 0

let camel_to_kebab s =
  let rex = Re.Pcre.re "((?:[A-Z]|[0-9]+)[a-z]*)" |> Re.compile in
  String.concat "-" @@ List.map String.lowercase_ascii @@ regex_findall ~rex s

(* ---- JSON loading, same structure as spectrum_palette_ppx/loader.ml ---- *)

type color_entry = {
  name : string;
  code : int;
  r : int;
  g : int;
  b : int;
}

let e_invalid = Failure "Invalid json data"

let int_of_yojson = function
  | `Int i -> i
  | _ -> raise e_invalid

let str_of_yojson = function
  | `String s -> s
  | _ -> raise e_invalid

let rgb_tuple_of_yojson = function
  | `Assoc a ->
    ( int_of_yojson @@ List.assoc "r" a,
      int_of_yojson @@ List.assoc "g" a,
      int_of_yojson @@ List.assoc "b" a )
  | _ -> raise e_invalid

let color_of_yojson = function
  | `Assoc a ->
    let r, g, b = rgb_tuple_of_yojson @@ List.assoc "rgb" a in
    { name = str_of_yojson @@ List.assoc "name" a;
      code = int_of_yojson @@ List.assoc "colorId" a;
      r; g; b }
  | _ -> raise e_invalid

let load_json fname =
  match Yojson.Safe.from_file fname with
  | `List colors -> List.map color_of_yojson colors
  | _ -> raise e_invalid

(* ---- .mld generation ---- *)

let hex_of_rgb r g b = Printf.sprintf "#%02x%02x%02x" r g b

let generate palette_type json_file =
  let colors = load_json json_file in
  let title, description =
    match palette_type with
    | "basic" ->
      ( "Basic Palette (ANSI-16)",
        "The 16 standard ANSI terminal colors (codes 30-37, 90-97)." )
    | "xterm256" ->
      ( "Xterm256 Palette (ANSI-256)",
        "The 256-color xterm palette (codes 0-255): 16 system colors, \
         a 6x6x6 color cube, and 24 grayscale shades." )
    | _ -> failwith ("Unknown palette type: " ^ palette_type)
  in
  Printf.printf "{0 %s}\n\n" title;
  Printf.printf "%s\n\n" description;
  Printf.printf "Tag names shown below are for use in Spectrum format strings, \
                 e.g. [@@{<tag-name>text@@}].\n\n";
  Printf.printf "{t\n";
  Printf.printf "| Code | Tag Name | Hex | R | G | B | Color |\n";
  Printf.printf "|------|----------|-----|---|---|---|-------|\n";
  List.iter
    (fun c ->
       let tag_name = camel_to_kebab c.name in
       let hex = hex_of_rgb c.r c.g c.b in
       Printf.printf
         "| %d | %s | %s | %d | %d | %d | \
          {%%html: <span style=\"display:inline-block;width:3em;height:1.2em;\
          background-color:%s\">&nbsp;</span>%%} |\n"
         c.code tag_name hex c.r c.g c.b hex)
    colors;
  Printf.printf "}\n"

let () =
  let palette_type = Sys.argv.(1) in
  let json_file = Sys.argv.(2) in
  generate palette_type json_file
