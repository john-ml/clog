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
    def __init__(self, statements, queries):
        self.statements = statements
        self.queries = queries
    def __str__(self):
        return '\n\n'.join(map(str, self.statements + self.queries))

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
    def subst(self, mapping):
        return Statement(self.lhs.subst(mapping), [r.subst(mapping) for r in self.rhs])

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
    def subst(self, mapping):
        return Clause(self.name, [a.subst(mapping) for a in self.args])

class Cons(AST):
    def __init__(self, exprs):
        self.exprs = exprs
    def __str__(self):
        return '(' + ' '.join(map(str, self.exprs)) + ')'
    def vars(self):
        return foldmap(lambda a: a.vars(), self.exprs)
    def uvars(self):
        return foldmap(lambda a: a.uvars(), self.exprs)
    def subst(self, mapping):
        return Cons([e.subst(mapping) for e in self.exprs])
    def zonk(self, uf):
        return Cons(e.zonk(uf) for e in self.exprs)

class Num(AST):
    def __init__(self, n):
        self.n = n
    def __str__(self):
        return str(self.n)
    def vars(self):
        return set()
    def uvars(self):
        return set()
    def subst(self, mapping):
        return Num(self.n)
    def zonk(self, uf):
        return Num(self.n)

class Atom(AST):
    def __init__(self, name):
        self.name = name
    def __str__(self):
        return self.name
    def vars(self):
        return set()
    def uvars(self):
        return set()
    def subst(self, mapping):
        return Atom(self.name)
    def zonk(self, uf):
        return Atom(self.name)

class Ident(AST):
    def __init__(self, name):
        self.name = name
    def __str__(self):
        return self.name
    def vars(self):
        return {self.name}
    def uvars(self):
        return set()
    def subst(self, mapping):
        return mapping[self.name] if self.name in mapping else Ident(self.name)
    def zonk(self, uf):
        return Ident(self.name)

class UVar(AST):
    def __init__(self, name):
        self.name = name
    def __str__(self):
        return '?' + self.name
    def vars(self):
        return set()
    def uvars(self):
        return {self.name}
    def subst(self, f):
        return UVar(self.name)
    def zonk(self, uf):
        e = uf.expand(self.name)
        return e.zonk(uf) if type(e) is not UVar else e

class UError(Exception):
    pass

class UF:
    def __init__(self, queries):
        self.next_fresh = 0
        self.ids = dict(
            (i, i)
            for q in queries 
            for i in q.uvars()) # Map ids to their parents
        self.keys = dict() # Map ids to expressions
        self.old = []
    
    def push(self):
        self.old.append((
            dict(self.ids),
            dict(self.keys)))

    def pop(self):
        self.ids, self.keys = self.old.pop()

    def drop(self):
        self.old.pop()

    def fresh(self):
        i = str(self.next_fresh)
        self.next_fresh += 1
        self.ids[i] = i
        return i

    def find(self, i):
        while i != self.ids[i]:
            i = self.ids[i] = self.ids[self.ids[i]]
        return i

    def union(self, i, j):
        i = self.find(i)
        j = self.find(j)
        if i != j:
            self.ids[i] = j

    def expand(self, i):
        i = self.find(i)
        return self.keys[i] if i in self.keys else UVar(i)
