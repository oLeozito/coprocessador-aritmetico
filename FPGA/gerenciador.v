module gerenciador(
    input clk,
    input reset_flag,              // Vem do bit 29 do barramento de entrada.
	 input botao_rst,               // Botão de reset assincrono.
    input [31:0] entrada,          // Barramento de 32 bits de entrada. HPS-FPGA
    output reg [31:0] saida,       // Barramento de 32 bits de saída. FPGA-HPS
	 
	 // Pode excluir os dois abaixo. (Excluir da instancia no ghrd_top também).
    output reg [4:0] estado_leds,  // Sinais para debugar o codigo.
	 output reg [4:0]index
);

	assign flag_HPS = (entrada[31]);        // Flag que vem da HPS.
	assign reset = (botao_rst |reset_flag); // Se o botao for pressionado ou o sinal de reset entrada[29] = 1.


   // Instância do coprocessador
   coprocessador cop_inst (
		 .clk(clk),                    // Clock do sistema.
		 .start(start),					 // Inutilizado.
		 .tamanho(tamanho),            // Inutilizado.
		 .op(opcode),                  // Código da operação (3 bits).
		 .matriz1(matriz1),            // Matriz A (25 valores de 8 bits).
		 .matriz2(matriz2),            // Matriz B (25 valores de 8 bits).
		 .matrizresult(matriz_C),      // Matriz C (25 valores de 8 bits) resultado.
		 .overflow(overflow),          // Flag que indica overflow.
		 .done(done)                   // Flag de conclusão do processamento.
	);

    // ESTADOS
    parameter ESPERA  = 2'b00;
    parameter LEITURA = 2'b01;
    parameter CALCULO = 2'b10;
    parameter ENVIO   = 2'b11;

	 
	 // DECLARAÇÕES
	 
	 // Matrizes montadas.
	 reg [7:0] matrizA [0:24];
    reg [7:0] matrizB [0:24];
    reg [7:0] matrizC [0:24];
	 
	 // Matrizes achatadas.
    reg [199:0] matriz1;
	 reg [199:0] matriz2;
    wire [199:0] matriz_C;
	 
	 // Inicialização de variáveis.
    reg [1:0] estado_atual, proximo_estado = ESPERA;
	 reg [4:0] indice = 0;
    reg [4:0] indice_envio;
    reg [2:0] i_envio;
    reg [2:0] opcode;
	 reg [1:0] tamanho;
	 
	 reg start;
	 reg flag;
    reg leu;
    reg carregouC;

	 // Variaveis intermediárias
    wire [7:0] valA = entrada[7:0];
    wire [7:0] valB = entrada[15:8];
    wire [2:0] op = entrada[18:16];
	 wire [1:0] tam = entrada[20:19];
	 
	 wire overflow;
	 wire done;
	 
	 

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
                proximo_estado = flag ? CALCULO : LEITURA;

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
			   flag <= 0;
            saida <= 0;
            indice <= 0;
            leu <= 0;
            i_envio <= 0;
            indice_envio <= 0;
            carregouC <= 0;
				tamanho <= 0;
				start <= 0;
				opcode <= 3'b111;

				
        end else begin
            case (estado_atual)
                ESPERA: begin
                    saida <= 0;
                    leu <= 0;
						  indice <=0;
                    i_envio <= 0;
                    indice_envio <= 0;
                    carregouC <= 0;
						  flag <= 0;
						  tamanho <= 0;
						  start <= 0;
						  opcode <= 3'b111;
						  

                end

                LEITURA: begin
						 if (!leu && flag_HPS) begin
							  matrizA[indice] <= valA;
							  matrizB[indice] <= valB;
							  opcode <= op;
							  tamanho <= tam;
							  saida[31] <= 1;
							  leu <= 1;
						 end
						 if (!flag_HPS && leu) begin
							  if (indice < 24) begin
									index <= indice;
									estado_leds <= matrizA[indice];
									indice <= indice + 1;
									saida[31] <= 0;
									leu <= 0;
							  end
							  else if (indice == 24) begin
									integer k;
									for (k = 0; k < 25; k = k + 1) begin
										 matriz1[k*8 +: 8] <= matrizA[k];
										 matriz2[k*8 +: 8] <= matrizB[k];
										 index <= indice;
										 estado_leds <= matrizA[indice];
									end
									saida[31] <= 0;
									flag <= 1;
							  end 
						 end
					end


                CALCULO: begin
						  if(!done && !carregouC)begin
								opcode <= op;
								tamanho <= tam;
								start <= 1;
						  end
                    if (done && !carregouC) begin
                        integer j;
                        for (j = 0; j < 25; j = j + 1) begin
                            matrizC[j] <= matriz_C[j*8 +: 8];
                        end
								saida[29] <= overflow;
                        carregouC <= 1;
                    end
                end

                ENVIO: begin
                    if (i_envio < 8) begin
                        if (!saida[30] & !entrada[30]) begin
                            saida[7:0]   <= matrizC[indice_envio];
                            saida[15:8]  <= matrizC[indice_envio + 1];
                            saida[23:16] <= matrizC[indice_envio + 2];
                            saida[30]    <= 1;
                        end
                        if (entrada[30] & saida[30]) begin
                            saida[30] <= 0;
                            indice_envio <= indice_envio + 3;
                            i_envio <= i_envio + 1;
                        end
                    end else begin
                        if (!saida[30] & !entrada[30]) begin
                            saida[7:0] <= matrizC[24];
                            saida[30]  <= 1;
                        end
                        if (entrada[30] & saida[30]) begin
                            saida[30] <= 0;
                        end
                    end
                end
            endcase
        end
    end

endmodule
