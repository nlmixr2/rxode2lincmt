# lincmt_1cmt_focei.R -- FOCEi cost of a one-compartment linCmt() model
# against the same model written as an ODE (rxode2lincmt#2).
#
#   R_LIBS=~/R/lib-lincmt-dev ROUTE=bolus REPS=3 \
#     taskset -c <idle core> Rscript bench/lincmt_1cmt_focei.R
#
# ROUTE is bolus, infusion or oral.  Each arm is fitted with a fixed number
# of outer iterations (ITER, default 20), so the time is the per-evaluation
# cost and not the optimizer's path; "posthoc" is the inner problems alone.
suppressMessages({
  library(rxode2)
  library(nlmixr2est)
})
setRxThreads(1L)

route <- Sys.getenv("ROUTE", "bolus")
nRep <- as.integer(Sys.getenv("REPS", "3"))
nIter <- as.integer(Sys.getenv("ITER", "20"))
nSub <- as.integer(Sys.getenv("NSUB", "100"))

simTimes <- c(0.25, 0.5, 1, 2, 4, 6, 8, 12, 16, 24)
doseTimes <- c(0, 24, 48)
obsTimes <- sort(unique(c(outer(simTimes, doseTimes, "+"))))

set.seed(42)
oral <- route == "oral"
trueTheta <- if (oral) c(ka = 1.2, cl = 4, v = 30) else c(cl = 4, v = 30)
etaNm <- names(trueTheta)
eta <- matrix(rnorm(nSub * length(etaNm), 0, 0.3), nSub, dimnames = list(NULL, etaNm))
pars <- as.data.frame(sweep(exp(eta), 2, trueTheta, "*"))

doseCmt <- if (oral) "depot" else "central"
odeLines <- if (oral) {
  "d/dt(depot) = -ka*depot\nd/dt(central) = ka*depot - cl/v*central"
} else {
  "d/dt(central) = -cl/v*central"
}
simMod <- rxode2(paste0(odeLines, "\ncp = central/v"))
ev <- et(amt = 100, cmt = doseCmt, time = doseTimes,
         dur = if (route == "infusion") 1 else 0) |> et(obsTimes)
sim <- rxSolve(simMod, pars, ev, cores = 1L, addDosing = FALSE)
set.seed(43)
obs <- data.frame(ID = sim$sim.id, TIME = sim$time,
                  DV = sim$cp * (1 + rnorm(nrow(sim), 0, 0.15)),
                  AMT = 0, RATE = 0, EVID = 0, CMT = "central")
dose <- expand.grid(TIME = doseTimes, ID = seq_len(nSub))
dose <- data.frame(ID = dose$ID, TIME = dose$TIME, DV = NA_real_, AMT = 100,
                   RATE = if (route == "infusion") 100 else 0, EVID = 1,
                   CMT = doseCmt)
dat <- rbind(dose, obs)
dat <- dat[order(dat$ID, dat$TIME, -dat$EVID), ]

iniTxt <- paste(c(sprintf("l%s <- log(%.6g)", etaNm, trueTheta * 1.2),
                  sprintf("eta.%s ~ 0.1", etaNm), "prop.sd <- 0.2"),
                collapse = "\n")
parTxt <- paste(sprintf("%s <- exp(l%s + eta.%s)", etaNm, etaNm, etaNm),
                collapse = "\n")
mkUi <- function(body) {
  eval(parse(text = sprintf(
    "function() {\nini({\n%s\n})\nmodel({\n%s\n%s\ncp ~ prop(prop.sd)\n})\n}",
    iniTxt, parTxt, body)))
}
uiLin <- mkUi("cp <- linCmt()")
uiOde <- mkUi(paste0(odeLines, "\ncp <- central/v"))

ctl <- function(it) {
  foceiControl(calcTables = FALSE, print = 0L, covMethod = "",
               maxOuterIterations = it,
               rxControl = rxControl(cores = 1L))
}
fitSec <- function(ui, it) {
  t0 <- proc.time()[["elapsed"]]
  fit <- suppressWarnings(suppressMessages(nlmixr2(ui, dat, "focei", ctl(it))))
  c(sec = proc.time()[["elapsed"]] - t0, objf = fit$objective)
}
# ARMS / WHAT (comma separated) pick the arms and stages; ARMS="" only
# sets up the data and models (for sourcing).
arms <- strsplit(Sys.getenv("ARMS", "linCmt,ode"), ",")[[1]]
whats <- strsplit(Sys.getenv("WHAT", "posthoc,fit"), ",")[[1]]
res <- NULL
for (arm in arms) {
  ui <- if (arm == "linCmt") uiLin else uiOde
  invisible(fitSec(ui, 0L)) # warm-up: compiles
  for (what in whats) {
    it <- if (what == "posthoc") 0L else nIter
    z <- vapply(seq_len(nRep), function(i) fitSec(ui, it), numeric(2))
    res <- rbind(res, data.frame(route = route, arm = arm, what = what,
                                 sec = min(z["sec", ]),
                                 objf = z["objf", 1]))
  }
}
if (!is.null(res)) print(res)
if (all(c("linCmt", "ode") %in% arms)) {
  w <- reshape(res[, c("arm", "what", "sec")], idvar = "what",
               timevar = "arm", direction = "wide")
  w$ratio <- w$sec.linCmt / w$sec.ode
  print(w)
}
