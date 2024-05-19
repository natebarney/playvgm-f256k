.include "xpeek.inc"

USEBANK = 5
USEMLUT = 3

.EXPORTZP TEMPZP = $fb

.SEGMENT "DATA"
GLOBADDR:
.byte 0,0,0

.SEGMENT "CODE"
;
; Read a byte from a global memory address
;
; Constants:
;
;   USEBANK - which memory bank to use to read the byte
;   USEMLUT - which memory look-up table to use to bank in the memory region
;
; Inputs:
;
;   GLOBADDR - 3 byte pointer to global memory
;
; Outputs:
;
;   A - byte at GLOBADDR in global memory
;
; Clobbers:
;
;   CF, ZF, NF
;
.proc xpeek

    ; get the top two bytes of peek address into TEMPZP
    lda GLOBADDR+1
    sta TEMPZP
    lda GLOBADDR+2
    sta TEMPZP+1

    ; shift 2 bytes at TEMPZP left 3 bits so that TEMPZP+1 has the MLUT value
    asl TEMPZP
    rol TEMPZP+1
    asl TEMPZP
    rol TEMPZP+1
    asl TEMPZP
    rol TEMPZP+1

    ; set up the MLUT
    lda $00             ; save existing MMU register
    pha                 ;


    lda #$80 | (USEMLUT << 4) | USEMLUT ; set MMU register
    sta $00                             ; (EDIT_EN=1, EDIT_MLUT=USEMLUT,
                                        ;  ACT_MLUT=USEMLUT)

    lda $08+USEBANK     ; save existing MLUT entry
    pha                 ;

    lda TEMPZP+1        ; set new MLUT entry
    sta $08+USEBANK     ;

    ; set 2 bytes at TEMPZP to be the 6502 address to read
    lda GLOBADDR        ; load low byte of address
    sta TEMPZP          ; store low byte of address
    lda GLOBADDR+1      ; load high byte of address
    and #%00011111      ; mask off top 3 bits of high byte of address
    ora #(USEBANK << 5) ; set top 3 bits to be the bank to use
    sta TEMPZP+1        ; store high byte of address

    ; read value and store in TEMPZP
    phy                 ; save Y register
    ldy #0              ; zero Y register
    lda (TEMPZP),y      ; load value from memory at address pointed to by TEMPZP
    ply                 ; restore Y register
    sta TEMPZP          ; store value in TEMPZP

    ; restore previous memory configuration
    pla                 ; restore previous MLUT entry
    sta $08+USEBANK     ;

    pla                 ; restore previous MMU register
    sta $00             ;

    ; increment GLOBADDR
    inc GLOBADDR
    bne incdone
    inc GLOBADDR+1
    bne incdone
    inc GLOBADDR+2
incdone:

    ; read value from TEMPZP into accumulator and return
    lda TEMPZP
    rts

.endproc