module Loader = Loader
module Palette = Palette
module Utils = Utils

open Ppxlib

(*
Example palette module:

module Basic : Palette.M = struct
  type t =
    | BrightWhite

  let of_string = function
    | "bright-white" -> BrightWhite
    | name -> raise @@ InvalidColorName name

  let to_code = function
    | BrightWhite -> 97

  let to_color = function
    | BrightWhite -> Color.of_rgb 255 255 255

  let color_list = [
    Color.of_rgb 255 255 255;
  ]
end
*)

let mod_type_txt dotted_path =
  (* TODO: I guess we could do a fold here to handle any no of segments *)
  match String.split_on_char ',' dotted_path with
  | [] -> raise (Failure "Empty module-type dotted path")
  | [a] -> Lident a
  | [a; b] -> Ldot (Lident a, b)
  | [a; b; c] -> Ldot (Ldot (Lident a, b), c)
  | _ -> raise (Failure "Too many segments in module-type dotted path")

let variant_of_defs ~loc defs = 
  let constructor name =
    (* one member of the variant *)
    {
      pcd_name = {txt = name; loc};
      pcd_args = Pcstr_tuple [];
      pcd_res = None;
      pcd_loc = loc;
      pcd_attributes = [];
    }
  in
  Ast_builder.Default.pstr_type ~loc Recursive [
    Ast_builder.Default.type_declaration
      ~loc
      ~name: {txt = "t"; loc}
      ~params: []
      ~cstrs: []
      ~kind: (Ptype_variant (List.map (fun (_, (def : Loader.t)) -> constructor def.name) defs))
      ~private_: Public
      ~manifest: None;
  ]

(* build AST for the generated of_string method *)
let of_string_f_of_defs ~loc defs =
  let def_to_case (def : Loader.t) =
    let name = Utils.camel_to_kebab def.name in
    {
      pc_lhs = Ast_builder.Default.ppat_constant ~loc (Pconst_string (name, loc, None));
      pc_guard = None;
      pc_rhs = Ast_builder.Default.pexp_construct ~loc {txt = Lident def.name; loc} None;
    }
  in
  let default_case = {
    pc_lhs = [%pat? name];
    pc_guard = None;
    pc_rhs = [%expr raise @@ Palette.InvalidColorName name];
  } in
  let cases = List.map (fun (_, def) -> def_to_case def) defs in
  Ast_builder.Default.pexp_function ~loc (cases @ [default_case])

(* build AST for the generated to_code method *)
let to_code_f_of_defs ~loc defs =
  let def_to_case (def : Loader.t) =
    {
      pc_lhs = Ast_builder.Default.ppat_construct ~loc {txt = Lident def.name; loc} None;
      pc_guard = None;
      pc_rhs = Ast_builder.Default.pexp_constant ~loc (Pconst_integer (Int.to_string def.code, None));
    }
  in
  let cases = List.map (fun (_, def) -> def_to_case def) defs in
  Ast_builder.Default.pexp_function ~loc cases

(* build AST for the generated to_color method *)
let to_color_f_of_defs ~loc defs =
  let def_to_case (def : Loader.t) =
    {
      pc_lhs = Ast_builder.Default.ppat_construct ~loc {txt = Lident def.name; loc} None;
      pc_guard = None;
      pc_rhs = Ast_builder.Default.pexp_apply ~loc
          (Ast_builder.Default.pexp_ident ~loc {txt = Ldot (Lident "Color", "of_rgb"); loc})
          (List.map (fun c ->
               (Nolabel, Ast_builder.Default.pexp_constant ~loc (Pconst_integer (Int.to_string c, None))))
              [def.r; def.g; def.b]);
    }
  in
  let cases = List.map (fun (_, def) -> def_to_case def) defs in
  Ast_builder.Default.pexp_function ~loc cases

(* build AST for the generated color_list *)
let color_list_of_defs ~loc defs =
  let def_to_color_expr (def : Loader.t) =
    Ast_builder.Default.pexp_apply ~loc
      (Ast_builder.Default.pexp_ident ~loc {txt = Ldot (Lident "Color", "of_rgb"); loc})
      (List.map
         (fun c ->
            (Nolabel, Ast_builder.Default.pexp_constant ~loc (Pconst_integer (Int.to_string c, None))))
         [def.r; def.g; def.b])
  in
  let colors_list_expr =
    List.fold_right
      (fun (_, def) accumulated ->
         Ast_builder.Default.pexp_construct
           ~loc
           {txt = Lident "::"; loc}
           (Some (Ast_builder.Default.pexp_tuple ~loc [def_to_color_expr def; accumulated])))
      defs
      (Ast_builder.Default.pexp_construct ~loc {txt = Lident "[]"; loc} None)
  in
  Ast_builder.Default.pstr_value ~loc Nonrecursive [
    Ast_builder.Default.value_binding ~loc
      ~pat: (Ast_builder.Default.ppat_var ~loc {txt = "color_list"; loc})
      ~expr: colors_list_expr;
  ]

(*
  Generate a Palette module from the given json config

  module MyPalette : Palette.M = [%palette "mycolors.json"]
*)
let expand ~ctxt filepath =
  let loc = Expansion_context.Extension.extension_point_loc ctxt in
  let defs = Loader.load_assoc @@ Sys.getcwd () ^ filepath in
  let mod_struct = [
    variant_of_defs ~loc defs;
    [%stri let of_string = [%e of_string_f_of_defs ~loc defs]];
    [%stri let to_code = [%e to_code_f_of_defs ~loc defs]];
    [%stri let to_color = [%e to_color_f_of_defs ~loc defs]];
    color_list_of_defs ~loc defs;
  ] in
  Ast_builder.Default.pmod_structure ~loc mod_struct

let palette_extension =
  Extension.V3.declare
    "palette"
    Extension.Context.module_expr  (* where it's valid *)
    Ast_pattern.(single_expr_payload (estring __))  (* arg def: expect a string *)
    expand

let rule = Ppxlib.Context_free.Rule.extension palette_extension

let () =
  Driver.register_transformation
    ~rules:[rule]
    "palette"
