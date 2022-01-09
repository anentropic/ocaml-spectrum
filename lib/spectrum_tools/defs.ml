type ansi_color = {
  name: string;
  code: int;
  r: int;
  g: int;
  b: int;
}

let e_invalid = Failure "Invalid json data"

let to_int = function
  | `Int i -> i
  | _ -> raise e_invalid

let to_str = function
  | `String s -> s
  | _ -> raise e_invalid

let to_rgb_tuple = function
  | `Assoc a -> (
      to_int @@ List.assoc "r" a,
      to_int @@ List.assoc "g" a,
      to_int @@ List.assoc "b" a
    )
  | _ -> raise e_invalid

let to_ansi_color = function
  | `Assoc a -> begin
      let (r, g, b) = to_rgb_tuple @@ List.assoc "rgb" a in
      {
        name = to_str @@ List.assoc "name" a;
        code = to_int @@ List.assoc "colorId" a;
        r; g; b;
      }
    end
  | _ -> raise e_invalid

(*
loader for "256-colors.json"
(from https://www.ditig.com/256-colors-cheat-sheet)
...which contains defs of the xterm 256-color palette
*)
let load fname =
  let data = Yojson.Safe.from_file fname in
  match data with
  | `List colors -> List.map to_ansi_color colors
  | _ -> raise e_invalid

let load_assoc fname = List.map (fun ac -> (ac.code, ac)) @@ load fname
