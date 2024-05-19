.INCLUDE "mmu.inc"

USEBANK = 5 ; set to configure which bank to use for reading extended memory

.SEGMENT "ZEROPAGE"

pointer: .RES 2 ; pointer to current location in specified memory bank

.SEGMENT "DATA"

mmu_seekaddr: .RES 3 ; exported, linear extended memory address for mmu_seek
oldmmu: .RES 1 ; saved copy of mmu register
oldpage: .RES 1 ; saved copy of mlut entry
page: .RES 1 ; which page the
offset: .RES 2

.SEGMENT "CODE"

.PROC mmu_init

    ; store original MMU register value
    lda MMU_MEM_CTRL
    sta oldmmu

    ; mask off all but ACT_LUT bits and store in temp variable
    and #%00000011
    sta oldpage

    ; shift ACT_LUT left 4 times to move it to EDIT_LUT
    asl
    asl
    asl
    asl

    ; add back in ACT_LUT bits
    ora oldpage

    ; set EDIT_EN bit
    ora #%10000000

    ; store modified value back into MMU
    sta MMU_MEM_CTRL

    ; save original MLUT table entry
    lda MMU_MLUT_TABLE + USEBANK
    sta oldpage

    ; set new entry
    lda page
    sta MMU_MLUT_TABLE + USEBANK

    rts

.ENDPROC

.PROC mmu_fini

    ; restore original MLUT entry
    lda oldpage
    sta MMU_MLUT_TABLE + USEBANK

    ; restore original MMU register
    lda oldmmu
    sta MMU_MEM_CTRL

    rts

.ENDPROC

.PROC mmu_seek

    ; get the top two bytes of seek address into temp variable
    lda mmu_seekaddr+1
    sta offset
    lda mmu_seekaddr+2
    sta offset+1

    ; shift pos and pos+1 left 3 bits so that pos+1 has the page
    asl offset
    rol offset+1
    asl offset
    rol offset+1
    asl offset
    rol offset+1

    ; store calculated page value
    lda offset+1
    sta page
    sta MMU_MLUT_TABLE + USEBANK

    ; calculate offset from seek address (low 13 bits)
    lda mmu_seekaddr
    sta offset
    sta pointer
    lda mmu_seekaddr+1
    and #%00011111      ; mask off top 3 bits
    sta offset+1
    ora #(USEBANK << 5) ; set top 3 bits to selected bank
    sta pointer+1

    rts

.ENDPROC

.PROC mmu_read

    ; read value at pointer, making sure to save/restore Y
    phy
    ldy #0
    lda (pointer),y
    ply

    ; intentional fallthrough to mmu_inc

.ENDPROC

.PROC mmu_inc

    ; increment first byte, and if there's no carry, we're done
    inc pointer
    inc offset
    bne done

    ; increment second byte and see if any of the top 3 bits are set. if not,
    ; we're done
    inc pointer+1
    inc offset+1
    pha
    lda offset+1
    and #%11100000
    beq pop

    ; we've crossed a page boundary, so mask off the top 3 bits of offset, and
    ; update the page and pointer values
    lda offset+1
    and #%00011111
    sta offset+1
    ora #(USEBANK << 5)
    sta pointer+1
    inc page
    inc MMU_MLUT_TABLE + USEBANK

pop:
    pla
done:
    rts

.ENDPROC
