# MATLAB Tools for Plasmonic Electrochemical Microscopy (PEM)

This repository provides a suite of MATLAB tools developed for **plasmonic electrochemical microscopy (PEM)** data analysis.  
The codes support image-based quantification and visualization of electrochemical activity.  
They were developed by the **Wang Research Group** in the Department of Chemistry and Biochemistry at **California State University, Los Angeles**.

---

## Overview

Plasmonic electrochemical microscopy (PEM) enables spatially resolved mapping of electrochemical processes through optical detection of refractive-index or potential-induced changes at electrode surfaces.  
The MATLAB scripts in this repository streamline post-acquisition processing and data visualization, facilitating reproducible and quantitative analysis of PEM datasets for electrochemical and bioanalytical research.

---

## Contents

### Core MATLAB Scripts

| Script | Function |
|--------|-----------|
| **`Load_Image_Stack_Smoothing_Derivative.m`** | Loads multi-frame image stacks, applies smoothing, and computes time derivatives. |
| **`resonanAnglefromImageStack.m` / `resonanAnglefromRealtime.m`** | Retrieve resonance-angle information from recorded images or live data streams. |
| **`Impedance.m`** | Calculates impedance magnitude and phase from voltage, current, and optical signals. |
| **`Formal_Potential.m`** | Determines the formal potential (E⁰′) from cyclic voltammetry data. |
| **`PlotCV.m`** | Select regions of interest and extract cyclic voltammetry plots with adjustable labels and color schemes. |
| **`SaveVideo.m`** | Exports processed image sequences or resonance-angle maps to video files for presentation and publication. |

## System Requirements

- **MATLAB:** R2019b or later (recommended)
- **Toolboxes:** Image Processing and Signal Processing Toolboxes are recommended for stack handling, filtering, and derivative operations.
- **Supported file formats:** TIFF image stacks; `.xlsx` output formats for numerical results.

---
