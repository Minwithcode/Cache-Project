`include "cache_params.vh"

module cache_data_array (
    input  wire                        clk,
    input  wire                        rst_n,

    input  wire [`INDEX_RANGE]          i_index,
    input  wire [`OFFSET_RANGE]         i_offset,
    input  wire                         i_way_select,
    input  wire                         i_wen,

    input  wire                         i_write_mode,   

    input  wire [`DATA_WIDTH-1:0]       i_cpu_write_data,
    input  wire [`BLOCK_WIDTH-1:0]      i_refill_data,

    output reg  [`DATA_WIDTH-1:0]       o_read_data,
    output reg  [`BLOCK_WIDTH-1:0]      o_evict_data
);

    reg [`BLOCK_WIDTH-1:0] bank0 [0:`NUM_SETS-1];
    reg [`BLOCK_WIDTH-1:0] bank1 [0:`NUM_SETS-1];

    wire [`BLOCK_WIDTH-1:0] data_way0 = bank0[i_index];
    wire [`BLOCK_WIDTH-1:0] data_way1 = bank1[i_index];

    wire [`BLOCK_WIDTH-1:0] selected_block;
    assign selected_block = (i_way_select == 1'b0) ? data_way0 : data_way1;

    always @(*) begin
        o_evict_data = selected_block;
    end

    wire [$clog2(`WORDS_PER_LINE)-1:0] word_sel;
    assign word_sel = i_offset[`WORD_SELECT_RANGE];

    always @(*) begin
        o_read_data = selected_block[word_sel*`DATA_WIDTH +: `DATA_WIDTH];
    end

    integer i;
    always @(posedge clk) begin
        if (i_wen) begin
            if (i_write_mode) begin // CPU Write (Write Hit)
                if (i_way_select == 1'b0)
                    bank0[i_index][word_sel*`DATA_WIDTH +: `DATA_WIDTH] <= i_cpu_write_data;
                else
                    bank1[i_index][word_sel*`DATA_WIDTH +: `DATA_WIDTH] <= i_cpu_write_data;
            end
            else begin // Refill từ RAM (Nạp cả Block)
                if (i_way_select == 1'b0) bank0[i_index] <= i_refill_data;
                else                      bank1[i_index] <= i_refill_data;
            end
        end
    end

endmodule
