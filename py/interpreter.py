from clogast import *
from parser import *

def eapply(uf, statement):
    return statement.subst(
      dict((v, UVar(uf.fresh())) for v in statement.vars()))

def unify(uf, e1, e2):
    e1 = uf.expand(e1.name) if type(e1) is UVar else e1
    e2 = uf.expand(e2.name) if type(e2) is UVar else e2
    if type(e1) is type(e2) is UVar:
        uf.union(e1.name, e2.name)
    elif type(e1) is UVar:
        uf.keys[e1.name] = e2
    elif type(e2) is UVar:
        uf.keys[e2.name] = e1
    elif type(e1) is not type(e2):
        raise UError
    elif Cons is type(e1) is type(e2):
        if len(e1.exprs) != len(e2.exprs):
            raise UError
        else:
            for l, r in zip(e1.exprs, e2.exprs):
                unify(uf, l, r)
    elif Num is type(e1) is type(e2):
        if e1.n != e2.n:
            raise UError
    elif Atom is type(e1) is type(e2):
        if e1.name != e2.name:
            raise UError
    elif Ident is type(e1) is type(e2):
        if e1.name != e2.name:
            raise UError
    else:
        raise UError

class Interpreter:
    def __init__(self, program):
        assert type(program) is Program
        self.statements = program.statements
        self.queries = program.queries
        self.uvars = {i for q in self.queries for i in q.uvars()}
        self.universes = [(self.queries, UF(self.uvars))]

    def step(self):
        def step_universe(queries, uf):
            universes = [([], uf)]
            for q in queries:
                new_universes = []
                for queued_queries, uf in universes:
                    relevant = (
                        s
                        for s in self.statements
                        if s.lhs.name == q.name)
                    for s in relevant:
                        try:
                            new_uf = uf.clone()
                            s = eapply(new_uf, s)
                            unify(new_uf, Cons(s.lhs.args), Cons(q.args))
                            new_universes.append(
                                (queued_queries + s.rhs, new_uf))
                        except UError:
                            pass
                universes = new_universes
            return universes
        universes = [
            u
            for queries, uf in self.universes
            for u in step_universe(queries, uf)]
        if universes == []:
            raise ValueError('Unsolvable query: ')
        self.universes = universes
        return self

    def solutions(self):
        return [
            dict(
                (i, uf.expand(i).zonk(uf))
                for i in self.uvars)
            for _, uf in self.universes]

    def pretty(self):
        return '\n----------\n'.join(
            '\n'.join(
                '{} = {}'.format(i, e)
                for i, e in s.items())
            for s in self.solutions())

if __name__ == '__main__':
    def show(s):
        print(s)
        print('-'*20)

    show(
        Interpreter(parse("""
        Man Socrates.
        Mortal x <- Man x.
        Mortal ?x.
        """))
        .step().step()
        .pretty())

    show(
        Interpreter(parse("""
        App Nil xs xs.
        App (Cons x xs) ys (Cons x zs) <- App xs ys zs.
        App
          (Cons 1 (Cons 2 (Cons 3 (Cons 4 Nil))))
          (Cons 5 (Cons 6 (Cons 7 (Cons 8 Nil))))
          ?r.
        App (Cons 1 (Cons 2 Nil)) ?s (Cons 1 (Cons 2 (Cons 3 (Cons 4 Nil)))).
        App ?t Nil (Cons 1 Nil).
        """))
        .step().step().step().step().step()
        .pretty())

    show(
        Interpreter(parse("""
        App Nil xs xs.
        App (Cons x xs) ys (Cons x zs) <- App xs ys zs.
        App ?t (Cons 3 Nil) (Cons 1 (Cons 2 (Cons 3 Nil))).
        """))
        .step().step().step().step()
        .pretty())

    show(
        Interpreter(parse("""
        App Nil xs xs.
        App (Cons x xs) ys (Cons x zs) <- App xs ys zs.
        Last xs x <- App ys (Cons x Nil) xs.
        Last (Cons 1 (Cons 2 (Cons 3 Nil))) ?x.
        """))
        .step().step().step().step().step()
        .pretty())

    show(
        Interpreter(parse("""
        App Nil xs xs.
        App (Cons x xs) ys (Cons x zs) <- App xs ys zs.
        Last xs x <- App ys (Cons x Nil) xs.
        App ?xs (Cons 2 Nil) ?ys.
        Last ?xs 3.
        """))
        .step().step().step().step()
        .pretty())
