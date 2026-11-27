# linCmtModelHess() against a 60-digit mpmath reference (fixtures/README.md):
# the central concentration's value, gradient and Hessian for 1-3
# compartments, bolus / infusion / oral, single dose and steady state.
#
# The generic cases are held to the closed forms' accuracy; the confluent ones
# -- ka within 1% of a disposition rate, a near-zero elimination, a
# near-double root -- go through the generator exponential (#18) and are held
# to their own (looser on the steady-state Hessian, which solves
# (I - exp(A tau)) x = d).

.mpmathCases <- function() {
  .ref <- readLines(test_path("fixtures", "closed_form_mpmath.txt"))
  .ref <- .ref[nzchar(trimws(.ref))]
  .num <- function(s) as.numeric(strsplit(s, ",", fixed = TRUE)[[1]])
  lapply(.ref, function(l) {
    f <- strsplit(l, ";", fixed = TRUE)[[1]]
    list(
      kind = f[1],
      p = .num(f[2]),
      t = as.numeric(f[3]),
      ii = as.numeric(f[4]),
      dur = as.numeric(f[5]),
      value = as.numeric(f[6]),
      grad = .num(f[7]),
      hess = .num(f[8])
    )
  })
}

.mpmathShape <- function(kind) {
  list(
    ncmt = as.integer(sub("^[a-z]+([123]).*$", "\\1", kind)),
    oral0 = as.integer(startsWith(kind, "oral")),
    ss = endsWith(kind, "ss"),
    inf = startsWith(kind, "inf")
  )
}

.mpmathConfluent <- function(cs) {
  sh <- .mpmathShape(cs$kind)
  p <- cs$p
  k <- p[1] / p[2]
  lam <- if (sh$ncmt == 1) {
    k
  } else {
    k12 <- p[3] / p[2]
    k21 <- p[3] / p[4]
    gen <- if (sh$ncmt == 2) {
      matrix(c(-(k + k12), k12, k21, -k21), 2)
    } else {
      k13 <- p[5] / p[2]
      k31 <- p[5] / p[6]
      matrix(c(-(k + k12 + k13), k12, k13, k21, -k21, 0, k31, 0, -k31), 3)
    }
    -Re(eigen(gen, only.values = TRUE)$values)
  }
  near <- min(lam) * cs$t < 1e-4
  if (sh$oral0) {
    near <- near || any(abs(p[2 * sh$ncmt + 1] - lam) / lam < 1e-2)
  }
  if (sh$ncmt == 3) {
    near <- near || min(abs(diff(sort(lam))) / max(lam)) < 1e-3
  }
  near
}

# value / gradient / Hessian of the central concentration at the case's time
.mpmathEval <- function(cs) {
  sh <- .mpmathShape(cs$kind)
  m <- sh$ncmt + sh$oral0
  n <- 2 * sh$ncmt + sh$oral0
  pp <- c(cs$p, rep(0, 7))
  ka <- if (sh$oral0) cs$p[n] else 0
  .step <- function(st, dt, rate = rep(0, m), type = 0L, tau = 0, tinf = 0, amt = 0) {
    linCmtModelHess(
      dt,
      pp[1],
      pp[2],
      if (sh$ncmt >= 2) pp[3] else 0,
      if (sh$ncmt >= 2) pp[4] else 0,
      if (sh$ncmt >= 3) pp[5] else 0,
      if (sh$ncmt >= 3) pp[6] else 0,
      ka,
      st$alast,
      st$H,
      rate,
      sh$ncmt,
      sh$oral0,
      1L,
      type = type,
      tau = tau,
      tinf = tinf,
      amt = amt,
      bolusCmt = 0L
    )
  }
  .nx <- function(r) list(alast = r$Alast, H = as.vector(r$H))
  st <- list(alast = rep(0, m + sh$ncmt * n + sh$oral0), H = rep(0, m * n * n))
  rt <- rep(0, m)
  if (sh$inf) {
    rt[1] <- 100 / cs$dur
  }
  .infusion <- function(st) {
    if (cs$t <= cs$dur) {
      .step(st, cs$t, rt)
    } else {
      .step(.nx(.step(st, cs$dur, rt)), cs$t - cs$dur)
    }
  }
  if (sh$ss && !sh$inf) {
    # the steady-state bolus kernel returns the state at the dose, dose included
    .step(.nx(.step(st, 0, type = 3L, tau = cs$ii, amt = 100)), cs$t)
  } else if (sh$ss) {
    # the steady-state infusion kernel returns the trough at the infusion start
    .infusion(.nx(.step(st, 0, rt, type = 2L, tau = cs$ii, tinf = cs$dur)))
  } else if (sh$inf) {
    .infusion(st)
  } else {
    st$alast[1] <- 100
    .step(st, cs$t)
  }
}

