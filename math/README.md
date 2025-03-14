Math
===

- [Math](#math)
  - [Arithmetic operations](#arithmetic-operations)
    - [Complex operations](#complex-operations)
    - [Real operations](#real-operations)
  - [Natural Logarithm](#natural-logarithm)
  - [Reciprocal Square Root](#reciprocal-square-root)
  - [Rounding](#rounding)
  - [Square Root](#square-root)
  - [Waves](#waves)

## Arithmetic operations

### Complex operations

**Filename** - `c_sum.vhd`, `c_sub.vhd`, `c_mult.vhd`  
Blocks perform operations such as complex addition, complex subtraction, and complex multiplication.  
Complex addition and subtraction have a latency of 1 clock cycle, while complex multiplication has a latency of 2 clock cycles.  
Signals port are represented as `std_logic_vector` and treated as `signed`.

### Real operations

**Filename** - `acc_N_sps.vhd`  
The block accumulates $N$ samples and gives the result after $N$ clock cycles. The output value is good when `valid_out` is high.

**Filename** - `mult.vhd`  
Block performs a real multiplication between 2 signals. Block has a latency of 1 clock cycle

**Filename** - `multAdd.vhd`  
Block performs the operation $A \times B + C$. Latency is variable and depends on registers settings.

## Natural Logarithm

**Filename** - `cordic_ln.vhd`  
The block allows you to implement the natural logarithm function based on the CORDIC algorithm.

## Reciprocal Square Root

TO DO...

## Rounding

**Filename** - `clip_slv.vhd`  
The block allows you to reduce the size of a `std_logic_vector` saturating it.

**Filename** - `round_slv.vhd`  
The block allows you to implement various rounding logics.

**Filename** - `round_and_clip_slv.vhd`  
The block allows you to round and reduce the size of a `std_logic_vector`.

**Filename** - `axi_clip_slv.vhd`  
AXI version of the block `clip_slv.vhd`.

**Filename** - `axi_round_slv.vhd`  
AXI version of the block `round_slv.vhd`.

**Filename** - `axi_round_and_clip_slv.vhd`  
AXI block composed of the cascade of `axi_round_slv.vhd` and `axi_clip_slv.vhd`.

## Square Root

**Filename** - `cordic_sqrt.vhd`  
The block allows you to implement a square root function based on the CORDIC algorithm.

## Waves

**Filename** - `gen_cos.vhd`  
The block allows you to implement a cosine wave.

**Filename** - `gen_sin.vhd`  
The block allows you to implement a sine wave.

**Filename** - `gen_c_wave.vhd`  
The block allows you to implement a complex wave.