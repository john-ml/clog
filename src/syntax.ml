type var = int
type atom = int

module Prop = struct

type t
  = Var of var
  | Atom of atom
  | List of t list
  | Meta of t ref

let string_of_ref p = Printf.sprintf "%x" (2 * Obj.magic p)

let rec show : t -> string = function
  | Var x -> "x" ^ string_of_int x
  | Atom x -> string_of_int x
  | List ps -> "(" ^ String.concat " " (List.map show ps) ^ ")"
  | Meta p -> "?" ^ string_of_ref p

exception UError of t * t

let reset_meta : t -> unit = function
  | Meta q as p -> q := p
  | _ -> ()

let rec reset_metas : t -> unit = function
  | Var _ | Atom _ -> ()
  | List ps -> List.iter reset_metas ps
  | Meta _ as p -> reset_meta p

let inst : t -> t =
  let vars = Hashtbl.create 10 in
  let rec go = function
    | Var x ->
        (match Hashtbl.find_opt vars x with
         | None ->
             let rec p = Meta (ref p) in
             Hashtbl.replace vars x p;
             p
         | Some p -> p)
    | Atom _ | Meta _ as p -> p
    | List ps -> List (List.map go ps)
  in
  go

let rec unify (p1 : t) (p2 : t) : unit =
  let open List in
  match p1, p2 with
  | Meta q1, _ when !q1 == p1 -> q1 := p2
  | _, Meta q2 when !q2 == p2 -> q2 := p1
  | Meta {contents = p}, q | p, Meta {contents = q} -> unify p q
  | Var x, Var y | Atom x, Atom y when x = y -> ()
  | List ps, List qs when length ps = length qs -> iter2 unify ps qs
  | _, _ -> raise (UError (p1, p2))

end

module Goal = struct

type t = Goal of Prop.t list

end

module Rule = struct

type t = Rule of Prop.t list * Prop.t

let reset_metas : t -> unit = function
  Rule (hyps, post) ->
    List.iter Prop.reset_metas hyps;
    Prop.reset_metas post

let inst (Rule (hyps, post)) = Rule (List.map Prop.inst hyps, Prop.inst post)

end

module Prgm = struct

type t = Prgm of Rule.t list * Goal.t

end
