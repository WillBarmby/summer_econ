# Frozen legacy IRF boundary

`run_legacy_irf` is the only supported entrypoint for the historical
workspace-driven IRF workflow. It deliberately contains the workspace adapter
needed by `Main_imp_resp_Sept_2009.m`; new research code must not depend on
those variables directly.

The historical numerical implementation remains in the adjacent model,
generation, and Common files so existing characterization fixtures stay
executable. The compatibility harness is the only normal caller of this
adapter. Do not add this directory to the general MATLAB path except through
`setup_ir_paths`.
