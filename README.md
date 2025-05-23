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

- `enviar_dados_para_FPGA`: Envia os dados para a FPGA.
- `receber_dados_da_FPGA`: Recebe os dados do FPGA.
- `configurar_mapeamento`: Configura o mapeamento de memória da ponte (Lightweight Bridge).

Cada função é responsável por acessar diretamente os endereços mapeados da FPGA via ponte HPS–FPGA.

#### `enviar_dados_para_FPGA`

#### `receber_dados_para_FPGA`

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
