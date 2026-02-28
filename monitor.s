	dev TTI = 010
	dev TTO = 011

	org 040
	var stackptr = stack_top
	var frameptr = stack_top
	var stacklim = stack_top + 02000
	var exhaustedptr = stack_exhausted

	org 0100

start:
	NIOS TTI

	ELEF 2, banner
	EJSR print

doprompt:	
	ELEF 2, prompt
	EJSR print

	ELEF 0, command_str
	PSH 0, 0
	JSR input
	POP 0, 0

	ELEF 0, command_str
	PSH 0, 0
	JSR string_to_oct
	POP 0, 0

	PSH 2, 2
	ELEF 0, targetstr
	PSH 0, 0
	JSR oct_to_string
	POP 0, 1

	ELEF 2, targetstr
	EJSR print

	ELEF 2, nl
	EJSR print

	JMP doprompt
	
	// ============================================================
	// Utility Functions
	// ============================================================

	// input - Get a line of input from the terminal
	//
	// Parameters:
	// - Stack: pointer to where to put the string
	//
	// No return value
input:
	SAVE 0
	LDA 2, -5, 3

	// Load register 1 with '\r'
	ELEF 1, 015

input_loop:
	SKPDN TTI
	JMP input_loop
	DIAS 0, TTI

input_outloop:
	SKPBZ TTO
	JMP input_outloop
	DOAS 0, TTO

	// Check if the received byte is \n
	SUB 0, 1, SNR
	JMP input_done

	// Store the byte, incerement the pointer
	STA 0, 0, 2
	INC 2, 2

	// Reload the \r (this is only necessary as dgasm doesn't support SUB# yet)
	ELEF 1, 015
	JMP input_loop

input_done:
	SKPBZ TTO
	JMP input_done

	ELEF 0, 012
	DOAS 0, TTO
	
	XOR 0, 0
	STA 0, 0, 2

	RTN
	
	// oct_to_string - Turn a given word into an octal string
	//
	// Parameters:
	// - Stack: the number
	// - Stack: pointer to where to put the string
	//
	// No return value
	//
	// Stack variables:
	// - Offset 0: Current offset into the string
oct_to_string:
	SAVE 1

	// If number is 0, print 0 and exit
	LDA 2, -6, 3
	MOV 2, 2, SNR
	JMP oct_to_string_zero

	// Set up the string offset
	ELEF 2, 5
	STA 2, 1, 3

	// Get the address of the string
	LDA 2, -5, 3
	LDA 0, 1, 3
	ADD 0, 2

	// NULL terminator
	XOR 1, 1
	STA 1, 1, 2

	ELEF 1, 1
	SUB 1, 0, SNR
	STA 0, 1, 3

oct_to_string_loop:	
	// Get the digit, AND off the bottom 3 bits
	LDA 2, -6, 3
	ELEF 1, 7
	AND 1, 2

	// Add '0' to it
	ELEF 1, 060
	ADD 2, 1

	// Get the address of the string
	LDA 2, -5, 3
	LDA 0, 1, 3
	ADD 0, 2

	// Store the character
	STA 1, 0, 2

	// Increment the offset
	MOV 0, 0, SNR
	JMP oct_to_string_pad_done

	ELEF 1, 1
	SUB 1, 0

	STA 0, 1, 3

	// Shift the number down and go round again
	LDA 2, -6, 3
	MOVZR 2,2
	MOVZR 2,2
	MOVZR 2,2
	STA 2, -6, 3

	// If it isn't zero, go round again
	MOV 2, 2, SZR
	JMP oct_to_string_loop

oct_to_string_pad_loop:
	ELEF 1, 060

	// Get the address of the string
	LDA 2, -5, 3
	LDA 0, 1, 3
	ADD 0, 2

	// Store the character
	STA 1, 0, 2

	// Increment the offset
	MOV 0, 0, SNR
	JMP oct_to_string_pad_done

	ELEF 1, 1
	SUB 1, 0

	STA 0, 1, 3
	JMP oct_to_string_pad_loop

oct_to_string_pad_done:	
	RTN

oct_to_string_zero:
	// String is '0'
	LDA 2, -5, 3
	ELEF 1, 060
	STA 1, 0, 2

	// NULL terminator
	XOR 1, 1
	STA 1, 1, 2

	RTN
	
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
	var prompt = "> "
	var nl = "\r\n"

	var targetstr resv 10
	var command_str resv 20

stack_exhausted:	
	HALT

stack_top:	
