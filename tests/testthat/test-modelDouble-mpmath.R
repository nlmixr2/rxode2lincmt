# linCmtModelDouble() (value and first derivatives) against a 60-digit
# mpmath reference (fixtures/README.md), including the confluences of the
# time-propagation solutions: an absorption rate equal or close to a
# disposition rate, and a near-zero elimination over the step.  Their
# quotients (E - Ea)/(ka - L) and (1 - E)/L are 0/0 at the confluence and
# cancel near it.
#
# Not covered here (nlmixr2/rxode2lincmt#18): confluences of the steady-state
# solutions and of the two and three compartment eigendecompositions.

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

# value and gradient of the central concentration (single dose of 100 at 0)
.mpmathFirst <- function(cs) {
  sh <- .mpmathShape(cs$kind)
  m <- sh$ncmt + sh$oral0
  n <- 2 * sh$ncmt + sh$oral0
  pp <- c(cs$p, rep(0, 7))
  ka <- if (sh$oral0) cs$p[n] else 0
  mask <- as.integer(c(6L, 30L, 126L)[sh$ncmt] + sh$oral0)
  .step <- function(alast, dt, rate) {
    linCmtModelDouble(dt, pp[1], pp[2], if (sh$ncmt >= 2) pp[3] else 0,
                      if (sh$ncmt >= 2) pp[4] else 0, if (sh$ncmt >= 3) pp[5] else 0,
                      if (sh$ncmt >= 3) pp[6] else 0, ka, alast, rate,
                      sh$ncmt, sh$oral0, 1L, TRUE, 0L, 0, 0, 0, 0L, mask, 3L)
  }
  a0 <- rep(0, m + sh$ncmt * n + sh$oral0)
  if (sh$inf) {
    rt <- c(100 / cs$dur, rep(0, m - 1))
    if (cs$t <= cs$dur) {
      return(.step(a0, cs$t, rt))
    }
    r <- .step(a0, cs$dur, rt)
    return(.step(r$Alast, cs$t - cs$dur, rep(0, m)))
  }
  a0[1] <- 100
  .step(a0, cs$t, rep(0, m))
}

.relErr <- function(got, want) max(abs(got - want)) / max(abs(want))

test_that("linCmtModelDouble is accurate at and near the propagation confluences", {
  # the kinds whose only confluence is in the propagation tails
  kinds <- c("oral1", "oral2", "oral3", "inf1", "bolus2")
  cases <- Filter(function(cs) cs$kind %in% kinds, .mpmathCases())
  expect_gte(length(cases), 80)
  for (cs in cases) {
    r <- .mpmathFirst(cs)
    n <- length(cs$p)
    expect_true(is.finite(r$val))
    expect_lt(.relErr(r$val, cs$value), 1e-10)
    expect_lt(.relErr(as.vector(r$Jg)[seq_len(n)], cs$grad), 1e-9)
  }
})
