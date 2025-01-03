

	processor 6502			; вказуємо DASM асемблеру, що система команд буде MOS 6502 
	include "vcs.h"			; підключаємо хедер-файл

	seg						; вказуємо асемблеру створити сегмент даних для нашого картриджу

;------------------------------------------------------
; константи
const1		equ     10			; перша константа має значення 10

;------------------------------------------------------
; початок оперативної пам'яті (від 0x80 до 0хFF)
			seg.u	vars		; uninitialized segment
			org		$80
var1		ds      1			; 1 байт - var1
var2		ds      1	 		; 1 байт - var2
var3    	ds      2           ; 2 байти - var3

;------------------------------------------------------
; початок блоку пам'яті ROM
	seg		main				; start of main segment
	org $1000				

reset:						; мітка, на яку перейде вказівник команд після ресету
; Первинна ініціалізація - очистка пам'яті та регистрів
    ldx #0
    lda #0
Clear 
    sta 0,x
    inx
    bne Clear
;------------------------------------------------------------------------------------

; Блок 1 - Необмежений по часу. Тут можна робити глобальну ініціалізацію.

;------------------------------------------------------------------------------------

startFrame:

;------------------------------------------------------------------------------------

; Блок 2 - Маємо 3040 циклів, поки TIA дійде до видимої частини екрану. 
; Тут можна робити зміни, однакові для всього кадру.

;------------------------------------------------------------------------------------

	lda #0               	; записуємо 0 в регістр А (аккумулятор)
	sta VBLANK              ; і зберігаємо його за адресою $0001, що відповідає регістру VBLANK. Це команда TIA перевести промінь на початок першої строки екрану
	lda #2                  ; далі треба дочекатись синхронізації з початком кадру, ставимо 1-й біт в одиницю (00000010 BIN = 2 DEC) 
	sta VSYNC               ; записуємо це значення в регістр VSYNC

	sta WSYNC               ; чекаємо 3 сканлайни для завершення синхронізації кадру
	sta WSYNC				; будь яке значення, записане в регістр WSYNC змушує процесор чекати початку сканлайна
	sta WSYNC               ; то ж можна перевикористати наше 2, яке вже лежить в акумуляторі
    sta VSYNC               ; і вимикаємо вертикальну синхронізацію

    ldx #0					; записуємо 0 в індексний регістр Х
verticalBlank:   
	sta WSYNC               ; чекаємо на початок сканлайну
	inx						; збільшуємо Х на 1 (increment)
	cpx #37                 ; порівнюємо з 37 (compare)
	bne verticalBlank       ; якщо не дорівнює, йдемо на мітку verticalBlank

; тут ми нарешті дісталися видимої частини екрану і можемо почати шось на ньому малювати, в нас є на це 192 сканлайни
	ldx #0
scanLine:
;---------------------------------------------------------------------------------------------------------------------

; Блок 3 - 76 циклів на зміну сканлайну

;---------------------------------------------------------------------------------------------------------------------
	sta WSYNC 				; поки нічого не робимо, чекаємо на наступний сканлайн
	inx 					; збільшуємо X на 1
	cpx #192				; проходимо 192 сканлайни 
	bne scanLine
;---------------------------------------------------------------------------------------------------------------------
; завершаємо кадр, нам треба пропустити ще 30 сканлайнів згідно рекомендації
	ldx #0					; записуємо 0 в регістр Х
overscan:        
	sta WSYNC				; чекаємо на сканлайн
	inx						; збільшуємо Х на 1
	cpx #30                 ; порівнюємо з 30, якщо ні, повторюємо цикл             
	bne overscan            ;        

	jmp startFrame          ; тут в нас безумовний перехід на початок нового кадру

;-------------------------------------------------------------------------------------------------------------------------------------------






;-------------------------------------------------------------------------------------------------------------------------------------------
	org $1ffa               ; в останні 6 байт прошивки картриджа нам треба покласти вектори переривань. Сюди процесор лізе при запуску системи
; всі 3 вектори ведуть на мітку	reset на початку нашого кода
interruptVectors:
	.word reset             ; nmi 
	.word reset             ; reset
	.word reset             ; irq