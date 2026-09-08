# CPU and ISA

## Overview

- 32-bit address space
- 32-bit data width
- 32x 32-bit general registers
- 32-bit PC
- 32-bit fixed instruction size
- 32 IRQ lines, IRQ0 > IRQ1 > IRQ2 > .... > IRQ30 > IRQ31 

## Instructions
### Type
Opcode: 6 bits
| Type | Word 1 (High word)                  | Word 0 (Low word)                    | Fields                      |
| ---- | ----------------------------------- | ------------------------------------ | --------------------------- |
| R    | `fb6 [15:10]`, `rb[9:5]`, `ra[4:0]` | `fa5[15:11]`, `rt [10:6]`, `op[5:0]` | rt, fa5, ra, rb, fb6        |
| I    | `im11[15:5]`              `rs[4:0]` | `fa5[15:11]`, `rt [10:6]`, `op[5:0]` | rt, fa5, rs, im11           |
| L    | `im16[15:0]`                        | `fa5[15:11]`, `rt [10:6]`, `op[5:0]` | rt, fa5, im16               |
| A    | `im16[15:0]`                        | `im5[15:11]`, `rt [10:6]`, `op[5:0]` | rt, im21={im16,im5}         |
| B    | `of6 [15:10]`, `rb[9:5]`, `ra[4:0]` | `fa5[15:11]`, `of5[10:6]`, `op[5:0]` | fa5, ra, rb, of11={of6,of5} |

### Operations
- M: memory
- se: signed extension
- ze: zero extension
- sr: status register
- sridx: status register index, uses `rs` field in I type
- pc': next PC

| Operation                  | Type | Op                   | `op`   | `fa5`  | Desc. (Concurrent actions)                 |
| -------------------------- | ---- | -------------------- | ------ | ------ | ------------------------------------------ |
| Arithmetic/Logic           | R    | `<op4> rt, ra, rb`   | `0x00` | (func) | `func(ra,rb) → rt`                         |
| Arithmetic/Logic immediate | I    | `<op>i rt, rs, im11` | `0x01` | (func) | `func(rs,im11) → rt`                       |
| Store word                 | I    | `sw    rt, rs(im11)` | `0x02` | `0x00` | `rt → M[rs+se(im11)]`                      |
| Store half                 | I    | `sh    rt, rs(im11)` | `0x02` | `0x01` | `rt[15:0] → M[rs+se(im11)]`                |
| Store byte                 | I    | `sb    rt, rs(im11)` | `0x02` | `0x02` | `rt[7:0] → M[rs+se(im11)]`                 |
| Load word                  | I    | `lw    rt, rs(im11)` | `0x03` | `0x00` | `ze(M[rs+se(im11)]) → rt`                  |
| Load half                  | I    | `lh    rt, rs(im11)` | `0x03` | `0x01` | `ze(M[rs+se(im11)][15:0]) → rt`            |
| Load byte                  | I    | `lb    rt, rs(im11)` | `0x03` | `0x02` | `ze(M[rs+se(im11)][7:0]) → rt`             |
| Load half signed           | I    | `lhs   rt, rs(im11)` | `0x03` | `0x05` | `se(M[rs+se(im11)][15:0]) → rt`            |
| Load byte signed           | I    | `lbs   rt, rs(im11)` | `0x03` | `0x06` | `se(M[rs+se(im11)][7:0]) → rt`             |
| Load half immediate        | L    | `lhi   rt, im16`     | `0x05` | `0x01` | `im16 → rt`                                |
| Load half signed immediate | L    | `lhsi  rt, im16`     | `0x05` | `0x05` | `se(im16) → rt`                            |
| Load half upper immediate  | L    | `lhui  rt, im16`     | `0x05` | `0x0D` | `rt \| (im16 << 16) → rt`                  |
| Add upper immediate to PC  | A    | `auipc rt, im21`     | `0x10` | (N/A)  | `pc + (im21 << 11) → rt`                   |
| Store status register      | I    | `ssr   rt, sridx`    | `0x12` | `0x00` | `rt → sr[sridx]`                           |
| Load status register       | I    | `lsr   rt, sridx`    | `0x13` | `0x00` | `sr[sridx] → rt`                           |
| Jump and link              | L    | `jal   rt, im16`     | `0x20` | `0x00` | `pc+4 → rt; pc+se(im16 << 2) → pc'`        |
| Jump register and link     | I    | `jral  rt, rs(im11)` | `0x21` | `0x00` | `pc+4 → rt; rs+se(im11 << 2) → pc'`        |
| Branch                     | B    | `<op>  ra, rb, of11` | `0x22` | (cond) | `if cond(ra,rb): pc+se(of11 << 2) → pc'`   |
| Return from event          | L    | `eret`               | `0x28` | `0x00` | `simb → sim; sepc → pc'`                   |
| Trigger interrupt          | L    | `int   im16`         | `0x29` | `0x00` | `pc → sepc; {0x02,im16} → seid; sim → simb; 0 → sim; sev & ~0x00000003 → pc'` |

#### Function (t: rt, a: ra, b: rb/im11)
##### Base function (fb6 = 0x00)
- `b2i(b) = b ? 1 : 0`

