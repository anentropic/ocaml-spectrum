open Spectrum.Capabilities

module NonWindowsOsInfo = (
  val (os_info_provider false (Some "")) : OsInfoProvider
)

let testable_color_level = Alcotest.testable pp_color_level equal_color_level

let map_of pairs = List.to_seq pairs |> StrMap.of_seq

let check_supported_color_level (module OsInfo : OsInfoProvider) is_tty env_pairs expected () =
  let module Env = (val (env_provider_of_map @@ map_of env_pairs) : EnvProvider) in
  let module C = Make(Env)(OsInfo) in
  let result = C.supported_color_level is_tty in
  let msg = Printf.sprintf "returns: %s" (show_color_level expected) in
  Alcotest.(check testable_color_level) msg expected result


let basic_force_color_tests =
  let open Alcotest in
  let base_check = check_supported_color_level (module NonWindowsOsInfo : OsInfoProvider) in
  let check = base_check false in
  [
    Printf.sprintf "FORCE_COLOR stream_is_tty=false", [
      test_case "FORCE_COLOR=0" `Quick (check [("FORCE_COLOR", "0")] Unsupported);
      test_case "FORCE_COLOR=1" `Quick (check [("FORCE_COLOR", "1")] Basic);
      test_case "FORCE_COLOR=2" `Quick (check [("FORCE_COLOR", "2")] Eight_bit);
      test_case "FORCE_COLOR=3" `Quick (check [("FORCE_COLOR", "3")] True_color);
      test_case "FORCE_COLOR=true" `Quick (check [("FORCE_COLOR", "true")] Basic);
      test_case "FORCE_COLOR=false" `Quick (check [("FORCE_COLOR", "false")] Unsupported);
      test_case "unrecognised: FORCE_COLOR=4" `Quick (check [("FORCE_COLOR", "4")] Unsupported);
      test_case "unrecognised: FORCE_COLOR=wtf" `Quick (check [("FORCE_COLOR", "wtf")] Unsupported);
    ];
  ]

let stream_no_tty_short_circuit_tests =
  let open Alcotest in
  let base_check = check_supported_color_level (module NonWindowsOsInfo : OsInfoProvider) in
  let check = base_check false in
  [
    Printf.sprintf "Short-circuit when is_tty=false", [
      test_case
        "FORCE_COLOR prevents the short-circuit, overridden by COLORTERM"
        `Quick (check [("FORCE_COLOR", "2"); ("COLORTERM", "truecolor")] True_color);
      test_case
        "COLORTERM=truecolor is short-circuited"
        `Quick (check [("COLORTERM", "truecolor")] Unsupported);
    ];
    Printf.sprintf "No short-circuit when is_tty=true", [
      test_case
        "is_tty=true"
        `Quick (base_check true [("COLORTERM", "truecolor")] True_color);
    ];
  ]

let dumb_term_tests =
  let open Alcotest in
  let check = check_supported_color_level (module NonWindowsOsInfo : OsInfoProvider) true in
  [
    Printf.sprintf "Min-level when TERM=dumb", [
      (* FORCE_COLOR sets min-level, COLORTERM overridden *)
      test_case
        "FORCE_COLOR sets min-level"
        `Quick (check [("FORCE_COLOR", "2"); ("COLORTERM", "truecolor"); ("TERM", "dumb")] Eight_bit);
      test_case
        "no FORCE_COLOR"
        `Quick (check [("COLORTERM", "truecolor"); ("TERM", "dumb")] Unsupported);
    ];
  ]

let windows_tests =
  let open Alcotest in
  let check is_windows os_version =
    check_supported_color_level
      (module
        (val
          (os_info_provider is_windows os_version) : OsInfoProvider) : OsInfoProvider)
      true
  in
  (* FORCE_COLOR sets min-level and is overridden *)
  [
    Printf.sprintf "Windows OS detection", [
      test_case "Not windows" `Quick (check false (Some "") [("FORCE_COLOR", "0")] Unsupported);
      test_case "too old: Windows 9" `Quick (check true (Some "9.0.0") [("FORCE_COLOR", "0")] Basic);
      test_case "too old: Windows 10.0 < 10586" `Quick (check true (Some "10.0.10585") [("FORCE_COLOR", "0")] Basic);
      test_case "256-color supported: Windows 10.0 10586 < x < 14931" `Quick (check true (Some "10.0.14930") [("FORCE_COLOR", "0")] Eight_bit);
      test_case "true-color supported: Windows 10.0 >= 14931" `Quick (check true (Some "10.0.14931") [("FORCE_COLOR", "0")] True_color);
      test_case "true-color supported: Windows 10.1" `Quick (check true (Some "10.1.0") [("FORCE_COLOR", "0")] True_color);
      test_case "true-color supported: Windows 11" `Quick (check true (Some "11.0.0") [("FORCE_COLOR", "0")] True_color);
      test_case "no os-version: Windows ???" `Quick (check true None [("FORCE_COLOR", "0")] Basic);
    ];
    Printf.sprintf "Windows OS detection: Error handling", [
      test_case "bad version: Windows 123" `Quick (check true (Some "123") [("FORCE_COLOR", "0")] Basic);
      test_case "bad version: Windows 10.0" `Quick (check true (Some "123") [("FORCE_COLOR", "0")] Basic);
      test_case "bad version: Windows 10.0.123a" `Quick (check true (Some "123") [("FORCE_COLOR", "0")] Basic);
    ];
  ]

