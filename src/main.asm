; ==============================================================================
; PROJ-C64-POKER: Motor de Logica de Cartas y Pantalla Principal de Apuestas
; Target: MOS 6502 / Commodore 64
; Assembler: 64tass
; Iniciativa: C64P-001
;
; Mapeo de Componentes y data-testid (UX/UI y Arquitectura):
; - data-testid="screen-container" : Matriz VIC-II Screen RAM ($0400-$07E7) y Color RAM ($D800-$DBE7)
; - data-testid="status-header"    : Cabecera Fila 0 ($0400-$0427) "*** C64 POKER ENGINE v1.0 - VIC-II 40X25 ***"
; - data-testid="card-slot-1"      : Fila 7-11 Col 4  (Carta 1)
; - data-testid="card-slot-2"      : Fila 7-11 Col 10 (Carta 2)
; - data-testid="card-slot-3"      : Fila 7-11 Col 16 (Carta 3)
; - data-testid="card-slot-4"      : Fila 7-11 Col 22 (Carta 4)
; - data-testid="card-slot-5"      : Fila 7-11 Col 28 (Carta 5)
; - data-testid="chip-panel"       : Fila 23 ($0798-$07BF) "FICHAS: 1000        POZO: 20"
; - data-testid="terminal-log"     : Filas 19-21 ($06F8-$076F) Mensajes del Dealer / Log
; - data-testid="kbd-help"         : Fila 24 ($07C0-$07E7) "ESPACIO: BARAJAR Y REPARTIR   R: RETIRAR"
; ==============================================================================

* = $0801

; ------------------------------------------------------------------------------
; BASIC Loader Stub: 10 SYS 2062 ($080E)
; ------------------------------------------------------------------------------
        .byte $0b, $08          ; Enlace a la siguiente linea BASIC ($080b)
        .byte $0a, $00          ; Numero de linea 10 ($000a)
        .byte $9e               ; Token SYS
        .byte $32, $30, $36, $32 ; "2062" en ASCII/PETSCII
        .byte $00               ; Fin de linea BASIC
        .byte $00, $00          ; Fin del programa BASIC

* = $080E

; ------------------------------------------------------------------------------
; Constantes y Registros de Hardware VIC-II, SID y KERNAL
; ------------------------------------------------------------------------------
VIC_CTRL1       = $d011
VIC_BORDER      = $d020
VIC_BG0         = $d021
VIC_BORDER_COLOR = $d020
VIC_BG_COLOR    = $d021
VIC_CHARPTR     = $d018

SID_V3_FREQ_LO  = $d40e
SID_V3_FREQ_HI  = $d40f
SID_CTRL        = $d412
SID_NOISE       = $d41b
SID_ENV3        = $d41c

KEY_GETIN       = $ffe4

SCREEN_RAM      = $0400
COLOR_RAM       = $d800

; Paleta Oficial de Colores VIC-II
COLOR_BLACK     = $00
COLOR_WHITE     = $01
COLOR_RED       = $02
COLOR_CYAN      = $03
COLOR_PURPLE    = $04
COLOR_GREEN     = $05
COLOR_BLUE      = $06
COLOR_YELLOW    = $07
COLOR_ORANGE    = $08
COLOR_BROWN     = $09
COLOR_LIGHT_RED = $0a
COLOR_DARK_GREY = $0b
COLOR_GREY      = $0c
COLOR_LIGHT_GREEN = $0d
COLOR_LIGHT_BLUE = $0e
COLOR_LIGHT_GREY = $0f

; Ubicacion de Datos del Juego
DECK_BASE       = $1000         ; Array de 52 bytes para el mazo
DECK_PTR        = $fb           ; Puntero en Zero Page para la siguiente carta

; Variables de Estado de Negocio (Gherkin BDD: Pozo 20 créditos, Saldo 1000 créditos)
pot_amount      = $0014         ; 20 créditos iniciales (0020 dec = $0014 hex)
player_credits  = $03e8         ; 1000 créditos meta ($03E8 hex = 1000 dec)

