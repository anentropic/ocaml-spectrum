type color_level =
  | Unsupported (* FORCE_COLOR=0 or FORCE_COLOR=false *)
  | Basic       (* FORCE_COLOR=1 or FORCE_COLOR=true *)
  | Eight_bit   (* FORCE_COLOR=2 *)
  | True_color  (* FORCE_COLOR=3 *)
[@@deriving show, eq]

type numeric_version = {
  major: int;
  minor: int;
  patch: int;
}

let parse_numeric_version s =
  let rex = Str.regexp "\\([0-9]+\\)\\.\\([0-9]+\\)\\.\\([0-9]+\\)" in
  let _ = Str.search_forward rex s 0 in
  {
    major = Str.matched_group 1 s |> int_of_string;
    minor = Str.matched_group 2 s |> int_of_string;
    patch = Str.matched_group 3 s |> int_of_string;
  }

module type EnvProvider = sig
  val getenv_opt : string -> string option
  val getenv : string -> string
end

module type OsInfoProvider = sig
  val is_windows : unit -> bool
  val os_version : unit -> string option
end

module type CapabilitiesProvider = sig
  val supported_color_level : bool -> color_level
end

module Make (Env: EnvProvider) (OsInfo: OsInfoProvider) : CapabilitiesProvider = struct
  (*  *)
  let env_force_level () =
    match Env.getenv_opt "FORCE_COLOR" with
    | Some "true" -> Some Basic
    | Some "false" -> Some Unsupported
    | Some s -> begin
        match String.length s with
        | 0 -> None
        | 1 -> begin
            match int_of_string_opt s with
            | Some 0 -> Some Unsupported
            | Some 1 -> Some Basic
            | Some 2 -> Some Eight_bit
            | Some 3 -> Some True_color
            | Some _ -> None
            | None -> None
          end
        | _ -> None
      end
    | None -> None

  let in_env name =
    match Env.getenv_opt name with
    | Some _ -> true
    | None -> false

  let has_env_matching_test name value_test =
    match Env.getenv_opt name with
    | Some s -> value_test s
    | None -> false

  let has_env_matching name value = has_env_matching_test name (String.equal value)

  let windows_level () =
    (* Windows 10 build 10586 is the first Windows release that supports 256 colors.
       Windows 10 build 14931 is the first release that supports 16m/TrueColor.
       Example value of [OpamSysPoll.os_version]: Some “10.0.19041” *)
    let get_level () =
      match OsInfo.os_version () with
      | Some s -> begin
          match parse_numeric_version s with
          | v when v.major == 10 && v.minor == 0 && v.patch >= 14931 -> True_color
          | v when v.major == 10 && v.minor == 0 && v.patch >= 10586 -> Eight_bit
          | v when v.major == 10 && v.minor > 0 -> True_color
          | v when v.major > 10 -> True_color
          | _ -> Basic
        end
      | None -> Basic (* is Windows, but version not returned *)
    in
    try get_level ()
    with Not_found | Failure _ -> Basic (* failed parsing version *)

  let teamcity_level () =
    let get_level () =
      let rex = Str.regexp "^\\(9\\.\\(0*[1-9][0-9]*\\)\\|[0-9][0-9]+\\)\\." in
      (* assume we've already tested for TEAMCITY_VERSION in env *)
      let version = Env.getenv "TEAMCITY_VERSION" in
      match Str.string_match rex version 0 with
      | true -> Basic
      | false -> Unsupported
    in
    try get_level ()
    with Not_found -> Unsupported (* failed parsing version *)

  let is_recognised_term_program () =
    match Env.getenv_opt "TERM_PROGRAM" with
    | Some "iTerm.app" -> true
    | Some "Apple_Terminal" -> true
    | _ -> false

  let iterm_level () =
    (* assume we've already tested for TERM_PROGRAM in env
       and therefore TERM_PROGRAM_VERSION is expected *)
    let get_level () =
      match parse_numeric_version (Env.getenv "TERM_PROGRAM_VERSION") with
      | v when v.major >= 3 -> True_color
      | _ -> Eight_bit
    in
    try get_level ()
    with Not_found | Failure _ -> Eight_bit (* failed parsing version *)

  let term_program_level () =
    match Env.getenv "TERM_PROGRAM" with
    | "iTerm.app" -> iterm_level ()
    | "Apple_Terminal" -> Eight_bit
    | _ -> Unsupported

  let term_is_256_color term =
    let rex = Str.regexp_case_fold "-256\\(color\\)?$" in
    try
      let _ = Str.search_forward rex term 0 in
      true
    with Not_found -> false

  let term_is_16_color term =
    let rex = Str.regexp_case_fold "^screen\\|^xterm\\|^vt100\\|^vt220\\|^rxvt\\|color\\|ansi\\|cygwin\\|linux" in
    try
      let _ = Str.search_forward rex term 0 in
      true
    with Not_found -> false

  (* This logic is adapted from the nodejs Chalk library
     see https://github.com/chalk/supports-color/blob/main/index.js *)
  let supported_color_level (is_tty : bool) =
    let force_level = env_force_level () in
    let min_level = match force_level with
      | Some cl -> cl
      | None -> Unsupported
    in
    if not is_tty && force_level == None then
      Unsupported
    else if has_env_matching "TERM" "dumb" then
      min_level
    else if OsInfo.is_windows () then
      windows_level ()
    else if in_env "CI" then
      if List.exists in_env [
          "TRAVIS";
          "CIRCLECI";
          "APPVEYOR";
          "GITLAB_CI";
          "GITHUB_ACTIONS";
          "BUILDKITE";
          "DRONE";
        ] || has_env_matching "CI_NAME" "codeship"
      then
        Basic
      else
        min_level
    else if in_env "TEAMCITY_VERSION" then
      teamcity_level ()
    else if in_env "TF_BUILD" && in_env "AGENT_NAME" then
      Basic
    else if has_env_matching "COLORTERM" "truecolor" then
      True_color
    else if is_recognised_term_program () then
      term_program_level ()
    else if has_env_matching_test "TERM" term_is_256_color then
      Eight_bit
    else if has_env_matching_test "TERM" term_is_16_color then
      Basic
    else if in_env "COLORTERM" then
      Basic
    else
      min_level
end

module StrMap = Map.Make(String)

(* util for using StrMap as a fake env (e.g. in tests) *)
let env_provider_of_map map =
  let module M = struct
    let getenv name = StrMap.find name map
    let getenv_opt name = StrMap.find_opt name map
  end
  in (module M : EnvProvider)

(* util for faking the OS checks (e.g. in tests) *)
let os_info_provider is_windows os_version =
  let module M = struct
    let is_windows () = is_windows
    let os_version () = os_version
  end
  in (module M : OsInfoProvider)

(* the legit OS info *)
module SysOsInfo = struct
  let is_windows () = Sys.win32
  let os_version () = OpamSysPoll.os_version ()
end

module Sys_Capabilities = Make(Sys)(SysOsInfo)

include Sys_Capabilities

type color_level_info = {
  stdout : color_level;
  stderr : color_level;
}

let supported_color_levels () = {
  stdout = supported_color_level (Unix.isatty Unix.stdout);
  stderr = supported_color_level (Unix.isatty Unix.stderr);
}
