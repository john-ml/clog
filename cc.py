import sys
import os
import subprocess
from functools import reduce

def collapse(gen):
  tmp = ''
  for l in gen:
    if l.startswith('--') or l.strip() == '':
      continue
    if l == l.lstrip():
      if tmp != '':
        yield tmp
      tmp = ''
    tmp = (tmp + ' ' + l.strip()).strip()
  if tmp != '':
    yield tmp

with open(sys.argv[1]) as f:
  *prog, query = list(collapse(f.readlines()))
desugar = lambda s: (s
  .replace(' where ', '__MAGIC_IMPL__')
  .replace(' <== ', '__MAGIC_IMPL__')
  .replace(', ', '__MAGIC_SEP__')
  .replace('=', 'tEQ')
  .replace('>', 'tLT')
  .replace('<', 'tGT')
  .replace('$', 'tDOLLAR')
  .replace('+', 'tADD')
  .replace('-', 'tSUB')
  .replace('*', 'tMUL')
  .replace(':', 'tCOLON')
  .replace(' ', ':')
  .replace('__MAGIC_IMPL__', ':-FUEL__@@')
  .replace('__MAGIC_SEP__', ',FUEL__@@'))
unlines = lambda s: '\n'.join(s)
prog = [('s(FUEL__)@@' if 'FUEL__' in p else '_@@') + p
  for l in prog
  for p in [desugar(l)]]

resugar = lambda s: (s
  .replace(':', ' ')
  .replace('tCOLON', ':')
  .replace('tMUL', '*')
  .replace('tSUB', '-')
  .replace('tADD', '+')
  .replace('tDOLLAR', '$')
  .replace('tLT', '<')
  .replace('tGT', '>')
  .replace('tEQ', '='))

i = query.index('?')
(fuel, *metas), query = query[:i].split(), desugar(query[i+1:].strip())

peano = lambda n: reduce(lambda x, _: f's({x})', range(n), 'z')
dump_metas_cmd = '(' + ', '.join(f"write('{x} = '), writeln({x})" for x in metas) + ')'
# commands = ',\n '.join(f'''
#   writeln('depth {n}'),
#   {peano(n)}@@{query},
#   {dump_metas_cmd}
# ''' for n in range(int(fuel)+1))
prog = f'''
:- op(150, yfx, :).
:- op(950, xfx, @@).
:- set_prolog_flag(occurs_check, true).
% :- use_module(library(tabling)).
% :- table (@@)/2.
tEQUAL(X, X).
run_query(z, D, Query) :- write('depth '), writeln(D), D@@Query.
run_query(s(Remaining), D, Query) :-
  write('depth '), writeln(D), D@@Query;
  run_query(Remaining, s(D), Query).
{unlines(prog)}
:- initialization forall(run_query({peano(int(fuel))}, z, {query}), {dump_metas_cmd}).'''

with open('tmp.pl' if len(sys.argv) <= 2 else sys.argv[2], 'w') as tmp:
  print(prog, file=tmp)

p = subprocess.Popen(['prolog', '-l', 'tmp.pl', '-t', 'halt'], stderr=open(os.devnull, 'w'))
try:
  while True: pass
except KeyboardInterrupt:
  p.terminate()

