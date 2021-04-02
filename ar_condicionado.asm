;                Trabalho Assembly de Arquitetura e Organização de Computadores
;
;
;                           ┌────────────────────────────────┐
;                           │   Ar Condicionado Automático   │
;                           └────────┬──────────────┬────────┘
;                                    │ Versão: 1.00 │
;                                    └──────────────┘
;
;
; Alunos:
;   - Felipe Bonato     [17201767]
;   - Thomas Bugs       [17202852]
;
;                                           Enunciado 
; 
; Desenvolver um projeto prático no simulador 8085.
; A aplicação a ser desenvolvida será parte do projeto.
; Ideias como um controle de semáforo, relógio digital são exemplos.
;
; Os critérios mínimos são:
;
; a) 
;   O sistema poderá trabalhar somente com variáveis digitais. Temos os interruptores e teclado
;   que podem simular estas variáveis. Os interruptores pode simular sensores, botões, etc. No
;   mínimo 4 variáveis de entrada.
;
; b)
;   As saídas podem ser os leds, simulando atuadores(motores, válvulas, lâmpadas, etc), display de
;   7 segmentos, alfanuméricos e as telas gráficas. Pelo menos 3 variáveis de saída.
;
; c)
;   O programa será avaliado pela quantidade de diferentes comandos usados e a complexidade
;   computacional.
;
; d)
;   O projeto deverá ser postado no moodle com um vídeo explicando a simulação.





.data 1000h
	; Dados para o display de 7 segmentos
    ;  0      1      2      3      4      5      6      7      8      9  
    DW 7777h, 7744h, 773Eh, 776Eh, 774Dh, 776Bh, 777Bh, 7746h, 777Fh, 774Fh
    ;  10
    DW 4477h, 4444h, 443Eh, 446Eh, 444Dh, 446Bh, 447Bh, 4446h, 447Fh, 444Fh
    ;  20
    DW 3E77h, 3E44h, 3E3Eh, 3E6Eh, 3E4Dh, 3E6Bh, 3E7Bh, 3E46h, 3E7Fh, 3E4Fh
    ;  30
    DW 6E77h, 6E44h, 6E3Eh, 6E6Eh, 6E4Dh, 6E6Bh, 6E7Bh, 6E46h, 6E7Fh, 6E4Fh
    ;  40
    DW 4D77h, 4D44h, 4D3Eh, 4D6Eh, 4D4Dh, 4D6Bh, 4D7Bh, 4D46h, 4D7Fh, 4D4Fh 
    
    
.data 1064h                     ; Temperatura atual
    DB 17h                      ; 23 em dec 

.data 1065h                     ; Temperatura target
    DB 19h                      ; 25 em dec 

.data 1066h                     ; Numero de pessoas na sala
    DB 00h

.data 1512h                     ; Seed para o gerador de números aleatórios
    DB 10101010b

;                               INPUT
; ┌───────────────────────────────────────────────────────────────┐
; │   PORTA       00h         => Controle (Esquerda para direita) │
; │          7º Interruptor   -> Controle diminuir temperatura    │
; │                              desejada                         │
; │          8º Interruptor   -> Controle aumentar temperatura    │
; │                              desejada                         │
; │   PORTA       01h         => Sensores movimento               │
; │          1º Interruptor   -> Sensor movimento entrada         │
; │          2º Interruptor   -> Sensor movimento saída           │
; │   PORTA       02h         => Sensor de temperatura            │
; └───────────────────────────────────────────────────────────────┘
;
;                               OUTPUT
; ┌───────────────────────────────────────────────────────────────┐
; │   PORTAS  00h até 07h     => Displays 7 segmentos             │
; │   PORTA       08h         => Led indicação estado             │
; └───────────────────────────────────────────────────────────────┘


;                   ┌────────────────────────┐
;                   │    INÍCIO DO CÓDIGO    │
;                   └────────────────────────┘

.org 2000h

CALL turn_off_seg               ; Limpar saída dos displays 7 segmentos

CALL read_initial_temperature   ; Leitura inicial de temperatura

loop:                           ; Loop principal

    CALL read_sens_mov          ; Chamada leitura movimento
    LDA 1066h                   ; Checagem se há pessoas na sala
    CPI 0h
    JZ loop
    
    CALL print_seg              ; Chamada para atualizar os displays 7 segmentos
    CALL read_sens_control      ; Chamada para ler o controle remoto
    CALL read_sens_temp         ; Chamada para ler a temperatura

    CALL ajust_ambient_temp     ; Chamada para simular a variação da temperatura quando 
                                ; a temperatura atual e desejada estiverem iguais
JMP loop

read_sens_mov:                  ; Leitura dos sensores de movimento
    IN 01h
    ; Sensor de Movimento
    CPI 10000000b               ; Lê sensor A (Entrada)
    CZ on_enter
    CPI 01000000b               ; Lê sensor B (Saída)
    CZ on_exit

