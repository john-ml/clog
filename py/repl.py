from interpreter import *

if __name__ == '__main__':
    statements = []
    queries = []

    while True:
        s = input('> ')
        if s == '!':
            break
        if s == '?':
            i = Interpreter(Program(statements, queries))
            while True:
                try:
                    i.step()
                    print(i.pretty(), end='')
                except UnsolvableError as e:
                    print(str(e))
                s = input()
                if s == '!':
                    statements = []
                    queries = []
                    break
        else:
            try:
                if s.startswith('#use '):
                    with open(s[len('#use '):], 'r') as f:
                        s = f.read()
                p = parse(s)
                statements.extend(p.statements)
                queries.extend(p.queries)
            except Exception as e:
                print(str(e))