.relErr <- function(got, want) max(abs(got - want)) / max(abs(want))

test_that("linCmtModelHess matches the 60-digit reference away from confluence", {
  cases <- .mpmathCases()
  generic <- Filter(function(cs) !.mpmathConfluent(cs), cases)
  expect_gte(length(generic), 25)
  kinds <- unique(vapply(generic, `[[`, "", "kind"))
  # every model shape, steady state included, is covered
  expect_true(all(
    c("bolus2", "bolus3", "inf1", "inf2", "inf3", "oral1", "oral2", "oral3", "oral1ss", "oral2ss", "oral3ss") %in% kinds
  ))
  for (cs in generic) {
    r <- .mpmathEval(cs)
    n <- length(cs$p)
    ut <- unlist(lapply(seq_len(n), function(i) r$Hc[i, i:n]))
    expect_lt(.relErr(r$val, cs$value), 1e-11)
    expect_lt(.relErr(as.vector(r$Jg)[seq_len(n)], cs$grad), 1e-10)
    expect_lt(.relErr(ut, cs$hess), 1e-7)
  }
})

test_that("the steady-state infusion kernel matches repeated dosing", {
  for (cfg in list(list("inf1ss", c(1, 10)), list("inf2ss", c(2, 10, 3, 30)))) {
    cs <- list(kind = cfg[[1]], p = cfg[[2]], t = 5, ii = 12, dur = 2)
    ss <- .mpmathEval(cs)
    sh <- .mpmathShape(cs$kind)
    m <- sh$ncmt
    n <- 2 * sh$ncmt
    pp <- c(cs$p, rep(0, 7))
    .step <- function(st, dt, rate) {
      linCmtModelHess(dt, pp[1], pp[2], pp[3], pp[4], 0, 0, 0, st$alast, st$H, rate, sh$ncmt, 0L, 1L)
    }
    .nx <- function(r) list(alast = r$Alast, H = as.vector(r$H))
    st <- list(alast = rep(0, m + sh$ncmt * n), H = rep(0, m * n * n))
    rt <- c(100 / cs$dur, rep(0, m - 1))
    for (i in seq_len(150)) {
      st <- .nx(.step(.nx(.step(st, cs$dur, rt)), cs$ii - cs$dur, rep(0, m)))
    }
    md <- .step(.nx(.step(st, cs$dur, rt)), cs$t - cs$dur, rep(0, m))
    expect_lt(.relErr(ss$val, md$val), 1e-12)
    expect_lt(.relErr(ss$Hc, md$Hc), 1e-10)
  }
})

test_that("linCmtModelHess matches the 60-digit reference at confluence (#18)", {
  conf <- Filter(.mpmathConfluent, .mpmathCases())
  expect_gte(length(conf), 100)
  for (cs in conf) {
    r <- .mpmathEval(cs)
    n <- length(cs$p)
    ut <- unlist(lapply(seq_len(n), function(i) r$Hc[i, i:n]))
    expect_true(all(is.finite(ut)))
    expect_lt(.relErr(r$val, cs$value), 1e-10)
    expect_lt(.relErr(as.vector(r$Jg)[seq_len(n)], cs$grad), 1e-9)
    expect_lt(.relErr(ut, cs$hess), 1e-6)
  }
})