; ==============================================================================
; Punto de Entrada Principal (SYS_START)
; ==============================================================================
start
SYS_START
        sei                     ; Deshabilitar interrupciones temporalmente

        ; Activar pantalla en VIC_CTRL1 (Bit 4 encendido)
        lda     VIC_CTRL1
        ora     #$10
        sta     VIC_CTRL1

        ; Configurar Borde (Negro $00) y Tapete Verde Oscuro ($05)
        lda     #COLOR_BLACK
        sta     VIC_BORDER
        lda     #COLOR_GREEN
        sta     VIC_BG0

        jsr     CLEAR_SCREEN    ; Limpiar los 1000 bytes de pantalla con espacios
        jsr     INIT_DECK       ; Inicializar mazo con las 52 cartas unicas (1-52)
        jsr     INIT_SID_RNG    ; Inicializar generador de ruido blanco SID
        jsr     DRAW_STATIC_UI  ; Renderizar cabecera, log y panel de fichas

        cli                     ; Rehabilitar interrupciones

        ; Barajado inicial y reparto de bienvenida
        jsr     SHUFFLE_DECK
        jsr     DRAW_CARDS

; ------------------------------------------------------------------------------
; Bucle Principal del Juego (Espera de Teclado)
; ------------------------------------------------------------------------------
MAIN_LOOP
        jsr     KEY_GETIN
        beq     MAIN_LOOP       ; Si no hay tecla presionada, esperar

        cmp     #$20            ; Barra espaciadora (ESPACIO = BARAJAR Y REPARTIR)
        beq     HANDLE_SPACE

        cmp     #'R'            ; Tecla 'R' (RETIRAR)
        beq     HANDLE_RETIRE

        jmp     MAIN_LOOP

HANDLE_SPACE
        jsr     SHUFFLE_DECK
        jsr     DRAW_CARDS
        jmp     MAIN_LOOP

HANDLE_RETIRE
        jsr     DRAW_RETIRE_MSG
        jmp     MAIN_LOOP

; ==============================================================================
; Rutina: Limpieza Total de Pantalla (40x25 celdas con $20 Espacio)
; data-testid="screen-container"
; ==============================================================================
CLEAR_SCREEN
        ldx     #$00
CL_LOOP
        lda     #$20            ; Caracter Espacio PETSCII
        sta     SCREEN_RAM,x
        sta     SCREEN_RAM+$100,x
        sta     SCREEN_RAM+$200,x
        sta     SCREEN_RAM+$2e8,x

        lda     #COLOR_GREEN    ; Atributo de color tapete verde
        sta     COLOR_RAM,x
        sta     COLOR_RAM+$100,x
        sta     COLOR_RAM+$200,x
        sta     COLOR_RAM+$2e8,x

        inx
        bne     CL_LOOP
        rts

; ==============================================================================
; Rutina: Inicializar Mazo de 52 Cartas en $1000
; Cartas unicas indexadas de 0 a 51 (Valor: bits 0-3, Palo: bits 4-5)
; ==============================================================================
INIT_DECK
        ldx     #$00
INIT_LOOP
        txa
        sta     DECK_BASE,x     ; Cada posicion recibe un indice unico 0..51
        inx
        cpx     #52
        bne     INIT_LOOP

        lda     #$00
        sta     DECK_PTR        ; Puntero de mazo en la cima
        rts

; ==============================================================================
; Rutina: Configurar Generador de Ruido SID para Entropia RNG ($D41B)
; ==============================================================================
INIT_SID_RNG
        lda     #$ff
        sta     SID_V3_FREQ_LO  ; Frecuencia maxima para fluctuacion de ruido
        sta     SID_V3_FREQ_HI
        lda     #$80            ; Modo Ruido (Noise Waveform) en Voz 3
        sta     SID_CTRL
        rts

; ==============================================================================
; Rutina: Barajado de Mazo Fisher-Yates (52 cartas sin duplicados)
; ==============================================================================
SHUFFLE_DECK
        ldx     #51
SHUFF_LOOP
SAMPLE_RNG
        lda     SID_NOISE
        and     #$3f            ; Rango 0..63
        cmp     #52             ; Asegurar que cae en [0..51]
        bcs     SAMPLE_RNG      ; Si >= 52, volver a muestrear

        ; Intercambio Fisher-Yates: SWAP(DECK_BASE[X], DECK_BASE[Y])
        tay
        lda     DECK_BASE,x
        pha
        lda     DECK_BASE,y
        sta     DECK_BASE,x
        pla
        sta     DECK_BASE,y

        dex
        bne     SHUFF_LOOP

        lda     #$00
        sta     DECK_PTR
        rts

; ==============================================================================
; Rutina: Dibujo de Elementos Estaticos de Pantalla
; Header, Separadores, Panel de Fichas y Ayuda de Teclado
; ==============================================================================
DRAW_STATIC_UI
        ; 1. Cabecera (Fila 0): data-testid="status-header"
        ldx     #0
HDR_LOOP
        lda     STR_HEADER,x
        beq     HDR_DONE
        sta     SCREEN_RAM,x
        lda     #COLOR_YELLOW
        sta     COLOR_RAM,x
        inx
        cpx     #40
        bne     HDR_LOOP
