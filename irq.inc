.GLOBAL irq_install
.GLOBAL irq_uninstall
.GLOBAL irq_handler
.GLOBAL irq_start_of_frame

.GLOBAL irq_sample_counter

VIRQ = $FFFE ; 6502 IRQ vector

INT_PEND_0 = $D660 ; Pending register for interrupts 0 - 7
INT_PEND_1 = $D661 ; Pending register for interrupts 8 - 15
INT_MASK_0 = $D66C ; Mask register for interrupts 0 - 7
INT_MASK_1 = $D66D ; Mask register for interrupts 8 - 15

INT_VKY_SOF = %00000001 ; bit for TinyVicky Start Of Frame interrupt
