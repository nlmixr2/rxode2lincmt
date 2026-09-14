/*
 * Receiver for rxode2's host table (inst/include/rxode2lincmtHost.h).
 *
 * Copies with bounds limits only -- no type, name, length or version checks.
 * Before rxode2 registers, every offset is -1 and every host function is a
 * local fallback, so standalone use never dereferences NULL.
 */
#define STRICT_R_HEADERS
#define USE_FC_LEN_T
#include <R.h>
#include <Rinternals.h>
#include "lcHost.h"

#define LC_MINUS1_(s, f, t, d) -1,
ptrdiff_t _lcOff[lcOffN] = {-1, -1, -1, RXLC_HOST_FIELDS(LC_MINUS1_)};

static double lcNoGetTime(int idx, rx_solving_options_ind *ind) {
  (void)idx;
  (void)ind;
  return NA_REAL;
}

static int lcNoRxThreadSlot(int mx) {
  (void)mx;
  return 0;
}

static rx_solve *lcNoGetRxSolve(void) {
  return NULL;
}

#define LC_FDEF_(n, r, a) lcHostFn_##n _lcHost_##n = &lcNo##n;
#define lcNogetTime lcNoGetTime
#define lcNorxThreadSlot lcNoRxThreadSlot
#define lcNogetRxSolve lcNoGetRxSolve
RXLC_HOST_FNS(LC_FDEF_)

#define _RXLCH_NEXT(var, type)                                          \
  do {                                                                  \
    if (_i < _n) var = (type) R_ExternalPtrAddrFn(VECTOR_ELT(p, _i));   \
    _i++;                                                               \
  } while (0)

SEXP _rxode2lincmt_iniHost(SEXP p) {
  int _n = (int)Rf_length(p);
  int _i = 0;
  if (_n > 0) {
    SEXP o = VECTOR_ELT(p, 0);
    int no = (int)Rf_length(o);
    int *po = INTEGER(o);
    for (int k = 0; k < no && k < lcOffN; ++k) {
      _lcOff[k] = (ptrdiff_t) po[k];
    }
  }
  _i = 1;
#define LC_NEXT_(n, r, a) _RXLCH_NEXT(_lcHost_##n, lcHostFn_##n);
  RXLC_HOST_FNS(LC_NEXT_)
  return R_NilValue;
}

// Test hook: the offsets currently held and which host functions are bound
SEXP _rxode2lincmt_hostInfo(void) {
  SEXP off = PROTECT(Rf_allocVector(INTSXP, lcOffN));
  int *po = INTEGER(off);
  for (int k = 0; k < lcOffN; ++k) {
    po[k] = (int)_lcOff[k];
  }
  SEXP fns = PROTECT(Rf_allocVector(LGLSXP, RXLC_HOST_NFNS));
  SEXP fnNames = PROTECT(Rf_allocVector(STRSXP, RXLC_HOST_NFNS));
  int k = 0;
#define LC_BOUND_(n, r, a)                                              \
  LOGICAL(fns)[k] = _lcHost_##n != &lcNo##n;                            \
  SET_STRING_ELT(fnNames, k, Rf_mkChar(#n));                            \
  k++;
  RXLC_HOST_FNS(LC_BOUND_)
  Rf_setAttrib(fns, R_NamesSymbol, fnNames);
  SEXP ret = PROTECT(Rf_allocVector(VECSXP, 2));
  SET_VECTOR_ELT(ret, 0, off);
  SET_VECTOR_ELT(ret, 1, fns);
  SEXP retNames = PROTECT(Rf_allocVector(STRSXP, 2));
  SET_STRING_ELT(retNames, 0, Rf_mkChar("offsets"));
  SET_STRING_ELT(retNames, 1, Rf_mkChar("fns"));
  Rf_setAttrib(ret, R_NamesSymbol, retNames);
  UNPROTECT(5);
  return ret;
}

// Test hook: "struct_field" names in wire order
SEXP _rxode2lincmt_hostFieldNames(void) {
  static const char *names[] = {RXLC_HOST_FIELDS(RXLC_NAME1_)};
  int n = (int)RXLC_HOST_NFIELDS;
  SEXP ret = PROTECT(Rf_allocVector(STRSXP, n));
  for (int k = 0; k < n; ++k) {
    SET_STRING_ELT(ret, k, Rf_mkChar(names[k]));
  }
  UNPROTECT(1);
  return ret;
}
