import sys
import os
from functools import reduce

with open(sys.argv[1]) as f:
  *prog, query = [l 
    for l in f.readlines()
    if len(l.strip()) > 0 and not l.startswith('--')]
desugar = lambda s: (s
  .replace(' <== ', '__MAGIC_IMPL__')
  .replace(', ', '__MAGIC_SEP__')
  .replace('=', 'tEQ')
  .replace('::', 'tCONS')
  .replace('++', 'tAPP')
  .replace('+', 'tADD')
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
:-op(150, yfx, :).
:-op(950, xfx, @@).
{unlines(prog)}
:- initialization forall(
  {fuel}@@({query}),
  ({', '.join(f"write('{x} = '), writeln({x})" for x in metas)})).
'''

with open('tmp.pl' if len(sys.argv) <= 2 else sys.argv[2], 'w') as tmp:
  print(prog, file=tmp)

os.system(f"prolog -l tmp.pl")
