.INCLUDE "irq.inc"
.INCLUDE "mmu.inc"

.SEGMENT "DATA"

irq_sample_counter: .RES 4
old_handler: .RES 2
old_int_mask_0: .RES 1
old_int_mask_1: .RES 1
old_bank_7: .RES 1

SAMPLES_60FPS = 44100 / 60
SAMPLES_70FPS = 44100 / 70
SAMPLES_PER_FRAME = SAMPLES_60FPS ; set to match framerate

.SEGMENT "CODE"

.PROC irq_install

    sei

    ; save previous MLUT entry for bank 7, and set bank 7 to page 7
    lda MMU_MLUT_TABLE+7
    sta old_bank_7
    lda #7
    sta MMU_MLUT_TABLE+7

    ; save old interrupt handler
    lda VIRQ
    sta old_handler
    lda VIRQ+1
    sta old_handler+1

    ; install new interrupt handler
    lda #<irq_handler
    sta VIRQ
    lda #>irq_handler
    sta VIRQ+1

    ; save previous interrupt masks
    lda INT_MASK_0
    sta old_int_mask_0
    lda INT_MASK_1
    sta old_int_mask_1

    ; enable start-of-frame interrupt
    lda #((~INT_VKY_SOF) & $ff)
    sta INT_MASK_0
    lda $ff
    sta INT_MASK_1

    ; clear all pending interrupts
    lda #$ff
    sta INT_PEND_0
    sta INT_PEND_1

    ; clear 32-bit sample counter
    stz irq_sample_counter
    stz irq_sample_counter+1
    stz irq_sample_counter+2
    stz irq_sample_counter+3

    cli
    rts

.ENDPROC

.PROC irq_uninstall
    sei

    ; restore previous MLUT entry 7
    lda old_bank_7
    sta MMU_MLUT_TABLE+7

    ; restore old interrupt handler
    lda old_handler
    sta VIRQ
    lda old_handler+1
    sta VIRQ+1

    ; restore old interrupt masks
    lda old_int_mask_0
    sta INT_MASK_0
    lda old_int_mask_1
    sta INT_MASK_1

    ; clear all pending interrupts
    lda #$ff
    sta INT_PEND_0
    sta INT_PEND_1

    cli
    rts

.ENDPROC

.PROC irq_handler

    ; save the registers
    pha
    phx
    phy

    ; save the system control register
    lda MMU_IO_CTRL
    pha

    ; switch to I/O page 0
    stz MMU_IO_CTRL

    ; check for SOF flag
    lda #INT_VKY_SOF
    bit INT_PEND_0

    ; if it’s zero, just return
    beq not_sof

    ; clear the flag for SOF
    sta INT_PEND_0

    jsr irq_start_of_frame

not_sof:

    ; restore system control register
    pla
    sta MMU_IO_CTRL

    ; restore the registers
    ply
    plx
    pla

    rti

.ENDPROC

.PROC irq_start_of_frame

    ; add to 32-bit sample counter
    clc
    lda irq_sample_counter
    adc #<SAMPLES_PER_FRAME
    sta irq_sample_counter
    lda irq_sample_counter+1
    adc #>SAMPLES_PER_FRAME
    sta irq_sample_counter+1
    lda irq_sample_counter+2
    adc #^SAMPLES_PER_FRAME ; almost certainly zero, but you never know
    sta irq_sample_counter+2
    lda irq_sample_counter+3
    adc #0
    sta irq_sample_counter+3

done:
    rts

.ENDPROC