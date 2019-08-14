import sys
import os
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
  .replace('=>', 'tRARR')
  .replace('->', 'tRAR')
  .replace('=', 'tEQ')
  .replace('>', 'tGTR')
  .replace('<', 'tLSS')
  .replace('::', 'tCONS')
  .replace('++', 'tAPP')
  .replace('$', 'tDOLLAR')
  .replace('+', 'tADD')
  .replace('-', 'tSUB')
  .replace('*', 'tMUL')
  .replace('**', 'tEXP')
  .replace(':', 'tCOLON')
  .replace(' ', ':')
  .replace('__MAGIC_IMPL__', ':-FUEL__@@')
  .replace('__MAGIC_SEP__', ',FUEL__@@'))
unlines = lambda s: '\n'.join(s)
prog = [('s(FUEL__)@@' if 'FUEL__' in p else '_@@') + p
  for l in prog
  for p in [desugar(l)]]

i = query.index('?')
(fuel, *metas), query = query[:i].split(), desugar(query[i+1:].strip())

fuel = reduce(lambda x, _: f's({x})', range(int(fuel)), 'z')
prog = f'''
:- op(150, yfx, :).
:- op(950, xfx, @@).
:- set_prolog_flag(occurs_check, true).
% :- use_module(library(tabling)).
% :- table (@@)/2.
tEQUAL(X, X).
{unlines(prog)}
:- initialization forall(
  (tEQUAL(FUEL__, {fuel}), FUEL__@@{query}),
  ({', '.join(f"write('{x} = '), writeln({x})" for x in metas)})).
'''

with open('tmp.pl' if len(sys.argv) <= 2 else sys.argv[2], 'w') as tmp:
  print(prog, file=tmp)

os.system(f"prolog -l tmp.pl")
