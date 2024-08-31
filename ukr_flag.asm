; helloworld for Atari 2600 - намалюємо український прапор

	processor 6502			; вказуємо DASM асемблеру, що система команд буде MOS 6502 
	include "vcs.h"			; підключаємо хедер-файл

	seg						; вказуємо асемблеру створити сегмент даних для нашого картриджу
	org $1000				; початок блоку пам'яті ROM

reset:						; мітка, на яку перейде вказівник команд після ресету

; отут бажано почистити пам'ять і регістри, бо після вмикання там може бути рандомне значення, але в емуляторі працює і так, то ж додамо пізніше

startFrame:
	lda #0               	; записуємо 0 в регістр А (аккумулятор)
	sta VBLANK              ; і зберігаємо його за адресою $0001, що відповідає регістру VBLANK. Це команда TIA перевести промінь на початок першої строки екрану
	lda #2                  ; далі треба дочекатись синхронізації з початком кадру, ставимо 1-й біт в одиницю (00000010 BIN = 2 DEC) 
	sta VSYNC               ; записуємо це значення в регістр VSYNC

	sta WSYNC               ; чекаємо 3 сканлайни для завершення синхронізації кадру
	sta WSYNC				; будь яке значення, записане в регістр WSYNC змушує процесор чекати початку сканлайна
	sta WSYNC               ; то ж можна перевикористати наше 2, яке вже лежить в акумуляторі

	lda #0					; записуємо в акумулятор 0 
	sta VSYNC               ; і вимикаємо вертикальну синхронізацію

; далі нам треба пропустити перші 37 строк VERTICAL BLANK щоб гарантовано потрапити у видиму частину екрану, 
; можна й менше, але деякі телевізори можуть обрізати зображення
; зараз ми просто чекаємо ці 37 сканлайнів, але в подальшому можна використати цей час з користю

	ldx #0					; записуємо 0 в індексний регістр Х
verticalBlank:   
	sta WSYNC               ; чекаємо на початок сканлайну
	inx						; збільшуємо Х на 1 (increment)
	cpx #37                 ; порівнюємо з 37 (compare)
	bne verticalBlank       ; якщо не дорівнює, йдемо на мітку verticalBlank

; тут ми нарешті дісталися видимої частини екрану і можемо почати шось на ньому малювати, в нас є на це 192 сканлайни
; давайте намалюємо прапор України :)

	ldx #0					; знову записуємо 0 в індексний регістр Х
	lda #$AE				; в акумулятор запишемо код блакитного кольору АЕ
	sta COLUBK				; і перенесемо цей колір в регістр COLUBK
topside:
	sta WSYNC				; чекаємо на початок сканлайну
	inx						; збільшуємо X на 1
	cpx #96                 ; та порівнюємо з 96 (середина екрану)
	bne topside           	; якщо не дорівнює, продовжуємо малювати блакитний фон

	lda #$EE				; якщо пройшли половину екрану, час змінити колір на жовтий EE
	sta COLUBK				; записуємо колір в регістр COLUBK
bottomside:	
	sta WSYNC				; чекаємо на початок сканлайну	
	inx						; збільшуємо X на 1					
	cpx #192				; тепер вже порівнюємо зі 192
	bne bottomside			; і малюємо до кінця екрану

	lda #0					; записуємо в СOLUBK чорний колір, щоб не малювати на "невидимій" частині екрану
	sta COLUBK				; хоча технічно можливо малювати шось на всіх сканлайнах

; завершаємо кадр, нам треба пропустити ще 30 сканлайнів згідно рекомендації
	ldx #0					; записуємо 0 в регістр Х
overscan:        
	sta WSYNC				; чекаємо на сканлайн
	inx						; збільшуємо Х на 1
	cpx #30                 ; порівнюємо з 30, якщо ні, повторюємо цикл             
	bne overscan            ;        

	jmp startFrame          ; тут в нас безумовний перехід на початок нового кадру

	org $1ffa               ; в останні 6 байт прошивки картриджа нам треба покласти вектори переривань. Сюди процесор лізе при запуску системи
; всі 3 вектори ведуть на мітку	reset на початку нашого кода
interruptVectors:
	.word reset             ; nmi 
	.word reset             ; reset
	.word reset             ; irq
