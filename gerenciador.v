module gerenciador(
    input clk,
    input reset,
    input [31:0] entrada,
    output reg [31:0] saida
);

    // Estados como números binários explícitos
    reg estado_atual;
    reg proximo_estado;
    reg [4:0] indice;
    reg [2:0] opcode;
    reg [7:0] matrizA [0:24];
    reg [7:0] matrizB [0:24];
    reg leu;

    wire [7:0] valA = entrada[7:0];
    wire [7:0] valB = entrada[15:8];
    wire [2:0] op   = entrada[18:16];
    wire flag_HPS  = entrada[31];

    // Estado atual
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            estado_atual <= 1'b0;
        end else begin
            estado_atual <= proximo_estado;
        end
    end

    // Transição de estado
    always @(*) begin
        case (estado_atual)
            1'b0: begin // Estado ESPERA
                if (flag_HPS)
                    proximo_estado = 1'b1;
                else
                    proximo_estado = 1'b0;
            end

            1'b1: begin // Estado LEITURA
                if (!flag_HPS)
                    proximo_estado = 1'b0;
                else
                    proximo_estado = 1'b1;
            end

            default: proximo_estado = 1'b0;
        endcase
    end

    // Ações em cada estado
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            saida <= 32'b0;
            indice <= 5'b0;
            leu <= 1'b0;
        end else begin
            case (estado_atual)
                1'b0: begin // Estado ESPERA
                    saida[31] <= 1'b0;
                    leu <= 1'b0;
                end

                1'b1: begin // Estado LEITURA
                    if (!leu) begin
                        matrizA[indice] <= valA;
                        matrizB[indice] <= valB;
                        opcode <= op;
                        saida[31] <= 1'b1;
                        leu <= 1'b1;
                    end

                    if (!flag_HPS) begin
                        if (indice == 5'd24)
                            indice <= 5'd0;
                        else
                            indice <= indice + 1'b1;
                    end
                end
            endcase
        end
    end

endmodule