HDR_DONE

        ; 2. Mensajes del Dealer (Filas 2 y 3)
        ldx     #0
DLR_LOOP
        lda     STR_DEALER,x
        beq     DLR_DONE
        sta     SCREEN_RAM+80,x ; Fila 2 ($0400 + 80)
        lda     #COLOR_CYAN
        sta     COLOR_RAM+80,x
        inx
        bne     DLR_LOOP
DLR_DONE

        ; 3. Separador (Fila 4)
        ldx     #0
        lda     #$40            ; Caracter linea horizontal PETSCII
SEP1_LOOP
        sta     SCREEN_RAM+160,x
        lda     #COLOR_BLUE
        sta     COLOR_RAM+160,x
        inx
        cpx     #40
        bne     SEP1_LOOP

        ; 4. Log de Estado (Filas 19-21): data-testid="terminal-log"
        ldx     #0
LOG_LOOP
        lda     STR_LOG,x
        beq     LOG_DONE
        sta     SCREEN_RAM+760,x ; Fila 19 ($0400 + 19*40 = $06F8)
        lda     #COLOR_CYAN
        sta     COLOR_RAM+760,x
        inx
        bne     LOG_LOOP
LOG_DONE

        ; 5. Panel de Fichas (Fila 23): data-testid="chip-panel"
        ; Despliega el Saldo de 1000 y el Pozo de 20
        ldx     #0
CHIP_LOOP
        lda     STR_CHIP_PANEL,x
        beq     CHIP_DONE
        sta     SCREEN_RAM+920,x ; Fila 23 ($0400 + 23*40 = $0798)
        lda     #COLOR_YELLOW
        sta     COLOR_RAM+920,x
        inx
        bne     CHIP_LOOP
CHIP_DONE

        ; 6. Barra de Ayuda (Fila 24): data-testid="kbd-help"
        ldx     #0
HELP_LOOP
        lda     STR_KBD_HELP,x
        beq     HELP_DONE
        sta     SCREEN_RAM+960,x ; Fila 24 ($0400 + 24*40 = $07C0)
        lda     #COLOR_LIGHT_GREEN
        sta     COLOR_RAM+960,x
        inx
        bne     HELP_LOOP
HELP_DONE
        rts

; ==============================================================================
; Rutina: Renderizado de la Mano del Jugador (5 Cartas de 3x3 celdas)
; data-testid="card-slot-1" .. "card-slot-5"
; ==============================================================================
DRAW_CARDS
        ldx     #0
CARD_LOOP
        stx     TEMP_CARD_IDX
        lda     DECK_BASE,x     ; Indice de carta 0..51
        sta     TEMP_CARD_VAL
        jsr     RENDER_SINGLE_CARD
        ldx     TEMP_CARD_IDX
        inx
        cpx     #5
        bne     CARD_LOOP
        rts

; Dibuja una carta individual en su slot correspondiente
RENDER_SINGLE_CARD
        ; Calcular offset de columna segun TEMP_CARD_IDX
        ldx     TEMP_CARD_IDX
        lda     CARD_COL_OFFSETS,x
        sta     TEMP_COL

        ; Determinar Palo (0..3) y Valor (0..12 -> 1..13)
        lda     TEMP_CARD_VAL
        jsr     DIVMOD13        ; A = Valor (0..12), Y = Palo (0..3)
        sta     CARD_RANK_IDX
        sty     CARD_SUIT_IDX

        ; Determinar Color:
        ; Palos 0 (Corazones) y 1 (Diamantes) -> COLOR_RED ($02)
        ; Palos 2 (Treboles) y 3 (Picas)      -> COLOR_BLACK ($00) o COLOR_WHITE ($01)
        cpy     #2
        bcc     IS_RED
        lda     #COLOR_BLACK
        sta     CARD_COLOR
        jmp     COLOR_READY
IS_RED
        lda     #COLOR_RED
        sta     CARD_COLOR
