module gerenciador(
    input clk,
    input reset,
    input [31:0] entrada,
    output reg [31:0] saida
);

    // Instância do coprocessador
    coprocessador cop (
        .clk(clk),
        .rst(reset),
        .op(opcode),
        .matriz1(matriz1),
        .matriz2(matriz2),
        .matrizresult(matriz_C),
        .done(done)
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

    reg [199:0] matriz1, matriz2;
    wire [224:0] matriz_C;

    reg leu;
    reg carregouC;
    wire done;

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
                proximo_estado = (done && carregouC) ? ENVIO : CALCULO;

            ENVIO:
                proximo_estado = (i_envio == 8 && entrada[30] && !saida[30]) ? ESPERA : ENVIO;

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
            carregouC <= 0;
        end else begin
            case (estado_atual)
                ESPERA: begin
                    saida <= 0;
                    leu <= 0;
                    i_envio <= 0;
                    indice_envio <= 0;
                    carregouC <= 0;
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

                        // Montar matriz1 e matriz2 após a leitura completa
                        if (indice == 24) begin
                            integer k;
                            for (k = 0; k < 25; k = k + 1) begin
                                matriz1[k*8 +: 8] <= matrizA[k];
                                matriz2[k*8 +: 8] <= matrizB[k];
                            end
                        end

                        leu <= 0;
                    end
                end

                CALCULO: begin
                    if (done && !carregouC) begin
                        integer j;
                        for (j = 0; j < 25; j = j + 1) begin
                            matrizC[j] <= matriz_C[j*9 +: 9];
                        end
                        carregouC <= 1;
                    end
                end

                ENVIO: begin
                    if (i_envio < 8) begin
                        if (!saida[30]) begin
                            saida[8:0]   <= matrizC[indice_envio];
                            saida[17:9]  <= matrizC[indice_envio + 1];
                            saida[26:18] <= matrizC[indice_envio + 2];
                            saida[30]    <= 1;
                        end
                        if (entrada[30]) begin
                            saida[30] <= 0;
                            indice_envio <= indice_envio + 3;
                            i_envio <= i_envio + 1;
                        end
                    end else begin
                        if (!saida[30]) begin
                            saida[8:0] <= matrizC[24];
                            saida[30]  <= 1;
                        end
                        if (entrada[30]) begin
                            saida[30] <= 0;
                        end
                    end
                end
            endcase
        end
    end
endmodule