let ci_tests =
  let open Alcotest in
  let check = check_supported_color_level (module NonWindowsOsInfo : OsInfoProvider) true in
  [
    Printf.sprintf "Min-level when CI unrecognised", [
      (* FORCE_COLOR sets min-level, COLORTERM is overridden *)
      test_case
        "CI + no provider env var"
        `Quick (check [("FORCE_COLOR", "2"); ("COLORTERM", "truecolor"); ("CI", "")] Eight_bit);
      test_case
        "Unrecognised CI_NAME"
        `Quick (check [("FORCE_COLOR", "2"); ("COLORTERM", "truecolor"); ("CI", ""); ("CI_NAME", "wtf")] Eight_bit);
    ];
    (* FORCE_COLOR sets min-level and is overridden *)
    Printf.sprintf "Basic when CI recognised", [
      test_case
        "CI + recognised provider"
        `Quick (check [("FORCE_COLOR", "2"); ("CI", ""); ("TRAVIS", "")] Basic);
      test_case
        "CI_NAME=codeship"
        `Quick (check [("FORCE_COLOR", "2"); ("CI", ""); ("CI_NAME", "codeship")] Basic);
    ];
  ]

let teamcity_tests =
  let open Alcotest in
  let check = check_supported_color_level (module NonWindowsOsInfo : OsInfoProvider) true in
  [
    Printf.sprintf "Teamcity", [
      (* FORCE_COLOR min-level is overridden *)
      test_case
        "too old: 8.1.0"
        `Quick (check [("FORCE_COLOR", "2"); ("TEAMCITY_VERSION", "8.1.0")] Unsupported);
      test_case
        "too old: 9.0.0"
        `Quick (check [("FORCE_COLOR", "2"); ("TEAMCITY_VERSION", "9.0.0")] Unsupported);
      test_case
        "16-color supported: >= 9.1.0"
        `Quick (check [("FORCE_COLOR", "2"); ("TEAMCITY_VERSION", "9.1.0")] Basic);
      test_case
        "16-color supported: 10.0.0"
        `Quick (check [("FORCE_COLOR", "2"); ("TEAMCITY_VERSION", "10.0.0")] Basic);
      test_case
        "16-color supported: 9.1.abc (non-numeric patch)"
        `Quick (check [("FORCE_COLOR", "2"); ("TEAMCITY_VERSION", "9.1.abc")] Basic);
      test_case
        "bad version: 123"
        `Quick (check [("FORCE_COLOR", "2"); ("TEAMCITY_VERSION", "123")] Unsupported);
    ];
  ]

let terraform_tests =
  let open Alcotest in
  let check = check_supported_color_level (module NonWindowsOsInfo : OsInfoProvider) true in
  [
    Printf.sprintf "Terraform", [
      (* COLORTERM is overridden *)
      test_case
        "recognised: 16-color supported"
        `Quick (check [("COLORTERM", "truecolor"); ("TF_BUILD", ""); ("AGENT_NAME", "wtf")] Basic);
      test_case
        "unrecognised: missing AGENT_NAME"
        `Quick (check [("COLORTERM", "truecolor"); ("TF_BUILD", "")] True_color);
      test_case
        "unrecognised: missing TF_BUILD"
        `Quick (check [("COLORTERM", "truecolor"); ("AGENT_NAME", "wtf")] True_color);
      test_case
        "unrecognised: return default"
        `Quick (check [("AGENT_NAME", "wtf")] Unsupported);
    ];
  ]

