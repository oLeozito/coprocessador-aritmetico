# Biblioteca Assembly para Multiplicação Matricial via Coprocessador – DE1-SoC

## 📌 Descrição do Projeto

Este projeto tem como objetivo o desenvolvimento de uma **biblioteca em linguagem Assembly** para a plataforma **DE1-SoC**, capaz de interagir com um **coprocessador aritmético especializado em multiplicação de matrizes**, previamente implementado na FPGA.  
A biblioteca facilita a utilização da aceleração em hardware para aplicações que realizam operações matriciais intensivas.

## 🎯 Objetivos de Aprendizagem

- Aplicar conhecimentos de interação hardware-software em sistemas embarcados;
- Compreender o mapeamento de memória entre o HPS (ARM Cortex-A9) e a FPGA;
- Utilizar a interface de comunicação entre HPS e FPGA na DE1-SoC;
- Desenvolver código Assembly compatível com arquitetura ARM;
- Entender aspectos de execução de código Assembly no Linux embarcado;
- Utilizar e integrar ferramentas de desenvolvimento e depuração para sistemas embarcados.

---

## 🛠️ Softwares e Ferramentas Utilizadas

| Ferramenta               | Versão/Descrição                                      |
|--------------------------|--------------------------------------------------------|
| Quartus Prime            | Configuração da FPGA e coprocessador                 |
| VS Code + Extensões      | Edição de código e integração com toolchain          |
| `arm-linux-gnueabihf-*`  | Assembler e linker para código Assembly ARM           |
| SCP/SSH                  | Transferência e execução de arquivos no HPS           |
| Make                     | Automação da compilação com `Makefile`                |
| GitHub                   | Repositório de código e documentação                  |

---

## 📦 Estrutura do Projeto

FAZER

---

## 📚 Descrição da Biblioteca

A biblioteca contém funções escritas em Assembly ARM que se comunicam com os registradores do coprocessador de multiplicação matricial mapeado na FPGA.

### 📌 Funções Implementadas 

- `enviar_dados_para_FPGA`
- `receber_dados_da_FPGA`
- `configurar_mapeamento`

Cada função é responsável por acessar diretamente os endereços mapeados da FPGA via ponte HPS–FPGA.

#### Módulo `enviar_dados_para_FPGA`

Este módulo, implementado em Assembly para ARM (Thumb), é responsável por enviar dados das matrizes A e B para a FPGA, um elemento comum em sistemas embarcados com coprocessadores personalizados. A função recebe como parâmetros os ponteiros para a base dos registradores de controle da FPGA (LEDR_ptr), as duas matrizes 5x5 (matrizA e matrizB) e um byte de controle (data).

O envio é feito célula a célula (25 no total), obedecendo o seguinte protocolo:

1. Sincronização com a FPGA: antes de cada envio, o processador verifica se a FPGA está pronta (bit 31 de um registrador de status deve estar em 0).

2. Formação da palavra de controle: para cada par de elementos correspondentes nas matrizes A e B, é construída uma palavra de 32 bits no formato:
   ```bash
    word = valA | (valB << 8) | (data << 16)
    ```
3. Envio e sinalização: essa palavra é escrita no registrador da FPGA e o bit 31 é setado para indicar que há novos dados.

4. Confirmação: o sistema aguarda até a FPGA confirmar a leitura, setando o bit 31 do registrador de retorno.

5. Limpeza do sinal e progresso: o bit de controle é limpo e a barra de progresso é atualizada no terminal.

A função utiliza otimizações como divisão inteira por 5 com multiplicação e acesso direto a elementos da matriz por aritmética de ponteiros. Ao final do processo, uma mensagem de confirmação é impressa.

Esse módulo é essencial para a comunicação eficaz entre o processador ARM e a lógica configurável da FPGA, garantindo envio ordenado, seguro e sincronizado dos dados.

#### Módulo `receber_dados_para_FPGA`

Este módulo, implementado em Assembly ARM, é responsável por realizar a leitura dos dados provenientes da FPGA e armazená-los em uma matriz 5x5 (representada por matrizC). Os dados são recebidos em blocos de 24 bits, sendo três elementos de 8 bits por ciclo de leitura. O processo segue uma lógica de sincronização utilizando o bit 30 de um registrador de controle (RETURN_ptr) para indicar quando há dados válidos prontos para leitura e quando a FPGA reconheceu a leitura.

O fluxo principal do módulo inclui:

1. nicialização de ponteiros e mensagens ao usuário.

2. Loop de recepção que percorre todos os 25 elementos da matriz.

3. A cada iteração, lê um valor de 24 bits da FPGA e distribui seus 3 bytes consecutivos nas posições corretas da matriz.

4. No final de cada leitura, confirma a recepção para a FPGA e espera o acknowledgment.

5. Atualiza uma barra de progresso visual para indicar o avanço da transferência.

6. Após concluir a leitura de todos os dados, imprime uma mensagem final e retorna.

O módulo faz uso de instruções específicas para cálculo eficiente de divisões por 5 (para calcular linha e coluna), manipulação de bits, e sincronização com hardware externo, demonstrando integração direta entre o processador ARM e a FPGA no sistema embarcado DE1-SoC.

#### `configurar_mapeamento`

---

## ⚙️ Compilação e Execução

### 🔧 Requisitos

- Toolchain `arm-linux-gnueabihf-`
- Acesso à DE1-SoC com Linux embarcado
- Comunicação via SSH/SCP entre host e DE1-SoC

### 🔨 Compilação

CORRiGIR

```bash
make
scp main root@<IP_DA_FPGA>:/home/root/
ssh root@<IP_DA_FPGA>
./main
```

---

## 🧪 Testes e Validação

Foram realizados testes comparando os resultados da multiplicação acelerada por hardware com os resultados obtidos por uma multiplicação feita puramente em software.

### Exemplos de Casos de Teste

| Matriz A         | Matriz B         | Resultado Esperado | Status |
|------------------|------------------|---------------------|--------|
| [[1, 2], [3, 4]] | [[5, 6], [7, 8]] | [[19, 22], [43, 50]]| OK     |
| [[1, 0], [0, 1]] | [[a, b], [c, d]] | [[a, b], [c, d]]    | OK     |

Critérios de validação:

- Correção dos resultados;
- Tolerância a entradas inválidas;
- Comparação de desempenho (tempo com/sem coprocessador).

---

## 🔍 Mapeamento de Memória 

| Endereço (hex)  | Registrador        | Descrição                         |
|------------------|---------------------|-------------------------------------|
| `0xFF200000`     | `LEDR_ptr`          | Endereço de ida da ponte            |
| `0xFF200010`     | `RETURN_ptr`        | Endereço volta da ponte             |

> CONFERIR ENDEREÇOS

---

## 📖 Referências

- Manual da DE1-SoC – Terasic  
- [MaJerle Code Style Guide](https://github.com/MaJerle/c-code-style)  
- Notas de aula de Sistemas Digitais – UEFS  
- Documentação do compilador `arm-linux-gnueabihf-gcc` e do assembler `as`  

---

## 👥 Equipe

- João Marcelo Nascimento Fernandes
- Leonardo Oliveira Almeida da Cruz
- João Gabriel Santos Silva

---

## 📄 Licença

Este projeto é parte de uma atividade acadêmica da Universidade Estadual de Feira de Santana (UEFS)  
e é distribuído apenas para fins educacionais. Nenhum uso comercial é autorizado.
