# CORDIC Natural Logarithm

This repository contains a VHDL implementation of the natural logarithm (ln) function, leveraging the CORDIC algorithm for hardware efficiency.
The design utilizes a fixed-point (FXP) representation for both input and output signals.
The input, an unsigned value, is interpreted as a UQ1.FF format, constraining its range to [0, 2 - 2^(-FF)), where FF is defined as Wl_in-1.
The output, a signed value, is represented in QX.Y format, covering the range [ln(0), ln(2-2^(-FF))).
To facilitate analysis and verification, a corresponding C implementation is provided.
This C code allows users to define the input word length, enabling a comparative study between the FXP results and floating-point (FLP) calculations.
This comparison helps in understanding and optimizing the fixed-point precision for the VHDL implementation.

## Summary of the CORDIC equations

The CORDIC algorithm, as detailed in *Ercegovac, Milos D., and Tomas Lang's Digital Arithmetic (2004)*, can be implemented across three coordinate systems by varying a single parameter, $m$.

- $m=1$ for circular coordinates
- $m=-1$ for hyperbolic coordinates
- $m=0$ for linear coordinates

Consequently, the unified microrotation is:

```math
\begin{align*}
x[j+1] &= x[j] - m \sigma_j 2^{-j} y[j] \\
y[j+1] &= y[j] + \sigma_j 2^{-j} x[j] \\

z[j+1] &= \begin{cases*}
z[j] - \sigma_j \tan^{-1}({2^{-j}}), & \textrm{if $m=1$} \\
z[j] - \sigma_j \tanh^{-1}({2^{-j}}), & \textrm{if $m=-1$} \\
z[j] - \sigma_j 2^{-j}, & \text{if $m=0$}
\end{cases*}
\end{align*}
```

and the gain factor is:

```math
K_m[j] = (1 + m 2^{-2j})^{1/2}
```

### How to use the algorithm

The algorithm is used in two modes: rotation and vectoring.

In the **rotation mode**, the initial value of $z$ is made equal to $\theta$, and $\sigma_j$ is selected so that the final angle is zero:

```math
\begin{align*}
z[0] &= \theta \\
\sigma_j &= \begin{cases*}
+1,  & \text{if $z[j] \ge 0$} \\
-1, & \text{if $z[j] < 0$}
\end{cases*}
\end{align*}
```

In the **vectoring mode**, the initial vector $(x_{in}, y_{in})$ is rotated until the $Y$ component is zero. Consequently, the rotation angle is accumulated in $z$. The $\sigma_j$ value is:

```math
\sigma_j &= \begin{cases*}
+1,  & \text{if $y[j] < 0$} \\
-1, & \text{if $y[j] \ge 0$}
\end{cases*}
```

### Implementable functions

In basis of the initial values, you can implement several functions:

| m    | Mode      | $x_{in}$        | $y_{in}$        | $z_{in}$ | $x_{R}$         | $y_{R}$ or $z_{R}$         |
| ---- | --------- | --------------- | --------------- | -------- | --------------- | -------------------------- |
| 1    | rotation  | $1$             | $0$             | $\theta$ | $\cos{\theta}$  | $y_R=\sin{\theta}$         |
| -1   | rotation  | $1$             | $0$             | $\theta$ | $\cosh{\theta}$ | $y_R=\cos{\theta}$         |
| -1   | rotation  | $a$             | $a$             | $\theta$ | $a\exp{\theta}$ | $y_R=a\exp{\theta}$        |
| 1    | vectoring | $1$             | $a$             | $\pi/2$  | $\sqrt{a^2+1}$  | $z_R=\cot^{-1}(a)$         |
| -1   | vectoring | $a$             | $1$             | $0$      | $\sqrt{a^2-1}$  | $z_R=\coth^{-1}(a)$        |
| -1   | vectoring | $a+1$           | $a-1$           | $0$      | $2\sqrt{a}$     | $z_R=0.5 \ln(a)$           |
| -1   | vectoring | $a+\frac{1}{4}$ | $a-\frac{1}{4}$ | $0$      | $\sqrt{a}$      | $z_R=\ln(\frac{1}{4}a)$    |
| -1   | vectoring | $a+b$           | $a-b$           | $0$      | $2\sqrt(ab)$    | $z_R=0.5 \ln{\frac{a}{b}}$ |

where:

- $\{x_{in},y_{in},z_{in}\}$ are the initial values
- $\{x_{R},y_{R},z_{R}\}$ are the functions to implement

**Important Note**
For hyperbolic CORDIC-based algorithms, the algorithm does not converge with the sequence of angles $\tanh({2^{-j}})$ since

```math
\sum_{j=i+1}^{\infty} \tanh^{-1}(2^{-j}) < \tanh^{-1}(2^{-j})
```

A solution is to repeat some iterations. Since:

```math
\sum_{j=i+1}^{\infty} \tanh^{-1}(2^{-j}) < \tanh^{-1}(2^{-j}) < \sum_{j=i+1}^{\infty} \tanh^{-1}(2^{-j}) + \tanh^{-1}(2^{-(3j+1)})
```

