module soma(
    input clk,
    input [31:0] entrada,
    output reg [31:0] saida
);

always @(posedge clk) begin
    saida <= entrada[11:4] + entrada[19:12];
end


endmodule
