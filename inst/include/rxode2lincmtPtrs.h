#ifndef RXODE2LINCMT_PTRS_H
#define RXODE2LINCMT_PTRS_H
/*
  External-pointer access to rxode2lincmt's linear compartment entry points,
  for rxode2.

  rxode2lincmt hands out a list of external pointers from
  `rxode2lincmt::.rxode2lincmtPtr()`; the consumer copies them into its own
  pointer variables from `.onLoad()` (the rxode2ll / lotri / n1qn1 pattern),
  so an updated rxode2lincmt is picked up on the next load instead of being
  baked into the consumer's object code.

  Consumer usage (exactly one translation unit):

      #include <rxode2lincmtPtrs.h>
      rxLcLinCmtA_t _p_linCmtA = &myStubA;   // define every _p_* variable,
      ...                                    // ideally at a harmless stub
      SEXP _mypkg_iniRxode2lincmtPtrs(SEXP p) {
        iniRxode2lincmtPtrs0(p);
        return R_NilValue;
      }

  and from R: `.Call(_mypkg_iniRxode2lincmtPtrs, rxode2lincmt::.rxode2lincmtPtr())`

  The list is APPEND-ONLY and its order is fixed, so a consumer built against
  an older rxode2lincmt keeps working with a newer one.  The reader only
  assigns slots the list provides; nothing is validated at load.
*/
#include <Rinternals.h>
#include <string.h>

#if defined(__cplusplus)
extern "C" {
#endif

struct rx_solve_s;
struct rx_solving_options_ind_s;

typedef double (*rxLcLinCmtA_t)(struct rx_solve_s *rx, int id,
                                double _t,
                                int linCmt, int ncmt,
                                int oral0, int which,
                                int trans,
                                double p1, double v1,
                                double p2, double p3,
                                double p4, double p5,
                                double ka);
typedef double (*rxLcLinCmtB_t)(struct rx_solve_s *rx, int id,
                                double _t, int linCmt,
                                int ncmt, int oral0,
                                int which1, int which2,
                                int trans,
                                double p1, double v1,
                                double p2, double p3,
                                double p4, double p5,
                                double ka);
typedef void (*rxLcEnsure_t)(int nCores);
typedef void (*rxLcIndFree_t)(struct rx_solving_options_ind_s *ind);
typedef double (*rxLcScaleInitPar_t)(int which);
typedef double (*rxLcScaleInitN_t)(void);
typedef int (*rxLcZeroJac_t)(int i);
typedef void (*rxLcEventJac_t)(double *a, int numLin, int depotLin, int numLinSens,
                               int c, int type, double factor);

extern rxLcLinCmtA_t _p_linCmtA;                 /* 0 */
extern rxLcLinCmtB_t _p_linCmtB;                 /* 1 */
extern rxLcEnsure_t _p_ensureLinCmtA;            /* 2 */
extern rxLcEnsure_t _p_ensureLinCmtB;            /* 3 */
extern rxLcIndFree_t _p_linCmtBindFree;          /* 4 */
extern rxLcScaleInitPar_t _p_linCmtScaleInitPar; /* 5 */
extern rxLcScaleInitN_t _p_linCmtScaleInitN;     /* 6 */
extern rxLcZeroJac_t _p_linCmtZeroJac;           /* 7 */
extern rxLcIndFree_t _p_linCmtFreeInd;           /* 8 */

#define _RXLC_NEXT(var, type)                                           \
  do {                                                                  \
    if (_i < _n) var = (type) R_ExternalPtrAddrFn(VECTOR_ELT(p, _i));   \
    _i++;                                                               \
  } while (0)

static inline void iniRxode2lincmtPtrs0(SEXP p) {
  int _n = (int)Rf_length(p);
  int _i = 0;
  _RXLC_NEXT(_p_linCmtA, rxLcLinCmtA_t);
  _RXLC_NEXT(_p_linCmtB, rxLcLinCmtB_t);
  _RXLC_NEXT(_p_ensureLinCmtA, rxLcEnsure_t);
  _RXLC_NEXT(_p_ensureLinCmtB, rxLcEnsure_t);
  _RXLC_NEXT(_p_linCmtBindFree, rxLcIndFree_t);
  _RXLC_NEXT(_p_linCmtScaleInitPar, rxLcScaleInitPar_t);
  _RXLC_NEXT(_p_linCmtScaleInitN, rxLcScaleInitN_t);
  _RXLC_NEXT(_p_linCmtZeroJac, rxLcZeroJac_t);
  _RXLC_NEXT(_p_linCmtFreeInd, rxLcIndFree_t);
}

/* Slot 9, linCmtCarryReset(ind): zeroes the linCmt() carry columns a
   subject has written since its last reset, for the consumer's per-subject
   setup.  Read by its own call, so a consumer built before it needs no
   variable for it; *out keeps its stub when the list is shorter. */
static inline void iniRxode2lincmtCarryReset(SEXP p, rxLcIndFree_t *out) {
  if (Rf_length(p) > 9) {
    *out = (rxLcIndFree_t) R_ExternalPtrAddrFn(VECTOR_ELT(p, 9));
  }
}

/* Slot 10, linCmtEventJac(a, numLin, depotLin, numLinSens, c, type,
   factor): after a replace (type 0) or multiply (type 1, by factor) of the
   linCmt() block's compartment c, makes that compartment's Jacobian row in
   the block `a` follow.  Read by its own call, and only from a list long
   enough that names it in its slot; *out keeps its stub otherwise. */
static inline void iniRxode2lincmtEventJac(SEXP p, rxLcEventJac_t *out) {
  SEXP nm = Rf_getAttrib(p, R_NamesSymbol);
  if (Rf_length(p) > 10 && nm != R_NilValue &&
      strcmp(CHAR(STRING_ELT(nm, 10)), "linCmtEventJac") == 0) {
    *out = (rxLcEventJac_t) R_ExternalPtrAddrFn(VECTOR_ELT(p, 10));
  }
}

#if defined(__cplusplus)
}
#endif

#endif
