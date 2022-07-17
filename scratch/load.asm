    DEVICE ZXSPECTRUM48

    org $8000

start:
    jp print_hello

; character codes
ENTER       = $0D

; ROM routines
ROM_CLS     = $0DAF
ROM_PRINT   = $203C

; Memory
SCREEN_BMP  = $4000
COLOR_ATTR  = $5800

hello:
    db "Y HALO THAR", ENTER

HELLO_LEN   = $ - hello

print_hello:
    call ROM_CLS
    
    ld de, hello
    ld bc, HELLO_LEN

    call ROM_PRINT

    ret

; deployment
    SAVESNA "load.sna", start
