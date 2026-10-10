`timescale 1ns / 1ps
`include "cache_params.vh"

module tb_cache;

    // =====================================================
    // 1. SIGNALS
    // =====================================================
    reg clk, rst_n;
    reg cpu_rd, cpu_wr;
    reg [`ADDR_WIDTH-1:0] cpu_addr;
    reg [`DATA_WIDTH-1:0] cpu_wdata;
    wire [`DATA_WIDTH-1:0] cpu_rdata;
    wire cache_hit;

    reg [2:0] scenario_id;

    // =====================================================
    // 2. STATISTICS
    // =====================================================
    integer total_access, hits, misses;
    integer total_penalty_cycles, total_access_cycles;
    integer read_count, write_count;

    reg [63:0] cycle_counter;
    integer start_cycle, end_cycle;

    real hr, amat, avg_miss_penalty;
    integer choice;

    // =====================================================
    // 3. DUT
    // =====================================================
    cache_top uut (
        .clk(clk),
        .rst_n(rst_n),
        .cpu_rd(cpu_rd),
        .cpu_wr(cpu_wr),
        .cpu_addr(cpu_addr),
        .cpu_wdata(cpu_wdata),
        .cpu_rdata(cpu_rdata),
        .cache_hit(cache_hit)
    );

    // =====================================================
    // 4. CLOCK
    // =====================================================
    always #5 clk = ~clk;

    initial cycle_counter = 0;
    always @(posedge clk) cycle_counter <= cycle_counter + 1;

    // =====================================================
    // 5. TASKS
    // =====================================================
    task reset_stats;
        begin
            total_access = 0;
            hits = 0;
            misses = 0;
            total_penalty_cycles = 0;
            total_access_cycles = 0;
            read_count = 0;
            write_count = 0;
        end
    endtask

    task cpu_read(input [`ADDR_WIDTH-1:0] addr);
        begin
            @(posedge clk);
            start_cycle = cycle_counter;
            cpu_rd = 1; cpu_wr = 0;
            cpu_addr = addr;

            @(posedge clk);
            wait (uut.u_ctrl.state == 2'b00); // Chờ về IDLE

            end_cycle = cycle_counter;

            if (cache_hit) hits++;
            else begin
                misses++;
                total_penalty_cycles += (end_cycle - start_cycle - 1);
            end

            total_access++;
            read_count++;
            total_access_cycles += (end_cycle - start_cycle);

            cpu_rd = 0;
            @(posedge clk);
        end
    endtask

    task cpu_write(input [`ADDR_WIDTH-1:0] addr,
                   input [`DATA_WIDTH-1:0] data);
        begin
            @(posedge clk);
            start_cycle = cycle_counter;
            cpu_wr = 1; cpu_rd = 0;
            cpu_addr = addr;
            cpu_wdata = data;

            @(posedge clk);
            wait (uut.u_ctrl.state == 2'b00);

            end_cycle = cycle_counter;

            if (cache_hit) hits++;
            else begin
                misses++;
                total_penalty_cycles += (end_cycle - start_cycle - 1);
            end

            total_access++;
            write_count++;
            total_access_cycles += (end_cycle - start_cycle);

            cpu_wr = 0;
            @(posedge clk);
        end
    endtask

    task evaluate_scenario(input string name);
        begin
            hr   = (total_access > 0) ? real'(hits)/total_access*100 : 0;
            amat = (total_access > 0) ? real'(total_access_cycles)/total_access : 0;
            avg_miss_penalty = (misses > 0) ? real'(total_penalty_cycles)/misses : 0;

            $display("\n============================================");
            $display(" SCENARIO : %s", name);
            $display(" Total Access      : %0d", total_access);
            $display(" Hit Rate          : %3.2f %%", hr);
            $display(" Avg Miss Penalty  : %3.2f cycles", avg_miss_penalty);
            $display(" AMAT              : %3.2f cycles", amat);
            $display("============================================\n");
        end
    endtask

    // =====================================================
    // 6. MAIN
    // =====================================================
    initial begin
        $dumpfile("cache_wave.vcd");
        $dumpvars(0, tb_cache);

        clk = 0; rst_n = 0;
        cpu_rd = 0; cpu_wr = 0;
        scenario_id = 0;

        reset_stats();
        #20 rst_n = 1;

        choice = 1;
        while (choice != 0) begin
            $display("\n====== CACHE TEST MENU ======");
            $display("1. Temporal Locality");
            $display("2. Spatial Locality");
            $display("3. Conflict Access (2-Way)");
            $display("4. Random Access");
            $display("5. Write & Read Back");
            $display("0. Exit");
            $write("Choice: ");
            $fscanf(32'h8000_0000, "%d", choice);

            case (choice)

            // 1. TEMPORAL: Truy cập cùng một địa chỉ liên tục
            1: begin
                integer k;
                scenario_id = 3'd1;
                for (k = 1000; k <= 20000; k += 1000) begin
                    reset_stats();
                    repeat (k) cpu_read(32'h0000_0100);
                    $display("Access=%0d HitRate=%3.2f%% AMAT=%3.2f",
                        total_access,
                        real'(hits)/total_access*100,
                        real'(total_access_cycles)/total_access);
                end
                evaluate_scenario("Temporal Locality");
            end

            // 2. SPATIAL: Truy cập 4 từ trong cùng 1 block 16-byte
            2: begin
                integer i, k;
                scenario_id = 3'd2;
                for (k = 100; k <= 2000; k += 100) begin
                    reset_stats();
                    for (i = 0; i < k; i++) begin
                        // Truy cập 4 địa chỉ liên tiếp cách nhau 4 bytes trong cùng 1 block
                        cpu_read(32'h0000_2000 + i*16 + 0);
                        cpu_read(32'h0000_2000 + i*16 + 4);
                        cpu_read(32'h0000_2000 + i*16 + 8);
                        cpu_read(32'h0000_2000 + i*16 + 12);
                    end
                    $display("Blocks=%0d HitRate=%3.2f%% AMAT=%3.2f",
                        k,
                        real'(hits)/total_access*100,
                        real'(total_access_cycles)/total_access);
                end
                evaluate_scenario("Spatial Locality");
            end

            // 3. CONFLICT: Kiểm tra 3 Tag tranh chấp 1 Index (Cache 2-Way)
            3: begin
                integer i, k;
                scenario_id = 3'd3;
                for (k = 100; k <= 3000; k += 200) begin
                    reset_stats();
                    for (i = 0; i < k; i++) begin
                        // A, B, C cùng Index (bit 10:4), khác Tag (bit 31:11)
                        cpu_read(32'h0000_0050); // Tag 0, Index 5
                        cpu_read(32'h0000_0850); // Tag 1, Index 5
                        cpu_read(32'h0001_0050); // Tag 2, Index 5 -> Gây ra replacement
                    end
                    $display("Iter=%0d HitRate=%3.2f%% AMAT=%3.2f",
                        k,
                        real'(hits)/total_access*100,
                        real'(total_access_cycles)/total_access);
                end
                evaluate_scenario("Conflict Access (2-Way)");
            end

            // 4. RANDOM: Giới hạn dải địa chỉ 64KB để đạt Hit Rate ~4-6%
            4: begin
                integer i, k;
                scenario_id = 3'd4;
                for (k = 1000; k <= 20000; k += 2000) begin
                    reset_stats();
                    for (i = 0; i < k; i++)
                        // Giới hạn trong vùng 64KB (16-bit) và align 16-byte
                        cpu_read(({$random} % 16'hFFFF) & 32'hFFFF_FFF0);
                    $display("Access=%0d HitRate=%3.2f%% AMAT=%3.2f",
                        total_access,
                        real'(hits)/total_access*100,
                        real'(total_access_cycles)/total_access);
                end
                evaluate_scenario("Random Access");
            end

            // 5. WRITE + READ: Kiểm tra ghi và đọc lại dữ liệu ngay lập tức
            5: begin
                integer i, k;
                scenario_id = 3'd5;
                for (k = 100; k <= 2000; k += 200) begin
                    reset_stats();
                    for (i = 0; i < k; i++) begin
                        cpu_write(32'h0000_8000 + i*4, i);
                        cpu_read (32'h0000_8000 + i*4);
                    end
                    $display("Pairs=%0d HitRate=%3.2f%% AMAT=%3.2f",
                        k,
                        real'(hits)/total_access*100,
                        real'(total_access_cycles)/total_access);
                end
                evaluate_scenario("Write & Read Back");
            end

            0: $display("Simulation finished.");
            default: $display("Invalid choice.");

            endcase
            #100;
        end
        $finish;
    end

endmodule