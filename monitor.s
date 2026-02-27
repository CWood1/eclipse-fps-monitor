	dev TTI = 010
	dev TTO = 011

	org 040
	var stackptr = 01000
	var frameptr = 01000
	var stacklim = 01500
	var x = 0600

	org 0100

start:	
	ELEF 2, banner
	JSR print

	ELEF 0, tst1
	ELEF 1, tst2
	PSH 0,1
	JSR strcmp
	POP 0,1  // Get the values back, although we don't really care about them much

	MOV 2, 2, SNR
	JMP start_tst1ne

	ELEF 2, same_str
	JSR print
	JMP start_tst2

start_tst1ne:
	ELEF 2, diff_str
	JSR print

start_tst2:
	ELEF 0, tst2
	ELEF 1, tst3
	PSH 0,1
	JSR strcmp
	POP 0,1  // Get the values back, although we don't really care about them much

	MOV 2, 2, SNR
	JMP start_tst2ne

	ELEF 2, same_str
	JSR print
	HALT

start_tst2ne:
	ELEF 2, diff_str
	JSR print
	HALT

	// strcmp - Compare two strings
	//
	// Parameters:
	// - Stack: string 1
	// - Stack: string 2
	//
	// Returns:
	// - AC2 = 0: Strings are the same
	// - AC2 = 1: Strings are different
	//
	// Stack variables:
	// - Offset 0: current string offset
strcmp:
	SAVE 1

	XOR 1,1       // AC1 is the current character within each string
	STA 1, 1, 3   // Place the current offset on the stack

strcmp_loop:	
	LDA 2, -7, 3  // Load AC2 with the first string
	ADD 1, 2      // Add AC1 to AC2, and place in AC2

	LDA 0, 0, 2   // Load the character from the first string in AC0

	LDA 2, -6, 3  // Load AC2 with the second string
	ADD 1, 2      // Offset into the string

	LDA 1, 0, 2   // Load the character from the second string into AC1

	SUB 0,1,SZR   // Subtract AC0 from AC1. If the result isn't 0, the two strings differ
	JMP strcmp_noteq

	MOV 0,0,SNR   // Check whether AC0 is zero. If it is, the strings are the same
	JMP strcmp_eq

	LDA 1, 1, 3   // Increment the current counter, and reload it in AC1
	INC 1, 1
	STA 1, 1, 3

	JMP strcmp_loop

strcmp_noteq:
	ELEF 2, 1      // Set the result in AC2. -3 from AC3 is the AC2 to restore
	STA 2, -2, 3
	RTN

strcmp_eq:
	XOR 2, 2
	STA 2, -2, 3
	RTN
	
	// print - Print a zero terminated string
	//
	// Parameters:
	// -  AC2: String to print
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
	var same_str = "Strings are the same!\r\n"
	var diff_str = "Strings are different!\r\n"

	var tst1 = "abc"
	var tst2 = "abc"
	var tst3 = "def"

	org 0600
	HALT
