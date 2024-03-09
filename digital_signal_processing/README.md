Digital Signal Processing
===

- [Digital Signal Processing](#digital-signal-processing)
  - [Filters](#filters)
  - [Sample rate converter](#sample-rate-converter)


## Filters

**Filename** - `fir_filter.vhd`  
This block (fir_filter.vhd) implements a Finite Impulse Response (FIR) filter using a systolic structure for efficient hardware implementation (similar to https://docs.xilinx.com/r/en-US/am004-versal-dsp-engine/Systolic-FIR-Filter). Rounding and saturation logic are included. Future additions will explore symmetric filter structures.  
Additionally, Python code is provided to:
- Generate FIR filter coefficients.
- Generate a test signal for the testbench.
- Analyze the output signal from the testbench.

## Sample rate converter


**Filename** - `fir_interpolator.vhd`, `fir_decimator.vhd`  
These blocks implements **Polyphase FIR Sample Rate Converters** for both FIR interpolation (fir_interpolator.vhd) and decimation (fir_decimator.vhd), leveraging polyphase structures for efficient sample rate conversion (similar to https://docs.xilinx.com/r/en-US/am004-versal-dsp-engine/Interpolating and https://docs.xilinx.com/r/en-US/am004-versal-dsp-engine/Decimating).  
Additionally, Python code is provided for:
- Generating filter coefficients for both interpolators and decimators.
- Generating test signals for the testbenches.
- Analyzing the output signals from the testbenches.