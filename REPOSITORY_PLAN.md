# Repository Inclusion Plan

## Include in GitHub

- `README.md`
- `.gitignore`
- `code/main.m`
- `code/removeNoisyChannels.m`
- `data/README.md`
- `models/README.md`
- `external/README.md`

## Exclude from GitHub

- `CCW.jac` because it is approximately 3.4 GB.
- `CCW1.nirs` because it is raw/experimental fNIRS data and should be stored externally.
- `vol2gm.mat` by default because it is a binary data-derived transform file.
- `MNI152_headModel/` because it is a binary anatomical model resource.
- `iso2mesh-master/` because it is a third-party toolbox.
- ZIP archives and generated MATLAB/image outputs.

## Recommended Public Layout

```text
DOT-and-fNirs-analysis/
├── README.md
├── .gitignore
├── REPOSITORY_PLAN.md
├── code/
│   ├── main.m
│   └── removeNoisyChannels.m
├── data/
│   └── README.md
├── models/
│   └── README.md
└── external/
    └── README.md
```
