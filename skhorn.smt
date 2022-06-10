; Typed SK

(set-logic HORN)

(declare-datatypes () ((Atom sym-s sym-k sym-b sym-c sym-arr)))
(declare-datatypes () (
  (Term
    (atom (un-atom Atom))
    (app (app-l Term) (app-r Term)))))
(define-const arr Term (atom sym-arr))
(define-const s Term (atom sym-s))
(define-const k Term (atom sym-k))
(define-const b Term (atom sym-b))
(define-const c Term (atom sym-c))

(declare-fun typ (Term Term) Bool)
(assert (forall ((R Term) (A Term) (B Term))
  (typ s (app (app (app (app R arr) (app (app A arr) B)) arr)
    (app (app (app (app R arr) A) arr) (app (app R arr) B))))))
(assert (forall ((A Term) (B Term))
  (typ k (app (app A arr) (app (app B arr) A)))))

(assert (forall ((f Term) (x Term) (A Term) (B Term))
  (=> (and (typ f (app (app A arr) B)) (typ x A)) (typ (app f x) B))))

(declare-const t Term)
(assert (typ (app (app s k) k) t))

(check-sat)
(get-model)
