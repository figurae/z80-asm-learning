        device  zxspectrum48

        org     $8000

seed:   equ     $ff00                   ; address of the seed
screen: equ     $4000                   ; screen memory start address

start:
        ld      b,0                     ; initialize inner loop (256 bits)
        ld      d,27                    ; initialize outer loop (24 bytes + 3 bytes)
        ld      a,$ff                   ; load initial bitmap value
        ld      hl,screen               ; load screen memory start address
.loop:
        ld      (hl),a                  ; write bitmap value in a to screen address
        push    hl
        push    de
        call    get_random_number       ; load a not-so-random value in a
        pop     de
        pop     hl
        inc     hl                      ; go to next screen address
        djnz    .loop                   ; complete inner loop
        dec     d                       ; decrease outer loop counter
        jp      nz,.loop                ; and complete outer loop
        ret

get_random_number:                      ; returns a, destroys hl, de 
        ld      hl,(seed)               ; load seed as address in hl 
        ld      e,(hl)                  ; get whatever is at the address
        ld      a,r                     ; load current refresh register value
        ld      d,a                     ; load it into d (magic-number d works too)
        add     hl,de                   ; add de to current seed
        xor     h                       ; xor h to get a pseudorandom byte into a
        ld      (seed),hl               ; save the new seed
        ret

        savesna "main.sna",start
