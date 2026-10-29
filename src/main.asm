; ==============================================================================
; PROJ-C64-POKER: COM-011 - Juego del Gato (Tic-Tac-Toe) & Retro Poker Suite
; Target: MOS 6502 / Commodore 64
; Assembler: 64tass (usa .enc "screen" para textos volcados a Screen RAM)
; Iniciativas integradas: C64P-001 (Poker Engine) y COM-011 (Juego del Gato)
;
; Mapeo de Componentes y data-testid (UX/UI y Arquitectura COM-011):
; - data-testid="c64-screen-container" : Matriz VIC-II Screen RAM ($0400-$07E7) y Color RAM ($D800-$DBE7)
; - data-testid="c64-title-banner"     : Cabecera Fila 1 ($0428-$044F) "**** COMMODORE 64 TRES EN RAYA ****"
; - data-testid="tictactoe-board"      : Tablero 3x3 centrado en filas 6-18, columnas 12-28
; - data-testid="board-cell-0-0"       : Celda (0,0) índice 0 ($C000 / Screen $059E)
; - data-testid="board-cell-0-1"       : Celda (0,1) índice 1 ($C001 / Screen $05A4)
; - data-testid="board-cell-0-2"       : Celda (0,2) índice 2 ($C002 / Screen $05AA)
; - data-testid="board-cell-1-0"       : Celda (1,0) índice 3 ($C003 / Screen $063E)
; - data-testid="board-cell-1-1"       : Celda (1,1) índice 4 ($C004 / Screen $0644)
; - data-testid="board-cell-1-2"       : Celda (1,2) índice 5 ($C005 / Screen $064A)
; - data-testid="board-cell-2-0"       : Celda (2,0) índice 6 ($C006 / Screen $06DE)
; - data-testid="board-cell-2-1"       : Celda (2,1) índice 7 ($C007 / Screen $06E4)
; - data-testid="board-cell-2-2"       : Celda (2,2) índice 8 ($C008 / Screen $06EA)
; - data-testid="color-cell-0-0"       : Atributo de Color RAM para Celda (0,0) en $D99E
; - data-testid="sidebar-hud"          : Panel lateral de estadísticas en columnas 31-39, filas 6-16
; - data-testid="score-p1"             : Marcador P1 (X) en $0608
; - data-testid="score-cpu"            : Marcador CPU/P2 (O) en $0630
; - data-testid="status-message"       : Mensaje de Turno / Estado en Fila 22 ($0780-$07A7)
;
; Componentes y data-testid heredados C64P-001 (Poker Engine):
; - data-testid="screen-container"     : Matriz VIC-II Screen RAM ($0400-$07E7)
; - data-testid="status-header"        : Cabecera de estado ($0400-$0427)
; - data-testid="card-slot-1" .. "5"   : Ranuras de naipes
; - data-testid="chip-panel"           : Saldo y pozo en Fila 23
; - data-testid="terminal-log"         : Log en Filas 19-21
; - data-testid="kbd-help"             : Ayuda de teclado en Fila 24
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

SID_V1_FREQ_LO  = $d400
SID_V1_FREQ_HI  = $d401
SID_V1_CTRL     = $d404
SID_V1_AD       = $d405
SID_V1_SR       = $d406
SID_VOL_FILTER  = $d418

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

; Ubicacion de Datos del Poker Engine (Compatibilidad C64P-001)
DECK_BASE       = $1000         ; Array de 52 bytes para el mazo
DECK_PTR        = $fb           ; Puntero en Zero Page para la siguiente carta
DEST_PTR        = $02           ; Puntero auxiliar Zero Page para renderizado
COLOR_PTR       = $04           ; Puntero auxiliar Zero Page para Color RAM

; Variables de Estado de Negocio Poker (Gherkin BDD: Pozo 20 créditos, Saldo 1000 créditos)
pot_amount      = $0014         ; 20 créditos iniciales (0020 dec = $0014 hex)
player_credits  = $03e8         ; 1000 créditos meta ($03E8 hex = 1000 dec)

; ==============================================================================
; Mapa de Memoria COM-011: Juego del Gato (Tic-Tac-Toe)
; ==============================================================================
GAME_BOARD      = $c000         ; Matriz de 9 bytes ($C000-$C008): 00=Vacio, 01=X, 02=O
GAME_TURN       = $c009         ; Turno actual: $00 = Jugador 1 (X), $01 = Jugador 2 / CPU (O)
GAME_STATUS     = $c00a         ; Estado del juego: $00 = En curso, $01 = Gana X, $02 = Gana O, $03 = Empate
GAME_MODE       = $c00b         ; Modo de juego: $00 = Humano vs CPU, $01 = Humano vs Humano (2P)
CURSOR_POS      = $c00c         ; Posicion actual del cursor (0..8)
SCORE_P1        = $c00d         ; Puntuacion acumulada P1
SCORE_CPU       = $c00e         ; Puntuacion acumulada CPU / P2

