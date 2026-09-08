# Bus and interface
## General conventions
- valid/ready pair for transition on bus 
- level state/W1 to clear for event reporting
  - Set have higher priority than clear 

## Bus
Basically Wishbone

### Signals
- System
  - `CLK`, `RSTn`: [I] for host and target
- Transition and control
  - `CYC`: [O] for host, [I] for target
  - `LCK`: [O] for host (asserted along with `CYC`), [I] for target
    - For declaring holding the bus/interconnect
  - `STB`: [O] for host, [I] for target
  - `WEN`: [O] for host, [I] for target. 1→Write, 0→Read
  - `ACK`, `ERR`: [I] for host, [O] for target
- Address, Data, and Metadata
  - `ADR`: `[31:0]`, [O] for host (valid on `STB`), [I] for target
  - `DAT_i` and `DAT_o`: `[31:0]`
    - `DAT_i` is [I] host and target
    - `DAT_o` is [O] host and target (valid on `STB`/`ACK`)
    - `DAT_o` of one side connected to `DAT_i` of the other side
  - `SEL`: `[3:0]`, [O] for host (valid on `STB`), [I] for target
    - Each bit in `SEL` corespond to 1 byte.
    - 1 → Written for Write, read as normal for Read
    - 0 → Not written for Write, read as 0 for Read
  - `BST`: `[1:0]`, [O] for host (valid on `STB`), [I] for target:
    - `00`: single R/W
    - `10`: burst with constant address
    - `11`: burst with incrementing address
    - `01`: burst end (last transaction of a burst)
  - `QOS`: `[2:0]`, [O] for host (valid on `CYC`), [I] for target
    - Used for arbitation priority

## Target, memory mapping, and connections

- All targets accepts address with 0 base address
- The spaces for every targets is a power of 2
- The memory region of every targets should be able to be decoded and translated by splitting the address:
  - `full_address = {target_addr_prefix, target_local_addr}`
  - Specified by `REGION_START` and `REGION_SIZE`
    - Assertions:
      - `REGION_SIZE & (REGION_SIZE - 1) == 0`
      - `REGION_START & (REGION_SIZE - 1) == 0`
