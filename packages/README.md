# VHDL Toolbox Package

This directory contains a VHDL package, `pkg_vhdl_toolbox.vhd`, providing a collection of utility functions and data types designed to simplify mathematical operations and data conversions within VHDL designs.

## `pkg_vhdl_toolbox.vhd`

### Description

The `pkg_vhdl_toolbox` package offers:

* Mathematical functions for logarithmic calculations and reciprocal approximations.
* Data conversion functions for fixed-point representation from real numbers and high-precision real-to-string conversion.
* Custom complex number data types for `std_logic_vector`, `signed`, and `unsigned` representations.

### Functions

* **`function log2(i : natural) return natural;`**
    * Calculates the floor of the base-2 logarithm of a natural number.
    * Returns `floor(log2(i))`.
* **`function inv(a : real) return real;`**
    * Approximates the reciprocal of a real number.
    * Implements an iterative approximation algorithm.
* **`function flp_to_fxp(x : real; Wl : integer; Fl : integer) return std_logic_vector;`**
    * Converts a real (floating-point) number `x` to a fixed-point `std_logic_vector` representation.
    * `Wl` specifies the total word length (number of bits).
    * `Fl` Specifies the fractional length (number of bits).
    * Handles saturation for out-of-range values and performs rounding.
* **`function real_to_string_full_precision(real_val : real; frac_chars : integer) return string;`**
    * Converts a real number `real_val` to a string representation with a specified number of fractional characters `frac_chars`.
    * Provides high-precision string conversion for simulation and debugging.

### Types

* **`type t_complex_std_vec16 is record ... end record;`**
    * Defines a complex number type with 16-bit `std_logic_vector` real and imaginary parts.
* **`type t_complex_int16 is record ... end record;`**
    * Defines a complex number type with 16-bit `signed` real and imaginary parts.
* **`type t_complex_uint16 is record ... end record;`**
    * Defines a complex number type with 16-bit `unsigned` real and imaginary parts.

### Usage

To use this package in your VHDL design:

1.  Place `pkg_vhdl_toolbox.vhd` in your VHDL project directory.
2.  Include the following library and use clauses in your VHDL architecture:

    ```vhdl
    library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;
    use ieee.math_real.all;
    use std.textio.all;
    use work.pkg_vhdl_toolbox.all;
    ```

3.  You can then use the functions and types defined in the package within your VHDL code.

### Notes

* The `real_to_string_full_precision` function is primarily intended for simulation and debugging.
* The `inv` function gives an approximation of the reciprocal.
* The `flp_to_fxp` function allows to convert real number to fixed point representation.
* The complex types allow to treat complex numbers in different representations.

### License

(Add your license information here. For example, MIT License, GPL, etc.) 
