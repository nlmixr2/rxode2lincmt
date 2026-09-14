# Base-R reference solutions for linear compartment models (no rxode2).
# States are ordered as the kernels order them: depot (when oral), central,
# peripheral 1, peripheral 2.

.lcRateMatrix <- function(ncmt, oral0, cl, v, q = 0, vp = 0, q2 = 0, vp2 = 0, ka = 0) {
  .k <- cl / v
  .n <- ncmt + oral0
  .K <- matrix(0, .n, .n)
  .c <- oral0 + 1L
  .K[.c, .c] <- -.k
  if (ncmt >= 2) {
    .p <- .c + 1L
    .K[.c, .c] <- .K[.c, .c] - q / v
    .K[.p, .c] <- q / v
    .K[.c, .p] <- q / vp
    .K[.p, .p] <- -q / vp
  }
  if (ncmt >= 3) {
    .p <- .c + 2L
    .K[.c, .c] <- .K[.c, .c] - q2 / v
    .K[.p, .c] <- q2 / v
    .K[.c, .p] <- q2 / vp2
    .K[.p, .p] <- -q2 / vp2
  }
  if (oral0 == 1L) {
    .K[1, 1] <- -ka
    .K[.c, 1] <- ka
  }
  .K
}

.lcExpm <- function(K, t) {
  .e <- eigen(K)
  Re(.e$vectors %*% diag(exp(.e$values * t), nrow(K)) %*% solve(.e$vectors))
}

# Amounts after `t` from amounts `a0` with constant zero-order rates `r`
.lcAmounts <- function(K, t, a0, r = numeric(nrow(K))) {
  .E <- .lcExpm(K, t)
  .a <- .E %*% a0
  if (any(r != 0)) {
    .a <- .a + solve(K, (.E - diag(nrow(K))) %*% r)
  }
  drop(.a)
}

# Number of carried state values the kernel expects
.lcNalast <- function(ncmt, oral0, deriv) {
  .nstate <- ncmt + oral0
  if (!deriv) {
    return(.nstate)
  }
  .npars <- 2L * ncmt + oral0
  .nstate + ncmt * .npars + oral0
}
