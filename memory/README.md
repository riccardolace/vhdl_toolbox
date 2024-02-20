Clock Domain Crossing
===

- [Clock Domain Crossing](#clock-domain-crossing)
  - [Fifo](#fifo)
    - [Axi Fifo 2clk](#axi-fifo-2clk)
  - [Ram](#ram)
    - [Dual clock synchronous RAM](#dual-clock-synchronous-ram)

## Fifo

### Axi Fifo 2clk

**Filename** - `axi_fifo_2clk.vhd`

The purpose of this dual clock FIFO is to enable two circuits that operate at different clock frequencies to communicate with each other.

A simplified diagram is shown as follows:

```
                       WRITE SIDE       ┊     READ SIDE        
                   ┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┊┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄
                                        ┊
               i_clk                    ┊          o_clk
               ─────────────────┐       ┊       ┌───────
                                │       ┊       │
               i_tdata          │       ┊       │
               ──────────────┐  │       ┊       │
                             │  │    ┌─────┐    │
                             │  └───>│     │<───┘
                             └──────>│  R  │
                                     │  A  ├───────────> y
                    ┏━━━━━━━━━━━━━━━>│  M  │              
                    ┃        ┌──────>│     │<───────────────┐
                    ┃        │       └─────┘                │
    ┌─────┐ wr_addr ┃        │          ┊                   │
 ┏━>│ cnt ├─────────╂────────┤          ┊                   │
 ┃  └─────┘         ┃        │          ┊                   │
 ┃                  ┃        │          ┊                   │
 ┃                  ┃        │  ┌────┐  ┊   ┌─────┐ rd_addr │
 ┃                  ┃        └─>│cdc ├─────>│ FSM ├─────────┘  
 ┃                  ┃           └────┘  ┊   └─────┘
 ┃                  ┃   write  ┌─────┐  ┊    ┌────┐
 ┗━━━━━━━━━━━━━━━━━━┻━━━━━━━━━━│logic│<──────┤cdc │
                               └─────┘  ┊    └────┘
                                        ┊
```

---

## Ram

### Dual clock synchronous RAM

**Filename** - `axi_fifo_2clk.vhd`

It is a dual clock synchronous RAM.

The design is
```
     WRITE SIDE       ┊     READ SIDE        
  ┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┊┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄
                      ┊        
  clk_a               ┊               clk_b
  ────────────┐       ┊       ┌────────────
  ena         │    ┌─────┐    │         enb
  ─────────┐  └───>│     │<───┘  ┌─────────
           └──────>│     │<──────┘
  data_in          │  R  │         data_out
  ────────────────>│  A  ├────────────────>
                   │  M  │
  wea      ┌──────>│     │<──────┐      wea
  ─────────┘  ┌───>│     │<───┐  └─────────
  addra       │    └─────┘    │       addra
  ────────────┘               └────────────
```