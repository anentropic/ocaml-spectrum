type terminal_colours = {
  fg: (Gg.v4, string) result;
  bg: (Gg.v4, string) result;
}

(*
  xterm compatible terminals should support xlib queries
  which allow us to learn the current foreground and background
  colours used
  for more heuristics which may work on other terminals see:
  https://github.com/egberts/shell-term-background/blob/master/term-background.bash
*)
module Xterm = struct
  (*
    Translation of Python's `tty.setraw`
    https://github.com/python/cpython/blob/main/Lib/tty.py#L18
  *)
  let set_raw ?(set_when=Unix.TCSAFLUSH) fd =
    let mode : Unix.terminal_io = {
      (Unix.tcgetattr fd) with
      c_brkint = false;
      c_icrnl = false;
      c_inpck = false;
      c_istrip = false;
      c_ixon = false;
      c_opost = false;
      c_csize = 8;
      c_parenb = false;
      c_echo = false;
      c_icanon = false;
      (* c_iexten = false; ...does not exist on Unix.terminal_io  *)
      c_ixoff = false; (* IEXTEN and IXOFF appear to set the same bit *)
      c_isig = false;
      c_vmin = 1;
      c_vtime = 0;
    } in
    Unix.tcsetattr fd set_when mode

  (*
    Based on a Python version here:
    https://stackoverflow.com/a/45467190/202168
  *)
  let query fd code =
    let fdname =
      if fd == Unix.stdin then "stdin"
      else if fd == Unix.stdout then "stdout"
      else if fd == Unix.stderr then "stderr"
      else "fd"
    in
    if Unix.isatty fd then
      let old_settings = Unix.tcgetattr fd in
      set_raw fd;
      Fun.protect
        ~finally:(fun () -> Unix.tcsetattr fd Unix.TCSADRAIN old_settings)
        (fun () ->
           Printf.printf "\o033]%s;?\o007" code;
           flush stdout;
           let r, _, _ = Unix.select [fd] [] [] 0.1 in
           let buf = Bytes.create 256 in
           (* Printf.printf ">> len r: %d\n" (List.length r); *)
           let readlen = match List.exists (fun (el) -> el == fd) r with
             | true -> Unix.read fd buf 0 256
             | false -> failwith @@ Printf.sprintf "Nothing to read on [%s]" fdname
           in
           (* Printf.printf ">> len buf: %d\n" readlen; *)
           Bytes.sub buf 0 readlen
           |> Bytes.escaped
           |> Bytes.to_string
        )
    else
      invalid_arg @@ Printf.sprintf "[%s] is not a tty" fdname

  let query fd code =
    try Ok ( query fd code )
    with Failure e | Invalid_argument e -> Error e

  (*
    Translates a hexadecimal string, of any width, to an 8-bit int.
    The value will be 'scaled' according to number of hex chars,
    where each char is worth 4-bits.
    e.g.
      C -> C/F * FF = 204
      CCCC -> CCCC/FFFF * FF = 204
      C3 -> C3/FF * FF = 195
      C3B -> C3B/FFF * FF = 195
      C3C3 -> C3C3/FFFF * FF = 195
    see: https://stackoverflow.com/q/70962440/202168
  *)
  let hex_to_8bit s =
    let scale = (16. ** float_of_int (String.length s)) -. 1. in
    let value = int_of_string @@ Printf.sprintf "0x%s" s in
    float_of_int value /. scale *. 255.
    |> Utils.int_round

  (* xterm returns colours in a 48-bit hex format *)
  let parse_colour s =
    let rex = Pcre.regexp {|rgb:([0-9a-f]{1,4})/([0-9a-f]{1,4})/([0-9a-f]{1,4})|} in
    try
      match Pcre.get_opt_substrings (Pcre.exec ~rex s) with
      | [| _; Some r; Some g; Some b;|] ->
        Ok ( Color.of_rgb (hex_to_8bit r) (hex_to_8bit g) (hex_to_8bit b) )
      | _ -> Error ( failwith @@ Printf.sprintf "Could not extract RGB from: %s" s )
    with Not_found -> Error ( failwith @@ Printf.sprintf "Unrecognised colour string: %s" s )

  let get_colours fd =
    {
      fg = query fd "10" |> Result.map parse_colour |> Result.join;
      bg = query fd "11" |> Result.map parse_colour |> Result.join;
    }
end
