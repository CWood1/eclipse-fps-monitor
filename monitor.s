	dev TTI = 010
	dev TTO = 011

	org 040
	var stackptr = 0400
	var frameptr = 0400
	var stacklim = 0600
	var stackfault = 0300

	org 0100

start:	
	ELEF 2, banner
	JSR print
	HALT

print:
	SAVE 0

print_outerloop:	
	LDA 0, 0, 2
	MOV 0,0,SNR
	JMP print_done

print_outputloop:	
	SKPBZ TTO
	JMP print_outputloop

	DOAS 0, TTO

	INC 2, 2
	JMP print_outerloop

print_done:
	SKPBZ TTO
	JMP print_done
	RTN

	var banner = "Eclipse FPS100 Resident Monitor v0.0.1\r\nAuthored by Venos\r\n\n"

	org 0300
	HALT