let colorterm_tests =
  let open Alcotest in
  let check = check_supported_color_level (module NonWindowsOsInfo : OsInfoProvider) true in
  [
    Printf.sprintf "COLORTERM", [
      test_case
        "truecolor"
        `Quick (check [("COLORTERM", "truecolor")] True_color);
      test_case
        "anything else"
        `Quick (check [("COLORTERM", "256-color")] Basic);
      test_case
        "default"
        `Quick (check [] Unsupported);
    ];
  ]

let term_program_tests =
  let open Alcotest in
  let check = check_supported_color_level (module NonWindowsOsInfo : OsInfoProvider) true in
  [
    Printf.sprintf "TERM_PROGRAM: iTerm (supports 256 or true color)", [
      test_case
        "no version"
        `Quick (check [("TERM_PROGRAM", "iTerm.app")] Eight_bit);
      test_case
        "bad version"
        `Quick (check [("TERM_PROGRAM", "iTerm.app"); ("TERM_PROGRAM_VERSION", "123")] Eight_bit);
      test_case
        "version < 3.0.0"
        `Quick (check [("TERM_PROGRAM", "iTerm.app"); ("TERM_PROGRAM_VERSION", "2.9.9")] Eight_bit);
      test_case
        "version >= 3.0.0 (3.0.0)"
        `Quick (check [("TERM_PROGRAM", "iTerm.app"); ("TERM_PROGRAM_VERSION", "3.0.0")] True_color);
      test_case
        "version >= 3.0.0 (10.1.123)"
        `Quick (check [("TERM_PROGRAM", "iTerm.app"); ("TERM_PROGRAM_VERSION", "10.1.123")] True_color);
    ];
    Printf.sprintf "TERM_PROGRAM: Apple terminal (supports 256 color)", [
      test_case
        "no version"
        `Quick (check [("TERM_PROGRAM", "Apple_Terminal")] Eight_bit);
      test_case
        "any version"
        `Quick (check [("TERM_PROGRAM", "Apple_Terminal"); ("TERM_PROGRAM_VERSION", "123")] Eight_bit);
    ];
    Printf.sprintf "TERM_PROGRAM: unrecognised", [
      test_case
        "default"
        `Quick (check [("TERM_PROGRAM", "wtf")] Unsupported);
      test_case
        "FORCE_COLOR sets min-level"
        `Quick (check [("TERM_PROGRAM", "wtf"); ("FORCE_COLOR", "2")] Eight_bit);
    ];
  ]

let term_tests =
  let open Alcotest in
  let check = check_supported_color_level (module NonWindowsOsInfo : OsInfoProvider) true in
  [
    (* anything ending with "-256color" or "-256"
       NOTE: this was the Chalk logic, should it also have the recognised prefix though? *)
    Printf.sprintf "TERM: recognised 256-color patterns", [
      test_case
        "xterm-256color"
        `Quick (check [("TERM", "xterm-256color")] Eight_bit);
      test_case
        "wtf-256"
        `Quick (check [("TERM", "wtf-256")] Eight_bit);
    ];
    (* anything not matched for 256-color and beginning with recognised prefix *)
    Printf.sprintf "TERM: recognised 16-color patterns", [
      test_case
        "xterm"
        `Quick (check [("TERM", "xterm")] Basic);
      test_case
        "xterm-wtf"
        `Quick (check [("TERM", "xterm-wtf")] Basic);
    ];
    Printf.sprintf "TERM: unrecognised", [
      test_case
        "wtf-xterm"
        `Quick (check [("TERM", "wtf-xterm")] Unsupported);
      test_case
        "wtf-256-ftw"
        `Quick (check [("TERM", "wtf-256-ftw")] Unsupported);
    ];
  ]

let () =
  let tests = List.concat [
      basic_force_color_tests;
      stream_no_tty_short_circuit_tests;
      dumb_term_tests;
      windows_tests;
      ci_tests;
      teamcity_tests;
      terraform_tests;
      colorterm_tests;
      term_program_tests;
      term_tests;
    ] in
  let (testsuite, exit) = Junit_alcotest.run_and_report "Capabilities" (tests) in
  let report = Junit.make [testsuite;] in
  Junit.to_file report "junit-capabilities.xml";
  exit ()
