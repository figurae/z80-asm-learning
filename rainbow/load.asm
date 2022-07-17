    DEVICE ZXSPECTRUM48

    org $8000

    jr start            ; jump to start (relative)

COUNTER_ZERO    = 0

ROM_CLS         = $0D6B
CLEAR_SCREEN    = $0DAF
COLOR_ATTR      = $5800
BORDER          = $229B ; gib black border
ATTR_P          = $5C8D

I_BLACK         = %00000000
I_BLUE          = %00000001
I_RED           = %00000010
I_MAGENTA       = %00000011
I_GREEN         = %00000100
I_CYAN          = %00000101
I_YELLOW        = %00000110
I_WHITE         = %00000111

P_BLACK         = %00000000
P_BLUE          = %00001000
P_RED           = %00010000
P_MAGENTA       = %00011000
P_GREEN         = %00100000
P_CYAN          = %00101000
P_YELLOW        = %00110000
P_WHITE         = %00111000

BRIGHT          = %01000000
FLASH           = %10000000

BLACK_SCREEN:
    xor a
    ld (ATTR_P), a
    call CLEAR_SCREEN
    call BORDER
    ret

start:
    call BLACK_SCREEN

    ld a, P_YELLOW
    push af 
    ld bc, COLOR_ATTR
    ;ei

    xor e
loop:
    ld a, 10
    cp e
    jr z, exit
    pop af
    ld (bc), a 
    push af
    ld a, 10
    inc bc
    inc e
    jr loop
exit:

    ret

; deployment
    SAVESNA "load.sna", start
