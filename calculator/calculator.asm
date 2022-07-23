    DEVICE ZXSPECTRUM48

    org $8000

; routines
OPEN_CHANNEL    = $1601 ; 5633

; addresses
SCREEN          = $4000 ; start of screen memory
ATTR_M          = $5800 ; start of color attribute memory

; constants
KEY_PORTS       = 8     ; number of keyboard ports
KEYS_IN_PORT    = 5     ; number of keys per port (row)

start:
    ei                  ; enable interrupts to enable screen updates
    ld a, 2             ; select upper screen
    call OPEN_CHANNEL   ; open channel
    ld de, SCREEN       ; load first screen memory address into de

main_loop:
    call read_key       ; poll keyboard
    cp 0                ; compare result to zero
    call nz, print_char ; if result is not zero, print found character
    jr main_loop        ; loop forever
    ; ret

read_key:
    ld hl, key_map      ; keyboard map address
    ld d, KEY_PORTS     ; number of keyboard ports
    ld c, $fe           ; port high byte, always fe
.search_port:
    ld b, (hl)          ; get port low byte
    inc hl              ; move to first character in port (row)
    in a, (c)           ; read port
    and $1f             ; mask first five bits
    ld e, KEYS_IN_PORT  ; number of keys per port
.check_key:
    srl a               ; shift a right, carry is set when...?
    jr nc, .key_found   ; we found a key!
    inc hl              ; go to next key
    dec e               ; until the end of current port
    jr nz, .check_key   ; check next key
    dec d               ; until the end of all ports
    jr nz, .search_port ; go to next port
    and a               ; nothing found, clear flags?
    ret
.key_found:
    ld a, (hl)          ; load keycode into a
    ret

print_char:
    rst $10             ; print char in a to screen
    inc de              ; go to next screen address
    halt                ; wait for frame
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
