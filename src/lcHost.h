#ifndef RXODE2LINCMT_LCHOST_H
#define RXODE2LINCMT_LCHOST_H
/*
 * rxode2's solver structs as seen from rxode2lincmt: opaque types whose
 * fields are read through the offsets rxode2 passes at load (see
 * inst/include/rxode2lincmtHost.h).  linCmt code writes IND(ind, f),
 * OPT(op, f) and RXS(rx, f), never ind->f.
 */
#include <stddef.h>

#ifdef __cplusplus
extern "C" {
#endif

typedef struct rx_solve_s rx_solve;
typedef struct rx_solving_options_ind_s rx_solving_options_ind;
/* anonymous in rxode2; no table function takes it, so a private tag is fine */
typedef struct rxlc_solving_options_s rx_solving_options;

#include "../inst/include/rxode2lincmtHost.h"

/* Per-field types keep array types, so sizeof/memcpy/[] behave as before */
#define LC_TD_(s, f, t, d) typedef t lcT_##s##f d;
RXLC_HOST_FIELDS(LC_TD_)

#define LC_EN_(s, f, t, d) lcOff_##s##f,
enum {
  lcOffIndSize = 0,
  lcOffCarryMax,
  lcOffOriginMax,
  RXLC_HOST_FIELDS(LC_EN_)
  lcOffN
};

/* ptrdiff_t, not int: writes through int* must not force offset reloads */
extern ptrdiff_t _lcOff[lcOffN];

#define LC_FLD(p, s, f) (*(lcT_##s##f*)((char*)(p) + _lcOff[lcOff_##s##f]))
#define IND(p, f) LC_FLD(p, ind, f)
#define OPT(p, f) LC_FLD(p, op, f)
#define RXS(p, f) LC_FLD(p, rx, f)
#define RX_IND(rx, id) ((rx_solving_options_ind*)((char*)RXS(rx, subjects) + \
                                                  (ptrdiff_t)(id)*_lcOff[lcOffIndSize]))
/* Only for fields appended after the first release */
#define LC_HAS(s, f) (_lcOff[lcOff_##s##f] >= 0)

/* Host functions; each starts at a local fallback, never NULL */
#define LC_FT_(n, r, a) typedef r (*lcHostFn_##n) a;
RXLC_HOST_FNS(LC_FT_)
#define LC_FE_(n, r, a) extern lcHostFn_##n _lcHost_##n;
RXLC_HOST_FNS(LC_FE_)

static inline double getTime(int idx, rx_solving_options_ind *ind) {
  return _lcHost_getTime(idx, ind);
}

static inline int rx_get_thread(int mx) {
  return _lcHost_rxThreadSlot(mx);
}

static inline rx_solve *getRxSolve_(void) {
  return _lcHost_getRxSolve();
}

/* From rxode2's inst/include/rxode2EventTranslate.h */
#define EVIDF_NORMAL 0
#define EVIDF_INF_RATE 1
#define EVIDF_INF_DUR  2
#define EVIDF_REPLACE  4
#define EVIDF_MULT     5
#define EVIDF_MODEL_DUR_ON   8
#define EVIDF_MODEL_DUR_OFF  6
#define EVIDF_MODEL_RATE_ON  9
#define EVIDF_MODEL_RATE_OFF 7

#define EVID0_REGULAR  1
#define EVID0_RATEADJ 2
#define EVID0_INFRM 8
#define EVID0_SS0 9
#define EVID0_SS 10
#define EVID0_SS20 19
#define EVID0_SS2 20
#define EVID0_OFF 30
#define EVID0_SSINF 40
#define EVID0_PHANTOM 50
#define EVID0_ONDOSE 60

static inline void getWh(int evid, int *wh, int *cmt, int *wh100, int *whI, int *wh0) {
  *wh = evid;
  *cmt = 0;
  *wh100 = *wh / 100000;
  *whI   = *wh / 10000 - *wh100 * 10;
  *wh    = *wh - *wh100 * 100000 - (*whI - 1) * 10000;
  *wh0   = (*wh % 10000) / 100;
  *cmt   = *wh0 - 1 + *wh100 * 100;
  *wh0   = evid - *wh100 * 100000 - *whI * 10000 - *wh0 * 100;
}

/* From rxode2's rxode2parse.h / rxode2parseHandleEvid.h / rxode2.h */
#define getEvid(ind, idx) (idx >= 0 ? IND(ind, evid)[idx] : IND(ind, extraDoseEvid)[-1-idx])
#define getDose(ind, idx) (idx >= 0 ? IND(ind, dose)[idx] : IND(ind, extraDoseDose)[-1-idx])

static inline double getDoseNumber(rx_solving_options_ind *ind, int i) {
  return getDose(ind, IND(ind, idose)[i]);
}

static inline int rxEffNeq(const rx_solving_options_ind *ind,
                           const rx_solving_options *op) {
  int o = IND(ind, neqOverride);
  return (o >= 0 && o <= OPT(op, neq)) ? o : OPT(op, neq);
}
#define getAdvan(idx) IND(ind, solve) + OPT(op, linOffset) + (rxEffNeq(ind, op))*(idx)

#ifndef max2
#define max2( a , b )  ( (a) > (b) ? (a) : (b) )
#endif

#ifdef __cplusplus
}
#endif

#endif
