from parsimonious.grammar import Grammar
from parsimonious.nodes import NodeVisitor

grammar = Grammar(
    r"""
    program      = statement* ws
    clause       = proper_ident expression*
    statement    = clause (ws "<-" clause (ws "," clause)*)? ws "."

    expression   = number
                 / proper_ident 
                 / ident
                 / uvar
                 / (ws "(" expression+ ws ")")

    number       = ws ~"-?[1-9][0-9]*|0"
    proper_ident = ws ~"[A-Z][a-zA-Z0-9_]*"
    ident        = ws ident_
    uvar         = ws "?" ident

    ident_       = ~"[a-z][a-zA-Z0-9_]*"
    ws           = ~"\s*"
    """
)

print(grammar.parse("""
Man Socrates.
Mortal x <- Man x.
Mortal ?x.

App Nil xs xs.
App (Cons x xs) ys (Cons x zs) <- Cons xs ys zs.
"""))


