/*
 * Manual .Call registration.  Arities are hardcoded: when an Rcpp export
 * changes its argument count, run Rcpp::compileAttributes() AND update the
 * matching entry here, or R reports "Incorrect number of arguments" at run
 * time.
 */
#define STRICT_R_HEADERS
#define USE_FC_LEN_T
#include <R.h>
#include <Rinternals.h>
#include <R_ext/Rdynload.h>

// src/ptr.c
SEXP _rxode2lincmt_ptr(void);
SEXP _rxode2lincmt_ptrNonNull(void);
// src/host.c
SEXP _rxode2lincmt_iniHost(SEXP);
SEXP _rxode2lincmt_hostInfo(void);
SEXP _rxode2lincmt_hostFieldNames(void);
// src/solComp.cpp, src/macros2micros.cpp, src/rxDerived.cpp
SEXP _rxode2lincmt_solComp2(SEXP, SEXP, SEXP);
SEXP _rxode2lincmt_solComp3(SEXP, SEXP, SEXP, SEXP, SEXP);
SEXP _rxode2lincmt_macros2micros(SEXP, SEXP, SEXP, SEXP, SEXP, SEXP, SEXP, SEXP);
SEXP _rxode2lincmt_calcDerived(SEXP, SEXP, SEXP, SEXP, SEXP, SEXP);
// src/RcppExports.cpp (linCmt.cpp)
SEXP _rxode2lincmt_linCmtDeltaMemo(SEXP);
SEXP _rxode2lincmt_linCmtSeqStats(SEXP);
SEXP _rxode2lincmt_linCmtModelDouble(SEXP, SEXP, SEXP, SEXP, SEXP, SEXP, SEXP,
                                     SEXP, SEXP, SEXP, SEXP, SEXP, SEXP, SEXP,
                                     SEXP, SEXP, SEXP, SEXP, SEXP, SEXP, SEXP,
                                     SEXP);
SEXP _rxode2lincmt_linCmtCarrySetFast(SEXP);
SEXP _rxode2lincmt_linCmtCarrySentinelMax(void);
SEXP _rxode2lincmt_linCmtCarryFastStats(SEXP);
SEXP _rxode2lincmt_linCmtCarryLiveTest(SEXP, SEXP, SEXP, SEXP, SEXP,
                                       SEXP, SEXP, SEXP, SEXP, SEXP);
SEXP _rxode2lincmt_linCmtBSensTypesSeen(SEXP);
SEXP _rxode2lincmt_linCmtBThreadsSeen(SEXP);

static const R_CallMethodDef callMethods[] = {
  {"_rxode2lincmt_ptr", (DL_FUNC) &_rxode2lincmt_ptr, 0},
  {"_rxode2lincmt_ptrNonNull", (DL_FUNC) &_rxode2lincmt_ptrNonNull, 0},
  {"_rxode2lincmt_iniHost", (DL_FUNC) &_rxode2lincmt_iniHost, 1},
  {"_rxode2lincmt_hostInfo", (DL_FUNC) &_rxode2lincmt_hostInfo, 0},
  {"_rxode2lincmt_hostFieldNames", (DL_FUNC) &_rxode2lincmt_hostFieldNames, 0},
  {"_rxode2lincmt_solComp2", (DL_FUNC) &_rxode2lincmt_solComp2, 3},
  {"_rxode2lincmt_solComp3", (DL_FUNC) &_rxode2lincmt_solComp3, 5},
  {"_rxode2lincmt_macros2micros", (DL_FUNC) &_rxode2lincmt_macros2micros, 8},
  {"_rxode2lincmt_calcDerived", (DL_FUNC) &_rxode2lincmt_calcDerived, 6},
  {"_rxode2lincmt_linCmtDeltaMemo", (DL_FUNC) &_rxode2lincmt_linCmtDeltaMemo, 1},
  {"_rxode2lincmt_linCmtSeqStats", (DL_FUNC) &_rxode2lincmt_linCmtSeqStats, 1},
  {"_rxode2lincmt_linCmtModelDouble", (DL_FUNC) &_rxode2lincmt_linCmtModelDouble, 22},
  {"_rxode2lincmt_linCmtCarrySetFast", (DL_FUNC) &_rxode2lincmt_linCmtCarrySetFast, 1},
  {"_rxode2lincmt_linCmtCarrySentinelMax", (DL_FUNC) &_rxode2lincmt_linCmtCarrySentinelMax, 0},
  {"_rxode2lincmt_linCmtCarryFastStats", (DL_FUNC) &_rxode2lincmt_linCmtCarryFastStats, 1},
  {"_rxode2lincmt_linCmtCarryLiveTest", (DL_FUNC) &_rxode2lincmt_linCmtCarryLiveTest, 10},
  {"_rxode2lincmt_linCmtBSensTypesSeen", (DL_FUNC) &_rxode2lincmt_linCmtBSensTypesSeen, 1},
  {"_rxode2lincmt_linCmtBThreadsSeen", (DL_FUNC) &_rxode2lincmt_linCmtBThreadsSeen, 1},
  {NULL, NULL, 0}
};

void R_init_rxode2lincmt(DllInfo *info) {
  R_registerRoutines(info, NULL, callMethods, NULL, NULL);
  R_useDynamicSymbols(info, FALSE);
}
