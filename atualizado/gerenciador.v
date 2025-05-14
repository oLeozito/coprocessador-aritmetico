module gerencia (
    input clk,
    input reset,
    input [31:0] entrada,
    input pronto_coprocessador,
    input [8:0] entrada_matrizC,
    input flag_lido,                  // entrada[30] da HPS
    output reg [31:0] saida
);

    // Estados
    parameter ESPERA  = 2'b00;
    parameter LEITURA = 2'b01;
    parameter CALCULO = 2'b10;
    parameter ENVIO   = 2'b11;

    reg [1:0] estado_atual, proximo_estado;

    reg [4:0] indice;
    reg [4:0] indice_envio;
    reg [2:0] i_envio;
    reg [2:0] opcode;
    reg [7:0] matrizA [0:24];
    reg [7:0] matrizB [0:24];
    reg [8:0] matrizC [0:24];
    reg [4:0] contador_entradaC;

    reg leu;
    reg carregandoC;

    wire [7:0] valA = entrada[11:4];
    wire [7:0] valB = entrada[19:12];
    wire [2:0] op   = entrada[3:1];
    wire flag_HPS   = entrada[0];

    // Estado Atual
    always @(posedge clk or posedge reset) begin
        if (reset)
            estado_atual <= ESPERA;
        else
            estado_atual <= proximo_estado;
    end

    // Transição de Estado
    always @(*) begin
        case (estado_atual)
            ESPERA:
                proximo_estado = flag_HPS ? LEITURA : ESPERA;

            LEITURA:
                proximo_estado = (indice == 24 && !flag_HPS) ? CALCULO : LEITURA;

            CALCULO:
                proximo_estado = (pronto_coprocessador && !carregandoC) ? ENVIO : CALCULO;

            ENVIO:
                proximo_estado = (i_envio == 8 && flag_lido && !saida[30]) ? ESPERA : ENVIO;

            default:
                proximo_estado = ESPERA;
        endcase
    end

    // Máquina de Estados Principal
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            saida <= 0;
            indice <= 0;
            leu <= 0;
            i_envio <= 0;
            indice_envio <= 0;
            contador_entradaC <= 0;
            carregandoC <= 0;
        end else begin
            case (estado_atual)
                ESPERA: begin
                    saida <= 0;
                    leu <= 0;
                    i_envio <= 0;
                    indice_envio <= 0;
                    contador_entradaC <= 0;
                    carregandoC <= 0;
                end

                LEITURA: begin
                    saida[0] <= 0;
                    if (!leu && flag_HPS) begin
                        matrizA[indice] <= valA;
                        matrizB[indice] <= valB;
                        opcode <= op;
                        saida[0] <= 1;
                        leu <= 1;
                    end
                    if (!flag_HPS && leu) begin
                        if (indice < 24)
                            indice <= indice + 1;
                        else
                            indice <= 0;
                        leu <= 0;
                    end
                end

                CALCULO: begin
                    // Recebe dados da matriz C
                    if (pronto_coprocessador && contador_entradaC <= 24) begin
                        matrizC[contador_entradaC] <= entrada_matrizC;
                        contador_entradaC <= contador_entradaC + 1;
                        carregandoC <= 1;
                    end
                    if (contador_entradaC == 25)
                        carregandoC <= 0;
                end

                ENVIO: begin
                    if (i_envio < 8) begin
                        if (!saida[30]) begin
                            saida[8:0]   <= matrizC[indice_envio];
                            saida[17:9]  <= matrizC[indice_envio + 1];
                            saida[26:18] <= matrizC[indice_envio + 2];
                            saida[30]    <= 1;
                        end
                        if (flag_lido) begin
                            saida[30] <= 0;
                            indice_envio <= indice_envio + 3;
                            i_envio <= i_envio + 1;
                        end
                    end else begin
                        // Último valor (índice 24)
                        if (!saida[30]) begin
                            saida[8:0] <= matrizC[24];
                            saida[30]  <= 1;
                        end
                        if (flag_lido) begin
                            saida[30] <= 0;
                        end
                    end
                end
            endcase
        end
    end
endmodule
