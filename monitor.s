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

	ELEF 0, tst2
	PSH 0,0
	JSR string_to_oct
	MOV 1, 1, SZR
	JMP start_right

	ELEF 2, wrong
	JSR print
	HALT

start_right:
	ELEF 2, right
	JSR print
	HALT

	// string_to_oct - Turn a given string into an octal number
	//
	// Parameters:
	// - Stack: string
	//
	// Returns:
	// - AC1 = 0 (on success), 1 (on NAN)
	// - AC2 = result
	//
	// Stack variables:
	// - Offset 0: current string offset
	// - Offset 1: current result
string_to_oct:
	SAVE 2

	XOR 1, 1
	STA 1, 1, 3

	STA 1, 2, 3

string_to_oct_loop:
	LDA 2, -5, 3  // Load AC2 with the first string
	ADD 1, 2

	LDA 0, 0, 2   // Load the first character into the string
	MOV 0, 0, SNR
	JMP string_to_oct_done

	ELEF 1, 060   // Character for zero
	SGE 0, 1      // If the current character is less than '0'
	JMP string_to_oct_nan

	SUB 1, 0
	ELEF 1, 7
	SGE 1, 0      // If the result is greater than 7...
	JMP string_to_oct_nan

	// Result = (result << 3) + AC0
	LDA 1, 2, 3
	MOVZL 1, 1
	MOVZL 1, 1
	MOVZL 1, 1
	ADD 0, 1
	STA 1, 2, 3

	// Next character
	LDA 1, 1, 3
	INC 1, 1
	STA 1, 1, 3

	JMP string_to_oct_loop

string_to_oct_done:
	LDA 1, 2, 3
	STA 1, -2, 3
	XOR 1, 1
	STA 1, -3, 3
	RTN

string_to_oct_nan:
	XOR 1, 1
	INC 1, 1
	STA 1, -3, 3
	RTN
	

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
	LDA 2, -5, 3  // Load AC2 with the first string
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
	var right = "Right\r\n"
	var wrong = "Wrong\r\n"

	var tst1 = "123456"
	var tst2 = "abc"

	org 0600
	HALT