These repeated iterations typically follow the pattern $j = 4, 13, 40, 121, \dots, k, 3k+1, \dots$

## CORDIC Kernel Algorithms Using Hyperbolic Computation Modes

Analyzing the table of the [Implementable functions](#implementable-functions) section, natural logarithm of the number $a$ can be implemented using the last row setting $b=1$. The CORDIC equations are as follows:

```math
\begin{align}
x[j+1] &= x[j] + \sigma_j 2^{-j} y[j] \\
y[j+1] &= y[j] + \sigma_j 2^{-j} x[j] \\
z[j+1] &= z[j] - \sigma_j \tanh^{-1}({2^{-j}})
\end{align}
```

where

```math
\sigma_j=
\begin{cases}
  +1 & y[j] < 0 \\
  -1 & y[j] \geq 0
\end{cases}
```

and $\tanh^{-1}(2^{-j})$ are precomputed and saved in memory.

This mode provides the following result as $N\to+\infty$

- $x_R \approx 2 \sqrt{ab}$
- $y_R \approx 0$
- $z_R \approx 0.5 \ln{(\frac{a}{b})}$

The result of the natural logarithm is $z_R$ and it doesn't require to apply the gain $K_m$. If we are interested to $x_R$ (or $y_R$ for the rotation mode), we must apply the gain $K_m$.

The number of iterations $N$ is chosen as the number of bits used to represent the fixed-point number $a$. As explained in the Introduction section, additive iterations must be considered to evaluate $N$.

### Computation Using the CORDIC Hyperbolic Vectoring Kernel

The judicious choice of initial values allows the CORDIC kernel hyperbolic vectoring mode algorithm to compute the natural logarithm.

Let’s consider the input number $a \in (1, 2)$. First, the following initialization steps are performed:

```math
\begin{align}
x_0 &= a + 1.0 \\
y_0 &= a - 1.0
\end{align}
```

where $b=1$. After $N$ iterations, these initial values lead to the following output as $N \to +\infty$:

```math
z_R \approx 0.5 \ln{(a)}
```

## Hardware Implementation

### C Design for FPGA

A C-based simulation environment is provided to facilitate the design and validation of the fixed-point (FXP) representation.
This environment computes natural logarithms using the defined FXP system and compares the results against standard C floating-point calculations.

To improve simulation performance, **OpenMP directives** are incorporated, allowing for parallel execution on multi-core processors when compiled with `gcc`.
The `bash_cmd.sh` script simplifies the compilation and execution process, enabling efficient exploration of different FXP configurations.

### Fixed-Point Representation

Understanding fixed-point representation is essential for this C implementation.
Input values $0 < a < 2$ are stored as `int64_t`, with the word length $Wl < 64$ controlling precision.
Q notation, specifically UQ1.(Wl-1), is used to visualize the allocation of bits between the integer and fractional parts. This ensures that fractional values are accurately represented, allowing for input values that generate output values between $-\infty$ and $\ln{(2)}$. For example, a Wl of 32 results in a UQ1.31 format, capable of representing numbers within the [0, 2) range.

#### Example - Binary Representation with Wl=32

To illustrate the fixed-point representation using Q notation, let's examine an example with a word length of 32 bits ($Wl=32$).For simplicity, we'll use the `uint32_t` data type.
The following table demonstrates how a binary number is represented under different interpretations, highlighting the relationship between the binary pattern and its numerical value.

| **Representation** | **Bit 31** | **Bit 30** | **Bit 29** | **$`\dots`$** | **Bit 0** |    **Number**     |
| ------------------ | :--------: | :--------: | :--------: | :---------:   | :-------: | :---------------: |
| uint32_t           |     1      |     0      |     0      |      0        |     0     |     $2^{31}$      |
| UQ1.31             |     1      |     0      |     0      |      0        |     0     |        $1$        |
| uint32_t           |     1      |     1      |     0      |      0        |     0     | $2^{31} + 2^{30}$ |
| UQ1.31             |     1      |     1      |     0      |      0        |     0     |       $1.5$       |
| uint32_t           |     0      |     0      |     1      |      0        |     0     |     $2^{29}$      |
| UQ1.31             |     0      |     0      |     1      |      0        |     0     |      $0.25$       |


For instance, the decimal value $0.25$, which falls within the valid input range of $[0, 2)$, can be converted to its corresponding fixed-point representation.
In UQ1.31, the value 0.25 is scaled by $2^{31}$. This results in:

$$
0.25 \times 2^{31}=536870912
$$

Converting this integer value to hexadecimal yields `0x20000000`.
Therefore, the decimal value $0.25$ is represented as `0x20000000` within a `uint32_t` variable using the UQ1.31 format.
This demonstrates how Q notation is used to represent fractional numbers in a fixed-point system.

### Block Diagram

The following block diagram illustrates the data flow and key processing stages of the natural logarithm implementation:

```
                                                                   ┌───────┐
                       ┌──────────────────────────────────────────>│ DELAY ├──┐
                       │                                           └───────┘  │
                       │                                                      │
                       │                                                      │    ┌─────────────┐    ┌───────┐ 
           ┌───────┐   │    ┌───────┐  shifted  ┌────────┐         ┌───────┐  └───>│ LEFT        │    │ ROUND │ data_out
data_in    │ COUNT │ n │    │ LEFT  │  data     │ CORDIC │         │ LEFT  │       │ BIT SHIFT   ├───>│ AND   ├──────────>
    ───┬──>│ ZERO  ├───┴───>│ BIT   ├──────────>│ KERNEL ├────────>│ SHIFT ├──────>│ COMPENSATOR │    │ CLIP  │ 
       │   │ BITS  │  ┌────>│ SHIFT │           │        │         │ BY 1  │       └─────────────┘    └───────┘ 
       │   └───────┘  │     └───────┘           └────────┘         └───────┘
       │              │
       └──────────────┘
```

Description of Blocks:

- Pre-processing:
  - **COUNT ZERO BITS**: This block determines the number of leading zeros in the input data_in. This count ($n$) is used for pre-scaling and post-processing.
  - **LEFT BIT SHIFT**: This block performs a left bit shift on the input data_in based on the number of leading zeros ($n$) determined by the *COUNT ZERO BITS* block. This effectively scales the input to the range [1, 2).
- Kernel:
  - **CORDIC KERNEL**: This block implements the CORDIC algorithm to compute $0.5 \cdot \ln{(a_s)}$, where $a_s$ is the shifted input.
- Post-processing:
  - **DELAY**: This block introduces a delay to synchronize the $n$ count with the shifted input data.
  - **LEFT SHIFT BY 1**: This block performs a left shift by 1 on the CORDIC output, equivalent to multiplying by 2, to compensate for the 0.5 factor introduced by the CORDIC algorithm.
  - **LEFT BIT SHIFT COMPENSATOR**: This block compensates the LEFT BIT SHIFT of the pre-processing. It subtracts $n \cdot \ln{(2)}$ from the shifted CORDIC result, completing the post-processing and providing the final data_out ($\ln{(a)}$).
  - **ROUND AND CLIP**: This block reduces the word length of the final data. It implements round and saturation logic.

#### Pre-Processing

The CORDIC algorithm's accuracy for natural logarithm calculations is maximized when the input falls within the $[1, 2)$ range.
To mitigate the impact of out-of-range inputs, a pre-scaling normalization technique is employed.
This method, leveraging the UQ1.FF fixed-point representation ($FF = Wl - 1$), transforms the input $a$ into a scaled value $a_s$' within the required range using:

```math
a = a \cdot 2^{n} \cdot 2^{-n} = a_s \cdot 2^{-n}
```

The integer $n$ ($0 \leq n < Wl$) controls the scaling, ensuring $a_s$ lies between 1 and 2.
The CORDIC algorithm outputs 0.5 * ln(a), which is calculated by:

```math
\begin{align*}
0.5 \cdot \ln({a}) &= 0.5 \big( \ln({a_s}\cdot 2^{-n}) \big) \\
&= 0.5 \big( \ln{(a_s)} + \ln{(2^{-n})} \big) \\
&= 0.5 \ln{(a_s)} - 0.5 \; n \;\ln({2}) \\
&= z_R -  0.5 \; n \; \ln(2)
\end{align*}
```

The pre-processing stage scales the input $a$ to $a_s$ (within the $[1, 2)$ range, UQ1.FF) and finds $n$, the number of leading zeros.
The CORDIC algorithm then computes $z_R = 0.5 \, ln(a_s)$. Bitwise operations and shifts are used to efficiently calculate $a_s$ and $n$.

#### CORDIC Kernel

The core of the CORDIC algorithm is defined by the following iterative equations:

```math
\begin{align}
\sigma_j &=
\begin{cases}
  +1 & y[j] < 0 \\
  -1 & y[j] \geq 0
\end{cases}\\
x[j+1] &= x[j] + \sigma_j 2^{-j} y[j] \\
y[j+1] &= y[j] + \sigma_j 2^{-j} x[j] \\
z[j+1] &= z[j] - \sigma_j \tanh^{-1}({2^{-j}})
\end{align}
```

To implement the $z$ update, a memory block is required to store precomputed values of $\tanh^{-1}({2^{-j}})$.
The number of stored values corresponds to the number of CORDIC iterations, typically equal to the word length ($N = Wl$).

#### Post-Processing

The result from the CORDIC kernel requires post-processing to account for the pre-scaling stage.
This involves adjusting the result to the correct output range by subtracting $n \cdot \ln{(\sqrt{2})}$.

Since the CORDIC gain is applied only to $x[j]$ and $y[j]$, and not to $z[j]$, the final output is obtained using:

```math
0.5 \ln{(a)} = z[N] - 0.5 \; n \cdot \ln{(2)} \implies \ln{(a)} = 2 \cdot z[N] - n \cdot \ln{(2)}
```

Here, $\ln{(2)}$ is precomputed, and $z[N]$ (which represents $0.5 \cdot \ln{(a_s)}$) is multiplied by 2 to compensate for the 0.5 factor inherent in the CORDIC algorithm's output.
