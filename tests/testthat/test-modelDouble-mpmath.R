# linCmtModelDouble() (value and first derivatives) against a 60-digit
# mpmath reference (fixtures/README.md): every case, the confluences
# included.  At a confluence the closed forms divide by differences of rates
# -- ka and a disposition rate (time propagation and steady state), two
# disposition rates (a near-double root), or every rate times a short step
# (a slow system) -- which are 0/0 there and cancel near it.  The
# propagation quotients are evaluated through a series inside their band;
# the steady states and the eigen bands through the compartment generator.

.mpmathCases <- function() {
  .ref <- readLines(test_path("fixtures", "closed_form_mpmath.txt"))
  .ref <- .ref[nzchar(trimws(.ref))]
  .num <- function(s) as.numeric(strsplit(s, ",", fixed = TRUE)[[1]])
  lapply(.ref, function(l) {
    f <- strsplit(l, ";", fixed = TRUE)[[1]]
    list(kind = f[1], p = .num(f[2]), t = as.numeric(f[3]), ii = as.numeric(f[4]),
         dur = as.numeric(f[5]), value = as.numeric(f[6]), grad = .num(f[7]))
  })
}

.mpmathShape <- function(kind) {
  list(ncmt = as.integer(sub("^[a-z]+([123]).*$", "\\1", kind)),
       oral0 = as.integer(startsWith(kind, "oral")),
       ss = endsWith(kind, "ss"), inf = startsWith(kind, "inf"))
}

# value and gradient of the central concentration (dose of 100 at 0); the
# steady-state bolus kernel returns the state at the dose, dose included, the
# steady-state infusion kernel the trough at the infusion start
.mpmathFirst <- function(cs) {
  sh <- .mpmathShape(cs$kind)
  m <- sh$ncmt + sh$oral0
  n <- 2 * sh$ncmt + sh$oral0
  pp <- c(cs$p, rep(0, 7))
  ka <- if (sh$oral0) cs$p[n] else 0
  mask <- as.integer(c(6L, 30L, 126L)[sh$ncmt] + sh$oral0)
  .step <- function(alast, dt, rate, type = 0L, tau = 0, tinf = 0, amt = 0) {
    linCmtModelDouble(dt, pp[1], pp[2], if (sh$ncmt >= 2) pp[3] else 0,
                      if (sh$ncmt >= 2) pp[4] else 0, if (sh$ncmt >= 3) pp[5] else 0,
                      if (sh$ncmt >= 3) pp[6] else 0, ka, alast, rate,
                      sh$ncmt, sh$oral0, 1L, TRUE, type, tau, tinf, amt, 0L, mask, 3L)
  }
  a0 <- rep(0, m + sh$ncmt * n + sh$oral0)
  z <- rep(0, m)
  rt <- z
  if (sh$inf) rt[1] <- 100 / cs$dur
  .infusion <- function(a) {
    if (cs$t <= cs$dur) {
      return(.step(a, cs$t, rt))
    }
    .step(.step(a, cs$dur, rt)$Alast, cs$t - cs$dur, z)
  }
  if (sh$ss && !sh$inf) {
    return(.step(.step(a0, 0, z, 3L, cs$ii, 0, 100)$Alast, cs$t, z))
  }
  if (sh$ss) {
    return(.infusion(.step(a0, 0, rt, 2L, cs$ii, cs$dur)$Alast))
  }
  if (sh$inf) {
    return(.infusion(a0))
  }
  a0[1] <- 100
  .step(a0, cs$t, z)
}

.relErr <- function(got, want) max(abs(got - want)) / max(abs(want))

test_that("linCmtModelDouble matches the 60-digit reference on every case, confluences included", {
  cases <- .mpmathCases()
  expect_equal(length(cases), 155)
  for (cs in cases) {
    r <- .mpmathFirst(cs)
    n <- length(cs$p)
    expect_true(is.finite(r$val))
    expect_lt(.relErr(r$val, cs$value), 1e-10)
    expect_lt(.relErr(as.vector(r$Jg)[seq_len(n)], cs$grad), 1e-9)
  }
})
