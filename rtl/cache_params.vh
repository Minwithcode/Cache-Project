`ifndef CACHE_PARAMS_VH
`define CACHE_PARAMS_VH

// =============================================================================
// FILE CẤU HÌNH DÙNG CHUNG CHO NHÓM (SHARED CONFIGURATION)
// Dự án: Mô phỏng Cache Memory 2-Way Set Associative
// =============================================================================

// -----------------------------------------------------------------------------
// 1. CÁC THÔNG SỐ CƠ BẢN (BASE PARAMETERS)
// -----------------------------------------------------------------------------
`define ADDR_WIDTH      32      // Độ rộng địa chỉ CPU (32-bit)
`define DATA_WIDTH      32      // Độ rộng dữ liệu 1 từ (1 Word = 4 Bytes)
`define CACHE_SIZE      4096    // Tổng dung lượng Cache (4 KB)
`define BLOCK_SIZE      16      // Kích thước 1 dòng Cache (16 Bytes)
`define WAYS            2       // Số đường (2-Way Set Associative)

// -----------------------------------------------------------------------------
// 2. TÍNH TOÁN CÁC THÔNG SỐ DẪN XUẤT (DERIVED PARAMETERS)
// -----------------------------------------------------------------------------
// Số lượng Sets = Cache Size / (Block Size * Ways) = 4096 / (16 * 2) = 128
`define NUM_SETS        128     
// Kích thước 1 dòng tính theo bit = 16 * 8 = 128 bit
`define BLOCK_WIDTH     128     
// Số lượng từ trong 1 dòng = 16 / 4 = 4 words
`define WORDS_PER_LINE  4       

// -----------------------------------------------------------------------------
// 3. PHÂN HOẠCH ĐỊA CHỈ (ADDRESS MAPPING)
// Cấu trúc 32-bit: [ Tag (21) | Index (7) | Offset (4) ]
// -----------------------------------------------------------------------------

// --- Offset: 4 bit [3:0] ---
// Bit [1:0]: Byte Offset (Thường là 00)
// Bit [3:2]: Word Offset (Chọn 1 trong 4 words)
`define OFFSET_WIDTH    4       
`define WORD_OFFSET_BIT 2       // Số bit để chọn Word

// --- Index: 7 bit [10:4] ---
// Dùng để chọn 1 trong 128 Sets (2^7 = 128)
`define INDEX_WIDTH     7       

// --- Tag: 21 bit [31:11] ---
// Phần còn lại: 32 - 7 - 4 = 21 bit
`define TAG_WIDTH       21      

// -----------------------------------------------------------------------------
// 4. BIT RANGES (Dùng để cắt bit địa chỉ trong code cho chuẩn)
// -----------------------------------------------------------------------------
// Ví dụ: wire [6:0] index = addr[`INDEX_RANGE];
`define OFFSET_RANGE    3:0
`define INDEX_RANGE     10:4
`define TAG_RANGE       31:11

// Dải bit chọn Word cụ thể (quan trọng cho MUX Data)
`define WORD_SELECT_RANGE 3:2   

`endif // CACHE_PARAMS_VH