; Caracteres UDG / Screen Codes para Fichas
UDG_CHAR_X      = $e0           ; Carácter personalizado o glifo X
UDG_CHAR_O      = $e1           ; Carácter personalizado o glifo O
SYM_SCREEN_X    = $18           ; Screen code 'X'
SYM_SCREEN_O    = $0f           ; Screen code 'O'

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

        ; Configurar juego de caracteres VIC-II en Uppercase/Graphics ($14 = $1000 ROM base)
        lda     #$14
        sta     VIC_CHARPTR

        ; Configurar Borde (Azul $06) y Fondo Negro ($00) para COM-011
        lda     #COLOR_BLUE
        sta     VIC_BORDER
        lda     #COLOR_BLACK
        sta     VIC_BG0

        jsr     CLEAR_SCREEN    ; Limpiar los 1000 bytes de pantalla con espacios
        jsr     INIT_SID_RNG    ; Inicializar generador de sonido y entropia SID
        jsr     INIT_DECK       ; Inicializar estructuras de compatibilidad
        jsr     INIT_TTT_GAME   ; Inicializar tablero y variables de COM-011
        jsr     DRAW_TTT_UI     ; Dibujar pantalla completa del Gato (VIC-II)

        cli                     ; Rehabilitar interrupciones

; ------------------------------------------------------------------------------
; Bucle Principal del Juego (MAIN_LOOP)
; ------------------------------------------------------------------------------
MAIN_LOOP
        ; Si el juego ya termino, esperar tecla para reiniciar
        lda     GAME_STATUS
        beq     ML_CHECK_TURN
        jsr     KEY_GETIN
        cmp     #$85            ; Tecla F1 (ASCII $85 en C64)
        beq     ML_RESET_GAME
        cmp     #$20            ; Espacio para reiniciar
        beq     ML_RESET_GAME
        jmp     MAIN_LOOP

ML_CHECK_TURN
        ; Verificar si es turno de la CPU (GAME_TURN == 1 y GAME_MODE == 0)
        lda     GAME_MODE
        bne     ML_HUMAN_INPUT
        lda     GAME_TURN
        beq     ML_HUMAN_INPUT

        ; Turno de la CPU
        jsr     CPU_MOVE
        jsr     RENDER_ALL_CELLS
        jsr     CHECK_WIN
        lda     GAME_STATUS
        bne     ML_GAME_OVER
        ; Cambiar turno a Humano
        lda     #0
        sta     GAME_TURN
        jsr     UPDATE_STATUS_MSG
        jmp     MAIN_LOOP

ML_HUMAN_INPUT
        jsr     KEY_GETIN
        beq     MAIN_LOOP       ; Sin tecla presionada

        ; Tecla '1' a '9': Seleccion directa de casilla (0 a 8)
        cmp     #$31            ; '1'
        bcc     ML_CHECK_FKEYS
        cmp     #$3a            ; '9' + 1
        bcs     ML_CHECK_FKEYS
        sec
        sbc     #$31            ; Convierte '1'-'9' a 0-8
        tax
        jsr     TRY_PLAYER_MOVE
        jmp     MAIN_LOOP

ML_CHECK_FKEYS
        cmp     #$85            ; F1: Nueva partida
        beq     ML_RESET_GAME
        cmp     #$86            ; F3: Alternar modo 1P vs CPU / 2P
        beq     ML_TOGGLE_MODE
        cmp     #$20            ; Espacio: Compatibilidad Poker Engine
        beq     ML_POKER_FALLBACK
        cmp     #'r'            ; 'R': Retirar (Compatibilidad Poker Engine)
        beq     ML_POKER_RETIRE
        cmp     #'R'
        beq     ML_POKER_RETIRE
        jmp     MAIN_LOOP

ML_RESET_GAME
        jsr     INIT_TTT_GAME
        jsr     DRAW_TTT_UI
        jmp     MAIN_LOOP

ML_TOGGLE_MODE
        lda     GAME_MODE
        eor     #$01            ; Alternar entre 0 (CPU) y 1 (2P)
        sta     GAME_MODE
        jsr     INIT_TTT_GAME
        jsr     DRAW_TTT_UI
        jmp     MAIN_LOOP

ML_POKER_FALLBACK
        jsr     SHUFFLE_DECK
        jsr     DRAW_CARDS
        jmp     MAIN_LOOP

ML_POKER_RETIRE
        jsr     DRAW_RETIRE_MSG
        jmp     MAIN_LOOP

ML_GAME_OVER
        jsr     PLAY_GAME_OVER_SOUND
        jsr     UPDATE_STATUS_MSG
        jsr     UPDATE_SCORES
        jmp     MAIN_LOOP

; ==============================================================================
; Subrutinas COM-011: Lógica de Tic-Tac-Toe (Gato)
; ==============================================================================

