# Farrow Filter (VHDL Implementation)

> <mark>**NOTE**</mark><br>
> The VHDL code will be developed in the future.
> Only the functions to generate the coefficients of the FIR filters that compose the Farrow filter are available.

This repository contains the code needed to implement a **Farrow filter**, a flexible and efficient structure for fractional delay filtering and sample rate conversion in digital signal processing.
The Farrow filter is a structure composed of FIR filters whose coefficients can be estimated by different methods. In this repository, two methods are implemented:
- Lagrange
- Weighted Least Square (WLS)
For each method, MATLAB or Python scripts are provided to generate the filter coefficients and to plot the magnitude, phase, and group delay responses. The code includes documentation on how to modify the Farrow filter configuration, such as the number of FIR sub-filters and the number of coefficients per sub-filter.

The report [Theory](Theory.md) is provided to understand how to create a Farrow filter.

## Project Overview

- **Goal:** Develop a parameterizable Farrow filter in VHDL.
- **Applications:** Sample rate conversion, interpolation, and fractional delay filtering.
- **Status:** Initial setup. VHDL code will be added soon.

## Getting Started

1. Clone this repository.
2. Check back for updates as VHDL code and documentation are developed.

---

*Contributions and suggestions are welcome!*