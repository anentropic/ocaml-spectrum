type t = {
  name: string;
  code: int;
  r: int;
  g: int;
  b: int;
}

let to_color (def : t) = Color.of_rgb def.r def.g def.b

let e_invalid = Failure "Invalid json data"

let int_of_yojson = function
  | `Int i -> i
  | _ -> raise e_invalid

let str_of_yojson = function
  | `String s -> s
  | _ -> raise e_invalid

let rgb_tuple_of_yojson = function
  | `Assoc a -> (
      int_of_yojson @@ List.assoc "r" a,
      int_of_yojson @@ List.assoc "g" a,
      int_of_yojson @@ List.assoc "b" a
    )
  | _ -> raise e_invalid

let ansi_color_of_yojson = function
  | `Assoc a ->
    let r, g, b = rgb_tuple_of_yojson @@ List.assoc "rgb" a in
    {
      name = str_of_yojson @@ List.assoc "name" a;
      code = int_of_yojson @@ List.assoc "colorId" a;
      r; g; b;
    }
  | _ -> raise e_invalid

(*
  loader for "256-colors.json"
  (from https://www.ditig.com/256-colors-cheat-sheet)
  ...which contains defs of the xterm 256-color palette

  Expects a list of items like:

    {
      "colorId": 32,
      "rgb":{
        "r": 0,
        "g": 128,
        "b": 0
      },
      "name": "BasicGreen"
    }

  Where:
  - colorId: the associated (foreground) ANSI code
  - name: should be CamelCase ... we will use this as variant type name and
      also parse a kebab-case string name for use in actual format tokens
*)
let load fname =
  let data = Yojson.Safe.from_file fname in
  match data with
  | `List colors -> List.map ansi_color_of_yojson colors
  | _ -> raise e_invalid

let load_assoc fname = List.map (fun ac -> (ac.code, ac)) @@ load fname

let get_defs () = load_assoc @@ Sys.getcwd () ^ "/lib/spectrum_palette/256-colors.json"

let v4_of_ansi_color (def : t) = Color.of_rgb def.r def.g def.b