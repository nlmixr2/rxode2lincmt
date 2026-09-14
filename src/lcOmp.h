#ifndef RXODE2LINCMT_LCOMP_H
#define RXODE2LINCMT_LCOMP_H
/* Thread slots come from rxode2 (rx_get_thread in lcHost.h), not from here. */
#ifdef _OPENMP
// R's `match` macro breaks the `declare variant match(...)` pragma in LLVM's
// omp.h when R headers were included first.
#pragma push_macro("match")
#undef match
#include <omp.h>
#pragma pop_macro("match")
#else
static inline int omp_get_num_procs(void) {
  return 1;
}

static inline int omp_get_thread_limit(void) {
  return 1;
}

static inline int omp_get_max_threads(void) {
  return 1;
}

static inline int omp_get_thread_num(void) {
  return 0;
}

static inline int omp_in_parallel(void) {
  return 0;
}
#endif

#endif
