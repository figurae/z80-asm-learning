    DEVICE ZXSPECTRUM48

    org $8000

; routines
OPEN_CHANNEL    = $1601         ; open channel

; addresses
SCREEN          = $4000         ; start of screen memory
ATTR_M          = $5800         ; start of color attribute memory
START_IDX       = $F000         ; ring buffer memory start index
END_IDX         = $F001         ; ring buffer memory end index
BUFFER          = $F002         ; start of ring buffer memory
BUFFER_FLAG     = $F018
BUFFER_SIZE     = $F            ; ring buffer memory size

; constants
KEY_PORTS       = 8             ; number of keyboard ports
KEYS_IN_PORT    = 5             ; number of keys per port (row)

start:
    ei                          ; enable interrupts to enable screen updates
    ld a, 2                     ; select upper screen
    call OPEN_CHANNEL           ; open channel to upper screen
    xor a

main_loop:
    call read_from_buffer
    call nz, print_char

    call read_key               ; poll keyboard
    cp 0                        ; compare result to zero
    call nz, write_to_buffer    ; place result in buffer
    jr main_loop                ; loop forever
    ; ret

;; TODO: refactor, ignore repeating keys, repeat keys after a while

read_key:                       ; destroys b, c, d, e, h, l, returns a
    ld hl, key_map              ; keyboard map address
    ld d, KEY_PORTS             ; number of keyboard ports
    ld c, $fe                   ; port high byte, always fe
.search_port:
    ld b, (hl)                  ; get port low byte
    inc hl                      ; move to first character in port (row)
    in a, (c)                   ; read port
    and $1f                     ; mask first five bits
    ld e, KEYS_IN_PORT          ; number of keys per port
.check_key:
    srl a                       ; shift a right, TODO: carry is set when...?
    jr nc, .key_found           ; we found a key!
    inc hl                      ; go to next key
    dec e                       ; until the end of current port
    jr nz, .check_key           ; check next key
    dec d                       ; until the end of all ports
    jr nz, .search_port         ; go to next port
    and a                       ; nothing found, TODO: are flags cleared?
    ret
.key_found:
    ld a, (hl)                  ; load keycode into a
    ret

print_char:
    rst $10                     ; print char in a to screen
    halt                        ; wait for frame, TODO: remove later
    ret

write_to_buffer:                ; destroys a, b, c, d, e, h, l
    ld b, a                     ; save char from a in b

    ld a, (END_IDX)             ; load index into a
    ld de, BUFFER               ; load zeroth buffer address
    ld hl, de                   ; duplicate it in hl for first run purposes (TODO: refactor)

    cp 0                        ; is index 0?
    jr z, .first_run            ; why, yes. yes, it is!

    ld l, a
    ld h, 0                     ; make index 16-bit
    add hl, de                  ; add index as offset to buffer address
    ; ld e, a                   ; TODO: y dis kawaii hack no work? UwU (switch address low byte with offset)

    dec hl                      ; go back to previous character
    ld c, (hl)                  ; load previous character into c
    ex af, af'                  ; give me secondary a
    ld a, b                     ; load new char to secondary a
    cp c                        ; compare new and previous char
    ret z                       ; abort if they're the same
    
    ex af, af'                  ; bring back primary a
    inc hl                      ; return to current char location
.first_run:
    inc a                       ; increment index
    cp BUFFER_SIZE              ; test for index overflow
    jr c, .no_overflow          ; no overflow found
    xor a                       ; reset index
.no_overflow:
    ld (END_IDX), a             ; save new index
    ld a, b                     ; restore char in a
    ld (hl), a                  ; write char to buffer
    ld hl, BUFFER_FLAG
    ld (hl), 1                  ; set buffer flag
    ret

read_from_buffer:               ; destroys d, e, h, l, returns a
    ld d, (BUFFER_FLAG)         ; load buffer edit flag
    xor a                       ; reset a
    cp d                        ; check buffer edit flag
    ret z                       ; abort if buffer flag is not set

    ld a, (START_IDX)           ; load index into a
    ld de, BUFFER               ; load zeroth buffer address
    ld l, a
    ld h, 0                     ; make index 16-bit
    add hl, de                  ; add index as offset to buffer address
    
    inc a                       ; increment index
    cp BUFFER_SIZE              ; test for index overflow
    jr c, .no_overflow          ; no overflow found
    xor a                       ; reset index
.no_overflow:
    ld (START_IDX), a           ; save new index
    ld a, (hl)                  ; load from buffer to a
    ld (hl), 0
    ld hl, BUFFER_FLAG
    ld (hl), 0                  ; reset buffer flag
    ret

key_map:
    db $fe, "#", "Z", "X", "C", "V"
    db $fd, "A", "S", "D", "F", "G"
    db $fb, "Q", "W", "E", "R", "T"
    db $f7, "1", "2", "3", "4" ,"5"
    db $ef, "0", "9", "8", "7", "6"
    db $df, "P", "O", "I", "U", "Y"
    db $bf, "#", "L", "K", "J", "H"
    db $7f, " ", "#", "M", "N", "B"

; snapshot
    SAVESNA "load.sna", start
