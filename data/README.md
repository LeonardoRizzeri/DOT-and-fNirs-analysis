# Data

This directory is reserved for local fNIRS/DOT data files required by the analysis.

Expected local files:

| File | Description | Repository policy |
|---|---|---|
| `CCW1.nirs` | Continuous-wave fNIRS recording used by the processing pipeline | Not tracked |
| `CCW.jac` | Precomputed Jacobian for DOT reconstruction | Not tracked; very large |
| `vol2gm.mat` | Mapping matrix from volumetric mesh nodes to grey-matter surface nodes | Not tracked by default |

These files are excluded from GitHub because they are binary data/model artifacts. Keep them in this folder locally before running `code/main.m`.