; Inicializa el estado del juego COM-011
INIT_TTT_GAME
        ldx     #0
        lda     #0
IT_LOOP
        sta     GAME_BOARD,x    ; 9 bytes a 00 (Vacío)
        inx
        cpx     #9
        bne     IT_LOOP

        lda     #0
        sta     GAME_TURN       ; Humano 1 (X) inicia
        sta     GAME_STATUS     ; Juego en curso (00)
        lda     #4
        sta     CURSOR_POS      ; Centro por defecto
        rts

; Intenta colocar ficha del jugador en la celda X (0..8)
; Retorna Carry Set si fue exitoso, Carry Clear si ocupada o invalida
TRY_PLAYER_MOVE
        cpx     #9
        bcs     TPM_FAIL
        lda     GAME_BOARD,x
        bne     TPM_FAIL        ; Ya esta ocupada

        ; Determinar simbolo segun GAME_TURN (0 -> 1=X, 1 -> 2=O)
        lda     GAME_TURN
        beq     TPM_SET_X
        lda     #$02            ; Simbolo 'O'
        bne     TPM_STORE
TPM_SET_X
        lda     #$01            ; Simbolo 'X'
TPM_STORE
        sta     GAME_BOARD,x    ; Actualizar estado en memoria $C000 + X

        jsr     PLAY_MOVE_SOUND ; Sonido de jugada
        jsr     RENDER_ALL_CELLS
        jsr     CHECK_WIN

        lda     GAME_STATUS
        bne     TPM_FINISHED

        ; Alternar turno
        lda     GAME_TURN
        eor     #$01
        sta     GAME_TURN
        jsr     UPDATE_STATUS_MSG
        sec
        rts

TPM_FINISHED
        jsr     PLAY_GAME_OVER_SOUND
        jsr     UPDATE_STATUS_MSG
        jsr     UPDATE_SCORES
        sec
        rts

TPM_FAIL
        clc
        rts

; ------------------------------------------------------------------------------
; Subrutina: CHECK_WIN
; Evalua los 8 combos ganadores en GAME_BOARD ($C000..$C008).
; Setea GAME_STATUS:
;   $01 = Victoria X (Humano 1)
;   $02 = Victoria O (CPU / Jugador 2)
;   $03 = Empate (Tablero lleno sin ganador)
;   $00 = En curso
; Carga en A el valor de nota o estado para el SID
; ------------------------------------------------------------------------------
CHECK_WIN
        ; Evaluar las 8 tripletas ganadoras
        ldx     #0
CW_TRIPLET_LOOP
        ldy     WIN_PATTERNS,x
        lda     GAME_BOARD,y
        beq     CW_NEXT_TRIPLET ; Si la primera celda es 0, no hay linea

        sta     TEMP_WINNER     ; Guardar candidato (1 o 2)

        ldy     WIN_PATTERNS+1,x
        lda     GAME_BOARD,y
        cmp     TEMP_WINNER
        bne     CW_NEXT_TRIPLET

        ldy     WIN_PATTERNS+2,x
        lda     GAME_BOARD,y
        cmp     TEMP_WINNER
        bne     CW_NEXT_TRIPLET

        ; Ganador confirmado: TEMP_WINNER contiene 1 (X) o 2 (O)
        lda     TEMP_WINNER
        sta     GAME_STATUS
        ; Cargar acumulador A con valor de tono SID para victoria
        lda     #$24            ; Frecuencia musical aguda
        rts

CW_NEXT_TRIPLET
        txa
        clc
        adc     #3
        tax
        cpx     #24             ; 8 combinaciones * 3 = 24 bytes
        bne     CW_TRIPLET_LOOP

        ; Si no hay ganador, verificar si hay empate (tablero lleno)
        ldy     #0
CW_CHECK_DRAW
        lda     GAME_BOARD,y
        beq     CW_STILL_PLAYING ; Si hay celda vacia, continua el juego
        iny
        cpy     #9
        bne     CW_CHECK_DRAW

        ; Tablero lleno: Empate
        lda     #$03
        sta     GAME_STATUS
        lda     #$80            ; Valor SID ruido blanco para empate
        rts

CW_STILL_PLAYING
        lda     #$00
        sta     GAME_STATUS
        rts

TEMP_WINNER     .byte 0

; 8 Lineas ganadoras (filas, columnas, diagonales)
WIN_PATTERNS
        .byte 0, 1, 2   ; Fila 0
        .byte 3, 4, 5   ; Fila 1
        .byte 6, 7, 8   ; Fila 2
        .byte 0, 3, 6   ; Col 0
        .byte 1, 4, 7   ; Col 1
        .byte 2, 5, 8   ; Col 2
        .byte 0, 4, 8   ; Diagonal principal
        .byte 2, 4, 6   ; Diagonal secundaria

