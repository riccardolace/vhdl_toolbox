Clock domain crossing
===

- [Clock domain crossing](#clock-domain-crossing)
  - [Synchronizer](#synchronizer)


## Synchronizer

**Filename** - `cdc_sync.vhd`

Synchronizer is used to synchronize a pulse generated in a faster clock domain (Clock1 in the design) to a slower clock domain (Clock2 in the design).

The design is:

```
                                            Synchronization Chain for REGS_STAGE=2
             ╔═══════════════════╗          ╔══════════════════════════════════════╗
             ║ Clock Domain 1    ║          ║ Clock Domain 2                       ║
             ║                   ║          ║                                      ║
             ║                   ║          ║                                      ║
             ║     ┌───────┐     ║          ║     ┌───────┐        ┌───────┐       ║
             ║     │       │     ║          ║     │       │        │       │       ║      Output 
   Data ─────╬────>│ D   Q ├─────╬──────────╬────>│ D   Q ├───────>│ D   Q ├───────╬────> Registers
             ║     │       │     ║          ║     │       │        │       │       ║
             ║     │╲      │     ║          ║     │╲      │        │╲      │       ║
 Clock1 ─────╬────>│╱      │     ║          ║ ┌──>│╱      │   ┌───>│╱      │       ║
             ║     │       │     ║          ║ │   │       │   │    │       │       ║
             ║     └───────┘     ║          ║ │   └───────┘   │    └───────┘       ║
             ║                   ║          ║ │               │                    ║
             ║                   ║          ║ │               │                    ║
             ╚═══════════════════╝          ╚═╬═══════════════╬════════════════════╝
                                              │               │
                                    Clock2 ───┴───────────────┘

```
