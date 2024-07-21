                device  zxspectrum48
                sldopt  COMMENT WPMEM,LOGPOINT,ASSERTION

                org     $8000

JOY_TYPE_ATTR   equ     $5800                   ; joystick type color attribute address
INPUT_ATTR      equ     $5801                   ; input status color attribute address

joy_type_count  equ     3                       ; number of supported joystick types

joy_kempston    equ     0
joy_sinclair    equ     1
joy_cursor      equ     2

start:
                ei
                call    selectJoyType           ; select joystick type using keyboard
                call    drawTypeSquare          ; draw selected joystick type square

                ld      a,(JOYSTICK_TYPE)       ; load selected joystick type
                cp      joy_kempston            ; is it Kempston?
                call    z,readKempston          ; read Kempston input

                ld      a,(JOYSTICK_TYPE)
                cp      joy_sinclair            ; is it Sinclair?
                call    z,readSinclair          ; read Sinclair input

                ld      a,(JOYSTICK_TYPE)
                cp      joy_cursor              ; is it Cursor?
                call    z,readCursor            ; read Cursor input

                call    drawInputSquare        ; draw currently pressed inputs square

                jp      start

; select joystick type using keys z, x and c;
; z selects Kempston, x selects Sinclair, c selects Cursor
;
; destroys af, bc
selectJoyType:
                ld      bc,$fefe
                in      a,(c)                   ; read port $fefe (shift/z/x/c/v)
                ld      b,a

                and     %00000010               ; is it z?
                jr      z,selectKempston

                ld      a,b
                and     %00000100               ; is it x?
                jr      z,selectSinclair

                ld      a,b
                and     %00001000               ; is it c?
                jr      z,selectCursor

                ret

; set JOYSTICK_TYPE to joy_kempston
;
; destroys a
selectKempston:
                ld      a,joy_kempston
                ld      (JOYSTICK_TYPE),a

                ret

; set JOYSTICK_TYPE to joy_sinclair
;
; destroys a
selectSinclair:
                ld      a,joy_sinclair
                ld      (JOYSTICK_TYPE),a

                ret

; set JOYSTICK_TYPE to joy_cursor
;
; destroys a
selectCursor:
                ld      a,joy_cursor
                ld      (JOYSTICK_TYPE),a

                ret

; set joystick type color attribute depending on JOYSTICK_TYPE
;
; destroys af, bc, de
drawTypeSquare:
                ld      hl,JOYSTICK_TYPE        ; load selected joystick type address
                ld      c,(hl)                  ; read joystick type
                ld      hl,JOY_TYPE_ATTR        ; load target type color attribute address
                ld      de,COLORS-1             ; load first paper color address - 1
                ld      b,joy_type_count        ; initialize loop counter
.loop:
                inc     de                      ; go to next paper color address

                ld      a,b                     ; copy counter
                dec     a                       ; decrement by 1 to get joy type number
                cp      c                       ; compare to selected joystick type

                call    z,drawColor             ; if counter - 1 == (JOYSTICK_TYPE)
                ret     z                       ; draw with color at de and break

                djnz    .loop                   ; otherwise continue looping

                call    drawGray                ; if nothing matches, draw gray

                ret

; read Kempston joystick input and set INPUT_MASK accordingly
;
; destroys af, bc, hl
readKempston:
                ld      c,$1f                   ; put Kempston port in c
                in      a,(c)                   ; read Kempston input

                ld      hl,KEMPSTON_MASKS-1     ; load address preceding first input mask

                ld      b,5                     ; initialize loop counter for 5 masks
.loop:
                inc     hl                      ; go to next input mask
                ld      c,(hl)                  ; load input mask in c

                push    af

                and     c                       ; compare mask with input
                push    hl
                call    nz,setInput             ; set bit in INPUT_MASK if match
                call    z,unsetInput            ; unset bit in INPUT_MASK if no match
                pop     hl

                pop     af

                djnz    .loop                   ; complete the loop

                ret

; read Sinclair joystick input and set INPUT_MASK accordingly
;
; destroys af, bc, de, hl
readSinclair:
                ld      bc,$f7fe                ; load Sinclair joystick interface port
                in      a,(c)

                ld      hl,SINCLAIR_MASKS-1     ; load first Sinclair input mask address - 1
                ld      de,KEMPSTON_MASKS-1     ; load first Kempston input mask address - 1
                                                ; since INPUT_MASK expects Kempston bits

                ld      b,5                     ; initialize loop counter for 5 masks
.loop:
                inc     hl                      ; go to next Sinclair input mask
                inc     de                      ; go to next Kempston input mask
                ld      c,(hl)                  ; load Sinclair input mask

                push    af

                and     c                       ; compare mask with Sinclair input

                ld      a,(de)                  ; load Kempston input mask
                ld      c,a                     ; to convert between Sinclair and Kempston

                push    hl
                call    nz,unsetInput           ; unset bit in INPUT_MASK if no match
                call    z,setInput              ; set bit in INPUT_MASK if match
                pop     hl

                pop     af

                djnz    .loop                   ; complete the loop

                ret

