    DEVICE ZXSPECTRUM48

    org $8000

    jr start            ; jump to start (extended immediate?, relative)

string:
    db "hello"

STRING_LENGTH   = 5
COUNTER         = 0

ROM_CLS         = $0DAF ; clear screen routine in ROM
COLOR_ATTR      = $5800 ; start of color attribute memory
ENTER           = $0D   ; enter key character code
BLACK_WHITE     = $47   ; white ink on black paper
RED_WHITE       = $57   ; white ink on red paper

start:
    im 1                ; set interrupt mode to 1
    call ROM_CLS        ; extended immediate
    ld hl, string       ; hl = string address (register, extended immediate)
    ld b, STRING_LENGTH ; b = string length (register, immediate)
loop:
    ld a, (hl)          ; a = byte at address in hl (register, register indirect)
    rst $10             ; print character code in a (modified page zero)
    inc hl              ; increment hl to next character address (register)
    dec b               ; decrement remaining characters (register)
    jr nz, loop         ; jump (rel) to loop if no characters left (condition, relative)
    ld a, ENTER         ; a = enter key character code (register, immediate)
    rst $10             ; print enter (modified page zero)

    ld a, BLACK_WHITE   ; a = BLACK_WHITE color attribute (register, immediate)
    ld (COLOR_ATTR), a  ; load a to color attribute memory (0, 0) (extended, register)

    ld ix, string       ; ix = string address (register, extended immediate)
    res 5, (ix)         ; reset bit 5 of first character (bit, indexed)
    ld a, (ix)          ; a = string[0] (register, indexed)
    rst $10             ; print character (modified page zero)
    ld a, (ix+1)        ; a = string[1] (register, indexed)
    rst $10
    ld a, (ix+2)
    rst $10
    ld a, (ix+3)
    rst $10
    ld a, (ix+4)
    rst $10
    ld a, ENTER
    rst $10

    ret                 ; return from call (implied)

; deployment
    SAVESNA "load.sna", start
