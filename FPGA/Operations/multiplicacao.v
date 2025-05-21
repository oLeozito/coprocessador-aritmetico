module multiplicacao (
    input  [199:0] matrix_a,   // 25 valores de 8 bits
    input  [199:0] matrix_b,   // 25 valores de 8 bits
    output reg [199:0] result_out, // 25 resultados de 8 bits
    output reg overflow_flag
);

    integer i;
    reg [7:0] a_elem, b_elem;
    reg [15:0] product;
    reg local_overflow;

    always @(*) begin
        result_out = 0;
        local_overflow = 0;

        for (i = 0; i < 25; i = i + 1) begin
            a_elem = matrix_a[(i*8) +: 8];
            b_elem = matrix_b[(i*8) +: 8];

            product = a_elem * b_elem;

            // Verifica overflow se resultado não cabe em 8 bits
            if (product > 8'hFF)
                local_overflow = 1;

            result_out[(i*8) +: 8] = product[7:0]; // só os 8 bits inferiores
        end

        overflow_flag = local_overflow;
    end

endmodule
