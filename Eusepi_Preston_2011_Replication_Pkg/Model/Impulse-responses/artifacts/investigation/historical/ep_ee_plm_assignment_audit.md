# Historical E&P EE PLM Assignment Audit

Snapshot audited: `08d2f09b97576e43938e67090448222a10b28e3d`.
The paths below are relative to
`112470-V1/AER_replication_files-MS20080712/Model/Simulation-Codes/`.
Both `simulation_codes_Euler_162` and `simulation_codes_Euler_sg_162` were
checked. The former is cited below because the material assignment structure
is the same in both directories.

## Assignment trace

`Model_Simul_Oct_2009.m` identifies consumption as row 12 (line 166), sets
`n_eq=7` (line 203), allocates `OMEGA_0` and `OMEGA_c` (lines 302--304), and
fills them with the RE coefficients returned by
`REDS_SOLDS_Model_Sept_2009.m`/`REE_solve.m`. The latter places the RE
consumption constant and capital coefficient in row 12.

During simulation, every observation supplied to RLS is `Y_var(1:n_eq,t)`
(line 713), its update loop is `1:n_eq` (lines 776--779), and the results are
copied back to `Regressors` over `1:n_eq` (lines 839--842). The two PLM
feedback loops write only `OMEGA_0(1:n_eq)` (lines 865--869) and
`OMEGA_c(1:n_eq,capital)` (lines 874--883). Thus the learned rows are rental return, wage, bond
return, output, hours, utilization, and capital. Row 12 is outside every
write range.

The remaining assignments are:

- zero allocation before RE initialization;
- RE initialization of the complete matrices;
- an impulse-response-only restart assignment at line 469, which is not
  entered by the Table 5 full-simulation call path; and
- end-of-function returned snapshots (`OMEGA_c_ini=OMEGA_c(:,capital)` and
  `OMEGA_0_ini=OMEGA_0`, lines 928--930). These are outputs, not aliases subsequently fed
  back into the Table 5 simulation.

`ALM_fun.m` reads the PLM matrices and returns ALM objects. It neither returns
the PLM matrices nor assigns into them. MATLAB numeric arguments have value
semantics (implemented copy-on-write), so a callee cannot indirectly mutate
the caller's row 12 without returning and reassigning a modified array. No
such return/reassignment exists. `Regressors` is constructed and updated as
simulation data; it is not an alias of either coefficient matrix.

**Conclusion:** on the released executable Table 5 path, consumption row 12
is initialized at RE and cannot change afterward. There is no direct or
indirect assignment capable of updating it.

## Alternate-file audit

The principal blobs in `simulation_codes_Euler_162` are:

| File | Git blob |
|---|---|
| `Model_Simul_Oct_2009.m` | `c9a977937dd03354d7a6ead9302f9fdfac9dd034` |
| `74693.m.ptl` | `c9a977937dd03354d7a6ead9302f9fdfac9dd034` |
| `Model_Simul_Oct_2009.asv` | `02486c3dd9220c2bcbaf9d305907ba912c3e6c04` |
| `ALM_fun.m` | `4d52bad7b8dcd3c2bd87e54c4bf54e7567a22266` |
| `REE_solve.m` | `6441ce33fc9d38dd1d8ffa0951cba81765cfb2da` |
| `REDS_SOLDS_Model_Sept_2009.m` | `002137ae0a560894a901fbe695217fe83330785f` |
| `74695.m.ptl` | `002137ae0a560894a901fbe695217fe83330785f` |
| `results_RBC_162.mat` | `0393f36934e1d1954f39d6517c26f907b21bc3ce` |

The numbered `74693.m.ptl` is byte-identical to the executable simulator and
`74695.m.ptl` is byte-identical to the executable REDS file. The other
numbered PTL files map to the remaining source files by content; none supplies
an alternate consumption-learning feedback loop. Autosaves retain stale
edits (most visibly the lower gain ceiling and a shock-sign difference), but
retain the seven-row RLS structure. The two saved `results_RBC_162.mat`
workspaces contain draw-level moments and summary objects, not time paths of
PLM coefficients that could evidence a separate update.

Git history contains no intervening modification of this assignment structure
between import at `08d2f09` and removal during the later directory cleanup.

## Evidentiary limit

This is strong evidence about every released source, autosave, PTL copy, and
saved workspace in the repository snapshot. It proves the released program's
behavior, but absence of another file is only bounded negative evidence: it
cannot prove that no unreleased final program ever existed.

## Output-volatility scale check

The archived 5,000-draw workspaces reconstruct absolute output volatility of
approximately `1.071`, versus `1.31` in Table 5, while all seven relative and
serial-correlation entries round to their published values. Matching `1.31`
would require multiplying all level volatilities by about `1.223`. The checked
executable/autosave shock-scale and sign differences do not produce that
factor, and a uniform level transformation would leave the relative moments
unchanged but is not documented in the released calculation. The discrepancy
therefore remains unresolved rather than being assigned a speculative cause.
