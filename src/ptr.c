/*
 * External-pointer export of the linCmt entry points rxode2 calls.
 *
 * See inst/include/rxode2lincmtPtrs.h for the consumer contract.  The order
 * here IS that contract: append only, never reorder or rename.
 */
#define STRICT_R_HEADERS
#define USE_FC_LEN_T
#include <R.h>
#include <Rinternals.h>
#include "lcHost.h"

double linCmtA(rx_solve *rx, int id, double _t, int linCmt, int ncmt,
               int oral0, int which, int trans, double p1, double v1,
               double p2, double p3, double p4, double p5, double ka);
double linCmtB(rx_solve *rx, int id, double _t, int linCmt, int ncmt,
               int oral0, int which1, int which2, int trans, double p1,
               double v1, double p2, double p3, double p4, double p5,
               double ka);
void ensureLinCmtA(int nCores);
void ensureLinCmtB(int nCores);
void linCmtBindFree(rx_solving_options_ind *ind);
double linCmtScaleInitPar(int which);
double linCmtScaleInitN(void);
int linCmtZeroJac(int i);
void linCmtFreeInd(rx_solving_options_ind *ind);

#define LC_NPTR 9

SEXP _rxode2lincmt_ptr(void) {
  SEXP ret = PROTECT(Rf_allocVector(VECSXP, LC_NPTR));
  SEXP nm = PROTECT(Rf_allocVector(STRSXP, LC_NPTR));
  int i = 0;
#define LC_PTR_(fn)                                                            \
  SET_VECTOR_ELT(ret, i, R_MakeExternalPtrFn((DL_FUNC)&fn, R_NilValue, R_NilValue)); \
  SET_STRING_ELT(nm, i, Rf_mkChar(#fn));                                       \
  i++;
  LC_PTR_(linCmtA)
  LC_PTR_(linCmtB)
  LC_PTR_(ensureLinCmtA)
  LC_PTR_(ensureLinCmtB)
  LC_PTR_(linCmtBindFree)
  LC_PTR_(linCmtScaleInitPar)
  LC_PTR_(linCmtScaleInitN)
  LC_PTR_(linCmtZeroJac)
  LC_PTR_(linCmtFreeInd)
  Rf_setAttrib(ret, R_NamesSymbol, nm);
  UNPROTECT(2);
  return ret;
}

// Test hook: every exported address is non-NULL
SEXP _rxode2lincmt_ptrNonNull(void) {
  SEXP p = PROTECT(_rxode2lincmt_ptr());
  int n = (int)Rf_length(p);
  SEXP ret = PROTECT(Rf_allocVector(LGLSXP, n));
  for (int k = 0; k < n; ++k) {
    LOGICAL(ret)[k] = R_ExternalPtrAddrFn(VECTOR_ELT(p, k)) != NULL;
  }
  UNPROTECT(2);
  return ret;
}
