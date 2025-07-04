Digital Signal Processing
===

- [Digital Signal Processing](#digital-signal-processing)
  - [Farrow Filter](#farrow-filter)
  - [Filters](#filters)
  - [Sample rate converter](#sample-rate-converter)

<br>

## Farrow Filter

> <mark>**NOTE**</mark>  
> The VHDL code will be developed in the future.
> Only the functions to generate the coefficients of the FIR filters that compose the Farrow filter are available.

<br>

## Filters

**Filename** - `fir_filter.vhd`  
This block (fir_filter.vhd) implements a Finite Impulse Response (FIR) filter using a systolic structure for efficient hardware implementation (similar to https://docs.xilinx.com/r/en-US/am004-versal-dsp-engine/Systolic-FIR-Filter). Rounding and saturation logic are included. Future additions will explore symmetric filter structures.  
Additionally, Python code is provided to:
- Generate FIR filter coefficients.
- Generate a test signal for the testbench.
- Analyze the output signal from the testbench.

<br>

## Sample rate converter


**Filename** - `fir_interpolator.vhd`, `fir_decimator.vhd`  
These blocks implements **Polyphase FIR Sample Rate Converters** for both FIR interpolation (fir_interpolator.vhd) and decimation (fir_decimator.vhd), leveraging polyphase structures for efficient sample rate conversion (similar to https://docs.xilinx.com/r/en-US/am004-versal-dsp-engine/Interpolating and https://docs.xilinx.com/r/en-US/am004-versal-dsp-engine/Decimating).  
Additionally, Python code is provided for:
- Generating filter coefficients for both interpolators and decimators.
- Generating test signals for the testbenches.
- Analyzing the output signals from the testbenches.