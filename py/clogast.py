from functools import reduce

foldmap = lambda f, a: reduce(lambda a, b: a | b, map(f, a), set())

class AST:
    def __str__(self):
        pass
    def vars(self):
        pass
    def uvars(self):
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
    def vars(self):
        return self.lhs.vars() | foldmap(lambda a: a.vars(), self.rhs)
    def uvars(self):
        return self.lhs.uvars() | foldmap(lambda a: a.uvars(), self.rhs)

class Clause(AST):
    def __init__(self, name, args):
        self.name = name
        self.args = args
    def __str__(self):
        return ' '.join([self.name] + list(map(str, self.args)))
    def vars(self):
        return foldmap(lambda a: a.vars(), self.args)
    def uvars(self):
        return foldmap(lambda a: a.uvars(), self.args)

class Cons(AST):
    def __init__(self, exprs):
        self.exprs = exprs
    def __str__(self):
        return '(' + ' '.join(map(str, self.exprs)) + ')'
    def vars(self):
        return foldmap(lambda a: a.vars(), self.exprs)
    def uvars(self):
        return foldmap(lambda a: a.uvars(), self.exprs)

class Num(AST):
    def __init__(self, n):
        self.n = n
    def __str__(self):
        return str(self.n)
    def vars(self):
        return set()
    def uvars(self):
        return set()

class Atom(AST):
    def __init__(self, name):
        self.name = name
    def __str__(self):
        return self.name
    def vars(self):
        return set()
    def uvars(self):
        return set()

class Ident(AST):
    def __init__(self, name):
        self.name = name
    def __str__(self):
        return self.name
    def vars(self):
        return {self.name}
    def uvars(self):
        return set()

class UVar(AST):
    def __init__(self, name):
        self.name = name
    def __str__(self):
        return '?' + self.name
    def vars(self):
        return set()
    def uvars(self):
        return {self.name}
