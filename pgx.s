.IMPORT __MAIN_START__

.SEGMENT "PGX"

.BYTE "PGX"
.BYTE $03
.DWORD __MAIN_START__
