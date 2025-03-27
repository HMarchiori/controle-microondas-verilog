// -----------------------------------------------------------------------------
// Módulo: ctrl_microondas
// Descrição: Este módulo implementa o controle de um micro-ondas em Verilog,
//            incluindo funcionalidades como iniciar, pausar, parar, ajustar
//            potência e configurar o tempo de operação. Ele utiliza detectores
//            de borda para capturar eventos de entrada e gerencia estados
//            internos para controlar o comportamento do micro-ondas.
// -----------------------------------------------------------------------------

// Entradas:
// - clock: Sinal de clock do sistema.
// - reset: Sinal de reset para inicializar o sistema.
// - start: Sinal para iniciar o micro-ondas.
// - pause: Sinal para pausar o micro-ondas.
// - stop: Sinal para parar o micro-ondas.
// - potencia: Sinal para habilitar o ajuste de potência.
// - porta: Indica se a porta do micro-ondas está aberta (1) ou fechada (0).
// - mais: Sinal para incrementar o tempo ou potência.
// - menos: Sinal para decrementar o tempo ou potência.
// - sec_mod: Modo de ajuste de segundos (1 para ajuste em dezenas de segundos).
// - min_mod: Modo de ajuste de minutos (2'b01 para unidades, 2'b10 para dezenas).

// Saídas:
// - an: Controle dos displays de 7 segmentos (ativação dos dígitos).
// - dec_cat: Dados para os displays de 7 segmentos (catodo comum).
// - potencia_rgb: Indicação visual da potência em LEDs RGB (3 bits).

// Registros Internos:
// - EA: Estado atual do micro-ondas (idle, cd, paused).
// - PE: Próximo estado do micro-ondas.
// - timeSeconds: Contador de segundos do temporizador.
// - timeMinutes: Contador de minutos do temporizador.
// - potencia_reg: Registro para armazenar o nível de potência atual.

// Fios Internos:
// - timer_done: Indica quando o temporizador atinge zero.
// - dec_cat_pot: Dados para exibir o nível de potência no display.
// - dec_cat_timer: Dados para exibir o tempo restante no display.
// - start_rising, pause_rising, stop_rising, mais_rising, menos_rising:
//   Sinais de borda de subida para os respectivos botões.

// Submódulos:
// - edge_detector: Detecta bordas de subida nos sinais de entrada.
// - timer: Gerencia o temporizador do micro-ondas.

// Funcionamento:
// 1. O módulo utiliza uma máquina de estados finitos (FSM) com três estados:
//    - idle: Estado inicial e de espera.
//    - cd: Estado de contagem regressiva (micro-ondas em operação).
//    - paused: Estado de pausa.
// 2. A FSM muda de estado com base nos sinais de entrada (start, pause, stop)
//    e no estado da porta.
// 3. O temporizador é ajustado pelos botões "mais" e "menos", com suporte para
//    modos de ajuste de minutos e segundos.
// 4. A potência pode ser ajustada em três níveis (baixa, média, alta) usando
//    os botões "mais" e "menos" quando o sinal "potencia" está ativo.
// 5. O display de 7 segmentos exibe o tempo restante ou o nível de potência,
//    dependendo do estado atual do micro-ondas.
// 6. LEDs RGB indicam visualmente o nível de potência selecionado.

// Observações:
// - O módulo assume que os sinais de entrada são devidamente sincronizados
//   com o clock do sistema.
// - A FSM garante que o micro-ondas não opere com a porta aberta.
// -----------------------------------------------------------------------------

`timescale 1 ns/10ps
`define idle  2'b00
`define cd   2'b01
`define paused 2'b10

