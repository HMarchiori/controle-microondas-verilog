# Controle Microondas em Verilog

Este projeto em Verilog implementa dois módulos principais para o controle de um timer, componente de um sistema de microondas. O microondas possui uma máquina de estados finita, controle lógico para ativação, pausa e finalização, além de controle de potência ajustável por meio de controles físicos.

## Módulos Principais

### 1. Timer (`timer`)
- Implementa um cronômetro que conta o tempo em minutos e segundos.
- Controla início, pausa e parada através de sinais de controle.
- Utiliza um circuito de detecção de borda para reconhecer transições de sinais e um contador de 1 segundo baseado no relógio do sistema.
- Exibe o tempo no display de 7 segmentos.

### 2. Controle de Microondas (`ctrl_microondas`)
- Gerencia a operação do microondas com funcionalidades de temporizador e ajuste de potência.
- Integra o módulo `timer`, permitindo ajustes de minutos e segundos, além de controle de potência com sinais de incremento e decremento.
- A potência é ajustada em três níveis (indicados por um valor RGB).
- O status do timer (iniciado, pausado ou concluído) é exibido no display de 7 segmentos.

## Funcionalidades Principais

### Timer
- Inicializa com o tempo fornecido em minutos e segundos.
- Realiza contagem regressiva com decremento de 1 segundo.
- Permite controle de início, pausa e parada.
- Exibe o tempo restante no display de 7 segmentos.

### Controle de Microondas
- Permite ajustes de tempo e potência.
- Ajusta o tempo com incremento ou decremento de minutos e segundos.
- Altera a potência entre três níveis com feedback visual (RGB).
- Interface com o usuário por meio de botões para iniciar, pausar e ajustar tempo e potência.

## Considerações Técnicas

- **Sincronização:** O uso de sinais de borda (`edge_detector`) garante que eventos como início, pausa, parada e alteração de potência sejam reconhecidos com precisão, evitando leituras incorretas.
- **Display de 7 Segmentos:** O tempo e a potência são apresentados em displays de 7 segmentos, com lógica de decodificação para números e cores RGB (para níveis de potência).
- **Contagem e Controle:** A contagem do tempo é baseada em um relógio de 1 segundo gerado por um contador. A potência é ajustada por um valor binário traduzido para um sinal RGB.

---
