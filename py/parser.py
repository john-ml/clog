from parsimonious.grammar import Grammar
from parsimonious.nodes import NodeVisitor
from clogast import *

grammar = Grammar(
    r"""
    program       = statement* ws
    statement     = clause (ws "<-" clause (ws "," clause)*)? ws "."
    clause        = ws proper_ident_ expression*

    expression    = number
                  / proper_ident 
                  / ident
                  / uvar
                  / cons

    number        = ws ~"-?[1-9][0-9]*|0"
    proper_ident  = ws proper_ident_
    ident         = ws ident_
    uvar          = ws "?" ident_
    cons          = ws "(" expression+ ws ")"

    ident_        = ~"[a-z][a-zA-Z0-9_]*"
    proper_ident_ = ~"[A-Z][a-zA-Z0-9_]*"
    ws            = ~"\s*"
    """
)

class ClogVisitor(NodeVisitor):
    def visit_program(self, _, __):
        statements, _ = __
        def is_statement(s):
            return s.uvars() == set()
        stmts = []
        queries = []
        for s in statements:
            if is_statement(s):
                stmts.append(s)
            elif s.rhs != []:
                raise ValueError('Bad query: {}'.format(s))
            else:
                queries.append(s.lhs)
        return Program(stmts, queries)

    def visit_statement(self, _, __):
        lhs, rhs, _, _ = __
        if type(rhs) is not list and rhs.text == "":
            return Statement(lhs, [])
        _, _, hd, tl = rhs[0]
        if type(tl) is not list and tl.text == "":
            return Statement(lhs, [hd])
        return Statement(lhs, [hd] + [c for _, _, c in tl])

    def visit_clause(self, _, __):
        _, name, args = __
        return Clause(name, args)

    def visit_expression(self, _, e):
        return e[0]

    def visit_number(self, _, __):
        _, n = __
        return Num(int(n.text))

    def visit_proper_ident(self, _, __):
        _, ident = __
        return Atom(ident)

    def visit_ident(self, _, __):
        _, ident = __
        return Ident(ident)

    def visit_uvar(self, _, __):
        _, _, ident = __
        return UVar(ident)

    def visit_cons(self, _, __):
        _, _, exprs, _, _ = __
        return Cons(exprs)

    def visit_proper_ident_(self, node, _):
        return node.text

    def visit_ident_(self, node, _):
        return node.text

    def generic_visit(self, node, visited_children):
        return visited_children or node

def parse(s):
    return ClogVisitor().visit(grammar.parse(s))

if __name__ == '__main__':
    print(str(ClogVisitor().visit(grammar.parse("""
    Man Socrates.
    Mortal x <- Man x.
    Mortal ?x.

    App Nil xs xs.
    App (Cons x xs) ys (Cons x zs) <- Cons xs ys zs.

    Last xs x <- App ys (Cons x Nil) xs.

    Last (Cons 1 (Cons 2 (Cons 3 Nil))) ?y.

    Foo x <- Bar x, Baz x.

    Fac 0 0.
    Fac n r <-
      Sub n 1 m,
      Fac m p,
      Mul n m r.
    """))))

