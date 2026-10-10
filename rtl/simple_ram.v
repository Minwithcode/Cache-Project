`include "cache_params.vh"

module simple_ram (
    input  wire                   clk,
    input  wire                   rst_n,
    input  wire                   req,    // Nối với refill_mode từ Controller
    input  wire [`ADDR_WIDTH-1:0] addr,   // Địa chỉ bắt đầu của block cần nạp

    output reg  [`DATA_WIDTH-1:0] data,
    output reg                    valid
);

    // Bộ nhớ RAM 4KB (1024 từ 32-bit)
    reg [`DATA_WIDTH-1:0] mem [0:1023];

    // Thanh ghi nội bộ để quản lý địa chỉ nạp block
    reg [`ADDR_WIDTH-1:0] current_addr;
    reg req_d; // Trễ 1 chu kỳ của req để bắt cạnh lên

    // 1. Khởi tạo dữ liệu mẫu để Debug
    integer i;
    initial begin
        for (i = 0; i < 1024; i = i + 1)
            mem[i] = 32'h1000_0000 + i; // Dữ liệu = 0x10000000 + index
    end

    // 2. Logic điều khiển địa chỉ
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            current_addr <= 0;
            req_d        <= 0;
            data         <= 0;
            valid        <= 0;
        end else begin
            req_d <= req;

            if (req) begin
                // Nếu vừa mới bắt đầu yêu cầu (Cạnh lên của req)
                if (!req_d) begin
                    // Căn chỉnh địa chỉ về đầu Block (xóa 4 bit thấp - Offset)
                    current_addr <= (addr & 32'hFFFF_FFF0); 
                end else begin
                    // Tăng địa chỉ lên 4 byte (1 word) mỗi chu kỳ để nạp block
                    current_addr <= current_addr + 4;
                end

                // Truy xuất dữ liệu (Giới hạn trong 1024 words bằng cách dùng bit [11:2])
                data  <= mem[current_addr[11:2]];
                valid <= 1'b1;
            end else begin
                valid <= 1'b0;
            end
        end
    end

endmodule