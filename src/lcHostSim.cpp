// Test hook: one synthetic subject solved through the real linCmtA() /
// linCmtB(), the way rxode2's linear-only solve (ind_linSolve) drives them,
// with no rxode2.  The solver structs are local stand-ins built from the
// host field list, the host offsets point at them for the call, and the
// offsets and host functions are restored after.
#define R_NO_REMAP
#include <Rcpp.h>
#include <vector>
#include <cstring>
#include "lcHost.h"
#include "linCmtSensType.h"

using namespace Rcpp;

extern "C" double linCmtA(rx_solve *rx, int id, double _t, int linCmt, int ncmt,
                          int oral0, int which, int trans, double p1, double v1,
                          double p2, double p3, double p4, double p5, double ka);
extern "C" double linCmtB(rx_solve *rx, int id, double _t, int linCmt, int ncmt,
                          int oral0, int which1, int which2, int trans, double p1,
                          double v1, double p2, double p3, double p4, double p5,
                          double ka);
extern "C" void ensureLinCmtA(int nCores);
extern "C" void ensureLinCmtB(int nCores);
extern "C" void linCmtFreeInd(rx_solving_options_ind *ind);
extern "C" void linCmtBindFree(rx_solving_options_ind *ind);

// One struct per host prefix, with exactly the listed fields
#define LCSIM_FLD_(s, f, t, d) LCSIM_##s(f, t, d)
#define LCSIM_rx(f, t, d) t f d;
#define LCSIM_op(f, t, d)
#define LCSIM_ind(f, t, d)
struct lcSimRx {
  RXLC_HOST_FIELDS(LCSIM_FLD_)
};
#undef LCSIM_rx
#undef LCSIM_op
#define LCSIM_rx(f, t, d)
#define LCSIM_op(f, t, d) t f d;
struct lcSimOp {
  RXLC_HOST_FIELDS(LCSIM_FLD_)
};
#undef LCSIM_op
#undef LCSIM_ind
#define LCSIM_op(f, t, d)
#define LCSIM_ind(f, t, d) t f d;
struct lcSimInd {
  RXLC_HOST_FIELDS(LCSIM_FLD_)
};
#undef LCSIM_rx
#undef LCSIM_op
#undef LCSIM_ind

#define LCSIM_T_rx lcSimRx
#define LCSIM_T_op lcSimOp
#define LCSIM_T_ind lcSimInd
#define LCSIM_OFF_(s, f, t, d) _lcOff[lcOff_##s##f] = offsetof(LCSIM_T_##s, f);

static lcSimRx *lcSimRxCur = NULL;
static std::vector<double> lcSimTimes;

static rx_solve *lcSimGetRxSolve(void) {
  return (rx_solve*)lcSimRxCur;
}

static double lcSimGetTime(int idx, rx_solving_options_ind *ind) {
  (void)ind;
  return (idx >= 0 && idx < (int)lcSimTimes.size()) ? lcSimTimes[idx] : NA_REAL;
}

// rxode2's encoded evid for a bolus or rate infusion into linCmt state cmt
static int lcSimEvid(int cmt, int infusion) {
  return (infusion ? 10000 : 0) + 100*(cmt + 1) + 1;
}

// The records, the per-record call arguments and the stand-in structs with
// the buffers they point at.
struct lcSim {
  NumericVector t, doseAmt, doseRate, ssTau, ssVar;
  IntegerVector doseCmt, ss, ssCmt;
  NumericMatrix theta;
  int n, ncmt, oral0, trans, m, neq;
  bool useB;
  int hPar;
  double hStep;
  int forwardMax;
  lcSimRx rx;
  lcSimOp op;
  lcSimInd ind;
  std::vector<double> solve, inits, ini0, save, infRate, dose, h;
  std::vector<int> ix, evid, idose;
  double scale[7] = {0, 0, 0, 0, 0, 0, 0};
  int extraEvid = 0;
  double extraDose = 0.0;
  ptrdiff_t saved[lcOffN];
  lcHostFn_getTime savedGetTime;
  lcHostFn_getRxSolve savedGetRx;

  double call(int i, int which1, int which2) {
    rx_solve *prx = (rx_solve*)&rx;
    if (useB) {
      return linCmtB(prx, 0, t[i], 0, ncmt, oral0, which1, which2, trans,
                     theta(i, 0), theta(i, 1), theta(i, 2), theta(i, 3),
                     theta(i, 4), theta(i, 5), theta(i, 6));
    }
    return linCmtA(prx, 0, t[i], 0, ncmt, oral0, which1, trans,
                   theta(i, 0), theta(i, 1), theta(i, 2), theta(i, 3),
                   theta(i, 4), theta(i, 5), theta(i, 6));
  }

