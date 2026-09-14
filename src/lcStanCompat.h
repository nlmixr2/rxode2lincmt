#ifndef RXODE2LINCMT_STAN_COMPAT_H
#define RXODE2LINCMT_STAN_COMPAT_H
/*
 * RcppParallel 6.0.0--6.1.1 shipped no linkable TBB on Windows, so
 * stan-math's ad_tape_observer (stan/math/rev/core/init_chainablestack.hpp)
 * cannot link there.  When configure finds no TBB it strips -DSTAN_THREADS
 * (inst/tools/workaround.R); pre-define that header's guard so the observer
 * never enters the build.  linCmt.cpp creates the main-thread AD tape itself
 * under RXODE2_NO_STAN_TBB_OBSERVER.  Inert when STAN_THREADS is defined.
 */
#if defined(_WIN32) && !defined(STAN_THREADS) && defined(__cplusplus)
#define STAN_MATH_REV_CORE_INIT_CHAINABLESTACK_HPP
#define RXODE2_NO_STAN_TBB_OBSERVER
#endif

#endif
