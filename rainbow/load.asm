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
    call black_screen       ; clear screen
    ei                      ; enable interrupts so that things can update

    call load_rainbow       ; load first address of rainbow data into de
begin_drawing:
    halt                    ; slow things down a bit
    halt
    halt
    halt
    ld hl, COLOR_ATTR       ; load color attribute memory address into hl
    ld b, 24                ; set counter to 24 (number of 8x8 cells vertically)
.loop:
    ld a, (de)              ; load a rainbow color into a
    call draw_line          ; draw a line using this color
    inc de                  ; go to next color in rainbow
    ld c, P_MAGENTA         ; load magenta into c
    cp c                    ; check if current color is magenta (last color)
    call z, load_rainbow    ; if all colors have been drawn, draw them again
    djnz .loop              ; draw next line
    jr begin_drawing        ; draw next screen
    ret

load_rainbow:
    ld de, rainbow          ; load first address of rainbow data into de
    ret

draw_line:
    push bc                 ; save b (vertical counter)
    ld b, 32                ; set counter to 32 (number of 8x8 cells horizontally)
.draw_cell:
    ld (hl), a              ; set current cell to color attribute in a
    inc hl                  ; move to next cell
    djnz .draw_cell         ; continue until all cells in line are set
    pop bc                  ; restore vertical counter
    ret

rainbow:                    ; sequence of rainbow colors
    db P_RED, P_RED | BRIGHT, P_YELLOW | BRIGHT, P_YELLOW, P_GREEN, P_GREEN | BRIGHT, P_BLUE | BRIGHT, P_BLUE, P_MAGENTA, P_MAGENTA | BRIGHT

black_screen:
    xor a                   ; a = 0
    ld (ATTR_P), a          ; make permanent current colors black
    call CLEAR_SCREEN       ; clear top and bottom with permanent current colors
    call BORDER             ; make border black
    ret

; deployment
    SAVESNA "load.sna", start
