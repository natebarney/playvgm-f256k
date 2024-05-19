.INCLUDE "irq.inc"
.INCLUDE "mmu.inc"
.INCLUDE "vgm.inc"

.SEGMENT "DATA"

delay_samp: .RES 2
sample_counter: .RES 3
sample_diff: .RES 3

.SEGMENT "CODE"

.PROC vgm_start

    pha                         ; save accumulator
    php                         ; save flags
    sei                         ; disable interrupts

    ; copy irq_sample_counter to sample_counter
    lda irq_sample_counter
    sta sample_counter
    lda irq_sample_counter+1
    sta sample_counter+1
    lda irq_sample_counter+2
    sta sample_counter+2

    plp                         ; restore flags
    pla                         ; restore accumulator
    rts

.ENDPROC

.PROC vgm_subtract_counter

    ; save flags, then disable interrupts
    php
    sei

    ; subtract irq_sample_counter from sample_counter into sample_diff
    sec
    lda sample_counter
    sbc irq_sample_counter
    sta sample_diff
    lda sample_counter+1
    sbc irq_sample_counter+1
    sta sample_diff+1
    lda sample_counter+2
    sbc irq_sample_counter+2
    sta sample_diff+2

    ; restore flags
    plp

    ; if high bit of high byte of sample_diff is set, result was negative
    lda sample_diff+2
    bmi nowait

    ; if bitwise OR of all sample_diff bytes is zero, result was zero
    ora sample_diff
    ora sample_diff+1
    beq nowait

    ; if we got here, result was positive, so signal to wait by returning
    ; non-zero in the accumulator
    lda #$ff
    bne done

    ; if we got here, result was not positive, so signal not to wait by
    ; returning zero in the accumulator
nowait:
    lda #0

done:
    rts

.ENDPROC

.PROC vgm_update

    ; if (sample_counter - irq_sample_counter) > 0, return
    jsr vgm_subtract_counter
    beq continue
    rts
continue:

playloop:
    jsr mmu_read
    cmp #$66
    beq rewind
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

rewind:
    jsr mmu_seek
    bra playloop

opl2_cmd:
    jsr mmu_read
    sta OPL3_ADDR_0
    bra opl_cmd

opl3_cmd:
    jsr mmu_read
    sta OPL3_ADDR_1

opl_cmd:
    jsr mmu_read
    sta OPL3_DATA
    bra playloop

delay_cmd:
    jsr mmu_read
    sta delay_samp
    jsr mmu_read
    sta delay_samp+1
    bra add_delay

delay_735_cmd:
    lda #<735
    sta delay_samp
    lda #>735
    sta delay_samp+1
    bra add_delay

delay_882_cmd:
    lda #<882
    sta delay_samp
    lda #>882
    sta delay_samp+1
    bra add_delay

add_delay:
    clc
    lda sample_counter
    adc delay_samp
    sta sample_counter
    lda sample_counter+1
    adc delay_samp+1
    sta sample_counter+1
    lda sample_counter+2
    adc #0
    sta sample_counter+2
    jmp vgm_update

end:
    rts

.endproc