COLOR_READY

        ; Renderizar Bloque 3x3 de la Carta
        ; Fila 7 (Top border):  + - +
        ; Fila 8 (Rank/Face):   | R |
        ; Fila 9 (Suit):        | S |
        ; Fila 10 (Bot border): + - +

        ; Fila 7: 7 * 40 = 280
        ldx     TEMP_COL
        lda     #$2b            ; '+'
        sta     SCREEN_RAM+280,x
        lda     #$2d            ; '-'
        sta     SCREEN_RAM+281,x
        lda     #$2b            ; '+'
        sta     SCREEN_RAM+282,x

        lda     #COLOR_WHITE
        sta     COLOR_RAM+280,x
        sta     COLOR_RAM+281,x
        sta     COLOR_RAM+282,x

        ; Fila 8 (Rank): 8 * 40 = 320
        lda     #$7c            ; '|'
        sta     SCREEN_RAM+320,x
        sta     SCREEN_RAM+322,x

        ldy     CARD_RANK_IDX
        lda     RANK_CHARS,y
        sta     SCREEN_RAM+321,x

        lda     #COLOR_WHITE
        sta     COLOR_RAM+320,x
        sta     COLOR_RAM+322,x
        lda     CARD_COLOR
        sta     COLOR_RAM+321,x

        ; Fila 9 (Suit): 9 * 40 = 360
        lda     #$7c            ; '|'
        sta     SCREEN_RAM+360,x
        sta     SCREEN_RAM+362,x

        ldy     CARD_SUIT_IDX
        lda     SUIT_CHARS,y
        sta     SCREEN_RAM+361,x

        lda     #COLOR_WHITE
        sta     COLOR_RAM+360,x
        sta     COLOR_RAM+362,x
        lda     CARD_COLOR
        sta     COLOR_RAM+361,x

        ; Fila 10 (Bottom): 10 * 40 = 400
        lda     #$2b            ; '+'
        sta     SCREEN_RAM+400,x
        lda     #$2d            ; '-'
        sta     SCREEN_RAM+401,x
        lda     #$2b            ; '+'
        sta     SCREEN_RAM+402,x

        lda     #COLOR_WHITE
        sta     COLOR_RAM+400,x
        sta     COLOR_RAM+401,x
        sta     COLOR_RAM+402,x

        ; Fila 11 (Numero de slot 1-5): 11 * 40 = 440
        ldy     TEMP_CARD_IDX
        lda     SLOT_NUMS,y
        sta     SCREEN_RAM+441,x
        lda     #COLOR_LIGHT_GREEN
        sta     COLOR_RAM+441,x

        rts

; Rutina auxiliar: Divide A por 13 -> Retorna A = A % 13 (Rank 0..12), Y = A / 13 (Palo 0..3)
DIVMOD13
        ldy     #0
DIV_LOOP
        cmp     #13
        bcc     DIV_DONE
        sbc     #13
        iny
        jmp     DIV_LOOP
DIV_DONE
        rts

; Rutina: Mensaje de Retiro
DRAW_RETIRE_MSG
        ldx     #0
RET_LOOP
        lda     STR_RETIRED,x
        beq     RET_DONE
        sta     SCREEN_RAM+760,x ; Fila 19
        lda     #COLOR_LIGHT_RED
        sta     COLOR_RAM+760,x
        inx
        bne     RET_LOOP
RET_DONE
        rts

; ==============================================================================
; Variables Temporales y Tablas de Datos
; ==============================================================================
TEMP_CARD_IDX   .byte 0
TEMP_CARD_VAL   .byte 0
TEMP_COL        .byte 0
CARD_RANK_IDX   .byte 0
CARD_SUIT_IDX   .byte 0
CARD_COLOR      .byte 0

; Columnas para los 5 slots de cartas (data-testid="card-slot-1" .. "card-slot-5")
CARD_COL_OFFSETS .byte 4, 10, 16, 22, 28

; Caracteres PETSCII para Ranks: A, 2, 3, 4, 5, 6, 7, 8, 9, T, J, Q, K
RANK_CHARS      .text "A23456789TJQK"

; Caracteres de Palos (Corazon, Diamante, Trebol, Pica)
SUIT_CHARS      .text "HDCS"

; Numeros de slots
SLOT_NUMS       .text "12345"

; ==============================================================================
; Cadenas de Texto PETSCII
; ==============================================================================
STR_HEADER
        .text "*** C64 POKER ENGINE V1.0 - VIC-II 40X25 ***"
        .byte 0

STR_DEALER
        .text "DEALER: APUESTA INICIAL REALIZADA."
        .byte 0

STR_LOG
        .text "> MANO REPARTIDA. PULSA ESPACIO / R     "
        .byte 0

STR_RETIRED
        .text "> JUGADOR SE RETIRA. PULSA ESPACIO NUEVA"
        .byte 0

STR_CHIP_PANEL
        .text "FICHAS: 1000        POZO: 20            "
        .byte 0

STR_KBD_HELP
        .text "ESPACIO: REPARTIR       R: RETIRAR      "
        .byte 0
