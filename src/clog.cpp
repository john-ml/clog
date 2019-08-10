// TODO
// - Backtracking
// - GC
#include <iostream>
#include <cstddef>
#include <cstdint>
#include <sys/mman.h>

namespace clog {

struct term {
  size_t data : 61;
  bool is_ctr : 1;
  bool is_var : 1;
  bool is_ptr : 1;
  char children[0];

  term* to_ptr() const { return reinterpret_cast<term*>(data << 3); }
  term& operator*() const { return *to_ptr(); }
  bool is_free() const { return is_var && to_ptr() == this; }
  bool is_link() const { return is_var && to_ptr()->is_var; }
  bool is_inst() const { return is_var && !to_ptr()->is_var; }
  size_t arity() const { return data >> 32; }
  size_t id() const { return data & 0xfffffffful; }

  term& operator[](size_t n) { return reinterpret_cast<term*>(children)[n]; }
  void set_ref(term* t) { data = reinterpret_cast<size_t>(t) >> 3; }

  friend std::ostream& operator<<(std::ostream& o, term& t) {
    if (t.is_var) o << '?' << t.to_ptr();
    else if (t.is_ptr) o << *t;
    else if (t.is_ctr) {
      o << '(';
      for (size_t i = 0; i < t.arity(); ++i) {
        o << t[i];
        if (i != t.arity() - 1)
          o << ' ';
      }
      o << ')';
    }
  }
};
static_assert(sizeof(term) == sizeof(size_t));

// TODO: store mutable updates to allow for backtracking
bool unify(term& s, term& t) {
  if (s.is_ptr) return unify(*s, t);
  if (t.is_ptr) return unify(s, *t);
  if (s.is_free()) { s.set_ref(&t); return true; }
  if (t.is_free()) { t.set_ref(&s); return true; }
  if (s.is_link()) return unify(*s, t);
  if (t.is_link()) return unify(s, *t);
  if (s.is_inst()) { term old = t; t = *s; return unify(old, *s); }
  if (t.is_inst()) { term old = s; s = *t; return unify(old, *t); }
  if (s.is_ctr && t.is_ctr && s.arity() == t.arity() && s.id() == t.id()) {
    for (size_t i = 0; i < s.arity(); ++i)
      if (!unify(s[i], t[i]))
        return false;
    return true;
  }
  return false;
}

const size_t MEM_SIZE = 1ul << 40;

struct mem {
  term terms[0];
};

auto pool = reinterpret_cast<mem*>(mmap(
  nullptr, MEM_SIZE,
  PROT_READ | PROT_WRITE,
  MAP_PRIVATE | MAP_ANONYMOUS,
  -1, 0));

};

int main() {
  puts("hi");
  clog::term s {reinterpret_cast<size_t>(&s) >> 3, false, true, false};
  clog::term t {reinterpret_cast<size_t>(&t) >> 3, false, true, false};
  std::cout << s << ',' << t << std::endl;
  std::cout << unify(s, t) << std::endl;
  std::cout << s << ',' << t << std::endl;
}