RET

read_sens_temp:                 ; Sub-Rotina para realizar a comparação de temperaturas
                                ; (target com atual) e 
                                ; manipular o motor do ar para aumentar ou diminuir a temperatura
    LXI H, 1064h                ; Atual
    LDA 1065h                   ; Target

    CMP M

    RZ                          ; Retorna se temperatura igual
    CP increase_temp            ; P salto se positivo (S=0), a temperatura atual é < que a target
    CM decrease_temp            ; M salto se negativo (S=1), a tempertaura atual é > que a target
RET

read_sens_control:              ; Leitura do controle remoto do ar condicionado

    IN 00h                      ; Controle Remoto

    CPI 00000001b               ; Aumentar temperatura target
    CZ increse_target_temp
    CPI 00000010b               ; Diminuir temperatura target
    CZ decrease_target_temp

RET

increse_target_temp:            ; Incremento da temperatura desejada do ar condicionado
    LXI H, 1065h
    MOV A, M
    
    CPI 28h                     ; Checar se a temperatura que está tentando ser setada é >= 40
    RZ
    
    INR M
RET

decrease_target_temp:           ; Decremento da temperatura desejada do ar condicionado
    LXI H, 1065h
    MOV A, M
    
    CPI 0Fh                     ; Checar para a temperatura não é <= 15
    RZ

    DCR M
RET

print_seg:                      ; Mostrar nos displays 7 segmentos as temperaturas desejada e atual

    ; Target        Atual
    ; 0 X X 0       0 X X 0
    ; 0h-----------------07h
    
    ; Target
    LDA 1065h
    RLC                         ; Multiplica por 2
    MVI H, 10h                  ; Parte alta do endereço
    MOV L, A                    ; M contem o endereço pra codigo do display de 7 seg
    MOV A, M                    ; Move a parte menos significativa
    OUT 02h
    INR L                       ; Incrementa pra pegar a parte mais significativa
    MOV A, M                    ; Move a parte mais significativa
    OUT 01h

    ; Atual
    LDA 1064h                   ; Segue a mesma ideia que a Target
    RLC
    MVI H, 10h
    MOV L, A
    MOV A, M
    OUT 06h
    INR L
    MOV A, M
    OUT 05h

RET

turn_off_seg:                   ; Limpar/Desligar os displays 7 segmentos e o led    
    MVI A, 0h
    OUT 00h
    OUT 01h
    OUT 02h
    OUT 03h
    OUT 04h
    OUT 05h
    OUT 06h
    OUT 07h

    OUT 08h                      ; Desligar a led
RET


on_enter:                       ; Simular a leitura de sensores com a entrada de pessoas na sala
    LXI H, 1066H
    INR M

    MVI A, FFH
    OUT 08h
RET

on_exit:                        ; Simular a leitura de sensores com a saída de pessoas na sala
    LXI H, 1066h                ; Carregar para o M (HL) o valor 1066h (Número de pessoas na sala)
    MOV A, M                    ; Mover para o acumulador o valor para onde M aponta
    CPI 00h                     ; Comparar acumulador com 00h
    RZ                          ; Se forem iguais retorna e não faz nada

    DCR M                       ; Decremento do numero de pessoas na sala
    
    CZ turn_off_seg             ; Se após o decremento não haver pessoas na sala, desliga o ar

RET

ajust_ambient_temp:             ; Muda a temperatura ambiente aleatoriamente
    CALL random_number
    LDA 1512h
    CPI 55h                     ; 1/3 chance de não fazer nada, 1/3 aumentar, 1/3 diminuir
    RM                          ; Não faz nada
    LDA 1512h
    CPI AAh
    CM increase_temp
    LDA 1512h
    CPI AAh
    CP decrease_temp
RET

random_number:                  ; Algoritmo xor shift
    LDA 1512h                   ; seed
    INR A
    MOV B, A
    LDA 1064h                   ; temp atual, usado para adicionar aleatoriedade
    XRA B
    RLC
    RLC
    RLC
    XRA B
    MOV B, A
    INR A
    RLC
    XRA B
    INR A
    STA 1512h                   ; Usar o número como próxima seed
RET

read_initial_temperature:       ; Ler a temperatura ambiente do sensor
    IN 02h
    STA 1064h

RET

increase_temp:                  ; Simulação do ar codicionado aumentando a temperatura ambiente
    LXI H, 1064h
    MOV A, M
    CPI 31h                     ; Checagem para a temperatura não ficar acima de 49
    RZ

    INR M
RET

decrease_temp:                  ; Simulação do ar condicionado diminuindo a temperatura ambiente
    LXI H, 1064h
    MOV A, M
    CPI 00h                     ; Checagem para a temperatura não ficar negativa
    RZ

    DCR M
RET

HLT