; ------------------------------------------------------------------------------
; Subrutina: CPU_MOVE (IA Heurística para Oponente)
; Prioridad 1: Ganar si tiene 2 en linea (O=2)
; Prioridad 2: Bloquear si Humano tiene 2 en linea (X=1)
; Prioridad 3: Ocupar el centro ($C004 / celda 4)
; Prioridad 4: Espacio vacio aleatorio o primer libre
; ------------------------------------------------------------------------------
CPU_MOVE
        ; Espera de frames (simulacion de delay visual)
        ldy     #15
CPU_DELAY_OUTER
        ldx     #$ff
CPU_DELAY_INNER
        dex
        bne     CPU_DELAY_INNER
        dey
        bne     CPU_DELAY_OUTER

        ; Prioridad 1: Buscar linea ganadora para CPU (O = 2)
        lda     #$02
        jsr     FIND_WINNING_CELL
        bcs     CPU_EXECUTE_MOVE

        ; Prioridad 2: Bloquear linea de victoria de Humano (X = 1)
        lda     #$01
        jsr     FIND_WINNING_CELL
        bcs     CPU_EXECUTE_MOVE

        ; Prioridad 3: Ocupar el centro ($C004 / celda 4)
        lda     GAME_BOARD+4
        bne     CPU_TRY_RANDOM
        ldx     #4
        jmp     CPU_EXECUTE_MOVE

CPU_TRY_RANDOM
        ; Prioridad 4: Seleccionar primera celda disponible asistida por entropia SID
        lda     SID_NOISE
        and     #$07            ; Valor 0..7
        tax
        lda     GAME_BOARD,x
        beq     CPU_EXECUTE_MOVE

        ; Busqueda lineal de primera celda libre
        ldx     #0
CPU_FREE_LOOP
        lda     GAME_BOARD,x
        beq     CPU_EXECUTE_MOVE
        inx
        cpx     #9
        bne     CPU_FREE_LOOP
        rts                     ; No hay movimiento disponible

CPU_EXECUTE_MOVE
        ; X contiene la celda (0..8) a ocupar por la CPU
        lda     #$02            ; Ficha 'O'
        sta     GAME_BOARD,x
        rts

; Rutina auxiliar para IA: Busca si el simbolo en A tiene 2 en una linea y el 3ero esta vacio.
; Retorna Carry Set y X = celda ganadora/bloqueo si encuentra; Carry Clear si no.
FIND_WINNING_CELL
        sta     SEARCH_SYM
        ldy     #0
FWC_LOOP
        ; Cargar las 3 celdas de la linea
        ldx     WIN_PATTERNS,y
        lda     GAME_BOARD,x
        sta     TRIPLET_VALS
        ldx     WIN_PATTERNS+1,y
        lda     GAME_BOARD,x
        sta     TRIPLET_VALS+1
        ldx     WIN_PATTERNS+2,y
        lda     GAME_BOARD,x
        sta     TRIPLET_VALS+2

        ; Contar coincidencias con SEARCH_SYM y verificar celda vacia
        lda     #0
        sta     MATCH_COUNT
        sta     EMPTY_INDEX

        ; Celda 0 de la terna
        lda     TRIPLET_VALS
        cmp     SEARCH_SYM
        bne     FWC_C0_EMPTY
        inc     MATCH_COUNT
        jmp     FWC_CHECK_C1
FWC_C0_EMPTY
        cmp     #0
        bne     FWC_NEXT_TERNA
        lda     #0
        sta     EMPTY_INDEX

FWC_CHECK_C1
        lda     TRIPLET_VALS+1
        cmp     SEARCH_SYM
        bne     FWC_C1_EMPTY
        inc     MATCH_COUNT
        jmp     FWC_CHECK_C2
FWC_C1_EMPTY
        cmp     #0
        bne     FWC_NEXT_TERNA
        lda     #1
        sta     EMPTY_INDEX

FWC_CHECK_C2
        lda     TRIPLET_VALS+2
        cmp     SEARCH_SYM
        bne     FWC_C2_EMPTY
        inc     MATCH_COUNT
        jmp     FWC_EVALUATE
FWC_C2_EMPTY
        cmp     #0
        bne     FWC_NEXT_TERNA
        lda     #2
        sta     EMPTY_INDEX

FWC_EVALUATE
        lda     MATCH_COUNT
        cmp     #2              ; ¿Hay exactamente 2 fichas del simbolo buscado?
        bne     FWC_NEXT_TERNA

        ; Victoria o Bloqueo encontrado: retornar la celda vacia en X
        tya
        clc
        adc     EMPTY_INDEX
        tax
        lda     WIN_PATTERNS,x
        tax                     ; X = Indice de celda 0..8 en GAME_BOARD
        sec
        rts

FWC_NEXT_TERNA
        tya
        clc
        adc     #3
        tay
        cpy     #24
        beq     FWC_EXHAUSTED
        jmp     FWC_LOOP
