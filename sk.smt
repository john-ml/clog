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

(declare-rel typ (Int Term Term))
(declare-var N Int)
(declare-var R Term)
(declare-var A Term)
(declare-var B Term)
(declare-var F Term)
(declare-var X Term)

(rule (=> (>= N 0) (typ N s (app (app (app (app R arr) (app (app A arr) B)) arr)
    (app (app (app (app R arr) A) arr) (app (app R arr) B))))))
(rule (=> (>= N 0) (typ N k (app (app A arr) (app (app B arr) A)))))

(rule (=> (and (>= N 0) (typ (- N 1) F (app (app A arr) B)) (typ (- N 1) X A)) (typ N (app F X) B)))

(declare-rel res (Term))
(rule (=> (typ 3 (app (app s k) k) X) (res X)))
; (rule (=> (typ 1 X (app (app k arr) k)) (res X)))
(query res :print-answer true)
