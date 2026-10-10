`include "cache_params.vh" 

module cache_tag_array (
    input wire clk,
    input wire rst,
    
    // Tín hiệu từ CPU
    input wire [`ADDR_WIDTH-1:0] addr,
    input wire wr_en,           // 1: Write, 0: Read
    
    // Tín hiệu từ Cache Controller (Bộ điều khiển)
    input wire update_en,       // Bật lên khi nạp xong dữ liệu từ RAM -> Cache
    
    // Output gửi đi
    output wire hit,            // 1: Trúng, 0: Trượt
    output wire hit_way,        // 0: Trúng ở Way 0, 1: Trúng ở Way 1 (để MUX chọn data)
    
    // Output phục vụ cho việc thay thế (Replacement Policy)
    output wire dirty_victim,   // Dòng sắp bị đuổi có Dirty không?
    output wire [`TAG_WIDTH-1:0] tag_victim // Tag của dòng sắp bị đuổi (để ghi trả RAM)
);

    // --- 1. Tách địa chỉ (Decode Address) ---
    wire [`INDEX_WIDTH-1:0] index = addr[`INDEX_RANGE]; // Bit [10:4]
    wire [`TAG_WIDTH-1:0]   tag   = addr[`TAG_RANGE];   // Bit [31:11]

    // --- 2. Khai báo bộ nhớ (Storage) ---
    // Vì là 2-way nên ta cần 2 bảng riêng biệt cho mỗi Way
    reg [`TAG_WIDTH-1:0] tag_way0 [0:`NUM_SETS-1];
    reg [`TAG_WIDTH-1:0] tag_way1 [0:`NUM_SETS-1];
    
    reg [`NUM_SETS-1:0] valid0, valid1; // Mảng 1 bit cho Valid
    reg [`NUM_SETS-1:0] dirty0, dirty1; // Mảng 1 bit cho Dirty
    reg [`NUM_SETS-1:0] lru;            // Mảng 1 bit cho LRU (0: Way0 cũ hơn, 1: Way1 cũ hơn)

    integer i;

    // --- 3. Logic So sánh (Comparator Logic) ---
    // Kiểm tra xem Tag có khớp và Valid có = 1 không
    assign match0 = valid0[index] && (tag_way0[index] == tag);
    assign match1 = valid1[index] && (tag_way1[index] == tag);

    // Kết quả Hit tổng
    assign hit = match0 || match1;
    
    // Xác định trúng ở Way nào (Nếu match1 thì là 1, ngược lại là 0)
    assign hit_way = match1; 

    // --- 4. Logic Thay thế (Eviction Logic) ---
    // Xác định "Nạn nhân" dựa trên bit LRU hiện tại
    // Nếu lru[index] == 0 nghĩa là Way 0 ít dùng -> Nạn nhân là Way 0
    wire victim_is_way1 = lru[index]; // 0: Way0, 1: Way1

    // Lấy thông tin nạn nhân để báo cho Controller
    assign dirty_victim = (victim_is_way1) ? dirty1[index] : dirty0[index];
    assign tag_victim   = (victim_is_way1) ? tag_way1[index] : tag_way0[index];

    // --- 5. Logic Cập nhật Trạng thái (Sequential Logic) ---
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            valid0 <= 0;
            valid1 <= 0;
            dirty0 <= 0;
            dirty1 <= 0;
            lru    <= 0;
            // Không cần reset Tag Array để tiết kiệm tài nguyên
        end 
        else begin
            // TRƯỜNG HỢP A: CACHE HIT (Đọc hoặc Ghi đều cập nhật LRU)
            if (hit) begin
                // 1. Cập nhật LRU: Vừa dùng Way nào thì đảo chiều LRU sang Way kia
                if (match0) lru[index] <= 1'b1; // Vừa dùng 0 -> Way 1 sẽ là nạn nhân
                else        lru[index] <= 1'b0; // Vừa dùng 1 -> Way 0 sẽ là nạn nhân
                
                // 2. Nếu là Ghi (Write Hit) -> Cập nhật Dirty Bit
                if (wr_en) begin
                    if (match0) dirty0[index] <= 1'b1;
                    else        dirty1[index] <= 1'b1;
                end
            end
            
            // TRƯỜNG HỢP B: NẠP TỪ RAM (MISS & UPDATE)
            else if (update_en) begin
                // Nạp vào Way "nạn nhân" (được chỉ bởi LRU)
                if (lru[index] == 1'b0) begin 
                    // Nạp vào Way 0
                    tag_way0[index] <= tag;     // Lưu Tag mới
                    valid0[index]   <= 1'b1;    // Bật Valid
                    dirty0[index]   <= wr_en;   // Nếu nạp để ghi (Write Miss) -> Dirty=1, Nạp để đọc -> Dirty=0
                    lru[index]      <= 1'b1;    // Nạp xong Way 0 -> Way 1 sẽ là nạn nhân tiếp theo
                end 
                else begin
                    // Nạp vào Way 1
                    tag_way1[index] <= tag;
                    valid1[index]   <= 1'b1;
                    dirty1[index]   <= wr_en;
                    lru[index]      <= 1'b0;
                end
            end
        end
    end

endmodule
