:- use_module(library(tabling)).
:- op(950, xfx, $$).
:- table ($$)/2.

0$$1 :- !.
1$$1 :- !.
N$$F :-
  N > 1,
  N1 is N-1,
  N2 is N-2,
  N1$$F1,
  N2$$F2,
  F is F1+F2.
