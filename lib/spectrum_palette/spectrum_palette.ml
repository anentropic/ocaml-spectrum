module Loader = Loader
module Palette = Palette
module Utils = Utils

open Ppxlib
module Ast = Ast_builder.Default

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

let variant_of_defs ~loc defs = 
  let constructor name =
    (* one member of the variant *)
    Ast.constructor_declaration
      ~loc
      ~name: {txt = name; loc}
      ~args: (Pcstr_tuple [])
      ~res: None
  in
  Ast.pstr_type ~loc Recursive [
    Ast.type_declaration
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
    Ast.case
      ~lhs: (Ast.ppat_constant ~loc (Pconst_string (name, loc, None)))
      ~guard: None
      ~rhs: (Ast.pexp_construct ~loc {txt = Lident def.name; loc} None)
  in
  let default_case =
    Ast.case
      ~lhs: [%pat? name]
      ~guard: None
      ~rhs: [%expr raise @@ Palette.InvalidColorName name]
  in
  let cases = List.map (fun (_, def) -> def_to_case def) defs in
  Ast.pexp_function ~loc (cases @ [default_case])

let const_integer_of_int i =
  Pconst_integer (Int.to_string i, None)

(* build AST for the generated to_code method *)
let to_code_f_of_defs ~loc defs =
  let def_to_case (def : Loader.t) =
    Ast.case
      ~lhs: (Ast.ppat_construct ~loc {txt = Lident def.name; loc} None)
      ~guard: None
      ~rhs: (Ast.pexp_constant ~loc (const_integer_of_int def.code))
  in
  let cases = List.map (fun (_, def) -> def_to_case def) defs in
  Ast.pexp_function ~loc cases

let apply_color_of_def ~loc (def : Loader.t) =
  Ast.pexp_apply ~loc
    (Ast.pexp_ident ~loc {txt = Ldot (Lident "Color", "of_rgb"); loc})
    (List.map (fun c ->
         (Nolabel, Ast.pexp_constant ~loc (const_integer_of_int c)))
        [def.r; def.g; def.b])

(* build AST for the generated to_color method *)
let to_color_f_of_defs ~loc defs =
  let def_to_case (def : Loader.t) =
    Ast.case
      ~lhs: (Ast.ppat_construct ~loc {txt = Lident def.name; loc} None)
      ~guard: None
      ~rhs: (apply_color_of_def ~loc def)
  in
  let cases = List.map (fun (_, def) -> def_to_case def) defs in
  Ast.pexp_function ~loc cases

(* build AST for the generated color_list *)
let color_list_of_defs ~loc defs =
  let colors_list_expr =
    (* AST for a List is recursive nested Head::Tail pairs *)
    List.fold_right
      (fun (_, def) accumulated ->
         Ast.pexp_construct
           ~loc
           {txt = Lident "::"; loc}
           (Some (Ast.pexp_tuple ~loc [apply_color_of_def ~loc def; accumulated])))
      defs
      (Ast.pexp_construct ~loc {txt = Lident "[]"; loc} None)
  in
  Ast.pstr_value ~loc Nonrecursive [
    Ast.value_binding ~loc
      ~pat: (Ast.ppat_var ~loc {txt = "color_list"; loc})
      ~expr: colors_list_expr;
  ]

(*
  Generate a Palette module from the given json config

  module MyPalette : Palette.M = [%palette "mycolors.json"]
*)
let expand ~ctxt filepath =
  let loc = Expansion_context.Extension.extension_point_loc ctxt in
  let defs = Loader.load_assoc filepath in
  let mod_struct = [
    variant_of_defs ~loc defs;
    [%stri let of_string = [%e of_string_f_of_defs ~loc defs]];
    [%stri let to_code = [%e to_code_f_of_defs ~loc defs]];
    [%stri let to_color = [%e to_color_f_of_defs ~loc defs]];
    color_list_of_defs ~loc defs;
  ] in
  Ast.pmod_structure ~loc mod_struct

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