FWC_EXHAUSTED
        clc
        rts

SEARCH_SYM      .byte 0
TRIPLET_VALS    .byte 0, 0, 0
MATCH_COUNT     .byte 0
EMPTY_INDEX     .byte 0

; ==============================================================================
; Renderizado y Pantalla VIC-II (COM-011)
; ==============================================================================

; Limpia los 1000 bytes de Screen RAM ($0400-$07E7) con espacios y Color RAM a Azul
CLEAR_SCREEN
        ldx     #0
CS_LOOP
        lda     #$20            ; Espacio en Screen Codes
        sta     SCREEN_RAM,x
        sta     SCREEN_RAM+$100,x
        sta     SCREEN_RAM+$200,x
        sta     SCREEN_RAM+$300,x

        lda     #COLOR_BLUE     ; Color base
        sta     COLOR_RAM,x
        sta     COLOR_RAM+$100,x
        sta     COLOR_RAM+$200,x
        sta     COLOR_RAM+$300,x
        inx
        bne     CS_LOOP
        rts

; Dibuja la interfaz completa del Gato (VIC-II)
DRAW_TTT_UI
        ; 1. Cabecera Fila 1 ($0428): **** COMMODORE 64 TRES EN RAYA **** (data-testid="c64-title-banner")
        ldx     #0
DUI_TITLE_LOOP
        lda     STR_TITLE_BANNER,x
        beq     DUI_TITLE_SUB
        sta     SCREEN_RAM+40,x
        lda     #COLOR_CYAN
        sta     COLOR_RAM+40,x
        inx
        bne     DUI_TITLE_LOOP

DUI_TITLE_SUB
        ldx     #0
DUI_SUB_LOOP
        lda     STR_SUB_BANNER,x
        beq     DUI_BOARD_GRID
        sta     SCREEN_RAM+80,x
        lda     #COLOR_WHITE
        sta     COLOR_RAM+80,x
        inx
        bne     DUI_SUB_LOOP

DUI_BOARD_GRID
        ; 2. Dibujar cuadricula del tablero (data-testid="tictactoe-board")
        ; Filas de separacion horizontal y columnas verticales
        ; Columnas del tablero: Col 12 a 28, Filas 6 a 17
        ; Dibujamos lineas verticales en col 17 y 23
        ldx     #0
DUI_VLINE_LOOP
        ldy     BOARD_ROWS,x
        ; Col 17 (|)
        lda     #$5d            ; Barra vertical
        sta     SCREEN_RAM+17,y
        sta     SCREEN_RAM+23,y
        lda     #COLOR_CYAN
        sta     COLOR_RAM+17,y
        sta     COLOR_RAM+23,y
        inx
        cpx     #12
        bne     DUI_VLINE_LOOP

        ; Lineas horizontales divisorias en fila 9 y fila 13
        ldx     #12
DUI_HLINE_1
        lda     #$40            ; Barra horizontal
        sta     SCREEN_RAM+360,x ; Fila 9 (9 * 40 = 360)
        sta     SCREEN_RAM+520,x ; Fila 13 (13 * 40 = 520)
        lda     #COLOR_CYAN
        sta     COLOR_RAM+360,x
        sta     COLOR_RAM+520,x
        inx
        cpx     #29
        bne     DUI_HLINE_1

        ; 3. Renderizar HUD Lateral (data-testid="sidebar-hud")
        ldx     #0
DUI_HUD_LOOP
        lda     STR_HUD_TITLE,x
        beq     DUI_HUD_P1
        sta     SCREEN_RAM+271,x ; Fila 6, Col 31
        lda     #COLOR_WHITE
        sta     COLOR_RAM+271,x
        inx
        bne     DUI_HUD_LOOP

DUI_HUD_P1
        ldx     #0
DUI_P1_LBL
        lda     STR_HUD_P1,x
        beq     DUI_HUD_CPU
        sta     SCREEN_RAM+351,x ; Fila 8, Col 31
        lda     #COLOR_GREEN
        sta     COLOR_RAM+351,x
        inx
        bne     DUI_P1_LBL

DUI_HUD_CPU
        ldx     #0
DUI_CPU_LBL
        lda     STR_HUD_CPU,x
        beq     DUI_HUD_MODE
        sta     SCREEN_RAM+391,x ; Fila 9, Col 31
        lda     #COLOR_RED
        sta     COLOR_RAM+391,x
        inx
        bne     DUI_CPU_LBL

DUI_HUD_MODE
        ldx     #0
DUI_MODE_LBL
        lda     STR_HUD_MODE,x
        beq     DUI_REFRESH_REST
        sta     SCREEN_RAM+471,x ; Fila 11, Col 31
        lda     #COLOR_CYAN
        sta     COLOR_RAM+471,x
        inx
        bne     DUI_MODE_LBL

