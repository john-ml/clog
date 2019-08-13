-- Equality

let X = X.

-- Lists

nil ++ XS = XS.
(X :: XS) ++ YS = (X :: ZS) where XS ++ YS = ZS.

length nil = z.
length (_ :: XS) = (s N) where length XS = N.

map _ nil = nil.
map F (X :: XS) = (Y :: YS) where F X = Y, map F XS = YS.

zipw _ nil _ = nil.
zipw _ _ nil = nil.
zipw F (X :: XS) (Y :: YS) = (Z :: ZS) where
  F X Y = Z,
  zipw F XS YS = ZS.

-- Naturals

z + M = M.
s N + M = (s P) where N + M = P.
add N M = P where N + M = P.

z * _ = z.
s N * M = K where
  N * M = P,
  M + P = K.
mul N M = P where N * M = P.

-- Pairs

fst (pair X _) = X.
snd (pair _ Y) = Y.

-- BinNats

normalized0 (hi :: nil).
normalized0 (lo :: N) <== normalized0 N.
normalized0 (hi :: (L :: N)) <== normalized0 (L :: N).
normalized nil.
normalized (L :: N) <== normalized0 (L :: N).

and lo _ = lo.
and _ lo = lo.
and hi P = P.
and P hi = P.

or hi _ = hi.
or _ hi = hi.
or lo P = P.
or P lo = P.

if hi then E else _ = E.
if lo then _ else E = E.

suc nil = (hi :: nil).
suc (lo :: N) = (hi :: N).
suc (hi :: N) = (lo :: M) where suc N = M.

adc lo lo lo => (lo lo).
adc lo lo hi => (hi lo).
adc lo hi lo => (hi lo).
adc lo hi hi => (lo hi).
adc hi lo lo => (hi lo).
adc hi lo hi => (lo hi).
adc hi hi lo => (lo hi).
adc hi hi hi => (hi hi).

adc nil N lo = N.
adc nil N hi = M where suc N = M.
adc N nil lo = N.
adc N nil hi = M where suc N = M.
adc (L :: M) (R :: N) C = (LR :: P) where
  adc L R C => (LR C1),
  adc M N C1 = P.

N + M = P where adc N M lo = P.

nil * _ = nil.
(lo :: M) * N = (lo :: P) where M * N = P.
(hi :: M) * N = P where M * N = K, N + (lo :: K) = P.

-- -- 11 * 23 = ? (253)
-- 10 M N P ?
--   let M = (hi :: (hi :: (lo :: (hi :: nil)))),
--   let N = (hi :: (hi :: (hi :: (lo :: (hi :: nil))))),
--   M * N = P

-- 11 * ? (23) = 253
9 M N P ?
  let M = (hi :: (hi :: (lo :: (hi :: nil)))),
  let P = (hi :: (lo :: (hi :: (hi :: (hi :: (hi :: (hi :: (hi :: nil)))))))),
  M * N = P

-- 10 M N P ?
--   let M = (lo :: (hi :: (lo :: (hi :: nil)))),
--   let P = (hi :: (lo :: (lo :: (lo :: (hi :: nil))))),
--   add M N = P,
--   normalized N

-- 3 X ZUV ? (x :: (y :: (z :: nil))) ++ (u :: (v :: nil)) = (X :: (y :: ZUV))
-- 10 X ? (s (s (s z))) * (s (s (s (s z)))) = X
-- 10 F ? map F (z :: ((s z) :: ((s (s z)) :: ((s (s (s z))) :: nil)))) = ((s (s z)) :: ((s (s (s z))) :: ((s (s (s (s z)))) :: ((s (s (s (s (s z))))) :: nil))))

-- 10 XS ? (zipw add (z :: ((s z) :: ((s (s z)) :: ((s (s (s z))) :: nil)))) ((s (s z)) :: ((s (s (s z))) :: ((s (s (s (s z)))) :: ((s (s (s (s (s z))))) :: nil))))) = XS

-- 10 N ? add (lo :: (hi :: (lo :: (hi :: nil)))) (hi :: (hi :: (hi :: nil))) = N
-- 10 M N ? add M N = (hi :: (lo :: (lo :: (lo :: (hi :: nil)))))
