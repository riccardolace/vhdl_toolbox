# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Next release...]

### To add

- [math/reciprocal_square_root] folder
- [math/waves] folder

## [2024.03.08]

### Added

**digital signal processing folder**
- filters
  - python
    - genFIRCoeffs.py
    - genSignal.py
    - readSignal.py
  - testbench
    - coeffs_len64_Wl18.txt
    - data_in.txt
    - data_out.txt
    - fir_filter_tb.vhd
  - vhdl
    - fir_filter.vhd
- sample_rate_converter
  - python
    - genFIRCoeffsDecimator.py
    - genFIRCoeffsInterpolator.py
    - genSignal.py
    - readSignal.py
  - testbench
    - coeffs_len128_Wl18_L8.txt
    - coeffs_len128_Wl18_M8.txt
    - data_in.txt
    - data_out.txt
    - fir_decimator_tb.vhd
    - fir_interpolator_tb.vhd
  - vhdl
    - fir_decimator.vhd
    - fir_interpolator.vhd

**math folder**
- arithmetic_operations
  - testbench
    - acc_N_sps_tb.vhd
    - multAdd_tb.vhd
  - vhdl
    - acc_N_sps.vhd
    - c_sum.vhd
    - c_sub.vhd
    - c_mult.vhd
    - mult.vhd
    - multAdd.vhd

**memory folder**
- fifo/testbench
    - axi_fifo_2clk_tb.vhd

### Changed

- Architecture names have been changed from `bhv` to `rtl`.
- Titles and subtitles of README files have been rearranged.


## [2024.03.05]

### Added

**memory folder**

- README.md: rom section has been added.
- rom
  - python
    - genCounter.vhd
  - testbench
    - data_signed.txt
    - data_unsigned.txt
    - rom_slv_tb.vhd
  - vhdl
    - rom_slv.vhd

**TCL script for testbench**
- sim_tb.tcl was created to automatically generate a Vivado project and test the code.

### Changed

- VHDL file comments have been changed.
- pkg_vhdl_toolbox.vhd has been moved from `packages` to `packages/vhdl`.

## [2024.02.20]

### Added

**basic folder**

- README.md
- counter
  - testbench
    - counter_with_hit_tb.vhd
  - vhdl
    - counter_with_hit.vhd
- delay
  - testbench
    - delay_chain_sl_tb.vhd
    - delay_chain_slv_tb.vhd
    - delay_ram_slv_tb.vhd
    - delay_sl_tb.vhd
    - delay_slv_tb.vhd
  - vhdl
    - delay_chain_sl.vhd
    - delay_chain_slv.vhd
    - delay_ram_slv.vhd
    - delay_sl.vhd
    - delay_slv.vhd

**clock_domain_crossing folder**
- README.md
- vhdl
  - cdc_sync.vhd


**math folder**

- README.md
- rounding
  - testbench
    - axi_round_and_clip_slv_tb.vhd
    - round_and_clip_slv_tb.vhd
  - vhdl
    - axi_clip_slv.vhd
    - axi_round_and_clip_slv.vhd
    - axi_round_slv.vhd
    - clip_slv.vhd
    - round_and_clip_slv.vhd
    - round_and_clip.vhd.toTest
    - round_slv.vhd


**memory folder**

- README.md
- fifo
  - vhdl
    - axi_fifo_2clk.vhd
- ram
  - vhdl
    - ram_2clk.vhd


**packages folder**

- pkg_dg.vhdl