DUI_REFRESH_REST
        jsr     UPDATE_SCORES
        jsr     RENDER_ALL_CELLS
        jsr     UPDATE_STATUS_MSG
        rts

; Array de offsets de filas para las 12 lineas verticales del tablero
BOARD_ROWS
        .word 240, 280, 320, 360, 400, 440, 480, 520, 560, 600, 640, 680

; ------------------------------------------------------------------------------
; Renderiza las 9 celdas en Screen RAM y Color RAM
; Mapeo exacto conforme a 2A_UXUI_SPEC.md:
; Celda 0 (0,0) en $059E / Color $D99E (data-testid="board-cell-0-0")
; ------------------------------------------------------------------------------
RENDER_ALL_CELLS
        ldx     #0
RAC_LOOP
        stx     CURRENT_CELL_IDX
        lda     GAME_BOARD,x    ; 0=Vacio, 1=X, 2=O

        ; Calcular offset en Screen RAM
        ldy     CURRENT_CELL_IDX
        lda     CELL_SCREEN_OFFSETS_LO,y
        sta     DEST_PTR
        lda     CELL_SCREEN_OFFSETS_HI,y
        sta     DEST_PTR+1

        ; Determinar caracter y color
        ldx     CURRENT_CELL_IDX
        lda     GAME_BOARD,x
        beq     RAC_DRAW_EMPTY
        cmp     #$01
        beq     RAC_DRAW_X

        ; Dibujar 'O' (Rojo $02)
        lda     #SYM_SCREEN_O   ; 'O'
        ldy     #0
        sta     (DEST_PTR),y
        ; Color RAM
        lda     DEST_PTR+1
        clc
        adc     #$d4            ; Convertir $0400->$D800 ($059E + $D400 = $D99E)
        sta     COLOR_PTR+1
        lda     DEST_PTR
        sta     COLOR_PTR
        lda     #COLOR_RED
        sta     (COLOR_PTR),y
        jmp     RAC_NEXT

RAC_DRAW_X
        ; Dibujar 'X' (Verde $05)
        lda     #SYM_SCREEN_X   ; 'X'
        ldy     #0
        sta     (DEST_PTR),y
        lda     DEST_PTR+1
        clc
        adc     #$d4
        sta     COLOR_PTR+1
        lda     DEST_PTR
        sta     COLOR_PTR
        lda     #COLOR_GREEN
        sta     (COLOR_PTR),y
        jmp     RAC_NEXT

RAC_DRAW_EMPTY
        ; Celda vacia: caracter espacio
        lda     #$20
        ldy     #0
        sta     (DEST_PTR),y
        lda     DEST_PTR+1
        clc
        adc     #$d4
        sta     COLOR_PTR+1
        lda     DEST_PTR
        sta     COLOR_PTR
        lda     #COLOR_BLACK
        sta     (COLOR_PTR),y

RAC_NEXT
        ldx     CURRENT_CELL_IDX
        inx
        cpx     #9
        bne     RAC_LOOP
        rts

CURRENT_CELL_IDX .byte 0

; Offsets exactos para las 9 celdas en Screen RAM:
; Celda 0 (0,0): Fila 7, Col 14  -> 7*40 + 14 = 294  -> $0400 + 294 = $0526 / o $059E (fila 10 col 14 = 414 = $059E)
; Conforme a QA-02: $059E = Celda (0,0)
CELL_SCREEN_OFFSETS_LO
        .byte <$059e, <$05a4, <$05aa
        .byte <$063e, <$0644, <$064a
        .byte <$06de, <$06e4, <$06ea

CELL_SCREEN_OFFSETS_HI
        .byte >$059e, >$05a4, >$05aa
        .byte >$063e, >$0644, >$064a
        .byte >$06de, >$06e4, >$06ea

; Actualiza el mensaje de estado en Fila 22 ($0780) (data-testid="status-message")
UPDATE_STATUS_MSG
        lda     GAME_STATUS
        beq     USM_CHECK_TURN
        cmp     #$01
        beq     USM_P1_WINS
        cmp     #$02
        beq     USM_P2_WINS
        ; Empate
        ldx     #0
USM_DRAW_LOOP
        lda     STR_STATUS_DRAW,x
        beq     USM_SUB_MSG
        sta     SCREEN_RAM+880,x ; Fila 22 ($0780 - 40 = 880 offset)
        lda     #COLOR_YELLOW
        sta     COLOR_RAM+880,x
        inx
        bne     USM_DRAW_LOOP
        jmp     USM_SUB_MSG

USM_P1_WINS
        ldx     #0
USM_P1_WIN_LOOP
        lda     STR_STATUS_P1_WINS,x
        beq     USM_SUB_MSG
        sta     SCREEN_RAM+880,x
        lda     #COLOR_LIGHT_GREEN
        sta     COLOR_RAM+880,x
        inx
        bne     USM_P1_WIN_LOOP
        jmp     USM_SUB_MSG

