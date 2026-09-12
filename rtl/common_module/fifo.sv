`default_nettype none
module fifo #(
    parameter int DATA_WIDTH = 8,
    parameter int FIFO_DEPTH,
    parameter int POINTER_WIDTH = $clog2(FIFO_DEPTH) + 1
) (
    input   wire CLK_sys,
    input   wire RST_n,
    
    input   wire [DATA_WIDTH-1:0] data_i,
    input   wire in_valid_i,
    output  wire in_ready_o,

    output  wire [DATA_WIDTH-1:0] data_o,
    output  wire out_valid_o,
    input   wire out_ready_i,

    output  wire [POINTER_WIDTH-1:0] count_o,

    input   wire [POINTER_WIDTH-1:0] almost_full_thres_i,
    input   wire [POINTER_WIDTH-1:0] almost_empty_thres_i,

    output  wire full_o,
    output  wire empty_o,
    output  wire almost_full_o,
    output  wire almost_empty_o
);
if (FIFO_DEPTH < 0 || !$onehot(FIFO_DEPTH)) 
    $error("FIFO_DEPTH must be a power of 2 and greater than 0");

(* ramstyle = "MLAB, no_rw_check" *)
logic [DATA_WIDTH-1:0] fifo_mem [0:FIFO_DEPTH-1];

logic [POINTER_WIDTH-1:0] write_ptr, read_ptr;
logic [POINTER_WIDTH-1:0] count;

assign count = write_ptr - read_ptr;
assign count_o = count;

assign full_o = (count == FIFO_DEPTH);
assign empty_o = (count == 0);
assign almost_full_o = (count >= almost_full_thres_i);
assign almost_empty_o = (count <= almost_empty_thres_i);

assign in_ready_o = ~full_o;
assign out_valid_o = ~empty_o;

logic write_ptr_advance, read_ptr_advance;
assign write_ptr_advance = in_valid_i & in_ready_o;
assign read_ptr_advance = out_valid_o & out_ready_i;

assign data_o = fifo_mem[read_ptr[POINTER_WIDTH-2:0]];
always_ff @(posedge CLK_sys or negedge RST_n) begin : fifo_write_read
    if (!RST_n) begin
        write_ptr <= 0;
        read_ptr <= 0;
    end else begin
        if (write_ptr_advance) begin
            fifo_mem[write_ptr[POINTER_WIDTH-2:0]] <= data_i;
            write_ptr <= write_ptr + 1;
        end
        if (read_ptr_advance) begin
            read_ptr <= read_ptr + 1;
        end
    end
end

endmodule
