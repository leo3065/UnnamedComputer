module lut_7seg (
    input   [3:0] val_i,
    // seg g is MSB, seg a is LSB
    output  [6:0] hex_o
);
const bit [6:0] LUT [0:15] = {
    7'b0111111, 7'b0000110, 7'b1011011, 7'b1001111,
    7'b1100110, 7'b1101101, 7'b1111101, 7'b0100111,
    7'b1111111, 7'b1101111, 7'b1110111, 7'b1111100,
    7'b1011000, 7'b1011110, 7'b1111001, 7'b1110001
};
assign hex_o = ~LUT[val_i];
endmodule
