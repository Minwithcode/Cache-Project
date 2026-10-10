`ifndef ADDRESS_DECODER_V
`define ADDRESS_DECODER_V

`include "cache_params.vh"

module address_decoder (
    input  logic [`ADDR_WIDTH-1:0] i_addr,
    output logic [`TAG_WIDTH-1:0]    o_tag,
    output logic [`INDEX_WIDTH-1:0]  o_index,
    output logic [`OFFSET_WIDTH-1:0] o_offset
);
    // Đưa ra ngoài always_comb
    assign o_tag    = i_addr[`TAG_RANGE];   // Sử dụng macro đã định nghĩa trong params
    assign o_index  = i_addr[`INDEX_RANGE];
    assign o_offset = i_addr[`OFFSET_RANGE];

endmodule

`endif