module ctrl_microondas
(
  input clock, reset,
  input start, pause, stop,
  input potencia, porta,
  input mais, menos,
  input sec_mod,
  input [1:0] min_mod,

  output [7:0] an, dec_cat,
  output reg [2:0] potencia_rgb
);

  reg [1:0] EA, PE;
  reg [6:0] timeSeconds, timeMinutes;
  reg [1:0] potencia_reg;
  wire timer_done;
  wire [7:0] dec_cat_pot, dec_cat_timer;
  wire start_rising, pause_rising, stop_rising, mais_rising, menos_rising;

  edge_detector start_edge (.clock(clock), .reset(reset), .din(start), .rising(start_rising));
  edge_detector pause_edge (.clock(clock), .reset(reset), .din(pause), .rising(pause_rising));
  edge_detector stop_edge (.clock(clock), .reset(reset), .din(stop), .rising(stop_rising));
  edge_detector mais_edge (.clock(clock), .reset(reset), .din(mais), .rising(mais_rising));
  edge_detector menos_edge (.clock(clock), .reset(reset), .din(menos), .rising(menos_rising));

  timer timer_inst (
    .clock(clock),
    .reset(reset),
    .min(timeMinutes),
    .sec(timeSeconds),
    .start(start_rising),
    .pause(pause_rising),
    .stop(stop_rising),
    .an(an),
    .dec_cat(dec_cat_timer), 
    .done(timer_done)
  );

  always @(posedge clock or posedge reset) begin
    if (reset == 1'b1) begin
      EA <= `idle;
    end else begin
      EA <= PE;
    end
  end

  always @(*) begin
    case(EA) 
      `idle: begin
        if (start_rising && !porta) begin
          PE <= `cd;
        end else begin
          PE <= `idle;
        end
      end

      `cd: begin
        if (timer_done || stop_rising) begin
          PE <= `idle;
        end else if (pause_rising || porta) begin
          PE <= `paused;
        end else begin
          PE <= `cd;
        end
      end

      `paused: begin
        if (start_rising && !porta) begin
          PE <= `cd;
        end else if (stop_rising) begin
          PE <= `idle;
        end else begin
          PE <= `paused;
        end
      end

      default: begin
        PE <= `idle;
      end
    endcase
  end

  always @(posedge clock or posedge reset) begin
    if (reset == 1'b1) begin
      potencia_reg <= 2'b00;
    end else begin
      if (potencia) begin
      if (mais_rising && potencia_reg < 2'b11) begin
        potencia_reg <= potencia_reg + 1;
      end else if (menos_rising && potencia_reg > 2'b00) begin
        potencia_reg <= potencia_reg - 1;
      end
    end
    end
  end

  assign dec_cat_pot = (potencia_reg == 2'b00) ? 8'b11101111 :
                       (potencia_reg == 2'b01) ? 8'b11111101 :
                       8'b01111111;

  assign dec_cat = (an == 8'b11011111) ? dec_cat_pot : dec_cat_timer;

  always @(EA) begin
    if (EA != `idle && potencia) begin
      case(potencia_reg)
        2'b00: potencia_rgb = 3'b001;
        2'b01: potencia_rgb = 3'b010;
        2'b10: potencia_rgb = 3'b100;
        default: potencia_rgb = 3'b000;
      endcase
    end
  end

  always @(posedge clock or posedge reset) begin
  if (reset == 1'b1) begin
    timeMinutes <= 7'd0;
    timeSeconds <= 7'd0;
  end else begin
    if (mais_rising) begin
      if (min_mod[1]) begin
        if (timeMinutes <= 89) begin
          timeMinutes <= timeMinutes + 10;
        end 
      end else if (min_mod[0]) begin
        if (timeMinutes < 99) begin
          timeMinutes <= timeMinutes + 1;
        end
      end else if (sec_mod) begin
        if (timeSeconds <= 49) begin
          timeSeconds <= timeSeconds + 10;
        end else if (timeMinutes < 99) begin
          timeSeconds <= timeSeconds + 10 - 60;
          timeMinutes <= timeMinutes + 1;
        end
      end else begin
        if (timeSeconds < 59) begin
          timeSeconds <= timeSeconds + 1;
        end else if (timeMinutes < 99) begin
          timeSeconds <= 0;
          timeMinutes <= timeMinutes + 1;
        end
      end
    end else if (menos_rising) begin
      if (min_mod[1]) begin
        if (timeMinutes >= 10) begin
          timeMinutes <= timeMinutes - 10;
        end
      end else if (min_mod[0]) begin
        if (timeMinutes > 0) begin
          timeMinutes <= timeMinutes - 1;
        end
      end else if (sec_mod) begin
        if (timeSeconds >= 10) begin
          timeSeconds <= timeSeconds - 10;
        end else if (timeMinutes > 0) begin
          timeSeconds <= timeSeconds + 60 - 10;
          timeMinutes <= timeMinutes - 1;
        end
      end else begin
        if (timeSeconds > 0) begin
          timeSeconds <= timeSeconds - 1;
        end else if (timeMinutes > 0) begin
          timeSeconds <= 59;
          timeMinutes <= timeMinutes - 1;
        end
      end
    end
  end
end

endmodule