USM_P2_WINS
        ldx     #0
USM_P2_WIN_LOOP
        lda     STR_STATUS_P2_WINS,x
        beq     USM_SUB_MSG
        sta     SCREEN_RAM+880,x
        lda     #COLOR_LIGHT_RED
        sta     COLOR_RAM+880,x
        inx
        bne     USM_P2_WIN_LOOP
        jmp     USM_SUB_MSG

USM_CHECK_TURN
        lda     GAME_TURN
        beq     USM_P1_TURN
        ; Turno P2 / CPU
        ldx     #0
USM_P2_TURN_LOOP
        lda     STR_STATUS_P2_TURN,x
        beq     USM_SUB_MSG
        sta     SCREEN_RAM+880,x
        lda     #COLOR_LIGHT_RED
        sta     COLOR_RAM+880,x
        inx
        bne     USM_P2_TURN_LOOP
        jmp     USM_SUB_MSG

USM_P1_TURN
        ldx     #0
USM_P1_TURN_LOOP
        lda     STR_STATUS_P1_TURN,x
        beq     USM_SUB_MSG
        sta     SCREEN_RAM+880,x
        lda     #COLOR_WHITE
        sta     COLOR_RAM+880,x
        inx
        bne     USM_P1_TURN_LOOP

USM_SUB_MSG
        ; Fila 23: [F1] NUEVA PARTIDA   [F3] CAMBIAR MODO
        ldx     #0
USM_SUB_LOOP
        lda     STR_STATUS_KEYS,x
        beq     USM_DONE
        sta     SCREEN_RAM+920,x ; Fila 23
        lda     #COLOR_YELLOW
        sta     COLOR_RAM+920,x
        inx
        bne     USM_SUB_LOOP
USM_DONE
        rts

; Actualiza marcador P1 y CPU en HUD
; Marcador P1 en $0608 (QA-04), Marcador CPU en $0630
UPDATE_SCORES
        ; P1 Score
        lda     SCORE_P1
        clc
        adc     #$30            ; Caracter ASCII '0'-'9'
        sta     SCREEN_RAM+520  ; $0400 + 520 = $0608
        lda     #COLOR_GREEN
        sta     COLOR_RAM+520

        ; CPU Score
        lda     SCORE_CPU
        clc
        adc     #$30
        sta     SCREEN_RAM+560  ; $0400 + 560 = $0630
        lda     #COLOR_RED
        sta     COLOR_RAM+560
        rts

; ==============================================================================
; Rutinas de Sonido SID
; ==============================================================================
INIT_SID_RNG
        ; Configurar Voz 3 para ruido blanco (Entropía RNG)
        lda     #$ff
        sta     SID_V3_FREQ_LO
        sta     SID_V3_FREQ_HI
        lda     #$80            ; Ruido blanco
        sta     SID_CTRL
        ; Configurar volumen general al maximo
        lda     #$0f
        sta     SID_VOL_FILTER
        rts

PLAY_MOVE_SOUND
        ; Beep corto para movimiento
        lda     #$00
        sta     SID_V1_CTRL
        lda     #$20
        sta     SID_V1_FREQ_HI
        lda     #$00
        sta     SID_V1_FREQ_LO
        lda     #$09            ; Attack / Decay rapido
        sta     SID_V1_AD
        lda     #$11            ; Onda triangular + Gate
        sta     SID_V1_CTRL
        rts

PLAY_GAME_OVER_SOUND
        lda     GAME_STATUS
        cmp     #$03            ; ¿Empate?
        beq     PGOS_NOISE
        ; Tono ascendente para victoria
        lda     #$00
        sta     SID_V1_CTRL
        lda     #$40
        sta     SID_V1_FREQ_HI
        lda     #$09
        sta     SID_V1_AD
        lda     #$21            ; Onda diente de sierra + Gate
        sta     SID_V1_CTRL
        rts
PGOS_NOISE
        ; Ruido blanco corto para empate
        lda     #$00
        sta     SID_V1_CTRL
        lda     #$81            ; Ruido + Gate
        sta     SID_V1_CTRL
        rts

; ==============================================================================
; Subrutinas Heredadas de Compatibilidad Poker (C64P-001)
; ==============================================================================
INIT_DECK
        ldx     #0
ID_LOOP
        txa
        sta     DECK_BASE,x     ; Llena 0..51
        inx
        cpx     #52
        bne     ID_LOOP
        lda     #0
        sta     DECK_PTR
        rts

SHUFFLE_DECK
        ldx     #51
SHUFFLE_LOOP
        lda     SID_NOISE       ; Byte de entropia pseudoaleatoria
        cmp     #52
        bcs     SHUFFLE_RNG_RETRY
        jmp     SHUFFLE_RNG_OK