  // the record's dose, as rxode2's handle_evid() applies it
  void applyDose(int i, double *yp, bool rateOnly) {
    if (doseCmt[i] < 0) return;
    if (doseRate[i] != 0.0) {
      infRate[doseCmt[i]] += doseRate[i];
    } else if (!rateOnly) {
      yp[doseCmt[i]] += doseAmt[i];
    }
  }

  void fillRecords() {
    ix.resize(n);
    evid.assign(n, 0);
    dose.assign(n, 0.0);
    for (int i = 0; i < n; i++) {
      ix[i] = i;
      if (doseCmt[i] >= 0) {
        int inf = doseRate[i] != 0.0;
        evid[i] = lcSimEvid(doseCmt[i], inf);
        dose[i] = inf ? doseRate[i] : doseAmt[i];
        idose.push_back(i);
      }
    }
  }

  void setupStructs(int sensType, int ndiff, int sensPhi, int lagMask, int originMask) {
    memset(&rx, 0, sizeof(rx));
    memset(&op, 0, sizeof(op));
    memset(&ind, 0, sizeof(ind));
    solve.assign((size_t)n*neq, 0.0);
    // amounts from ini0, their sensitivities 0
    inits.assign(neq, 0.0);
    std::copy(ini0.begin(), ini0.end(), inits.begin());
    save.assign(neq, 0.0);
    infRate.assign(neq, 0.0);
    rx.subjects = (rx_solving_options_ind*)&ind;
    rx.op = (rx_solving_options*)&op;
    rx.ndiff = ndiff;
    rx.sensType = sensType;
    rx.linCmtScale = scale;
    rx.linCmtSensPhi = sensPhi;
    rx.linCmtSuspect = 1e-6;
    rx.linCmtForwardMax = forwardMax;
    op.neq = neq;
    op.inits = inits.data();
    op.numLin = m;
    op.linCmtLagMask = lagMask;
    op.linCmtOriginMask = originMask;
    ind.idose = idose.empty() ? NULL : idose.data();
    ind.ndoses = (int)idose.size();
    ind.InfusionRate = infRate.data();
    ind.ix = ix.data();
    ind.solve = solve.data();
    ind.neqOverride = -1;
    ind.evid = evid.data();
    ind.extraDoseEvid = &extraEvid;
    ind.dose = dose.data();
    ind.extraDoseDose = &extraDose;
    ind.linCmtSave = save.data();
    ind.linH = h.data();
    ind.linCmtHparIndex = -2;
    ind.linCmtH = NA_REAL;
    ind.linCmtCarryTlast = NA_REAL;
    ind.linCmtCarryRow = -1;
    ind.n_all_times = n;
  }

  // Point the host table at the stand-ins; nothing until unbind() calls back
  // into R with an error.
  void bind() {
    memcpy(saved, _lcOff, sizeof(saved));
    savedGetTime = _lcHost_getTime;
    savedGetRx = _lcHost_getRxSolve;
    _lcOff[lcOffIndSize] = sizeof(lcSimInd);
    _lcOff[lcOffCarryMax] = RXLC_CARRY_MAXPAIRS;
    _lcOff[lcOffOriginMax] = RXLC_ORIGIN_MAX;
    RXLC_HOST_FIELDS(LCSIM_OFF_)
    lcSimRxCur = &rx;
    lcSimTimes.assign(t.begin(), t.end());
    _lcHost_getTime = &lcSimGetTime;
    _lcHost_getRxSolve = &lcSimGetRxSolve;
    ensureLinCmtA(1);
    ensureLinCmtB(1);
  }

  void freeInd() {
    linCmtFreeInd((rx_solving_options_ind*)&ind);
    linCmtBindFree((rx_solving_options_ind*)&ind);
  }

  void unbind() {
    freeInd();
    memcpy(_lcOff, saved, sizeof(saved));
    _lcHost_getTime = savedGetTime;
    _lcHost_getRxSolve = savedGetRx;
    lcSimRxCur = NULL;
  }

  // a steady-state record: rxode2 switches the record's infusion on first,
  // then solves the steady state; returns whether the infusion was applied
  bool setupSs(int i, double *yp) {
    ind.linSS = ss[i];
    ind.doSS = ss[i] != 0;
    if (ss[i] == 0) return false;
    ind.linSStau = ssTau[i];
    ind.linSSvar = ssVar[i];
    ind.linSSbolusCmt = ssCmt[i];
    bool ssInf = doseCmt[i] >= 0 && doseRate[i] != 0.0;
    if (ssInf) applyDose(i, yp, true);
    return ssInf;
  }