readCursor:
                ld      bc,$f7fe                ; load first port of Cursor interface
                in      a,(c)

                ld      hl,CURSOR_MASKS         ; load first Cursor input mask address
                ld      de,KEMPSTON_MASKS       ; load first Kempston input mask address
                                                ; since INPUT_MASK expects Kempston bits
                ld      b,(hl)                  ; load first Cursor input mask (left)
                and     b                       ; check if it's pressed

                ld      a,(de)                  ; load first Kempston input mask
                ld      c,a                     ; to convert between Cursor and Kempston

                push    hl
                call    nz,unsetInput           ; unset bit in INPUT_MASK if no match     
                call    z,setInput              ; set bit in INPUT_MASK if match
                pop     hl

                ld      bc,$effe                ; load second port of Cursor interface
                in      a,(c)

                ld      b,4                     ; initialize loop counter for 4 masks
.loop:
                inc     hl                      ; go to next Cursor input mask
                inc     de                      ; go to next Kempston input mask
                ld      c,(hl)                  ; load Cursor input mask

                push    af

                and     c                       ; compare mask with Cursor input

                ld      a,(de)                  ; load Kempston input mask
                ld      c,a                     ; to convert between Cursor and Kempston

                push    hl
                call    nz,unsetInput           ; unset bit in INPUT_MASK if no match     
                call    z,setInput              ; set bit in INPUT_MASK if match
                pop     hl

                pop     af

                djnz    .loop                   ; complete the loop

                ret

; set bits in currently pressed inputs at INPUT_MASK
;
; input: c = bits to set, destroys af, hl
setInput:
                ld      hl,INPUT_MASK
                ld      a,(hl)                  ; load currently pressed inputs mask
                or      c                       ; combine with mask in c
                ld      (hl),a

                ret

; unset bits in currently pressed inputs at INPUT_MASK
;
; input: c = bits to unset, destroys c, af, hl        
unsetInput:
                ld      a,c
                cpl                             ; invert bits in c
                ld      c,a

                ld      hl,INPUT_MASK
                ld      a,(hl)                  ; load currently pressed inputs mask
                and     c                       ; inverted c bits and input mask give
                                                ; input mask w/o bits from c
                ld      (hl),a

                ret

; set paper color at INPUT_ATTR depending on which inputs are pressed
;
; destroys af, bc, hl, de
drawInputSquare:
                ld      hl,INPUT_MASK           ; load currently pressed inputs address
                ld      c,(hl)                  ; save input mask in c

                ld      hl,KEMPSTON_MASKS-1     ; load address preceding first input mask
                ld      de,COLORS-1             ; load address preceding first color

                ld      b,5                     ; initialize loop counter for 5 masks/colors

.loop:
                inc     de                      ; go to next paper color
                inc     hl                      ; go to next expected input mask

                ld      a,(hl)                  ; load expected input mask
                and     c                       ; compare pressed and expected masks

                push    hl
                ld      hl,INPUT_ATTR           ; set target attribute address for drawColor
                                                ; NOTE: can this be removed from the loop?
                call    nz,drawColor            ; draw paper color at de if masks match
                pop     hl

                ret     nz                      ; stop looping if masks match

                djnz    .loop                   ; loop through remaining masks

                push    hl
                ld      hl,INPUT_ATTR           ; set target attribute address for drawGray
                call    drawGray                ; if nothing matches, draw gray square
                pop     hl

                ret

; set color attribute at hl to gray paper color
;
; destroys a
drawGray:
                ld      a,%000111000            ; set gray paper color
                ld      (hl),a

                ret

; set color attribute at hl to attribute at de
;
; input: de = attribute address, destroys a
drawColor:
                ld      a,(de)                  ; load attribute from de
                ld      (hl),a                  ; set color attribute at hl

                ret

; sequence of kempston input masks: left, right, down, up, fire
KEMPSTON_MASKS:
                db      %00000010,%00000001,%00000100,%00001000,%00010000

; sequence of sinclair input masks: left, right, down, up, fire
SINCLAIR_MASKS:
                db      %00000001,%00000010,%00000100,%00001000,%00010000

; sequence of cursor input masks: left, right, down, up, fire,
; first mask port = $f7fe, remaining masks port = $effe
CURSOR_MASKS:
                db      %00010000,%00000100,%00010000,%00001000,%00000001

; sequence of five paper colors: blue, red, green, magenta, yellow        
COLORS:
                db      %00001000,%00010000,%00100000,%00011000,%00110000

; address of the currently pressed inputs mask,
; uses Kempston's 000FUDLR
INPUT_MASK:
                db      %00000000

; address of the currently selected joystick type,
; 0 = Kempston, 1 = Sinclair, 2 = Cursor; defaults to 1
JOYSTICK_TYPE:
                db      1

                savesna "main.sna",start