SHUFFLE_RNG_RETRY
        and     #$1f            ; Mascara 0..31 si fue >= 52
SHUFFLE_RNG_OK
        tay
        lda     DECK_BASE,x
        pha
        lda     DECK_BASE,y
        sta     DECK_BASE,x
        pla
        sta     DECK_BASE,y
        dex
        bne     SHUFFLE_LOOP
        lda     #0
        sta     DECK_PTR
        rts

DRAW_CARDS
        ldx     #0
DC_LOOP
        stx     TEMP_CARD_IDX
        ldy     DECK_PTR
        lda     DECK_BASE,y
        sta     TEMP_CARD_VAL
        inc     DECK_PTR

        ldx     TEMP_CARD_IDX
        lda     CARD_COL_OFFSETS,x
        sta     TEMP_COL

        jsr     RENDER_CARD_AT_COL

        ldx     TEMP_CARD_IDX
        inx
        cpx     #5
        bne     DC_LOOP
        rts

RENDER_CARD_AT_COL
        lda     TEMP_CARD_VAL
        jsr     DIVMOD13
        sta     CARD_RANK_IDX
        sty     CARD_SUIT_IDX

        cpy     #0              ; Corazones
        beq     IS_RED
        cpy     #1              ; Diamantes
        beq     IS_RED
        lda     #COLOR_BLACK
        sta     CARD_COLOR
        jmp     COLOR_READY
IS_RED
        lda     #COLOR_RED
        sta     CARD_COLOR
COLOR_READY
        ldx     TEMP_COL
        ; Fila 7 border
        lda     #$70
        sta     SCREEN_RAM+280,x
        lda     #$40
        sta     SCREEN_RAM+281,x
        lda     #$6e
        sta     SCREEN_RAM+282,x
        lda     #COLOR_WHITE
        sta     COLOR_RAM+280,x
        sta     COLOR_RAM+281,x
        sta     COLOR_RAM+282,x

        ; Fila 8 rank
        lda     #$5d
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

        ; Fila 9 suit
        lda     #$5d
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

        ; Fila 10 bottom
        lda     #$6d
        sta     SCREEN_RAM+400,x
        lda     #$40
        sta     SCREEN_RAM+401,x
        lda     #$7d
        sta     SCREEN_RAM+402,x
        lda     #COLOR_WHITE
        sta     COLOR_RAM+400,x
        sta     COLOR_RAM+401,x
        sta     COLOR_RAM+402,x

        ; Fila 11 slot num
        ldy     TEMP_CARD_IDX
        lda     SLOT_NUMS,y
        sta     SCREEN_RAM+441,x
        lda     #COLOR_LIGHT_GREEN
        sta     COLOR_RAM+441,x
        rts

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

DRAW_STATIC_UI
        rts

DRAW_RETIRE_MSG
        ldx     #0
RET_LOOP
        lda     STR_RETIRED,x
        beq     RET_DONE
        sta     SCREEN_RAM+760,x
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

CARD_COL_OFFSETS .byte 4, 10, 16, 22, 28
SUIT_CHARS      .byte $53, $5a, $58, $41

; ==============================================================================
; Sección de Cadenas y Glifos codificados con .enc "screen"
; ==============================================================================
    .enc "screen"

; Ranks: A, 2, 3, 4, 5, 6, 7, 8, 9, T, J, Q, K
RANK_CHARS      .text "A23456789TJQK"
SLOT_NUMS       .text "12345"

; Cadenas COM-011 (Tres en Raya / Gato)
STR_TITLE_BANNER
        .text "**** COMMODORE 64 TRES EN RAYA ****"
        .byte 0

STR_SUB_BANNER
        .text "PROJ: COM-011 - VIC-II UI"
        .byte 0

STR_HUD_TITLE
        .text "HUD STATS"
        .byte 0

STR_HUD_P1
        .text "P1 (X): "
        .byte 0

STR_HUD_CPU
        .text "CPU(O): "
        .byte 0

STR_HUD_MODE
        .text "MODO: 1P/CPU"
        .byte 0

STR_STATUS_P1_TURN
        .text "TURNO JUGADOR 1 (X)                  "
        .byte 0

STR_STATUS_P2_TURN
        .text "TURNO CPU / P2 (O)                   "
        .byte 0

STR_STATUS_P1_WINS
        .text "** VICTORIA JUGADOR 1 (X)! **        "
        .byte 0

STR_STATUS_P2_WINS
        .text "** VICTORIA CPU / P2 (O)! **         "
        .byte 0

STR_STATUS_DRAW
        .text "** PARTIDA EN TABLAS / EMPATE! **    "
        .byte 0

STR_STATUS_KEYS
        .text "[F1] NUEVA PARTIDA   [F3] CAMBIAR MODO"
        .byte 0

; Cadenas de compatibilidad Poker Engine
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

    .enc "none"
