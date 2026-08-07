# Schema 3 artifact guide

Schema `3.0` is the active, pre-public artifact contract. It deliberately does
not load or migrate schema-2 output. Older files and frozen fixtures remain
useful as numerical references only.

Artifacts are nonexecutable scalar structs. The supported kinds are:

- `single_run`: one primitive simulation;
- `training`: a reusable training result and terminal state;
- `irf`: baseline, shocked, native, reported, and RE responses;
- `training_irf`: separate training and IRF artifacts from `run_case`;
- `case_collection`: compact draw evidence and summaries for one case;
- `comparison`: independently understandable case collections.

Every kind carries explicit identity, dimensions, axes, timing, status, and
provenance. Reporting series carry `id`, `label`, `unit`, and transformation
metadata. Use `describe_artifact` for a concise inspectable description and
`validate_artifact` when accepting an in-memory value from another caller.

## Persistence

```matlab
paths = save_artifact("results/my_study.mat",artifact);
restored = load_artifact(paths.mat);
```

The MAT file is the source of truth and contains exactly one scalar struct
named `artifact`, saved in MATLAB v7.3 format. The JSON sidecar contains only
human-readable metadata and the MAT file's SHA-256 checksum. It intentionally
omits paths, innovations, beliefs, and matrices.

Saving validates before writing and rejects existing files by default:

```matlab
save_artifact("results/my_study.mat",artifact,'Overwrite',true);
```

Loading first inspects the MAT contents, accepts schema `3.0` only, validates
the complete artifact, and checks an existing sidecar. The MAT remains valid
if its sidecar is absent; a present sidecar with a wrong checksum, schema, or
kind raises an integrity error.

Figure and CSV export are deliberately separate from artifact persistence.