  // the model's value call advancing record i from the previous record
  void advance(int i, double xp, double *yp, NumericVector &val) {
    ind.linCmtAlast = yp;
    ind.tprior = xp;
    ind.tout = t[i];
    if (hPar >= 0) {
      ind.linCmtHparIndex = hPar;
      ind.linCmtH = hStep;
    }
    val[i] = call(i, -1, useB ? -1 : 0);
    ind.linCmtHparIndex = -2;
    ind.linCmtH = NA_REAL;
    std::copy(save.begin(), save.begin() + neq, yp);
  }

  // rxode2's linear-only solve loop (ind_linSolve); iniSubject() starts the
  // first record at op->inits
  void solvePass(NumericVector &val) {
    std::fill(solve.begin(), solve.end(), 0.0);
    std::copy(inits.begin(), inits.end(), solve.begin());
    std::fill(infRate.begin(), infRate.end(), 0.0);
    double xp = t[0];
    ind._rxFlag = 1;
    ind.solvedIdx = 0;
    for (int i = 0; i < n; i++) {
      double *yp = solve.data() + (size_t)i*neq;
      if (i > 0) std::copy(yp - neq, yp, yp);
      ind.idx = i;
      bool ssInf = setupSs(i, yp);
      if (t[i] != xp || ss[i] != 0) advance(i, xp, yp, val);
      if (!ssInf) applyDose(i, yp, false);
      ind.doSS = 0;
      ind.linSS = 0;
      xp = t[i];
      ind.solvedIdx = i;
    }
  }

  // rxode2's output pass: the model re-runs on every solved record
  void outputPass(const IntegerMatrix &calls, NumericVector &lhs, NumericMatrix &callOut) {
    ind._rxFlag = 11;
    for (int i = 0; i < n; i++) {
      ind.idx = i;
      lhs[i] = call(i, -1, useB ? -1 : 0);
      for (int k = 0; k < calls.nrow(); k++) {
        callOut(i, k) = call(i, calls(k, 0), useB ? calls(k, 1) : 0);
      }
    }
  }

  NumericMatrix state() const {
    NumericMatrix out(n, neq);
    for (int i = 0; i < n; i++) {
      for (int j = 0; j < neq; j++) out(i, j) = solve[(size_t)i*neq + j];
    }
    return out;
  }
};

static void lcSimCheck(int n, int m, int ncmt, int oral0, IntegerVector doseCmt,
                       NumericVector doseAmt, NumericVector doseRate,
                       NumericMatrix theta, IntegerMatrix calls, NumericVector linH,
                       IntegerVector ss, NumericVector ssTau, NumericVector ssVar,
                       IntegerVector ssCmt, NumericVector inits) {
  // every per-record input has one entry per record
  const R_xlen_t lens[] = {doseCmt.size(), doseAmt.size(), doseRate.size(), ss.size(),
                           ssTau.size(), ssVar.size(), ssCmt.size(), theta.nrow()};
  for (R_xlen_t len : lens) {
    if (len != n) Rcpp::stop("linCmtHostSim: inconsistent inputs");
  }
  bool shape = n >= 1 && ncmt >= 1 && ncmt <= 3 && (oral0 == 0 || oral0 == 1);
  bool dims = theta.ncol() == 7 && calls.ncol() == 2 && linH.size() == 7 &&
    (inits.size() == 0 || inits.size() == m);
  if (!shape || !dims) Rcpp::stop("linCmtHostSim: inconsistent inputs");
  for (int i = 0; i < n; i++) {
    if (doseCmt[i] >= m || ss[i] < 0 || ss[i] > 3) {
      Rcpp::stop("linCmtHostSim: dose or steady state out of range at record %d", i + 1);
    }
  }
}

