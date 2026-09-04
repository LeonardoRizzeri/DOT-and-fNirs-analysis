# DOT and fNIRS Analysis

MATLAB workflow for diffuse optical tomography (DOT) reconstruction and functional near-infrared spectroscopy (fNIRS) analysis on a checkerboard stimulation dataset. The project compares hemodynamic reconstructions obtained with and without short-separation (SS) channel regression using an MNI152 head model, volumetric/surface grey-matter meshes, and a precomputed Jacobian.

## Project Overview

This analysis focuses on the effect of short-separation regression on fNIRS/DOT image reconstruction. The pipeline loads raw continuous-wave fNIRS data, performs channel quality control, converts intensity measurements to optical density and hemoglobin concentration changes, estimates the hemodynamic response function (HRF) with a GLM, and reconstructs HbO/HbR maps on a grey-matter surface mesh.

Main processing steps:

1. Load MNI152 volumetric, scalp, and grey-matter surface meshes.
2. Visualize the 3D optode array, including sources, detectors, and measurement channels.
3. Compute source-detector distances and identify short/long separation structure.
4. Reject noisy channels based on signal-to-noise ratio.
5. Convert raw intensity to optical density.
6. Apply wavelet motion correction and temporal band-pass filtering.
7. Convert optical density to HbO/HbR concentration changes.
8. Estimate HRFs with and without short-separation regression.
9. Display array sensitivity over the volumetric grey-matter mesh.
10. Reconstruct DOT HbO/HbR maps and compare SS vs noSS reconstructions by spatial correlation.

## Repository Structure

```text
DOT-and-fNirs-analysis/
├── README.md
├── .gitignore
│
├── code/
│   ├── main.m
│   └── removeNoisyChannels.m
│
├── data/
│   └── README.md
│
├── models/
│   └── README.md
│
└── external/
    └── README.md
```

## Data and Large Files

The complete local project contains several binary resources that should not be committed directly to GitHub:

| File or directory | Size | GitHub decision | Reason |
|---|---:|---|---|
| `code/main.m` | ~17 KB | Include | Core MATLAB analysis script |
| `code/removeNoisyChannels.m` | <1 KB | Include | Channel quality-control helper |
| `CCW1.nirs` | ~48 MB | Exclude from Git; store externally | Experimental fNIRS data; acceptable size technically, but better treated as data |
| `CCW.jac` | ~3.4 GB | Exclude from Git | Far above practical GitHub repository size; precomputed model/data artifact |
| `vol2gm.mat` | ~1.8 MB | Optional external data | Binary transform matrix needed for reconstruction |
| `MNI152_headModel/` | ~26 MB zipped | Exclude from Git; document setup | Anatomical model resource |
| `iso2mesh-master/` | ~30 MB zipped | Exclude from Git; install from source | Third-party dependency, should not be vendored |

For reproducibility, place local resources in the following structure after cloning:

```text
data/
├── CCW1.nirs
├── CCW.jac
└── vol2gm.mat

models/
└── MNI152_headModel/
    ├── 10-5_Points.txt
    ├── GMSurfaceMesh.mat
    ├── HeadVolumeMesh.mat
    ├── LandmarkPoints.txt
    ├── ScalpSurfaceMesh.mat
    ├── TissueMask.mat
    └── TissueTypes.txt

external/
└── iso2mesh-master/
```

## Requirements

- MATLAB
- Homer/Homer2-style fNIRS functions:
  - `hmrMotionCorrectWavelet`
  - `hmrBandpassFilt`
  - `hmrOD2Conc`
  - `hmrDeconvHRF_DriftSS`
  - `hmrConc2OD`
  - `GetExtinctions`
- iso2mesh for mesh visualization and processing, especially `plotmesh`
- MNI152 DOT/fNIRS head model files listed above
- Precomputed Jacobian file `CCW.jac`

## How to Run

1. Clone this repository.
2. Download or copy the required data/model files into `data/`, `models/`, and `external/` as shown above.
3. Open MATLAB from the repository root.
4. Run:

```matlab
run("code/main.m")
```

The script automatically adds `code/` and `external/` to the MATLAB path.

## Notes

The repository intentionally tracks only source code and documentation. Large `.jac`, `.nirs`, `.mat`, anatomical mesh, and external toolbox files are excluded through `.gitignore` to keep the GitHub repository lightweight, readable, and suitable for public presentation.
