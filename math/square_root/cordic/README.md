# CORDIC Square Root

This repository implements the CORDIC (COordinate Rotation DIgital Computer) algorithm specifically for calculating square roots.

The CORDIC algorithm, based on Givens rotations (see references [Ref 1](https://ieeexplore.ieee.org/document/5222693), [Ref 2](https://dl.acm.org/doi/abs/10.1145/1478786.1478840)), is known for its hardware efficiency.
Unlike traditional methods, it relies solely on iterative shift and add operations, eliminating the need for complex multipliers.
This efficiency makes CORDIC suitable for a wide range of functions, including:

- Trigonometric calculations (sine, cosine, arcsine, arccosine, arctangent)
- Vector operations (magnitude)
- Arithmetic operations (division, square root)
- Hyperbolic and logarithmic functions

**Important Note:** For hyperbolic CORDIC-based algorithms like square root, specific iterations require repetition to achieve convergence.
These repeated iterations typically follow a pattern like i = 4, 13, 40, 121, ..., k, 3k+1, ... (where k is a constant).
The provided implementation incorporates this repetition for accurate square root results.

## CORDIC Square Root - C Implementation for FPGA

To ensure optimal fixed-point (FXP) representation, the design leverages C code for initial exploration. The C code defines the FXP system and compares its square root output with the standard C floating-point implementation. This comparison helps validate the chosen FXP representation before integrating it into the VHDL code.

**Additionally, the project utilizes OpenMP for parallel processing**. This allows the C code to be compiled into an executable that can leverage multiple threads, potentially reducing simulation execution time. For ease of use, a bash script named `bash_cmd.sh` is provided. This script streamlines the compilation process using `gcc` and executes the generated executable.

## CORDIC Kernel Algorithms Using Hyperbolic Computation Modes

You can use a CORDIC computing mode algorithm to calculate hyperbolic functions, such as hyperbolic trigonometric, square root, log, exp, etc.

### CORDIC Equations in Hyperbolic Vectoring Mode

The hyperbolic vectoring mode is used for computing square root. For the vectoring mode, the CORDIC equations are as follows:

```math
\begin{align}
x_{i+1} &= x_i + y_i d_i 2^{-i} \\
y_{i+1} &= y_i + x_i d_i 2^{-i} \\
z_{i+1} &= z_i - d_i \arctan{2^{-i}}
\end{align}
```

where

```math
d_i=
\begin{cases}
  +1 & y_i<0 \\
  -1 & y_i\geq0
\end{cases}
```

This mode provides the following result as $N\to+\infty$

- $x_N \approx A_n \sqrt{x_0^2 - y_0^2}$
- $y_N \approx 0$
- $z_N \approx z_0 + \mathrm{arctanh}({y_0 / x_0})$

where $A_n$ is the gain introduced by the algorithm, and it is evaluated through a comparison between the output algorithm and a reference number evaluated as $|\sqrt(x)|$ where $x$ is a floating-point number.
After $N$ iterations, $x$ tends to the desired result, while $y$ tends to 0. 
The $z$ computation can be avoided because it is not significant for the square root computation.

The number of iterations $N$ is chosen as the number of bits used to represent the fixed-point number $x$.
As explained in the Introduction section, additive iterations must be considered to evaluate $N$.

### Square Root Computation Using the CORDIC Hyperbolic Vectoring Kernel

The judicious choice of initial values allows the CORDIC kernel hyperbolic vectoring mode algorithm to compute square root.

Let’s consider the input number $v \in [0.25, 2)$. First, the following initialization steps are performed:

```math
\begin{align}
x_0 &= v + 0.25 \\
y_0 &= v - 0.25
\end{align}
```

After $N$ iterations, these initial values lead to the following output as $N \to +\infty$:

```math
x_n \approx A_n \sqrt{(v + 0.25)^2 - (v - 0.25)^2}
```

This may be further simplified as follows:

```math
x_n \approx A_n \sqrt{v}
```

## C Implementation

### Fixed-Point Representation

- As shown in the previous sections, the input number must be in a range 0.5 and 2.
- FXP system implemented in C allows to define an even number of bits to represent the numbers. The even number is defined as Wl that means Word Length
- input numbers are represented in C using `uint64_t` type and
-  it is important understand how to represent a fractional number using integer types
- Q notation is used. If Wl=32 for example, we have 1 bit for the integer part and 31 bits for the fractional part

Building on the previous sections, it's important to understand how fractional numbers are represented within the C code's fixed-point (FXP) system. Since the FXP system requires an even number of bits (denoted as `Wl` for Word Length) to represent numbers, and the input range is restricted to $[0.5, 2)$, we leverage the `uint64_t` data type in C for efficient storage.

**Q notation** provides a convenient way to visualize this representation.  
For example, if `Wl` is set to 32, then UQ1.31 indicates one bit is allocated for the integer portion (allowing representation of values from 0 to 1), and the remaining 31 bits represent the fractional part.
This allows for precise representation of numbers within the valid input range (0.5 to 2) using the chosen `uint64_t` data type.

While several examples are provided using a Word Length (Wl) of 32, we can simplify our initial exploration by utilizing `uint32_t` instead of `uint64_t`. This is because the upper 32 bits of a `uint64_t` would be zero for the relevant input range (0.5 to 2).



| **Representation** | **Bit 31** | **Bit 30** | **Bit 29** | **$`\dots`$** | **Bit 0** |    **Number**     |
| ------------------ | :--------: | :--------: | :--------: | :---------:   | :-------: | :---------------: |
| uint32_t           |     1      |     0      |     0      |      0        |     0     |     $2^{31}$      |
| UQ1.31             |     1      |     0      |     0      |      0        |     0     |        $1$        |
| uint32_t           |     1      |     1      |     0      |      0        |     0     | $2^{31} + 2^{30}$ |
| UQ1.31             |     1      |     1      |     0      |      0        |     0     |       $1.5$       |
| uint32_t           |     0      |     0      |     1      |      0        |     0     |     $2^{29}$      |
| UQ1.31             |     0      |     0      |     1      |      0        |     0     |      $0.25$       |


Let's illustrate the scaled value representation using Q notation. If we consider a Word Length (Wl) of 32 and UQ1.31 notation, then the value 0.25 (which falls within the valid input range) would be represented in hexadecimal format as `0x20000000` within a `uint32_t` variable.

### Pre-Processing

The CORDIC algorithm for square root calculations is most effective when the input value lies within the range of 0.5 to 2 (exclusive). Values outside this range can negatively impact the algorithm's accuracy. To address this limitation and ensure correct operation, the implementation incorporates a pre-scaling stage based on the UQ1.31 fixed-point representation.

This sensitivity to input range can be mitigated through a normalization process. This process leverages mathematical relationships to adjust the input value $u$ such that it falls within the acceptable range $[0.5,2)$ for the CORDIC algorithm.

```math
v=u \cdot 2^n
```
for some $0.5 \leq u <2$ and some integer $n$.

The output of the algorithm is:

```math
\sqrt{v} = \sqrt{u} \cdot 2^{n/2}
```

During the normalization process, the algorithm determines two key values: $u$ and $v$.These values are derived from the input number. Additionally, the process finds $n$, which represents the number of leading zeros (most significant bits) in the binary representation of the input.

To calculate $u$ and $v$, the implementation employs a series of bitwise logic operations and bit shifts. These operations efficiently extract the necessary information from the input to prepare it for the CORDIC algorithm.

**Note:** because $n$ <u>must be even</u>, if the number of leading zero MSBs is odd, one additional bit shift is made to make even. The resulting value after these shifts is the value:

```math
0.5 \leq u < 2
```

The normalized value $u$ becomes the input to the core CORDIC square root algorithm. This algorithm then calculates an approximation to the square root of $u$.

Following the CORDIC calculation, the result needs to be scaled back to the appropriate output range. To achieve this, the result is multiplied by a factor of 2 raised to the power of $n$ divided by 2 (written as $2^{n/2}$).
This scaling is implemented efficiently using a bit shift operation. The number of bits to shift by is $n/2$.

### CORDIC Square Root Kernel

The CORDIC Square Root Kernel is shown as follows:

```math
\begin{align}
x_{i+1} &= x_i + y_i d_i 2^{-i} \\
y_{i+1} &= y_i + x_i d_i 2^{-i}
\end{align}
```

The $z_{i+1}$ is not considered because it is not used for the $\sqrt{x}$ estimation.

### Post-Processing

**First**, the value of $u$ requires scaling to compensate for the pre-processing stage. Recall that the input was normalized during pre-processing to fit the CORDIC's acceptable range. This normalization involved scaling the input, and the current step reverses that scaling to bring the result back to the original range of the square root function.

**Second**, a correction factor called the *CORDIC gain* is applied. The CORDIC algorithm itself introduces a slight scaling factor during its calculations. This *CORDIC gain* is a constant value and needs to be factored out to obtain the final, accurate square root. It is estimates as:

$$
G = \frac{1}{\prod_i \sqrt{1 - 2^{-2i}}}
$$

for $i=\{1,2,3,4,4,5,\dots\}$.