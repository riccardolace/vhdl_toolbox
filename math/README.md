math
===

- [math](#math)
  - [Complex operations](#complex-operations)
  - [Reciprocal Square Root](#reciprocal-square-root)
  - [Rounding](#rounding)
    - [Clip - std\_logic\_vector](#clip---std_logic_vector)
    - [Round - std\_logic\_vector](#round---std_logic_vector)
    - [Round and clip - std\_logic\_vector](#round-and-clip---std_logic_vector)
    - [AXI Clip - std\_logic\_vector](#axi-clip---std_logic_vector)
    - [AXI Round - std\_logic\_vector](#axi-round---std_logic_vector)
    - [AXI Round and clip - std\_logic\_vector](#axi-round-and-clip---std_logic_vector)
  - [Waves](#waves)


## Complex operations


## Reciprocal Square Root


## Rounding

### Clip - std_logic_vector

**Filename** - `clip_slv.vhd`

The block allows you to reduce the size of a `std_logic_vector` saturating it..

<br>

### Round - std_logic_vector

**Filename** - `round_slv.vhd`

The block allows you to implement various rounding logics.


<br>

### Round and clip - std_logic_vector

**Filename** - `round_and_clip_slv.vhd`

The block allows you to round and reduce the size of a `std_logic_vector`.

<br>

### AXI Clip - std_logic_vector

**Filename** - `axi_clip_slv.vhd`

AXI version of the block `clip_slv.vhd`.

<br>

### AXI Round - std_logic_vector

**Filename** - `axi_round_slv.vhd`

AXI version of the block `round_slv.vhd`.

<br>

### AXI Round and clip - std_logic_vector

**Filename** - `axi_round_and_clip_slv.vhd`

AXI block composed of the cascade of `axi_round_slv.vhd` and `axi_clip_slv.vhd`.

<br>

## Waves


