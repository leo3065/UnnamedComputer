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
  - [ ] IRQ and exception hander
  - [ ] [SW] CustomASM rule definition
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
- [ ] HDMI audio
  - [ ] I2S
  - [ ] Fixed buffer
- [ ] SD card
  - [ ] SPI
  - [ ] SD card controller
- [ ] SDRAM controller
- [ ] DMA
  - [ ] Parameterized HxT bus despatcher
- [ ] USB HID host
  - [ ] USB host
- [ ] Graphic acceleration
