# Read (and optionally reset) the amortized linCmt() sequential counters

Read (and optionally reset) the amortized linCmt() sequential counters

## Usage

``` r
.linCmtSeqStats(reset = FALSE)
```

## Arguments

- reset:

  logical; when TRUE zero the counters after reading

## Value

named integer vector: windows (window-constant recomputations),
seqTailRows (rows evaluated from the window's dt-dependent tail),
seqFullRows (rows that fell back to the full forward evaluator),
valueCompute (value executions that solved the row), valueRestore (value
executions that restored an already-solved row), memoHit (value
executions short-circuited by the last-row memo), valueLite
(already-solved value re-executions served by the thin fx-plus-scaling
path with the Jacobian restore skipped), expBuild (delta-keyed
exponential-memo builds: one per distinct row gap per theta window),
expHit (rows whose exponentials came from the delta memo; disable with
RX_LINCMT_DELTA_MEMO=off), expSolo (of those builds, the ones that went
to the within-row slot the guard keeps serving after it stops
speculating), dualRows (rows whose tail took one multi-direction pass,
linCmtSensType="ADm"), phiAnalyticRows (rows propagated through the
closed-form transition matrix; RX_LINCMT_PHI=2)
