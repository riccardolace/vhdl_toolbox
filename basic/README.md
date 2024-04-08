Basic
===

- [Basic](#basic)
  - [Counter](#counter)
  - [Delay](#delay)
  - [Encoder](#encoder)
  - [Shifter](#shifter)


## Counter

**Filename** - `counter_with_hit.vhd`  
It is an unsigned counter. The  `cnt` output of the register is incremented by `Inc`. When `cnt=valToRst`, the `hit` output is 1.  
The design is:

```
                           ┌───┐
              valToRst ───>│ = ├──> hit
                           └─┬─┘
        ┌─────┐              │
Inc ───>│ Sum │       ┌───┐  │
     ┌─>│     ├──────>│Reg├──┼────> cnt
     │  └─────┘       └───┘  │
     │                       │
     └───────────────────────┘
```

## Delay

**Filename** - `delay_sl.vhd`  
It is a delay used for a `std_logic` signal. The design is:

```
     ┌───┐  
x ──>│Reg├──> y
     └───┘
```

<br>

**Filename** - `delay_slv.vhd`  
It is a delay used for a `std_logic_vector` signal. The design is:

```
     ┌───┐  
x ──>│Reg├──> y
     └───┘
```

<br>

**Filename** - `delay_chain_sl.vhd`  
It is a delay-chain used for a `std_logic` signal. The design is:

```
     ┌───┐   ┌───┐           ┌───┐  
x ──>│Reg├──>│Reg├──> ... ──>│Reg├──> y
     └───┘   └───┘           └───┘
```

<br>

**Filename** - `delay_chain_slv.vhd`  
It is a delay-chain used for a `std_logic_vector` signal. The design is:

```
     ┌───┐   ┌───┐           ┌───┐  
x ──>│Reg├──>│Reg├──> ... ──>│Reg├──> y
     └───┘   └───┘           └───┘
```

<br>

**Filename** - `delay_ram_slv.vhd`  
It is a delay-chain used for a `std_logic_vector` signal.
The RAM is filled with zeros when the reset is high.  
The design is:

```
x  ───────────┐ 
              │  │╲
              │  │ ╲
              └─>│  │  ram_i_data
                 │  │─────────────────────────┐
              ┌─>│  │                         │
              │  │ ╱                          │
     addr_wr  │  │╱                           │
0  ───────────┘                               │
                                              │
   ┌─────┐                                    │
   │ cnt │  addr_rst                          │
   │     ├───────────┐                        │    
   └─────┘           │  │╲                    │   ┌─────┐
                     │  │ ╲                   └──>│     │
                     └─>│  │  ram_addr_wr         │  R  │
                        │  │─────────────────────>│  A  │───> y
                     ┌─>│  │                      │  M  │  
   ┌─────┐           │  │ ╱                   ┌──>│     │  
   │ cnt │  addr_wr  │  │╱                    │   └─────┘  
   │     ├───────────┘                        │    
   └─────┘                                    │     
                                              │     
   ┌─────┐                                    │     
   │ cnt │  ram_addr_rd                       │     
   │     ├────────────────────────────────────┘     
   └─────┘
 
```

## Encoder

**Filename** - `priorityEncoder.vhd`  
It is a priority encoder takes multiple binary inputs and efficiently converts them into a single output code.
The output represents the index of the highest priority active input.

```
                 ┌─────────────┐    z0           ┌─────────┐
     x0    ─────>│             ├────────────────>│         ├────> y0
     x1    ─────>│ PRIORITY    ├────────────────>│ 2^n     ├────> y1
     .           │             │       .         │ BINARY  │  .
     .           │ RESOLUTION  │       .         │ ENCODER │  .
     .           │             │       .         │         │  .
 x_{2^n-1} ─────>│             ├────────────────>│         ├────> y_{n-1}
                 └─────────────┘    z_{2^n-1}    └─────────┘
```

## Shifter

**Filename** - `barallelShifter.vhd`  
This VHDL code implements a barrel shifter using a cascaded structure.
Each stage utilizes a multiplexer controlled by a single bit from the 'sel' input.
For a 3-bit 'sel' signal, there will be three cascaded stages with a 1-bit multiplexer in each.
Registers are inserted after each stage to introduce pipeline delays.

```
             s0  ┌─────┐    s1  ┌─────┐    s2  ┌─────┐
             ───>│     │    ───>│     │    ───>│     │
                 │     │        │     │        │     │
  data_in   ┌───>│ MUX │   ┌───>│ MUX │   ┌───>│ MUX │
        ────┤    │     ├───┤    │     ├───┤    │     ├───> data_out
            └───>│     │   └───>│     │   └───>│     │
             >>1 └─────┘    >>2 └─────┘    >>4 └─────┘
```