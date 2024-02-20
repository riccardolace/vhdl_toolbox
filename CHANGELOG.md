# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Next release...]

### To add ...

- [math/complex_operations] folder
- [math/reciprocal_square_root] folder
- [math/waves] folder
- [memory/rom] folder

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
