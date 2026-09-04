# Models

This directory is reserved for the MNI152 head model required by the DOT/fNIRS reconstruction workflow.

Expected local structure:

```text
models/
└── MNI152_headModel/
    ├── 10-5_Points.txt
    ├── GMSurfaceMesh.mat
    ├── HeadVolumeMesh.mat
    ├── LandmarkPoints.txt
    ├── ScalpSurfaceMesh.mat
    ├── TissueMask.mat
    └── TissueTypes.txt
```

The head model files are not tracked in Git because they are binary resources. Copy or extract them locally before running the MATLAB script.
