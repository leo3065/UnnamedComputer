interface bus_if #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32
) (
    input   CLK_sys,
    input   RST_n
);
    logic CYC, STB, WEN;
    logic ACK, ERR;
    logic [ADDR_WIDTH-1:0] ADR;
    logic [DATA_WIDTH-1:0] DAT_h, DAT_t;
    logic [(DATA_WIDTH/8)-1:0] SEL;
    
    typedef enum logic [1:0] { 
        SINGLE      = 2'b00,
        BURST_CONST = 2'b10,
        BURST_INC   = 2'b11,
        BURST_END   = 2'b01
    } burst_t;
    burst_t BST;

    logic [2:0] QOS;

    modport host (
        input   CLK_sys, RST_n;
        output  CYC, STB, WEN;
        input   ACK, ERR;
        output  ADR, DAT_h;
        input   DAT_t;
        output  BST, QOS;
    );
    modport target (
        input   CLK_sys, RST_n;
        input   CYC, STB, WEN;
        output  ACK, ERR;
        input   ADR, DAT_h;
        output  DAT_t;
        input   BST, QOS;
    );
endinterface //bus_if
