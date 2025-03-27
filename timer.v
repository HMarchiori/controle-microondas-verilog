//-----------------------------------------------------------------------------
// Módulo: timer
// Descrição: Implementa um temporizador para controle de micro-ondas com 
//            funcionalidades de iniciar, pausar e parar. O temporizador 
//            também exibe o tempo restante em displays de 7 segmentos.
// Entradas:
//   - clock: Sinal de clock do sistema.
//   - reset: Sinal de reset para inicializar o temporizador.
//   - min: Valor inicial dos minutos (7 bits).
//   - sec: Valor inicial dos segundos (7 bits).
//   - start: Sinal para iniciar o temporizador.
//   - pause: Sinal para pausar o temporizador.
//   - stop: Sinal para parar o temporizador.
// Saídas:
//   - an: Controle dos displays de 7 segmentos (8 bits).
//   - dec_cat: Dados para os displays de 7 segmentos (8 bits).
//   - done: Indica que o temporizador terminou (1 bit).
// Dependências:
//   - edge_detector: Módulo para detectar bordas de sinais.
//   - dspl_drv_NexysA7: Driver para controlar os displays de 7 segmentos.
// Funcionamento:
//   - O temporizador possui três estados principais: `idle` (inativo), 
//     `cd` (contagem regressiva) e `paused` (pausado).
//   - O estado é controlado por sinais de borda (start, pause, stop) e 
//     pelo tempo restante (minutos e segundos).
//   - O tempo é decrementado a cada segundo enquanto o temporizador está 
//     no estado `cd`.
//   - O tempo inicial é carregado quando o temporizador está no estado `idle`.
//   - O módulo também calcula os dígitos individuais para exibição nos 
//     displays de 7 segmentos.
// Notas:
//   - O clock interno para contagem de segundos é gerado dividindo o clock 
//     principal.
//   - O temporizador retorna ao estado `idle` quando o tempo chega a zero 
//     ou quando o sinal de stop é ativado.
//-----------------------------------------------------------------------------

`timescale 1 ns/10ps
`define idle   2'b00
`define cd     2'b01
`define paused 2'b10

module timer
(
    input clock, reset,
    input [6:0] min, sec,
    input start, pause, stop,
    output [7:0] an, dec_cat, 
    output done
);
    wire start_rising, pause_rising, stop_rising;

    wire [5:0] d1,d2,d3,d4,d5,d6,d7,d8; 

    reg [1:0] EA, PE;

    reg ck1seg;
    reg [6:0] timeSeconds;
    reg [6:0] timeMinutes;
    reg [25:0] timeClock;       
    wire [3:0] min_units;
    wire [3:0] min_tens;
    wire [3:0] sec_units;
    wire [3:0] sec_tens;


    edge_detector start_edge (.clock(clock), .reset(reset), .din(start), .rising(start_rising));
    edge_detector pause_edge (.clock(clock), .reset(reset), .din(pause), .rising(pause_rising));
    edge_detector stop_edge  (.clock(clock), .reset(reset), .din(stop), .rising(stop_rising));

    always @(posedge clock or posedge reset)
    begin
        if (reset == 1'b1) begin
            ck1seg <= 1'b0;
            timeClock <= 0;
        end
        else if (timeClock > 49999999) begin
            ck1seg <= ~ck1seg;
            timeClock <= 0;
        end
        else begin
            timeClock <= timeClock + 1;
        end
    end

    always @(posedge clock or posedge reset)
    begin  
        if (reset == 1'b1) begin
            EA <= `idle;
        end else begin
            EA <= PE;
        end
    end
    
    always @(*)
    begin
        case (EA)
            `idle: begin
                if (start_rising) begin
                    PE = `cd;
                end else begin
                    PE = `idle;
                end
            end

            `cd: begin
                if (pause_rising) begin
                    PE = `paused;
                end else if (stop_rising || (timeMinutes == 0 && timeSeconds == 0)) begin
                    PE = `idle;
                end else begin
                    PE = `cd;
                end
            end

            `paused: begin
                if (stop_rising) begin
                    PE = `idle;
                end else if (pause_rising) begin
                    PE = `cd;
                end else begin
                    PE = `paused;
                end
            end

            default:
                PE = `idle;
        endcase
    end

    always @(posedge ck1seg or posedge reset)
    begin
        if (reset == 1'b1) begin
            timeSeconds <= 0;
            timeMinutes <= 0;
        end else if (EA == `idle) begin
            timeMinutes <= min;
            timeSeconds <= sec;
        end else if (EA == `cd) begin
            if (timeSeconds > 0) begin
                timeSeconds <= timeSeconds - 1;
            end else if (timeMinutes > 0) begin
                timeSeconds <= 59;
                timeMinutes <= timeMinutes - 1;
            end
        end
    end

        assign done = (EA == `idle && timeSeconds == 1'b0 && timeMinutes == 1'b0) ? 1'b1 : 1'b0;
        assign min_units = timeMinutes % 4'd10;
        assign min_tens = timeMinutes / 4'd10;
        assign sec_units = timeSeconds % 4'd10;
        assign sec_tens = timeSeconds / 4'd10;

        assign d1 = {1'b1, sec_units, 1'b0};
        assign d2 = {1'b1, sec_tens, 1'b0};
        assign d3 = {1'b1, min_units, 1'b1};
        assign d4 = {1'b1, min_tens, 1'b0};
        assign d5 = 6'b0;
        assign d6 = 6'b100000;
        assign d7 = 6'b0;
        assign d8 = 6'b0;

    dspl_drv_NexysA7 display_driver (
        .clock(clock),
        .reset(reset),
        .d1(d1),
        .d2(d2),
        .d3(d3),
        .d4(d4),
        .d5(d5),
        .d6(d6),
        .d7(d7),
        .d8(d8),
        .an(an),
        .dec_cat(dec_cat)
    );

endmodule
