.INCLUDE "vgm.inc"
.INCLUDE "xpeek.inc"

OPL3_ADDR_0 = $d580
OPL3_DATA = $d581
OPL3_ADDR_1 = $d582

T0_CTR = $d650
UP = %00001000
LD = %00000100
CLR = %00000010
EN = %00000001

T0_STAT = $d650
EQ = %00000001

T0_VAL = $d651

T0_CMP_CTR = $d654
RELD = %00000010
RECLR = %00000001

T0_CMP = $d655

;ONE_FRAME = $0666ff
ONE_FRAME = $063000

.SEGMENT "DATA"
delay_samp: .res 2

.SEGMENT "CODE"

.proc playvgm

stz delay_samp
stz delay_samp+1

playloop:
    jsr xpeek
    cmp #$66
    beq end
    cmp #$5a
    beq opl2_cmd
    cmp #$5e
    beq opl2_cmd
    cmp #$5f
    beq opl3_cmd
    cmp #$61
    beq delay_cmd
    cmp #$62
    beq delay_735_cmd
    cmp #$63
    beq delay_882_cmd
    bra playloop

end:
    rts

opl2_cmd:
    jsr xpeek
    sta OPL3_ADDR_0
    jsr xpeek
    sta OPL3_DATA
    bra playloop

opl3_cmd:
    jsr xpeek
    sta OPL3_ADDR_1
    jsr xpeek
    sta OPL3_DATA
    bra playloop

delay_cmd:
    jsr xpeek
    clc
    adc delay_samp
    sta delay_samp
    php
    jsr xpeek
    plp
    adc delay_samp+1
    sta delay_samp+1
    jsr sample_delay
    bra playloop

delay_735_cmd:
    lda #$df
    clc
    adc delay_samp
    sta delay_samp
    php
    lda #$02
    plp
    adc delay_samp+1
    sta delay_samp+1
    jsr sample_delay
    bra playloop

delay_882_cmd:
    lda #$72
    clc
    adc delay_samp
    sta delay_samp
    php
    lda #$03
    plp
    adc delay_samp+1
    sta delay_samp+1
    jsr sample_delay
    jmp playloop

.endproc

.proc sample_delay

    ; if delay_samp >= 735, subtract 735, delay 1/60 sec, and loop again
    lda #$02
    cmp delay_samp+1
    beq next
    bcs done
    bra subtract
next:
    lda #$df
    cmp delay_samp
    bcs done
    bra subtract

done:
    rts

subtract:
    sec
    lda delay_samp
    sbc #$df
    sta delay_samp
    lda delay_samp+1
    sbc #$02
    sta delay_samp+1

    ; store 1/60 second's worth of ticks in timer 0 value and compare registers
    lda #<ONE_FRAME
    sta T0_VAL
    sta T0_CMP
    lda #>ONE_FRAME
    sta T0_VAL+1
    sta T0_CMP+1
    lda #^ONE_FRAME
    sta T0_VAL+2
    sta T0_CMP+2

    ; load value on timer 0 completion
    lda #RELD
    sta T0_CMP_CTR

    ; clear timer 0
    lda #CLR
    sta T0_CTR

    ; count up, no load, no clear, enable
    lda #(UP | EN)
    sta T0_CTR

    ; wait for timer to complete
loop:
    lda T0_STAT
    beq loop

    bra sample_delay

.endproc