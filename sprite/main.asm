                device  zxspectrum48
                sldopt  COMMENT WPMEM,LOGPOINT,ASSERTION

                org     $8000

; addresses
SHIFT           equ     $ff00                   ; current sprite bitshift counter
X_DIR           equ     $ff01                   ; current x movement direction (-1 | 1)
Y_DIR           equ     $ff02                   ; current y movement direction (-1 | 1)

start:
                ld      b,0                     ; initialize x (in pixels)
                ld      c,0                     ; initialize y (in pixels)
                ld      a,1                     ; initialize x and y movement directions
                ld      (X_DIR),a
                ld      (Y_DIR),a
                ei
.loop:
                ld      a,b                     ; check three least significant bits of x coord
                and     %00000111               ; to get distance in pixels from cell start
                ld      (SHIFT),a               ; which is the number of needed bitshifts
                call    get_pixel_address       ; get video memory address in hl
                push    bc
                call    draw_sprite             ; draw sprite (this moves 8 pixels down)
                pop     bc
                halt
                call    get_pixel_address       ; rewind hl to the original position
                push    bc
                call    clear_sprite            ; clear the sprite we've drawn
                pop     bc
                ld      a,(X_DIR)
                add     b
                ld      b,a
                ld      a,(Y_DIR)
                add     c
                ld      c,a
                call    reverse_x_dir           ; reverse sprite x direction
                call    reverse_y_dir           ; reverse sprite y direction
                jp      .loop
                ret

reverse_x_dir:                                  ; reverse X_DIR, destroys a
                ld      a,b
                sub     256-9                   ; subtract screen width less sprite size
                ret     c                       ; ignore if sprite within bounds
                ld      a,(X_DIR)
                neg
                ld      (X_DIR),a
                ret

reverse_y_dir:                            ; reverse Y_DIR, destroys a
                ld      a,c
                sub     192-9                   ; subtract screen height less sprite size
                ret     c                       ; ignore if sprite within bounds
                ld      a,(Y_DIR)
                neg
                ld      (Y_DIR),a
                ret

; draw 8x8 sprite at x, y pixel coordinates
;
; input: hl = video memory address, SPRITE = 8x8 sprite data address,
; SHIFT = sprite bitshift count in pixels, destroys a, bc, de,
; moves hl 8 pixels down
draw_sprite:
                ld      b,$8                    ; set counter to sprite size in pixels
                ld      de,SPRITE               ; load sprite data address into de
.loop:
                ld      a,(SHIFT)               ; get sprite bitshift count
                ld      c,a                     ; and save it in c
                ld      a,(de)                  ; get current sprite line
                call    shift_by_c              ; shift it right by the correct amount
                ld      (hl),a                  ; write shifted line to video memory
                inc     l                       ; go right to next character cell
                ld      a,(SHIFT)               ; get bitshift count again
                ld      c,a
                ld      a,(de)                  ; get current sprite line again
                call    reverse_shift_by_c      ; shift it left by 8 - SHIFT
                ld      (hl),a                  ; write it to the second cell
                dec     l                       ; return to the previous cell
                call    go_to_next_line         ; move to next y value
                inc     de                      ; select next sprite line
                djnz    .loop                   ; repeat until b == 0
                ret

shift_by_c:                                     ; shift a right by c, destroys c
                inc     c                       ; check if we start with zero
                dec     c                       ; NOTE: maybe there's a faster way?
                ret     z                       ; zero means no need for shifting
.loop:
                srl     a                       ; shift right and zero leftmost bit
                dec     c                       ; decrease bitshift count
                jp      nz,.loop                ; repeat until SHIFT == 0
                ret

reverse_shift_by_c:                             ; shift a left by 8 - c, destroys c
                push    af
                ld      a,c
                sub     8                       ; calculate SHIFT - 8
                neg                             ; negate to get 8 - SHIFT
                ld      c,a
                pop     af
                ret     z                       ; nothing to be done if 8 - 8
.loop:
                sla     a                       ; shift left and zero rightmost bit
                dec     c                       ; decrease bitshift count
                jp      nz,.loop                ; repeat until 8 - SHIFT == 0
                ret

; clear 8x8 sprite at x, y pixel coordinates
;
; input: hl = video memory address, destroys a, b, moves hl 8 pixels down
clear_sprite:
                ld      b,$8                    ; set counter to sprite size in pixels
.loop:
                ld      (hl),0                  ; zero current address
                inc     l                       ; go right to next cell
                ld      (hl),0                  ; zero current address
                dec     l                       ; return to first cell
                call    go_to_next_line         ; go down one pixel
                djnz    .loop                   ; repeat until done :3
                ret

; get video memory address of pixel coordinates
;
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

; move video address in hl one line down
;
; input: hl = video memory address, destroys a
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

SPRITE          db      %00111100               ; 8x8 sprite data
                db      %01000010
                db      %10000001
                db      %10100101
                db      %10000001
                db      %10011001
                db      %01000010
                db      %00111100

                savesna "main.sna",start
