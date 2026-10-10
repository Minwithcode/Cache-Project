`timescale 1ns / 1ps
`include "cache_params.vh"

module cache_top (
    input  wire                   clk,
    input  wire                   rst_n,

    // CPU interface
    input  wire                   cpu_rd,
    input  wire                   cpu_wr,
    input  wire [`ADDR_WIDTH-1:0] cpu_addr,
    input  wire [`DATA_WIDTH-1:0] cpu_wdata,

    output wire [`DATA_WIDTH-1:0] cpu_rdata,
    output wire                   cache_hit
);

    // =========================================================
    // 1. Address Decode
    // =========================================================
    wire [`TAG_WIDTH-1:0]    tag;
    wire [`INDEX_WIDTH-1:0]  index;
    wire [`OFFSET_WIDTH-1:0] offset;

    address_decoder u_dec (
        .i_addr   (cpu_addr),
        .o_tag    (tag),
        .o_index  (index),
        .o_offset (offset)
    );

    // =========================================================
    // 2. Controller signals (PHẢI KHAI BÁO TRƯỚC)
    // =========================================================
    wire update_en;
    wire data_wen;
    wire refill_mode;

    // =========================================================
    // 3. Tag + Status Array (đã tích hợp LRU 2-way)
    // =========================================================
    wire hit;
    wire hit_way;
    wire dirty_victim;
    wire [`TAG_WIDTH-1:0] tag_victim;

    cache_tag_array u_tag (
        .clk          (clk),
        .rst          (~rst_n),
        .addr         (cpu_addr),
        .wr_en        (cpu_wr),
        .update_en    (update_en),
        .hit          (hit),
        .hit_way      (hit_way),
        .dirty_victim (dirty_victim),
        .tag_victim   (tag_victim)
    );

    // =========================================================
    // 4. Data Array
    // =========================================================
    wire [`BLOCK_WIDTH-1:0] refill_line;
    wire [`BLOCK_WIDTH-1:0] evict_line;

    cache_data_array u_data (
        .clk               (clk),
        .rst_n             (rst_n),
        .i_index           (index),
        .i_offset          (offset),
        .i_way_select      (hit_way),
        .i_wen             (data_wen),
        .i_write_mode      (refill_mode),
        .i_cpu_write_data  (cpu_wdata),
        .i_refill_data     (refill_line),
        .o_read_data       (cpu_rdata),
        .o_evict_data      (evict_line)
    );

    // =========================================================
    // 5. Simple RAM (giả lập bộ nhớ chính)
    // =========================================================
    wire [`DATA_WIDTH-1:0] ram_data;
    wire ram_valid;

    simple_ram u_ram (
        .clk   (clk),
        .req   (refill_mode),
        .addr  (cpu_addr),
        .data  (ram_data),
        .valid (ram_valid)
    );

    // =========================================================
    // 6. Line Assembler (gom word → cache line)
    // =========================================================
    wire refill_done;

    line_assembler u_line (
        .clk         (clk),
        .rst_n       (rst_n),
        .i_start     (refill_mode),
        .i_mem_data  (ram_data),
        .i_mem_valid (ram_valid),
        .o_line_data (refill_line),
        .o_done      (refill_done)
    );

    // =========================================================
    // 7. Cache Controller (FSM)
    // =========================================================
    cache_controller u_ctrl (
        .clk         (clk),
        .rst_n       (rst_n),
        .cpu_rd      (cpu_rd),
        .cpu_wr      (cpu_wr),
        .hit         (hit),
        .refill_done (refill_done),
        .update_en   (update_en),
        .data_wen    (data_wen),
        .refill_mode (refill_mode),
        .cache_hit   (cache_hit)
    );

endmodule
