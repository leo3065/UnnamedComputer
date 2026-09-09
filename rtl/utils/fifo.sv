module fifo #(
    parameter int DATA_WIDTH = 8,
    parameter int FIFO_DEPTH,
    parameter int POINTER_WIDTH = $clog2(FIFO_DEPTH) + 1
) (
    input   CLK_sys,
    input   RST_n,
    
    input   [DATA_WIDTH-1:0] data_i,
    input   in_valid_i,
    output  in_ready_o,

    output  [DATA_WIDTH-1:0] data_o,
    output  out_valid_o,
    input   out_ready_i,

    output  [POINTER_WIDTH-1:0] fifo_count_o,
    output  fifo_full_o,
    output  fifo_empty_o
);
if (FIFO_DEPTH < 0 || !$onehot(FIFO_DEPTH)) 
    $error("FIFO_DEPTH must be a power of 2 and greater than 0");

(* ramstyle = "MLAB, no_rw_check" *)
logic [DATA_WIDTH-1:0] fifo_mem [0:FIFO_DEPTH-1];

logic [POINTER_WIDTH-1:0] write_ptr, read_ptr;
logic [POINTER_WIDTH-1:0] fifo_count;

assign fifo_count = write_ptr - read_ptr;
assign fifo_count_o = fifo_count;
assign fifo_full_o = (fifo_count == FIFO_DEPTH);
assign fifo_empty_o = (fifo_count == 0);

assign in_ready_o = ~fifo_full_o;
assign out_valid_o = ~fifo_empty_o;

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
