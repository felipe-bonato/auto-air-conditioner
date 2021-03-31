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
    
    
.data 1064h ; Temperatura atual
    DB 17h  ; 23 em hexa 

.data 1065h ; Temperatura target
    DB 23h  ; 35 em dec 

.data 1066h ; Numero de pessoas na sala
    DB 00h  

; 10 0011

.org 2000h

CALL turn_off_seg

CALL read_initial_temperature

loop:

    CALL read_sens_mov
    LDA 1066h
    CPI 0h
    JZ loop
    
    CALL print_seg
    CALL read_sens_control
    CALL read_sens_temp
JMP loop

read_sens_mov:
    IN 0h
    ; Sensor de Movimento
    CPI 10000000b ; Lê sensor A
    CZ on_enter
    CPI 01000000b ; Lê sensor B
    CZ on_exit

RET

read_sens_temp:
    LDA 1066h
    CPI 0h
    CNZ read_temp

RET

read_sens_control:

    IN 00h
    ; Controle Remoto
    CPI 00000001b   ; Aumenta temperatura target
    CZ increse_target_temp
    CPI 00000010b   ; Diminui temperatura target
    CZ decrease_target_temp

RET

increse_target_temp:
    LXI H, 1065h
    MOV A, M
    
    CPI 31h     ; checa se a temperatura que está tentando ser setada é maior que 49
    RZ
    
    INR M
RET

decrease_target_temp:
    LXI H, 1065h
    MOV A, M
    
    CPI 00h         ; Checagem para a temperatura não ficar negativa
    RZ

    DCR M
RET

print_seg:

    ; Target        Atual
    ; 0 X X 0       0 X X 0
    ; 0h-----------------07h
    
    ; Target
    LDA 1065h
    RLC         ; Multiplica por 2
    MVI H, 10h  ; Parte alta do endereço
    MOV L, A    ; M contem o endereço pra codigo do display de 7 seg
    MOV A, M    ; Move a parte menos significativa
    OUT 02h
    INR L       ; Incrementa pra pegar a parte mais significativa
    MOV A, M    ; Move a parte mais significativa
    OUT 01h

    ; Atual
    LDA 1064h
    RLC
    MVI H, 10h
    MOV L, A
    MOV A, M
    OUT 06h
    INR L
    MOV A, M
    OUT 05h

RET

turn_off_seg:
    MVI A, 0h
    OUT 0h
    OUT 1h
    OUT 2h
    OUT 3h
    OUT 4h
    OUT 5h
    OUT 6h
    OUT 7h
RET


on_enter:
    LXI H, 1066H
    INR M
RET

on_exit:
    LXI H, 1066h
    MOV A, M
    CPI 0h
    RZ

    DCR M
    
    CZ turn_off_seg

RET

read_initial_temperature:

    IN 01h
    STA 1064h

RET

read_temp:
    LXI H, 1064h            ; atual  0001 1001 19h
    LDA 1065h               ; target

    CMP M

    RZ                      ; Retorna se temperatura igual
    CP increase_temp        ; P salto se positivo (S=0),
    CM decrease_temp        ; M salto se negativo (S=1)
RET

increase_temp:
    MOV A, M
    CPI 31h                 ; Checagem para a temperatura não ficar acima de 49
    RZ

    INR M
RET

decrease_temp:
    MOV A, M
    CPI 00h                 ; Checagem para a temperatura não ficar negativa
    RZ

    DCR M
RET


HLT
