module Loader = Loader
module Palette = Palette
module Utils = Utils

open Ppxlib
module Ast = Ast_builder.Default

(* ppxlib 0.33+ changed pexp_function to take function_param list instead of
   case list. Use pexp_fun + pexp_match for cross-version compatibility. *)
let function_of_cases ~loc cases =
  Ast.pexp_fun ~loc Nolabel None
    (Ast.ppat_var ~loc {txt = "__x"; loc})
    (Ast.pexp_match ~loc (Ast.pexp_ident ~loc {txt = Lident "__x"; loc}) cases)

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
      ~lhs: [%pat? _]
      ~guard: None
      ~rhs: [%expr raise @@ Palette.InvalidColorName __x]
  in
  let cases = List.map (fun (_, def) -> def_to_case def) defs in
  (* Match on String.lowercase_ascii of the input for case-insensitive lookup,
     but use the original input (__x) in the error message *)
  Ast.pexp_fun ~loc Nolabel None
    (Ast.ppat_var ~loc {txt = "__x"; loc})
    (Ast.pexp_match ~loc
       [%expr String.lowercase_ascii __x]
       (cases @ [default_case]))

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
  function_of_cases ~loc cases

let apply_color_of_def ~loc (def : Loader.t) =
  Ast.pexp_apply ~loc
    (Ast.pexp_ident ~loc {txt = Ldot (Ldot (Lident "Color", "Rgb"), "to_gg"); loc})
    [
      (Nolabel,
       Ast.pexp_apply ~loc
         (Ast.pexp_ident ~loc {txt = Ldot (Ldot (Lident "Color", "Rgb"), "v"); loc})
         (List.map (fun c ->
              (Nolabel, Ast.pexp_constant ~loc (const_integer_of_int c)))
             [def.r; def.g; def.b]))
    ]

(* build AST for the generated to_color method *)
let to_color_f_of_defs ~loc defs =
  let def_to_case (def : Loader.t) =
    Ast.case
      ~lhs: (Ast.ppat_construct ~loc {txt = Lident def.name; loc} None)
      ~guard: None
      ~rhs: (apply_color_of_def ~loc def)
  in
  let cases = List.map (fun (_, def) -> def_to_case def) defs in
  function_of_cases ~loc cases

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

let rec find_in_ancestors ~start relpath =
  let candidate = Filename.concat start relpath in
  if Sys.file_exists candidate then Some candidate
  else
    let parent = Filename.dirname start in
    if String.equal parent start then None
    else find_in_ancestors ~start:parent relpath

let resolve_palette_filepath filepath =
  if not (Filename.is_relative filepath) then filepath
  else if Sys.file_exists filepath then filepath
  else
    match Sys.getenv_opt "DUNE_SOURCEROOT" with
    | Some root ->
      let candidate = Filename.concat root filepath in
      if Sys.file_exists candidate then candidate
      else (
        match find_in_ancestors ~start:(Sys.getcwd ()) filepath with
        | Some p -> p
        | None -> filepath
      )
    | None -> (
        match find_in_ancestors ~start:(Sys.getcwd ()) filepath with
        | Some p -> p
        | None -> filepath
      )

(*
  Generate a Palette module from the given json config

  module MyPalette : Palette.M = [%palette "mycolors.json"]
*)
let expand ~ctxt filepath =
  let loc = Expansion_context.Extension.extension_point_loc ctxt in
  let defs = Loader.load_assoc (resolve_palette_filepath filepath) in
  let mod_struct = [
    variant_of_defs ~loc defs;
    [%stri let of_string = [%e of_string_f_of_defs ~loc defs]];
    [%stri let to_code = [%e to_code_f_of_defs ~loc defs]];
    [%stri let to_color = [%e to_color_f_of_defs ~loc defs]];
    color_list_of_defs ~loc defs;
    [%stri let nearest = Palette.nearest_of_list color_list];
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
