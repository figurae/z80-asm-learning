    DEVICE ZXSPECTRUM48

    org $8000

    jr start

string:
    db "hello"

STRING_LENGTH   = 5


start:
    ld a,$F1
    ld ($5800),a
    ret

;   Deployment: Snapshot
    SAVESNA "load.sna", start
