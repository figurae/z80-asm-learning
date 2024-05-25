        device  zxspectrum48
        sldopt  COMMENT WPMEM, LOGPOINT, ASSERTION

        org     $8000

start:
        ld      b,$8
        ld      c,$8
        call    get_pixel_address
        ld      b,$8
        ld      de,SPRITE
.loop:
        ld      a,(de)
        ld      (hl),a
        inc     h
        inc     de
        djnz    .loop
        ret

; input: b = x pixel pos, c = y pixel pos, returns hl, destroys a
get_pixel_address:
        ld      a,c                     ; load y coordinate
        and     %00000111               ; mask out bits that are not y2, y1, y0
        or      %01000000               ; set screen base address ($4000 high byte)
        ld      h,a                     ; store partial y in h
        ld      a,c                     ; load y coordinate again
        rra                             ; rotate to get y7, y6
        rra
        rra
        and     %00011000               ; mask out other bits
        or      h                       ; combine with partial y
        ld      h,a                     ; and store in h again
        ld      a,c                     ; load y coordinate again
        rla                             ; rotate to get y5, y4, y3
        rla
        and     %11100000               ; mask out other bits
        ld      l,a                     ; store in l
        ld      a,b                     ; load x coordinate
        rra                             ; rotate to get x5, x4, x3, x2, x1
        rra
        rra
        and     %00011111               ; mask out non-x bits
        or      l                       ; combine with y5, y4, y3
        ld      l,a                     ; store in l
        ret

SPRITE:
        db      %00111100
        db      %01000010
        db      %10000001
        db      %10100101
        db      %10000001
        db      %10011001
        db      %01000010
        db      %00111100

        savesna "main.sna",start
