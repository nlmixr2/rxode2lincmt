#ifndef RXODE2LINCMT_HOST_H
#define RXODE2LINCMT_HOST_H
/*
 * Host contract: what rxode2 hands rxode2lincmt at load.
 *
 * rxode2lincmt never includes rxode2's struct headers.  rxode2 fills the
 * offsetof() of exactly the fields listed here and passes them, with a few
 * host functions, through `.rxode2lincmtIniHost()`.  The linCmt code reads
 * every field through those offsets (see src/lcHost.h).
 *
 * APPEND ONLY.  The row order is the wire order; a released rxode2 built
 * against an older list keeps working with a newer rxode2lincmt.  Nothing
 * checks this list at load -- rxode2 enforces the types at its own compile
 * time with RXLC_HOST_STATIC_CHECKS.
 *
 * Wire format (VECSXP):
 *   [0] INTSXP: sizeof(rx_solving_options_ind), RX_LINCMT_CARRY_MAXPAIRS,
 *       RX_LINCMT_ORIGIN_MAX, then one offset per RXLC_HOST_FIELDS row
 *   [1..] external pointers, one per RXLC_HOST_FNS row
 *
 * Pure C with no R dependency; rxode2 reads it through LinkingTo.
 */
#include <stddef.h>

#ifndef RX_LINCMT_CARRY_MAXPAIRS
#define RX_LINCMT_CARRY_MAXPAIRS 8
#endif
#ifndef RX_LINCMT_ORIGIN_MAX
#define RX_LINCMT_ORIGIN_MAX 4
#endif

/* X(struct, field, type, arraySuffix); struct is rx, op or ind */
#define RXLC_HOST_FIELDS(X)                                                  \
  X(rx, subjects, rx_solving_options_ind*, )                                 \
  X(rx, op, rx_solving_options*, )                                           \
  X(rx, ndiff, int, )                                                        \
  X(rx, sensType, int, )                                                     \
  X(rx, linCmtScale, double*, )                                              \
  X(rx, linCmtSensPhi, int, )                                                \
  X(rx, linCmtSuspect, double, )                                             \
  X(rx, linCmtForwardMax, int, )                                             \
  X(op, neq, int, )                                                          \
  X(op, inits, double*, )                                                    \
  X(op, numLin, int, )                                                       \
  X(op, linOffset, int, )                                                    \
  X(op, linCmtLagMask, int, )                                                \
  X(op, linCmtOriginMask, int, )                                             \
  X(ind, cmt, int, )                                                         \
  X(ind, doSS, int, )                                                        \
  X(ind, idose, int*, )                                                      \
  X(ind, idx, int, )                                                         \
  X(ind, InfusionRate, double*, )                                            \
  X(ind, ix, int*, )                                                         \
  X(ind, ndoses, int, )                                                      \
  X(ind, _rxFlag, int, )                                                     \
  X(ind, solvedIdx, int, )                                                   \
  X(ind, tout, double, )                                                     \
  X(ind, tprior, double, )                                                   \
  X(ind, neqOverride, int, )                                                 \
  X(ind, solve, double*, )                                                   \
  X(ind, evid, int*, )                                                       \
  X(ind, extraDoseEvid, int*, )                                              \
  X(ind, dose, double*, )                                                    \
  X(ind, extraDoseDose, double*, )                                           \
  X(ind, linCmtSave, double*, )                                              \
  X(ind, linCmtAlast, double*, )                                             \
  X(ind, linSS, int, )                                                       \
  X(ind, linSSbolusCmt, int, )                                               \
  X(ind, linSStau, double, )                                                 \
  X(ind, linSSvar, double, )                                                 \
  X(ind, linH, double*, )                                                    \
  X(ind, linCmtHparIndex, int, )                                             \
  X(ind, linCmtH, double, )                                                  \
  X(ind, linCmtHV, double, )                                                 \
  X(ind, linCmtRateHist, double*, )                                          \
  X(ind, linCmtRateHistCap, int, )                                           \
  X(ind, linCmtRateHistW, int, )                                             \
  X(ind, linCmtCarryT, double, [4*RX_LINCMT_CARRY_MAXPAIRS])                 \
  X(ind, linCmtCarryTlast, double, )                                         \
  X(ind, linCmtCarryPrevTheta, double, [7])                                  \
  X(ind, linCmtCarryVarying, int, )                                          \
  X(ind, linCmtBind, void*, )                                                \
  X(ind, linCmtOrigin, double, [RX_LINCMT_ORIGIN_MAX*RX_LINCMT_ORIGIN_MAX])  \
  X(ind, linCmtOriginSeeded, int, )                                          \
  X(ind, linCmtOriginOut, double, [RX_LINCMT_ORIGIN_MAX*RX_LINCMT_ORIGIN_MAX]) \
  X(ind, linCmtOriginOutSeeded, int, )                                       \
  X(ind, linCmtOriginIdx, int, )                                             \
  X(ind, linCmtOriginSS, int, )                                              \
  X(ind, linCmtOriginHist, double*, )                                        \
  X(ind, linCmtOriginHistCap, int, )                                         \
  X(ind, linCmtOriginHistW, int, )

/* X(name, returnType, (argTypes)) */
#define RXLC_HOST_FNS(X)                                                     \
  X(getTime, double, (int, rx_solving_options_ind*))                         \
  X(rxThreadSlot, int, (int))                                                \
  X(getRxSolve, rx_solve*, (void))

#define RXLC_HOST_HEAD_N 3
#define RXLC_COUNT1_(s, f, t, d) +1
#define RXLC_HOST_NFIELDS (0 RXLC_HOST_FIELDS(RXLC_COUNT1_))
#define RXLC_HOST_NOFF (RXLC_HOST_HEAD_N + RXLC_HOST_NFIELDS)
#define RXLC_COUNTF_(n, r, a) +1
#define RXLC_HOST_NFNS (0 RXLC_HOST_FNS(RXLC_COUNTF_))

/* Struct name for each row prefix, for offsetof() on the rxode2 side */
#define RXLC_STRUCT_rx rx_solve
#define RXLC_STRUCT_op rx_solving_options
#define RXLC_STRUCT_ind rx_solving_options_ind

/* rxode2 side, C++ only (needs <type_traits>): each listed field exists with
   exactly this type.  A mismatch fails rxode2's compile, never its load. */
#define RXLC_CHECK1_(s, f, t, d)                                             \
  static_assert(std::is_same<decltype(((RXLC_STRUCT_##s*)0)->f), t d>::value, \
                "rxode2lincmt host field type changed: " #s "." #f);
#define RXLC_HOST_STATIC_CHECKS RXLC_HOST_FIELDS(RXLC_CHECK1_)

/* "struct_field" names in wire order, for tests */
#define RXLC_NAME1_(s, f, t, d) #s "_" #f,

#endif
