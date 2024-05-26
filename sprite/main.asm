        device  zxspectrum48
        sldopt  COMMENT WPMEM, LOGPOINT, ASSERTION

        org     $8000

rotation equ $ff00

start:
        ld      b,0
        ld      c,0
        ei
.loop:
        ld      a,b
        and     %00000111               ; get x rotation count
        ld      (rotation),a            ; and store it in memory
        call    get_pixel_address
        push    bc
        call    draw_sprite
        pop     bc
        halt
        call    get_pixel_address
        push    bc
        call    clear_sprite
        pop     bc
        inc     b
        inc     c
        call    reset_b_if_over_256
        call    reset_c_if_over_192
        jp      .loop
        ret

reset_b_if_over_256:
        ld      a,b
        sub     256-8
        ret     c
        ld      b,0
        ret

reset_c_if_over_192:
        ld      a,c
        sub     192-8
        ret     c
        ld      c,0
        ret

draw_sprite:
        ld      b,$8
        ld      de,SPRITE
.loop:
        ld      a,(rotation)
        ld      c,a
        ld      a,(de)
        call    rotate_by_c
        ld      (hl),a
        inc     l
        ld      a,(rotation)
        ld      c,a
        ld      a,(de)
        call    reverse_rotate_by_c
        ld      (hl),a
        dec     l
        call    go_to_next_line
        inc     de
        djnz    .loop
        ret

rotate_by_c:
        inc     c
        dec     c
        ret     z
.loop:
        srl     a
        dec     c
        jp      nz,.loop
        ret

reverse_rotate_by_c:
        push    af
        ld      a,c
        sub     8
        neg
        ld      c,a
        pop     af
        ret     z
.loop:
        sla     a
        dec     c
        jp      nz,.loop
        ret
        

clear_sprite:
        ld      b,$8
.loop:
        ld      (hl),0
        inc     l
        ld      (hl),0
        dec     l
        call    go_to_next_line
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
        rra                             ; divide by 8 to get x4, x3, x2, x1, x0
        rra
        rra
        and     %00011111               ; mask out non-x bits
        or      l                       ; combine with y5, y4, y3
        ld      l,a                     ; store in l
        ret
        
go_to_next_line:
        inc     h                       ; increment y2, y1, y0
        ld      a,h
        and     %00000111               ; did we overflow into y6?
        ret     nz                      ; return if not
        ld      a,l                     ; if yes, go to next character line
        add     a,%00100000             ; increment y3
        ld      l,a
        ret     c                       ; did we overflow l (y5, y4, y3)?
        ld      a,h                     ; if not, undo overflow into y6
        sub     %00001000               ; to not jump to next 3rd of screen
        ld      h,a
        ret
        
go_to_previous_line:
        dec     h
        ld      a,h
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
