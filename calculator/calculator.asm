    DEVICE ZXSPECTRUM48

    org $8000

SCREEN          = $4000
ATTR_M          = $5800

KEY_PORTS       = 8
KEYS_IN_PORT    = 5

    jr start

start:
    ei
    ld a, 2
    call 5633
    ld de, SCREEN

main_loop:
    call read_key
    cp 0
    call nz, print_char
    jr main_loop

    ret

read_key:
    ld hl, key_map      ; keyboard map address
    ld d, KEY_PORTS     ; number of keyboard ports
    ld c, $fe           ; port high byte, always fe
.search_port:
    ld b, (hl)          ; get port low byte
    inc hl              ; move to first character in port
    in a, (c)           ; ?
    and $1f             ; mask first five bits
    ld e, KEYS_IN_PORT  ; number of keys per port
.check_key:
    srl a               ; shift a right, why?
    jr nc, .key_found   ; we found a key!
    inc hl              ; go to next key
    dec e               ; until the end of current port
    jr nz, .check_key   ; check next key
    dec d               ; until the end of all ports
    jr nz, .search_port ; go to next port
    and a               ; nothing found, clear a
    ret
.key_found:
    ld a, (hl)          ; load keycode into a
    ret

print_char:
    rst $10
    inc de
    halt
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
