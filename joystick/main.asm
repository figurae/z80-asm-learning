        device  zxspectrum48
        sldopt  COMMENT WPMEM,LOGPOINT,ASSERTION

        org $8000

BUTTONS         equ     $ff00

start:
                ei
                call    read_kempston
                call    flash_square

                jp      start

; read kempston joystick input and write it in BUTTONS
;
; destroys af, bc, hl
read_kempston:
                ld      hl,KEMPSTON_MASKS       ; load kempston port ($1f)
                ld      c,(hl)                  ; put kempston port in c
                in      a,(c)                   ; read kempston input
                ld      b,5                     ; initialize loop counter
.loop:
                inc     hl                      ; go to next input mask
                ld      c,(hl)                  ; load input mask in c
                push    af
                and     c                       ; compare mask with input
                push    hl
                call    nz,set_button           ; set button if mask matches
                call    z,unset_button          ; unset button if mask doesn't match
                pop     hl
                pop     af
        
                djnz    .loop                   ; complete the loop
        
                ret

; set first color attribute depending on pressed buttons
;
; destroys af, bc, hl, de
flash_square:
                ld      hl,BUTTONS              ; load pressed buttons address
                ld      c,(hl)                  ; load buttons byte in c
                ld      hl,KEMPSTON_MASKS+1     ; load first input mask address
                ld      de,COLORS               ; load first color address
                ld      b,5                     ; initialize loop counter
        
.button_loop:
                ld      a,(hl)                  ; load buttons byte
                and     c                       ; compare current input mask with buttons
                
                push    hl
                call    nz,draw_color           ; draw paper color if mask matches
                pop     hl
        
                ret     nz                      ; stop looping if mask matches

                inc     de                      ; go to next paper color
                inc     hl                      ; go to next input mask

                djnz    .button_loop            ; loop through input masks
        
                call    draw_gray               ; if nothing matches, draw gray

                ret

; sets first color attribute to gray paper color
;
; destroys a, hl
draw_gray:
                ld      hl,$5800                ; load first color attribute address
                ld      a,%000111000            ; set gray paper color
                ld      (hl),a
                
                ret

; sets first color attribute to attribute at de
;
; input: de = attribute address, destroys a, hl
draw_color:
                ld      hl,$5800                ; load first color attribute address
                ld      a,(de)                  ; load attribute from de
                ld      (hl),a                  ; set first color attribute

                ret

; set button in byte at BUTTONS using the given mask
;
; input: c = mask, destroys af, hl
set_button:
                ld      hl,BUTTONS
                ld      a,(hl)                  ; load buttons byte
                or      c                       ; combine mask with buttons byte
                ld      (hl),a

                ret

; unset button in byte at BUTTONS using the given mask
;
; input: c = mask, destroys c, af, hl        
unset_button:
                ld      a,c
                cpl                             ; invert mask bits
                ld      c,a

                ld      hl,BUTTONS
                ld      a,(hl)                  ; load buttons byte
                and     c                       ; inverted mask and buttons byte give
                                                ; buttons byte w/o button from og mask
                ld      (hl),a

                ret

; kempston port and sequence of input masks: right, left, down, up, fire
KEMPSTON_MASKS:
        db $1f, %00000001, %00000010, %00000100, %00001000, %00010000

; sequence of five paper colors: blue, red, green, magenta, yellow        
COLORS:
        db %00001000, %00010000, %00100000, %00011000, %00110000

        savesna "main.sna",start
