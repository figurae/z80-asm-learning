        DEVICE ZXSPECTRUM48

        org $8000

start:
        ld b,128        ; load inner loop counter
        ld d,14         ; load outer loop counter
        ld a,$ff        ; load initial pixel/color value
        ld hl,$4000     ; load start of bitmap data address
loop:                   ; this works by overflowing into the color attribute data
        ld (hl),a       ; write pixel/color value into the address
        dec a
        dec a
        dec a
        inc hl
        inc hl
        djnz loop       ; decrement b and repeat the loop
        dec d           ; decrement d
        jp nz,loop      ; and repeat the loop
        ret

        SAVESNA "load.sna", start
        
