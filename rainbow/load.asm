    DEVICE ZXSPECTRUM48

    org $8000

    jr start            ; jump to start (relative)

; addresses
COLOR_ATTR      = $5800 ; start of color attribute memory
BORDCR          = $5C48 ; border color
ATTR_P          = $5C8D ; permanent current colors

; routines
ROM_CLS         = $0D6B ; clear top with ATTR P, bottom with BORDCR
CLEAR_SCREEN    = $0DAF ; clear top and bottom with ATTR P
BORDER          = $229B ; set border color to value in a (0..15)

I_BLACK         = %00000000 ; ink colors
I_BLUE          = %00000001
I_RED           = %00000010
I_MAGENTA       = %00000011
I_GREEN         = %00000100
I_CYAN          = %00000101
I_YELLOW        = %00000110
I_WHITE         = %00000111

P_BLACK         = %00000000 ; paper colors
P_BLUE          = %00001000
P_RED           = %00010000
P_MAGENTA       = %00011000
P_GREEN         = %00100000
P_CYAN          = %00101000
P_YELLOW        = %00110000
P_WHITE         = %00111000

BRIGHT          = %01000000
FLASH           = %10000000

start:
    call black_screen
    ei

    call load_rainbow
begin_drawing:
    halt
    halt
    halt
    halt
    ld hl, COLOR_ATTR
    ld b, 24
.loop:
    ld a, (de)
    call draw_line
    inc de
    ld c, P_MAGENTA
    cp c
    call z, load_rainbow
    djnz .loop
    jr begin_drawing
    ret

load_rainbow:
    ld de, rainbow
    ret

draw_line:
    push bc
    ld b, 32
.draw_cell:
    ld (hl), a
    inc hl
    djnz .draw_cell
    pop bc
    ret

rainbow:
    db P_RED, P_RED | BRIGHT, P_YELLOW | BRIGHT, P_YELLOW, P_GREEN, P_GREEN | BRIGHT, P_BLUE | BRIGHT, P_BLUE, P_MAGENTA, P_MAGENTA | BRIGHT

black_screen:
    xor a               ; a = 0
    ld (ATTR_P), a      ; make permanent current colors black
    call CLEAR_SCREEN   ; clear top and bottom with permanent current colors
    call BORDER         ; make border black
    ret

; deployment
    SAVESNA "load.sna", start
