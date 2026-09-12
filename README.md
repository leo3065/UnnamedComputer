# Custom Computer Project: C-32

Building a computer from the ground up.

## TODO

- [ ] UART
  - [x] RX
  - [x] TX
  - [x] FIFO
- [ ] Bus
  - [x] Definition
  - [ ] Testing manual host
  - [ ] ROM block
  - [ ] Parameterized 1xT bus interconnect
  - [ ] RAM block
  - [ ] UART bus debug master
  - [ ] Parameterized HxT bus interconnect
  - [ ] UART bus target
- [ ] CPU
  - [ ] ALU
  - [ ] Register file and special registers
  - [ ] Bus interface
  - [ ] PC and Instruction decoder
  - [ ] Testing manual target
  - [ ] Timer
  - [ ] IRQ and exception handler
  - [ ] [SW] CustomASM rule definition
  - [ ] **V1: working computer with program ROM, data RAM, and (primarily) UART IO**
  - [ ] (optional) ESP8266 AT command test (uses UART)
- [ ] I2C
  - [ ] I2C host
  - [ ] I2C bus interface
  - [ ] TLA2528 ADC test
  - [ ] Nunchuck test
- [ ] HDMI video
  - [ ] Configuration sequence (uses I2C)
  - [ ] Frame signal generation
  - [ ] Character screen
  - [ ] Palette/low-bit-depth graphic
- [ ] **V2: V1 + Video output and Nunchuck input**
- [ ] HDMI audio
  - [ ] I2S
  - [ ] Fixed buffer
- [ ] SD card
  - [ ] SPI host
  - [ ] SD card controller
- [ ] SDRAM controller
- [ ] **V3: V2 + standalone storage and bulk memory**
- [ ] DMA
  - [ ] DMA controller
  - [ ] DMA-driven buffer fetch
- [ ] **V4: V3 + streams with higher throughput**
- [ ] USB HID host
  - [ ] USB host
- [ ] **V5**
- [ ] Graphic acceleration
  - [ ] Composition of multiple sources
  - [ ] Shape drawing
- [ ] **V6**
