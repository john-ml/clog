// TODO
// - Backtracking
// - GC
#include <iostream>
#include <cstddef>
#include <cstdint>
#include <sys/mman.h>

namespace clog {

// -------------------- Memory --------------------

template<typename T>
struct mem {
  T* end;
  T data[0];
};

// Assume result is 8-aligned
template<typename T>
mem<T>* mmap_alloc(size_t bytes) {
  auto res = reinterpret_cast<mem<T>*>(mmap(
    nullptr, bytes,
    PROT_READ | PROT_WRITE,
    MAP_PRIVATE | MAP_ANONYMOUS,
    -1, 0));
  res->end = &res->data[0];
  return res;
}

// -------------------- Term representation --------------------
//
// Term
//   = ?x + A + [Term]
//   = ?x + A + Cell
//   = *(Term + A + Cell)
//   = *Term + A + *Cell
// 
// Cell = (n : Nat) Term[n]

constexpr uint64_t
  VAR = 0ul,
  LIT = 1ul,
  CTR = 2ul,
  LNK = 3ul;

struct term;
struct cell;

// Variant tags for constructors
struct var_t {}; const var_t var;
struct lit_t {}; const lit_t lit;
struct ctr_t {}; const ctr_t ctr;
struct link_t {}; const link_t link;

struct term {
  uint64_t a;

  // Assume p is 4-aligned
  term(var_t _, term* p) : a(reinterpret_cast<uint64_t>(p) | VAR) {}
  term(lit_t _, uint64_t id) : a(id | LIT) {}
  term(ctr_t _, cell* p) : a(reinterpret_cast<uint64_t>(p) | CTR) {}
  term(link_t _, term* p) : a(reinterpret_cast<uint64_t>(p) | LNK) {}

  uint64_t ty() const { return a & 3ul; }

  // Assume ty() = VAR = 0
  term* var() { return reinterpret_cast<term*>(a); }
  term& operator*() { return *var(); } 

  // Assume ty() = LIT
  uint64_t lit() { return a; }

  // Assume ty() = CTR
  cell* ctr() { return reinterpret_cast<cell*>(a & ~3ul); }

  // Assume ty() = INST
  term* inst() { return reinterpret_cast<term*>(a & ~3ul); }

  friend std::ostream& operator<<(std::ostream& o, term& t);
};

struct cell {
  uint64_t len;
  term subs[0];
};

auto heap = mmap_alloc<term>(1ul << 40);
auto undo = mmap_alloc<term>(1ul << 20);

void fail() {}

void unify(term* s, term* t) {
  // A ~ A and physical equality of subtrees
  if (s->a == t->a) return;
  // (?x -> ?y) ~ (?z -> ?w) <== ?y ~ ?w
  if (s->ty() == VAR) while (s->var() != s) s = s->var();
  if (t->ty() == VAR) while (t->var() != t) t = t->var();
  // ?x ~ ?y <== ?x -> ?y
  if (s->ty() == VAR && t->ty() == VAR) s->a = reinterpret_cast<size_t>(t);
  // ?x ~ t <== x -> t
  else if (s->ty() == VAR) *s = {link, t};
  else if (t->ty() == VAR) *t = {link, s};
  // (x -> s) ~ t <== replace t with x -> s; s ~ old t
  else if (s->ty() == LNK) { term u = *t; t->a = s->a; unify(s, &u); }
  else if (t->ty() == LNK) { term u = *s; s->a = t->a; unify(t, &u); }
  // xs... ~ ys... <== len(xs) = len(ys), xs[i] ~ ys[i]
  else if (s->ty() == CTR && t->ty() == CTR) {
    auto ss = s->ctr(), ts = t->ctr();
    if (ss->len != ts->len)
      fail();
    else for (auto i = ss->len; i--;)
      unify(ss->subs + i, ts->subs + i);
  }
  else fail();
}

std::ostream& operator<<(std::ostream& o, term& t) { return o; };

}; // namespace clog

int main() {
  using namespace clog;
  puts("hi");
  term s = {var, &s};
  term t = {var, &t};
  std::cout << s << ',' << t << std::endl;
  unify(&s, &t);
  std::cout << s << ',' << t << std::endl;
}
