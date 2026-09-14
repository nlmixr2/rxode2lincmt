#' Micro-constants of a linear compartment model
#'
#' Converts one parameter set, in any of the `linCmt()` parameterizations, to
#' the central volume and micro-constants that the analytic solutions use.
#'
#' Supported `trans` values: one compartment 1 (`cl`, `v`), 2 (`k`, `v`), 10
#' (`alpha`, `A` with `v1` holding `A`), 11 (`alpha`, `v`); two compartments 1
#' (`cl`, `v`, `q`, `vp`), 2 (`k`, `v`, `k12`, `k21`), 3 (`cl`, `v`, `q`,
#' `vss`), 4 (`alpha`, `beta`, `k21`), 5 (`alpha`, `beta`, `aob`), 10, 11;
#' three compartments 1 (`cl`, `v`, `q`, `vp`, `q2`, `vp2`), 2 (`k`, `v`,
#' `k12`, `k21`, `k13`, `k31`), 10, 11.
#'
#' @param p1 first parameter (for example clearance or `k`)
#' @param v1 central volume (or its parameterization-specific counterpart)
#' @param p2 second parameter (two and three compartments)
#' @param p3 third parameter (two and three compartments)
#' @param p4 fourth parameter (three compartments)
#' @param p5 fifth parameter (three compartments)
#' @param ncmt number of compartments, 1 to 3
#' @param trans parameterization number (see Details)
#' @return named numeric vector: `v`, `k`, and for two or more compartments
#'   `k12`, `k21`, and for three compartments `k13`, `k31`
#' @export
#' @author Matthew L. Fidler
#' @examples
#' linCmtMicros(p1 = 2, v1 = 20, ncmt = 1)
#' linCmtMicros(p1 = 2, v1 = 20, p2 = 3, p3 = 40, ncmt = 2)
linCmtMicros <- function(p1, v1, p2 = 0, p3 = 0, p4 = 0, p5 = 0, ncmt, trans = 1L) {
  checkmate::assertIntegerish(ncmt, lower = 1, upper = 3, len = 1, any.missing = FALSE)
  .valid <- list(c(1L, 2L, 10L, 11L), c(1L, 2L, 3L, 4L, 5L, 10L, 11L), c(1L, 2L, 10L, 11L))[[ncmt]]
  checkmate::assertIntegerish(trans, len = 1, any.missing = FALSE)
  checkmate::assertChoice(as.integer(trans), .valid)
  checkmate::assertNumber(p1, finite = TRUE)
  checkmate::assertNumber(v1, finite = TRUE)
  checkmate::assertNumber(p2, finite = TRUE)
  checkmate::assertNumber(p3, finite = TRUE)
  checkmate::assertNumber(p4, finite = TRUE)
  checkmate::assertNumber(p5, finite = TRUE)
  .m <- .Call(`_rxode2lincmt_macros2micros`, as.double(p1), as.double(v1),
              as.double(p2), as.double(p3), as.double(p4), as.double(p5),
              as.integer(trans), as.integer(ncmt))
  .ret <- as.vector(t(.m))
  names(.ret) <- c("v", "k", "k12", "k21", "k13", "k31")[seq_len(2L * ncmt)]
  .ret
}
