open Syntax

let _ =
  let open Prop in
  let p = List [Atom 0; Var 1; List [Atom 2; Var 4]; Var 3] in
  print_endline (show (Prop.inst p));