| Function                         | Op name | `fa5`  | Operation                 | Ext. on b |
| -------------------------------- | ------- | ------ | ------------------------- | --------- |
| Add                              | `add`   | `0x00` | `t = a + ze(b)`           | ZE        |
| Subtract                         | `sub`   | `0x01` | `t = a - ze(b)`           | ZE        |
|                                  |         | `0x02` |                           |           |
|                                  |         | `0x03` |                           |           |
| Multiply low                     | `mul`   | `0x04` | `t = (a * ze(b))[31:0]`   | ZE        |
| Multiply high                    | `muh`   | `0x05` | `t = (a * ze(b))[63:32]`  | ZE        |
| Multiply high signed             | `muhs`  | `0x06` | `t = (a *s se(b))[63:32]` | SE        |
| Multiply high signed unsigned    | `muhsu` | `0x07` | `t = (a *s ze(b))[63:32]` | ZE        |
| And                              | `and`   | `0x08` | `t = a & ze(b)`           | ZE        |
|                                  |         | `0x09` |                           |           |
| Or                               | `or`    | `0x0A` | `t = a \| ze(b)`          | ZE        |
| Ex-Or                            | `xor`   | `0x0B` | `t = a ^ ze(b)`           | ZE        |
| Shift Right (Logical)            | `srl`   | `0x0C` | `t = a >> ze(b)`          | ZE        |
| Shift Left  (Logical)            | `sll`   | `0x0D` | `t = a << ze(b)`          | ZE        |
| Shift Right (Arithmetic)         | `sra`   | `0x0E` | `t = a >>> ze(b)`         | ZE        |
|                                  |         | `0x0F` |                           |           |
| Set If equal                     | `seq`   | `0x10` | `t = b2i(ra == ze(rb))`   | ZE        |
| Set If not equal                 | `sne`   | `0x11` | `t = b2i(ra != ze(rb))`   | ZE        |
| Set If greater than              | `sgt`   | `0x12` | `t = b2i(ra >  ze(rb))`   | ZE        |
| Set If less or equal than        | `sle`   | `0x13` | `t = b2i(ra <= ze(rb))`   | ZE        |
|                                  |         | `0x14` |                           |           |
|                                  |         | `0x15` |                           |           |
| Set If greater than signed       | `sgts`  | `0x16` | `t = b2i(ra >s  se(rb))`  | SE        |
| Set If less or equal than signed | `sles`  | `0x17` | `t = b2i(ra <=s se(rb))`  | SE        |
|                                  |         | `0x18` |                           |           |
|                                  |         | `0x19` |                           |           |
|                                  |         | `0x1A` |                           |           |
|                                  |         | `0x1B` |                           |           |
|                                  |         | `0x1C` |                           |           |
|                                  |         | `0x1D` |                           |           |
|                                  |         | `0x1E` |                           |           |
|                                  |         | `0x1F` |                           |           |

#### Condition (a: ra, b: rb)
| Condition                    | Op name | `fa5`  | Operation   |
| ---------------------------- | ------- | ------ | ----------- |
| If equal                     | `beq`   | `0x00` | `ra == rb`  |
| If not equal                 | `bne`   | `0x01` | `ra != rb`  |
| If greater than              | `bgt`   | `0x02` | `ra >  rb`  |
| If less or equal than        | `ble`   | `0x03` | `ra <= rb`  |
|                              |         | `0x04` |             |
|                              |         | `0x05` |             |
| If greater than signed       | `bgts`  | `0x06` | `ra >s  rb` |
| If less or equal than signed | `bles`  | `0x07` | `ra <=s rb` |
|                              |         | `0x08` |             |
|                              |         | `0x09` |             |
|                              |         | `0x0A` |             |
|                              |         | `0x0B` |             |
|                              |         | `0x0C` |             |
|                              |         | `0x0D` |             |
|                              |         | `0x0E` |             |
|                              |         | `0x0F` |             |
| (unused for now)             |         | `0x1_` |             |

## Registers
### General Registers
- `r0` / `zero`: constant 0 on read, no effect on write
- `r1` ~ `r31`
**TODO: Alias and calling convention**

### Special Registers
All are 32 bit:
| Name   | `sridx` | Desc. |
| ------ | ------- | ----- |
| `sev`  | `0x00`  | Event vector, base address to jump to when having exception or interrupt |
| `sepc` | `0x01`  | Event PC, PC when exception or interrupt happens |
| `seid` | `0x02`  | Event ID, cause/source of event |
| `sim`  | `0x03`  | Interrupt mask, bit masking of interrupt |
| `simb` | `0x04`  | Interrupt mask backup |

When there is event:
`pc → sepc; exception_id → seid; sim → simb; 0 → sim; sev & ~0x00000003 → pc'`

#### Exception IDs
Types:
| `seid`         | Type      | Desc. |
| -------------- | --------- | ----- |
| `{0x0000____}` | Exception | Exception encountered during execution of the commands |
| `{0x0001____}` | HW. Int.  | Interrupts triggered by hardware or inputs |
| `{0x0002____}` | SW. Int.  | Interrupts triggered by software |

**TODO: Exception IDs**
