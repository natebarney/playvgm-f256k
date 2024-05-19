.INCLUDE "irq.inc"
.INCLUDE "mmu.inc"
.INCLUDE "vgm.inc"

data_addr = $010000

.proc main

    stz MMU_IO_CTRL

    jsr mmu_init ; initialize MMU library

    ; seek to beginning of music data
    lda #<data_addr
    sta mmu_seekaddr
    lda #>data_addr
    sta mmu_seekaddr+1
    lda #^data_addr
    sta mmu_seekaddr+2
    jsr mmu_seek

    jsr irq_install
    jsr vgm_start

loop:
    jsr vgm_update
    bra loop

.endproc