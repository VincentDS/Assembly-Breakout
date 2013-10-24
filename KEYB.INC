; ==============================================================================
; Keyboard functionality.
; ==============================================================================

; --- EXPORTS ------------------------------------------------------------------

externdef installKeyboardHandler:FAR, uninstallKeyboardHandler:FAR, keyboardHandler:FAR
externdef __keyboardState:BYTE, __rawScanCode:BYTE, __keysActive:BYTE

; Scancodes
; for more codes, see http://www.ee.bgu.ac.il/~microlab/MicroLab/Labs/ScanCodes.htm
SCANCODE_ESC	equ	01h
SCANCODE_1	equ	02h
SCANCODE_2	equ	03h
SCANCODE_3	equ	04h
SCANCODE_4	equ	05h
SCANCODE_5	equ	06h
SCANCODE_6	equ	07h
SCANCODE_7	equ	08h
SCANCODE_8	equ	09h
SCANCODE_9	equ	0ah
SCANCODE_0	equ	0bh
SCANCODE_BACKSPACE	equ	0eh
SCANCODE_TAB	equ	0fh
SCANCODE_UP	equ	48h
SCANCODE_DOWN	equ	50h
SCANCODE_LEFT	equ	4bh
SCANCODE_RIGHT	equ	4dh

; --- MACROS AND CONSTANTS -----------------------------------------------------

