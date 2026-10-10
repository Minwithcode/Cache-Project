`include "cache_params.vh"

module cache_controller (
    input  wire clk,
    input  wire rst_n,

    // CPU request
    input  wire cpu_rd,
    input  wire cpu_wr,

    // From tag array
    input  wire hit,

    // From line assembler
    input  wire refill_done,

    // Control outputs
    output reg  update_en,     
    output reg  data_wen,      
    output reg  refill_mode,   
    output reg  cache_hit
);

    // =========================================================
    // STATE ENCODING (IVERILOG FRIENDLY)
    // =========================================================
    localparam [1:0]
        IDLE   = 2'b00,
        MISS   = 2'b01,
        REFILL = 2'b10;

    reg [1:0] state, next_state;

    // =========================================================
    // STATE REGISTER
    // =========================================================
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            state <= IDLE;
        else
            state <= next_state;
    end

    // =========================================================
    // NEXT STATE LOGIC
    // =========================================================
    always @(*) begin
        next_state = state;

        case (state)
            IDLE: begin
                if (cpu_rd || cpu_wr)
                    next_state = hit ? IDLE : MISS;
            end

            MISS: begin
                next_state = REFILL;
            end

            REFILL: begin
                if (refill_done)
                    next_state = IDLE;
            end

            default: next_state = IDLE;
        endcase
    end

    // =========================================================
    // OUTPUT LOGIC
    // =========================================================
    always @(*) begin
        update_en   = 1'b0;
        data_wen    = 1'b0;
        refill_mode = 1'b0;
        cache_hit   = 1'b0;

        case (state)
            IDLE: begin
                if (hit) begin
                    cache_hit = 1'b1;
                    data_wen  = cpu_wr; 
                end
            end
            MISS: begin
                refill_mode = 1'b1; // Kích hoạt nạp từ MISS
            end
            REFILL: begin
                refill_mode = 1'b1;
                if (refill_done) begin
                    update_en = 1'b1; // CHỈ bật update_en khi nạp xong
                end
            end
        endcase
    end

endmodule
