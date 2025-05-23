.syntax unified
.arch armv7-a
.thumb

.section .rodata
msg_enviando:       .ascii "Enviando dados para o coprocessador:\000"
msg_dados_enviados: .ascii "\012Dados enviados com sucesso!\000"
msg_processando:    .ascii "\012(Processando dados)\012\000"
msg_recebendo:      .ascii "Recebendo dados de volta:\000"
msg_dados_recebidos:.ascii "\012Dados recebidos com sucesso!\012\000"

.section .text
.align 2







@  =============================================================================
@  Função: enviar_dados_para_fpga
@  Parâmetros: 
@    r0 = LEDR_ptr (ponteiro base)
@    r1 = matrizA (ponteiro para matriz A)
@    r2 = matrizB (ponteiro para matriz B) 
@    r3 = data (dados de controle)
@  =============================================================================
.global enviar_dados_para_fpga
.thumb_func
enviar_dados_para_fpga:
    push    {r4-r7, lr}         @  Salva registradores
    sub     sp, sp, #32         @  Reserva espaço na stack
    mov     r7, sp              @  Frame pointer
    
    @  Salva parâmetros na stack
    str     r0, [r7, #12]       @  LEDR_ptr
    str     r1, [r7, #8]        @  matrizA  
    str     r2, [r7, #4]        @  matrizB
    strb    r3, [r7, #3]        @  data
    
    @  Calcula RETURN_ptr = LEDR_ptr + 16 (4 words)
    ldr     r3, [r7, #12]       @  Carrega LEDR_ptr
    add     r3, r3, #16         @  Adiciona offset
    str     r3, [r7, #20]       @  Salva RETURN_ptr
    
    @  Imprime mensagem inicial
    ldr     r0, =msg_enviando
    bl      puts
    
    @  Inicializa contador do loop (i = 0)
    mov     r3, #0
    str     r3, [r7, #16]       @  i = 0
    
loop_envio:
    @  Verifica se i < 25
    ldr     r3, [r7, #16]       @  Carrega i
    cmp     r3, #24
    bgt     fim_envio
    
    @  Aguarda FPGA ficar pronto (bit 31 do RETURN_ptr == 0)
espera_fpga_pronto:
    ldr     r3, [r7, #20]       @  Carrega RETURN_ptr
    ldr     r3, [r3, #0]        @  Lê valor do registrador
    tst     r3, #0x80000000     @  Testa bit 31
    bne     espera_fpga_pronto  @  Se bit 31 = 1, continua esperando
    
    @  Calcula índices da matriz (i/5 e i%5)
    ldr     r2, [r7, #16]       @  r2 = i
    
    @  Divisão por 5 usando multiplicação mágica
    @  Equivale a: linha = i / 5, coluna = i % 5
    movw    r3, #26215          @  Constante mágica para divisão por 5
    movt    r3, #26214
    smull   r1, r3, r3, r2      @  Multiplicação 64 bits
    asr     r1, r3, #1          @  Shift aritmético
    asr     r3, r2, #31         @  Sinal
    sub     r4, r1, r3          @  r4 = linha = i/5
    
    @  Calcula coluna: i - (linha * 5)
    mov     r3, r4              @  r3 = linha
    lsl     r3, r3, #2          @  linha * 4
    add     r3, r3, r4          @  linha * 5
    sub     r5, r2, r3          @  r5 = coluna = i % 5
    
    @  Lê valor da matrizA[linha][coluna]
    ldr     r2, [r7, #8]        @  Carrega ponteiro matrizA
    mov     r3, r4              @  linha
    lsl     r3, r3, #2          @  linha * 4
    add     r3, r3, r4          @  linha * 5 
    add     r0, r2, r3          @  matrizA + (linha * 5)
    ldrb    r3, [r0, r5]        @  matrizA[linha][coluna]
    strb    r3, [r7, #30]       @  Salva valA
    
    @  Lê valor da matrizB[linha][coluna] (mesmo cálculo)
    ldr     r2, [r7, #4]        @  Carrega ponteiro matrizB
    mov     r3, r4              @  linha
    lsl     r3, r3, #2          @  linha * 4
    add     r3, r3, r4          @  linha * 5
    add     r0, r2, r3          @  matrizB + (linha * 5)
    ldrb    r3, [r0, r5]        @  matrizB[linha][coluna]
    strb    r3, [r7, #31]       @  Salva valB
    
    @  Monta palavra de 32 bits: word = valA | (valB << 8) | (data << 16)
    mov     r3, #0              @  word = 0
    str     r3, [r7, #24]
    
    ldrb    r3, [r7, #30]       @  Carrega valA
    ldr     r2, [r7, #24]       @  Carrega word atual
    orr     r3, r3, r2          @  word |= valA
    str     r3, [r7, #24]       @  Salva word
    
    ldrb    r3, [r7, #31]       @  Carrega valB
    lsl     r3, r3, #8          @  valB << 8
    ldr     r2, [r7, #24]       @  Carrega word atual
    orr     r3, r3, r2          @  word |= (valB << 8)
    str     r3, [r7, #24]       @  Salva word
    
    ldrb    r3, [r7, #3]        @  Carrega data
    and     r3, r3, #63         @  Máscara 6 bits
    lsl     r3, r3, #16         @  data << 16
    ldr     r2, [r7, #24]       @  Carrega word atual
    orr     r3, r3, r2          @  word |= (data << 16)
    str     r3, [r7, #24]       @  Salva word final
    
    @  Escreve palavra no registrador LEDR
    ldr     r3, [r7, #12]       @  Carrega LEDR_ptr
    ldr     r2, [r7, #24]       @  Carrega word
    str     r2, [r3, #0]        @  *LEDR_ptr = word
    
    @  Sinaliza início da transmissão (bit 31 = 1)
    ldr     r3, [r7, #12]       @  Carrega LEDR_ptr
    ldr     r3, [r3, #0]        @  Lê valor atual
    orr     r2, r3, #0x80000000 @  Seta bit 31
    ldr     r3, [r7, #12]       @  Carrega LEDR_ptr
    str     r2, [r3, #0]        @  Escreve de volta
    
    @  Aguarda confirmação do FPGA (bit 31 do RETURN_ptr == 1)
espera_confirmacao:
    ldr     r3, [r7, #20]       @  Carrega RETURN_ptr
    ldr     r3, [r3, #0]        @  Lê valor
    tst     r3, #0x80000000     @  Testa bit 31
    beq     espera_confirmacao  @  Se bit 31 = 0, continua esperando
    
    @  Limpa sinal de transmissão (bit 31 = 0)
    ldr     r3, [r7, #12]       @  Carrega LEDR_ptr
    ldr     r3, [r3, #0]        @  Lê valor atual
    bic     r2, r3, #0x80000000 @  Limpa bit 31
    ldr     r3, [r7, #12]       @  Carrega LEDR_ptr
    str     r2, [r3, #0]        @  Escreve de volta
    
    @  Atualiza barra de progresso
    ldr     r3, [r7, #16]       @  Carrega i
    add     r0, r3, #1          @  i + 1 (para progresso)
    mov     r1, #25             @  Total
    bl      print_progress_bar
    
    @  Delay
    movw    r0, #34464          @  100ms em microssegundos
    movt    r0, #1
    bl      usleep
    
    @  Incrementa contador
    ldr     r3, [r7, #16]       @  Carrega i
    add     r3, r3, #1          @  i++
    str     r3, [r7, #16]       @  Salva i
    
    b       loop_envio          @  Volta para o loop

fim_envio:
    @  Imprime mensagem final
    ldr     r0, =msg_dados_enviados
    bl      puts
    
    @  Restaura stack e retorna
    add     sp, sp, #32
    pop     {r4-r7, pc}











@  =============================================================================
@  Função: receber_dados_da_fpga
@  Parâmetros:
@    r0 = LEDR_ptr (ponteiro base)
@    r1 = matrizC (ponteiro para matriz resultado)
@  =============================================================================
.global receber_dados_da_fpga
.thumb_func
receber_dados_da_fpga:
    push    {r4-r7, lr}         @  Salva registradores
    sub     sp, sp, #24         @  Reserva espaço na stack
    mov     r7, sp              @  Frame pointer
    
    @  Salva parâmetros
    str     r0, [r7, #4]        @  LEDR_ptr
    str     r1, [r7, #0]        @  matrizC
    
    @  Calcula RETURN_ptr = LEDR_ptr + 16
    ldr     r3, [r7, #4]        @  Carrega LEDR_ptr
    add     r3, r3, #16         @  Adiciona offset
    str     r3, [r7, #16]       @  Salva RETURN_ptr
    
    @  Imprime mensagens iniciais
    ldr     r0, =msg_processando
    bl      puts
    ldr     r0, =msg_recebendo
    bl      puts
    
    @  Inicializa contador (indice = 0)
    mov     r3, #0
    str     r3, [r7, #12]       @  indice = 0
    
loop_recebimento:
    @  Verifica se indice < 25
    ldr     r3, [r7, #12]       @  Carrega indice
    cmp     r3, #24
    bgt     fim_recebimento
    
    @  Aguarda dados válidos (bit 30 do RETURN_ptr == 1)
espera_dados_validos:
    ldr     r3, [r7, #16]       @  Carrega RETURN_ptr
    ldr     r3, [r3, #0]        @  Lê valor
    tst     r3, #0x40000000     @  Testa bit 30
    beq     espera_dados_validos @  Se bit 30 = 0, continua esperando
    
    @  Lê dado do registrador
    ldr     r3, [r7, #16]       @  Carrega RETURN_ptr
    ldr     r3, [r3, #0]        @  Lê dado
    str     r3, [r7, #20]       @  Salva dado
    
    @  Verifica se ainda há mais de 3 elementos para processar
    ldr     r3, [r7, #12]       @  Carrega indice
    cmp     r3, #21
    bgt     processa_ultimo_elemento
    
    @  Processa 3 elementos de uma vez
    @  Elemento 1: dado[7:0] -> matrizC[indice/5][indice%5]
    ldr     r2, [r7, #12]       @  r2 = indice
    
    @  Calcula linha e coluna para elemento atual
    movw    r3, #26215          @  Constante mágica
    movt    r3, #26214
    smull   r1, r3, r3, r2      @  Divisão por 5
    asr     r1, r3, #1
    asr     r3, r2, #31
    sub     r4, r1, r3          @  r4 = linha
    mov     r3, r4
    lsl     r3, r3, #2
    add     r3, r3, r4          @  linha * 5
    sub     r5, r2, r3          @  r5 = coluna
    
    ldr     r2, [r7, #0]        @  Carrega matrizC
    mov     r3, r4
    lsl     r3, r3, #2
    add     r3, r3, r4          @  linha * 5
    add     r0, r2, r3          @  matrizC + (linha * 5)
    ldr     r3, [r7, #20]       @  Carrega dado
    uxtb    r3, r3              @  Extrai byte inferior
    strb    r3, [r0, r5]        @  matrizC[linha][coluna] = dado[7:0]
    
    @  Elemento 2: dado[15:8] -> matrizC[(indice+1)/5][(indice+1)%5]
    ldr     r3, [r7, #12]       @  Carrega indice
    add     r2, r3, #1          @  indice + 1
    
    @  Calcula linha e coluna para indice+1
    movw    r3, #26215
    movt    r3, #26214
    smull   r1, r3, r3, r2
    asr     r1, r3, #1
    asr     r3, r2, #31
    sub     r4, r1, r3          @  linha
    mov     r3, r4
    lsl     r3, r3, #2
    add     r3, r3, r4
    sub     r5, r2, r3          @  coluna
    
    ldr     r2, [r7, #0]        @  matrizC
    mov     r3, r4
    lsl     r3, r3, #2
    add     r3, r3, r4
    add     r0, r2, r3
    ldr     r3, [r7, #20]       @  Carrega dado
    lsr     r3, r3, #8          @  Desloca para pegar bits 15:8
    uxtb    r3, r3
    strb    r3, [r0, r5]        @  matrizC[linha][coluna] = dado[15:8]
    
    @  Elemento 3: dado[23:16] -> matrizC[(indice+2)/5][(indice+2)%5]
    ldr     r3, [r7, #12]       @  Carrega indice
    add     r2, r3, #2          @  indice + 2
    
    @  Calcula linha e coluna para indice+2
    movw    r3, #26215
    movt    r3, #26214
    smull   r1, r3, r3, r2
    asr     r1, r3, #1
    asr     r3, r2, #31
    sub     r4, r1, r3          @  linha
    mov     r3, r4
    lsl     r3, r3, #2
    add     r3, r3, r4
    sub     r5, r2, r3          @  coluna
    
    ldr     r2, [r7, #0]        @  matrizC
    mov     r3, r4
    lsl     r3, r3, #2
    add     r3, r3, r4
    add     r0, r2, r3
    ldr     r3, [r7, #20]       @  Carrega dado
    lsr     r3, r3, #16         @  Desloca para pegar bits 23:16
    uxtb    r3, r3
    strb    r3, [r0, r5]        @  matrizC[linha][coluna] = dado[23:16]
    
    @  Incrementa indice em 3
    ldr     r3, [r7, #12]
    add     r3, r3, #3
    str     r3, [r7, #12]
    
    b       confirma_recebimento

processa_ultimo_elemento:
    @  Processa último elemento: matrizC[4][4] = dado[7:0]
    ldr     r3, [r7, #0]        @  matrizC
    add     r3, r3, #20         @  Vai para última linha (4*5)
    ldr     r2, [r7, #20]       @  Carrega dado
    uxtb    r2, r2              @  Extrai byte inferior
    strb    r2, [r3, #4]        @  matrizC[4][4] = dado[7:0]
    
    @  Incrementa indice
    ldr     r3, [r7, #12]
    add     r3, r3, #1
    str     r3, [r7, #12]

confirma_recebimento:
    @  Confirma recebimento (seta bit 30)
    ldr     r3, [r7, #4]        @  LEDR_ptr
    ldr     r3, [r3, #0]        @  Lê valor atual
    orr     r2, r3, #0x40000000 @  Seta bit 30
    ldr     r3, [r7, #4]        @  LEDR_ptr
    str     r2, [r3, #0]        @  Escreve de volta
    
    @  Aguarda FPGA confirmar (bit 30 do RETURN_ptr == 0)
espera_ack_fpga:
    ldr     r3, [r7, #16]       @  RETURN_ptr
    ldr     r3, [r3, #0]        @  Lê valor
    tst     r3, #0x40000000     @  Testa bit 30
    bne     espera_ack_fpga     @  Se bit 30 = 1, continua esperando
    
    @  Limpa confirmação (bit 30 = 0)
    ldr     r3, [r7, #4]        @  LEDR_ptr
    ldr     r3, [r3, #0]        @  Lê valor atual
    bic     r2, r3, #0x40000000 @  Limpa bit 30
    ldr     r3, [r7, #4]        @  LEDR_ptr
    str     r2, [r3, #0]        @  Escreve de volta
    
    @  Atualiza barra de progresso
    ldr     r3, [r7, #12]       @  Carrega indice
    cmp     r3, #25             @  Se indice > 25
    it      ge
    movge   r3, #25             @  Limita a 25
    mov     r0, r3              @  Progresso atual
    mov     r1, #25             @  Total
    bl      print_progress_bar
    
    @  Delay
    movw    r0, #34464          @  100ms
    movt    r0, #1
    bl      usleep
    
    b       loop_recebimento    @  Volta para o loop

fim_recebimento:
    @  Imprime mensagem final
    ldr     r0, =msg_dados_recebidos
    bl      puts
    
    @  Restaura stack e retorna
    add     sp, sp, #24
    pop     {r4-r7, pc}

@.end


.syntax unified
.arch armv7-a
.thumb

.section .rodata
msg_erro_dev_mem:    .ascii "ERRO: não foi possível abrir \"/dev/mem\"...\000"
msg_erro_mmap:       .ascii "ERRO: mmap() falhou...\000"
path_dev_mem:        .ascii "/dev/mem\000"

.section .text
.align 2

@ =============================================================================
@ Função: configurar_mapeamento
@ Descrição: Configura mapeamento de memória para acesso ao hardware
@ Parâmetros: 
@   r0 = ponteiro para variável que receberá o file descriptor
@ Retorna:
@   r0 = ponteiro virtual para memória mapeada (ou NULL se erro)
@ =============================================================================
.global configurar_mapeamento
.thumb_func
configurar_mapeamento:
    push    {r7, lr}            @ Salva frame pointer e link register
    sub     sp, sp, #24         @ Reserva 24 bytes na stack para variáveis locais
    add     r7, sp, #8          @ Configura frame pointer (sp + 8)
    
    @ Salva parâmetro na stack
    str     r0, [r7, #4]        @ fd_ptr = r0 (ponteiro para file descriptor)
    
    @ =========================================================================
    @ PASSO 1: Abrir /dev/mem
    @ =========================================================================
    ldr     r0, =path_dev_mem    @ r0 = "/dev/mem"
    movw    r1, #4098            @ r1 = O_RDWR | O_SYNC (4098)
    bl      open                 @ Chama open("/dev/mem", O_RDWR | O_SYNC)
    
    @ Salva file descriptor retornado
    mov     r2, r0               @ r2 = fd retornado por open()
    ldr     r3, [r7, #4]         @ r3 = fd_ptr
    str     r2, [r3, #0]         @ *fd_ptr = fd
    
    @ Verifica se open() falhou
    ldr     r3, [r7, #4]         @ r3 = fd_ptr
    ldr     r3, [r3, #0]         @ r3 = *fd_ptr (file descriptor)
    cmp     r3, #-1              @ Compara fd com -1 (erro)
    bne     fazer_mapeamento     @ Se fd != -1, pula para mapeamento
    
    @ Se chegou aqui, open() falhou
    ldr     r0, =msg_erro_dev_mem @ Carrega mensagem de erro
    bl      puts                 @ Imprime erro
    mov     r3, #0               @ Retorna NULL
    b       fim_funcao           @ Vai para o fim
    
fazer_mapeamento:
    @ =========================================================================
    @ PASSO 2: Fazer mapeamento de memória com mmap()
    @ =========================================================================
    
    @ Preparar parâmetros para mmap()
    @ mmap(addr, length, prot, flags, fd, offset)
    
    ldr     r3, [r7, #4]         @ r3 = fd_ptr
    ldr     r3, [r3, #0]         @ r3 = fd
    str     r3, [sp, #0]         @ Param 5: fd na stack
    
    mov     r3, #0               @ Prepara parte baixa do offset
    movt    r3, #65312           @ r3 = 0xFF000000 (65312 = 0xFF00)
    str     r3, [sp, #4]         @ Param 6: offset = 0xFF000000 na stack
    
    mov     r0, #0               @ Param 1: addr = NULL (deixa sistema escolher)
    movw    r1, #20480           @ Param 2: length = 20480 bytes (0x5000)
    mov     r2, #3               @ Param 3: prot = PROT_READ | PROT_WRITE
    mov     r3, #1               @ Param 4: flags = MAP_SHARED
    
    bl      mmap                 @ Chama mmap()
    
    str     r0, [r7, #12]        @ Salva ponteiro virtual retornado
    
    @ Verifica se mmap() falhou
    ldr     r3, [r7, #12]        @ r3 = ponteiro virtual
    cmp     r3, #-1              @ Compara com MAP_FAILED (-1)
    bne     mapeamento_sucesso   @ Se não falhou, pula para sucesso
    
    @ Se chegou aqui, mmap() falhou
    ldr     r0, =msg_erro_mmap   @ Carrega mensagem de erro
    bl      puts                 @ Imprime erro
    
    @ Fecha file descriptor antes de retornar
    ldr     r3, [r7, #4]         @ r3 = fd_ptr
    ldr     r3, [r3, #0]         @ r3 = fd
    mov     r0, r3               @ r0 = fd
    bl      close                @ Fecha arquivo
    
    mov     r3, #0               @ Retorna NULL
    b       fim_funcao           @ Vai para o fim
    
mapeamento_sucesso:
    @ Se chegou aqui, mmap() teve sucesso
    ldr     r3, [r7, #12]        @ r3 = ponteiro virtual (valor de retorno)
    
fim_funcao:
    @ Restaura stack e retorna
    mov     r0, r3               @ r0 = valor de retorno
    add     r7, r7, #16          @ Restaura frame pointer
    mov     sp, r7               @ Restaura stack pointer
    pop     {r7, pc}             @ Restaura registradores e retorna

@ =============================================================================
@ EXPLICAÇÃO DA FUNÇÃO:
@ 
@ 1. A função abre o arquivo especial /dev/mem que permite acesso direto à
@    memória física do sistema
@ 
@ 2. Usa mmap() para mapear uma região de memória física (0xFF000000) para
@    o espaço virtual do processo, permitindo acesso direto ao hardware
@ 
@ 3. Parâmetros do mmap():
@    - addr = NULL: deixa o sistema escolher o endereço virtual
@    - length = 20480: mapeia 20KB de memória
@    - prot = PROT_READ|PROT_WRITE: permite leitura e escrita
@    - flags = MAP_SHARED: mudanças são visíveis para outros processos
@    - fd = file descriptor do /dev/mem
@    - offset = 0xFF000000: endereço físico base a ser mapeado
@ 
@ 4. Retorna o ponteiro virtual para a memória mapeada, ou NULL se erro
@ =============================================================================

.end
