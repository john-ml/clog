class AST:
    def __str__(self):
        pass

class Program(AST):
    def __init__(self, stmts, queries):
        self.stmts = stmts
        self.queries = queries
    def __str__(self):
        return '\n\n'.join(map(str, self.stmts + self.queries))

class Statement(AST):
    def __init__(self, lhs, rhs):
        self.lhs = lhs
        self.rhs = rhs
    def __str__(self):
        if self.rhs == []:
            return '{}.'.format(self.lhs)
        return '{} <- {}.'.format(self.lhs, ', '.join(map(str, self.rhs)))

class Clause(AST):
    def __init__(self, name, args):
        self.name = name
        self.args = args
    def __str__(self):
        return ' '.join([self.name] + list(map(str, self.args)))

class Cons(AST):
    def __init__(self, exprs):
        self.exprs = exprs
    def __str__(self):
        return '(' + ' '.join(map(str, self.exprs)) + ')'

class Num(AST):
    def __init__(self, n):
        self.n = n
    def __str__(self):
        return str(self.n)

class Atom(AST):
    def __init__(self, name):
        self.name = name
    def __str__(self):
        return self.name

class Ident(AST):
    def __init__(self, name):
        self.name = name
    def __str__(self):
        return self.name

class UVar(AST):
    def __init__(self, name):
        self.name = name
    def __str__(self):
        return '?' + self.name
