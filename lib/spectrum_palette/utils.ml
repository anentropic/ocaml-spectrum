(* similar to python re.findall, but returns i-th element from each capture group *)
let regex_findall ~rex ?(i = 0) s =
  let unfolder last_r =
    try begin
      let (l, r) = Pcre.get_substring_ofs (Pcre.exec ~rex ~pos:last_r s) i in
      let outval = String.sub s l (r - l) in
      Some (outval, r)
    end with
      Not_found -> None
  in
  List.of_seq @@ Seq.unfold unfolder 0

(* splits on capital letters or a numeric sequence then hyphenates *)
let camel_to_kebab s =
  let rex = Pcre.regexp "((?:[A-Z]|[0-9]+)[a-z]*)" in
  String.concat "-" @@ List.map String.lowercase_ascii @@ regex_findall ~rex s
