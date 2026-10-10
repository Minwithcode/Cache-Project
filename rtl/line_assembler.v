`ifndef LINE_ASSEMBLER_V
`define LINE_ASSEMBLER_V

`include "cache_params.vh"

module line_assembler (
    input  wire                        clk,
    input  wire                        rst_n,

    // Control
    input  wire                        i_start,     // Nối với refill_mode từ Controller

    // Memory interface (từ simple_ram)
    input  wire [`DATA_WIDTH-1:0]      i_mem_data,
    input  wire                        i_mem_valid,

    // Output to Data Array
    output reg  [`BLOCK_WIDTH-1:0]     o_line_data,
    output reg                         o_done
);

    // Bộ đếm từ 0 đến 3 (cho 4 words per line)
    reg [1:0] word_count;
    reg       active; // Cờ nội bộ để quản lý trạng thái nạp

    

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            o_line_data <= 128'b0;
            word_count  <= 2'b0;
            o_done      <= 1'b0;
            active      <= 1'b0;
        end 
        else begin
            if (i_start) begin
                if (!active) begin
                    // Chu kỳ đầu tiên khi bắt đầu Refill
                    word_count  <= 2'b0;
                    o_done      <= 1'b0;
                    active      <= 1'b1;
                end 
                else if (i_mem_valid && !o_done) begin
                    // Nhận dữ liệu từng Word từ RAM
                    o_line_data[word_count * `DATA_WIDTH +: `DATA_WIDTH] <= i_mem_data;
                    
                    if (word_count == 2'd3) begin
                        o_done <= 1'b1;
                        active <= 1'b0; // Hoàn thành
                    end else begin
                        word_count <= word_count + 1'b1;
                    end
                end
            end 
            else begin
                // Reset khi tín hiệu điều khiển i_start xuống thấp
                active      <= 1'b0;
                o_done      <= 1'b0;
                word_count  <= 2'b0;
            end
        end
    end

endmodule

`endif