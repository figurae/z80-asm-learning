        DEVICE ZXSPECTRUM48

        org $8000

SEED = $F000

start:
        ld b,0
        ld d,24
        ld a,$ff
        ld (SEED),a
        ld hl,$4000
loop:
        ld (hl),a
        push hl
        push de
        ld hl,(SEED)
        ld e,(hl)
        add hl,de
        xor h
        ld (SEED),hl
        pop de
        pop hl
        inc hl
        djnz loop
        dec d
        jp nz,loop
        ret


        SAVESNA "load.sna", start
