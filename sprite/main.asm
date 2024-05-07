        device  zxspectrum48

        org     $8000

flags:  equ     $ff00

horizontal_line_height = 8

start:
        xor     a                               ; reset a to 0
        ld      (flags),a                       ; set flags byte to 0
        ld      c,192                           ; initialize outer loop (y in pixels)
        ld      d,horizontal_line_height        ; initialize horizontal line counter
.outer_loop:
        dec     c                               ; decrement c to work with 0-191 range
        ld      b,32                            ; initialize inner loop (x in characters)
.inner_loop:
        dec     b                               ; decrement b to work with 0-31 range
        push    bc
        rl b                                    ; multiply b by 8 to get x in pixels
        rl b
        rl b
        call    get_pixel_address               ; get memory address of coords
        pop     bc                              ; restore unmultiplied b
        ld      a,0
        cp      b
        call    nz,draw_vertical_pixel          ; draw vertical line if not leftmost
        ld      a,(flags)
        bit     0,a
        call    nz,draw_horizontal_line         ; draw horizontal line if correct height
        inc     b                               ; increase b by one to complete last
        djnz    .inner_loop                     ; inner loop when b = 0
        dec     d                               ; decrease line height counter
        call    nz,res_flag                     ; reset line height flag
        call    z,set_flag                      ; or set it if the counter is 0
        ld      a,0                             ; ZF from dec c can't survive to here
        cp      c                               ; recreate it now
        jp      nz,.outer_loop                  ; and complete outer loop
        ret

set_flag:
        ld      a,(flags)
        set     0,a                             ; set line height flag
        ld      (flags),a
        ld      d,horizontal_line_height        ; and reset line height counter
        ret

res_flag:
        ld      a,(flags)
        res     0,a                             ; reset line height flag
        ld      (flags),a
        ret

draw_vertical_pixel:
        ld      a,%10000000                     ; draw leftmost pixel
        ld      (hl),a
        ret

draw_horizontal_line:
        ld      a,%01111111                     ; draw line without leftmost pixel
        ld      (hl),a
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

        savesna "main.sna",start