//' Solve one synthetic subject through linCmtA()/linCmtB() (test hook)
//'
//' Replays rxode2's linear-only solve loop on local stand-ins for its solver
//' structs: each record advances the linear system from the previous record
//' (the model's value call), stores the amounts (and with linCmtB() their
//' sensitivities), then applies the record's dose.  A second pass re-queries
//' every record as rxode2's output pass does.
//'
//' @param t record times (sorted)
//' @param doseCmt linCmt state receiving the record's dose (0 = depot when
//'   oral, else central), or -1 for an observation
//' @param doseAmt bolus amount (0 for none)
//' @param doseRate infusion rate change at the record (0 for none)
//' @param theta numeric matrix, one row of (p1, v1, p2, p3, p4, p5, ka) per
//'   record
//' @param ncmt number of compartments
//' @param oral0 1 for a depot, else 0
//' @param trans parameterization code
//' @param useB `TRUE` for linCmtB() (sensitivities), `FALSE` for linCmtA()
//' @param sensType linCmtB() Jacobian method
//' @param ndiff linCmtB() derivative bit mask (0 = all)
//' @param sensPhi `linCmtSensPhi` control (-1 unset, 0, 1, 2)
//' @param calls integer matrix of extra `(which1, which2)` linCmtB() calls
//'   made after each record's value call in the output pass
//' @param linH finite-difference steps (length 7) for the FD methods
//' @param ss per-record steady-state type (0 none, 1 infinite infusion, 2
//'   repeated infusion, 3 repeated bolus) evaluated at that record
//' @param ssTau,ssVar steady-state interval and infusion duration or bolus
//'   amount per record
//' @param ssCmt steady-state bolus compartment per record
//' @param lagMask,originMask the model's `op->linCmtLagMask` and
//'   `op->linCmtOriginMask`
//' @param hPar,hStep with `hPar >= 0`, an H-perturbed evaluation of parameter
//'   `hPar` by `hStep` (rxode2's step-size probe)
//' @param forwardMax `linCmtForwardMax`: the most points the forward
//'   difference methods use (rxode2's default is 2)
//' @param inits initial amounts of the linCmt states (`op->inits`), length
//'   `ncmt + oral0`, or length 0 for none
//' @return list with `val` (solve pass value per record), `lhs` (output pass
//'   value), `state` (solve buffer, one row per record) and `calls` (output
//'   pass results of `calls`, one row per record)
//' @keywords internal
//' @export
// [[Rcpp::export(.linCmtHostSim)]]
List linCmtHostSim(NumericVector t, IntegerVector doseCmt, NumericVector doseAmt,
                   NumericVector doseRate, NumericMatrix theta, int ncmt, int oral0,
                   int trans, bool useB, int sensType, int ndiff, int sensPhi,
                   IntegerMatrix calls, NumericVector linH, IntegerVector ss,
                   NumericVector ssTau, NumericVector ssVar, IntegerVector ssCmt,
                   int lagMask, int originMask, int hPar, double hStep,
                   int forwardMax, NumericVector inits) {
  int n = t.size();
  int m = ncmt + oral0;
  lcSimCheck(n, m, ncmt, oral0, doseCmt, doseAmt, doseRate, theta, calls, linH,
             ss, ssTau, ssVar, ssCmt, inits);
  lcSim sim;
  sim.t = t; sim.doseCmt = doseCmt; sim.doseAmt = doseAmt; sim.doseRate = doseRate;
  sim.theta = theta; sim.ss = ss; sim.ssTau = ssTau; sim.ssVar = ssVar; sim.ssCmt = ssCmt;
  sim.n = n; sim.ncmt = ncmt; sim.oral0 = oral0; sim.trans = trans; sim.m = m;
  sim.useB = useB; sim.hPar = hPar; sim.hStep = hStep;
  sim.forwardMax = forwardMax;
  // the state width: amounts, then (linCmtB) their sensitivities
  sim.neq = useB ? (m + ncmt*(2*ncmt + oral0) + oral0) : m;
  sim.h.assign(linH.begin(), linH.end());
  sim.ini0.assign(inits.begin(), inits.end());
  sim.fillRecords();
  sim.setupStructs(sensType, ndiff, sensPhi, lagMask, originMask);
  sim.bind();
  NumericVector val(n, NA_REAL), lhs(n, NA_REAL);
  NumericMatrix callOut(n, calls.nrow());
  if (useB && !linCmtSensIsAD(sensType)) {
    // rxode2's step-size setup starts with a base solve with linH zeroed,
    // which resets the kernel's theta scaling for the first subject
    std::vector<double> hKeep = sim.h;
    std::fill(sim.h.begin(), sim.h.end(), 0.0);
    sim.solvePass(val);
    sim.h = hKeep;
    sim.freeInd();
  }
  sim.solvePass(val);
  sim.outputPass(calls, lhs, callOut);
  NumericMatrix state = sim.state();
  sim.unbind();
  return List::create(_["val"] = val, _["lhs"] = lhs, _["state"] = state,
                      _["calls"] = callOut);
}
