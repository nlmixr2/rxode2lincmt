#ifndef RXODE2LINCMT_STAN_COMPAT_H
#define RXODE2LINCMT_STAN_COMPAT_H
/*
 * Keep stan-math's TBB ad_tape_observer (stan/math/rev/core/
 * init_chainablestack.hpp) out of the build: it is the only code here that
 * needs the TBB library, and loading TBB is what CRAN's gcc-UBSAN check
 * reports.  linCmt.cpp creates the loading thread's AD tape under
 * RXODE2_NO_STAN_TBB_OBSERVER and linCmtRevTapeInit() any other thread's, so
 * -DSTAN_THREADS and the numerics are unchanged.
 */
#ifdef __cplusplus
#define STAN_MATH_REV_CORE_INIT_CHAINABLESTACK_HPP
#define RXODE2_NO_STAN_TBB_OBSERVER
/*
 * reduce_sum and map_rect (unused here) include TBB's partitioner.h, whose
 * non-inline static functions call into libtbb.  Unoptimized builds (-O0:
 * load_all(), covr) keep them and would then fail to load without libtbb.
 */
#define STAN_MATH_PRIM_FUNCTOR_REDUCE_SUM_HPP
#define STAN_MATH_PRIM_FUNCTOR_REDUCE_SUM_STATIC_HPP
#define STAN_MATH_REV_FUNCTOR_REDUCE_SUM_HPP
#define STAN_MATH_REV_FUNCTOR_MAP_RECT_CONCURRENT_HPP
#endif

#endif
