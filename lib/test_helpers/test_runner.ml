let run name ~junit_filename tests =
  let (testsuite, exit) = Junit_alcotest.run_and_report name tests in
  (match Sys.getenv_opt "JUNIT_OUTPUT" with
   | Some dir ->
     let report = Junit.make [testsuite] in
     Junit.to_file report (Filename.concat dir junit_filename)
   | None -> ());
  exit ()
