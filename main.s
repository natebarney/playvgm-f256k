.include "xpeek.inc"
.include "vgm.inc"

DATAADDR = $010000

.proc main

    stz $01

    ; copy DATAADDR to GLOBADDR
    lda #<DATAADDR
    sta GLOBADDR
    lda #>DATAADDR
    sta GLOBADDR+1
    lda #^DATAADDR
    sta GLOBADDR+2

    jsr playvgm
    bra main

.endproc