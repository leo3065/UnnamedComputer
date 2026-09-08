# Unnamed Computer

Building a computer from the ground up.

## TODO

- [ ] UART
  - [x] RX
  - [ ] TX
  - [ ] FIFO
  - [ ] UART bus interface (along with the bus)
  - [ ] IRQ wrapper
- [ ] Bus
  - [ ] Definition
  - [ ] Direct connecter
  - [ ] Testing manual host
  - [ ] Parameterized 1xT bus despatcher
  - [ ] ROM block and RAM block
- [ ] CPU
  - [ ] ALU
  - [ ] Register file and special registers
  - [ ] Bus interface
  - [ ] PC and Instruction decoder
  - [ ] IRQ and exception handler
  - [ ] [SW] CustomASM rule definition
- [ ] **V1: working computer with program ROM, data RAM, and (primarily) UART IO**
- [ ] (optional) ESP8266 AT command test (uses UART)
- [ ] I2C
  - [ ] I2C host
  - [ ] I2C bus interface
  - [ ] Nunchuck test
- [ ] HDMI video
  - [ ] Configuration sequence (uses I2C)
  - [ ] Frame signal generation
  - [ ] Character screen
  - [ ] Palette/low-bitdepth graphic
- [ ] **V2: V1 + Video output and Nunchuck input**
- [ ] HDMI audio
  - [ ] I2S
  - [ ] Fixed buffer
- [ ] SD card
  - [ ] SPI host
  - [ ] SD card controller
- [ ] SDRAM controller
- [ ] **V3: V2 + standalone storage and balk memory**
- [ ] DMA
  - [ ] Parameterized HxT bus despatcher
  - [ ] DMA controller
  - [ ] DM-driven buffer fetch
- [ ] **V3.5: V3 + streams with higher thoughput**
- [ ] USB HID host
  - [ ] USB host
- [ ] Graphic acceleration
  - [ ] Composition of multiple sources
  - [ ] Shape drawing
- [ ] **V4**
