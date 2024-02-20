Basic
===

- [Basic](#basic)
  - [Counter](#counter)
    - [Counter with hit](#counter-with-hit)
  - [Delay](#delay)
    - [Basic delay - std\_logic](#basic-delay---std_logic)
    - [Basic delay - std\_logic\_vector](#basic-delay---std_logic_vector)
    - [Delay chain - std\_logic](#delay-chain---std_logic)
    - [Delay chain - std\_logic\_vector](#delay-chain---std_logic_vector)
    - [RAM-based delay - std\_logic\_vector](#ram-based-delay---std_logic_vector)


## Counter

### Counter with hit

**Filename** - `counter_with_hit.vhd`

It is an unsigned counter. The  `cnt` output of the register is incremented by `Inc`.  
When `cnt=valToRst`, the `hit` output is 1.

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

<br>

## Delay

### Basic delay - std_logic

**Filename** - `delay_sl.vhd`

It is a delay used for a `std_logic` signal.

The design is:

```
     ┌───┐  
x ──>│Reg├──> y
     └───┘
```

<br>

### Basic delay - std_logic_vector

**Filename** - `delay_slv.vhd`

It is a delay used for a `std_logic_vector` signal.

The design is:

```
     ┌───┐  
x ──>│Reg├──> y
     └───┘
```

<br>

### Delay chain - std_logic

**Filename** - `delay_chain_sl.vhd`

It is a delay-chain used for a `std_logic` signal.

The design is:

```
     ┌───┐   ┌───┐           ┌───┐  
x ──>│Reg├──>│Reg├──> ... ──>│Reg├──> y
     └───┘   └───┘           └───┘
```

<br>

### Delay chain - std_logic_vector

**Filename** - `delay_chain_slv.vhd`

It is a delay-chain used for a `std_logic_vector` signal.

The design is:

```
     ┌───┐   ┌───┐           ┌───┐  
x ──>│Reg├──>│Reg├──> ... ──>│Reg├──> y
     └───┘   └───┘           └───┘
```

<br>

### RAM-based delay - std_logic_vector

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

<br>
