from clogast import *
from parser import *

class Interpreter:
    def __init__(self, program):
        assert type(program) is Program
        self.statements = program.statements
        self.queries = program.queries
        self.uf = UF(self.queries)
        self.uvars = {i for q in self.queries for i in q.uvars()}

    def eapply(self, statement):
        return statement.subst(
          dict((v, UVar(self.uf.fresh())) for v in statement.vars()))

    def unify(self, e1, e2):
        e1 = self.uf.expand(e1.name) if type(e1) is UVar else e1
        e2 = self.uf.expand(e2.name) if type(e2) is UVar else e2
        if type(e1) is type(e2) is UVar:
            self.uf.union(e1.name, e2.name)
        elif type(e1) is UVar:
            self.uf.keys[e1.name] = e2
        elif type(e2) is UVar:
            self.uf.keys[e2.name] = e1
        elif type(e1) is not type(e2):
            raise UError
        elif Cons is type(e1) is type(e2):
            if len(e1.exprs) != len(e2.exprs):
                raise UError
            else:
                for l, r in zip(e1.exprs, e2.exprs):
                    self.unify(l, r)
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

    def step_query(self, query):
        relevant = [self.eapply(s)
            for s in self.statements
            if s.lhs.name == query.name]
        queries = []
        query_ok = False
        for s in relevant:
            try:
                #print(f'unify({Cons(s.lhs.args)}, {Cons(query.args)})')
                self.uf.push()
                self.unify(Cons(s.lhs.args), Cons(query.args))
                self.uf.drop()
                queries.extend(s.rhs)
                query_ok = True
            except UError:
                self.uf.pop()
        if not query_ok:
            raise ValueError(f'Unsolvable query: {query.zonk(self.uf)}')
        return queries

    def step(self):
        self.queries = [
            q
            for query in self.queries
            for q in self.step_query(query)]
        return self

    def solution(self):
        return dict(
            (i, self.uf.expand(i).zonk(self.uf))
            for i in self.uvars)

    def pretty(self):
        return '\n'.join(
            '{} = {}'.format(i, e)
            for i, e in self.solution().items())

if __name__ == '__main__':
    print(
        Interpreter(parse("""
        Man Socrates.
        Mortal x <- Man x.
        Mortal ?x.
        """))
        .step().step()
        .pretty())

    print(
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

    print(
        Interpreter(parse("""
        App Nil xs xs.
        App (Cons x xs) ys (Cons x zs) <- App xs ys zs.
        App ?t (Cons 3 Nil) (Cons 1 (Cons 2 (Cons 3 Nil))).
        """))
        .step().step().step()
        .pretty())

    print(
        Interpreter(parse("""
        App Nil xs xs.
        App (Cons x xs) ys (Cons x zs) <- App xs ys zs.
        Last xs x <- App ys (Cons x Nil) xs.
        Last (Cons 1 (Cons 2 (Cons 3 Nil))) ?x.
        """))
        .step().step().step().step()
        .pretty())
