; ==============================================================================
; Commodore 64 - MOS 6502 Assembly Entry Point
; Target Assembler: 64tass
; ==============================================================================

; Standard C64 BASIC loader stub (* = $0801 -> 10 SYS 2061)
* = $0801
    .byte $0c, $08          ; Pointer to next line ($080c)
    .byte $0a, $00          ; Line number 10
    .byte $9e               ; SYS token
    .text "2061"           ; 2061 ($080d)
    .byte $00               ; End of line
    .byte $00, $00          ; End of BASIC program

; Program entry point at $080d (2061)
* = $080d

; Memory mapped hardware registers
VIC_BORDER_COLOR   = $d020
VIC_BG_COLOR       = $d021
SCREEN_RAM         = $0400
COLOR_RAM          = $d800

; VIC-II Color Palette constants
COLOR_BLACK        = $00
COLOR_WHITE        = $01
COLOR_RED          = $02
COLOR_CYAN         = $03
COLOR_PURPLE       = $04
COLOR_GREEN        = $05
COLOR_BLUE         = $06
COLOR_YELLOW       = $07

; Zero Page / Game state variables
pot_amount         = $0014    ; 20 credits initial pot
player_credits     = $03e8    ; 1000 credits goal

start:
    ; Set Border and Background to black
    lda #COLOR_BLACK
    sta VIC_BORDER_COLOR
    sta VIC_BG_COLOR

    ; Clear screen with spaces (PETSCII $20) and green characters
    ldx #$00
clear_screen_loop:
    lda #$20
    sta SCREEN_RAM,x
    sta SCREEN_RAM+$100,x
    sta SCREEN_RAM+$200,x
    sta SCREEN_RAM+$2e8,x

    lda #COLOR_GREEN
    sta COLOR_RAM,x
    sta COLOR_RAM+$100,x
    sta COLOR_RAM+$200,x
    sta COLOR_RAM+$2e8,x

    inx
    bne clear_screen_loop

    ; Return cleanly
    rts
