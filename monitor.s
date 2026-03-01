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
	EJSR input
	POP 0, 0

	ELEF 0, command_str
	ELEF 1, command_tokens
	ELEF 2, 8
	PSH 0, 2
	EJSR strtok
	POP 2, 0

	ELEF 0, top_level_command_table
	ELEF 1, command_str
	ELEF 2, command_tokens + 1
	ELEF 3, 7  // 8 possible locations, the first must be the command
	PSH 0, 3

	EJSR cmdtbl

	POP 3, 0

	JMP doprompt

	var command_str resv 80
	var command_tokens resv 9

	var banner = "Eclipse FPS100 Resident Monitor v0.0.1\r\nAuthored by Venos\r\n\n"
	var prompt = "> "
	var nl = "\r\n"

	// ============================================================
	// Commands
	// ============================================================
	var deposit_command_name = "d"
	var examine_command_name = "x"

top_level_command_table:
	var deposit_command_name_p = deposit_command_name
	var deposit_command_func = dep
	var examine_command_name_p = examine_command_name
	var examine_command_func = exam
	var end = 0
	var end2 = 0

	// dep - Deposit a value into the AP
	//
	// Parameters:
	// - Stack: pointer to address string
	// - Stack: pointer to value string
	//
	// Stack variables:
	// - Offset 0: address to write to
	//
	// NOTE: for testing purposes, this doesn't (yet) talk to the AP
dep:
	SAVE 1

	// First, convert the address into octal
	LDA 2, -11, 3
	MOV 2, 2, SNR
	JMP dep_done

	PSH 2, 2
	EJSR string_to_oct
	POP 0, 0

	MOV 1, 1, SZR
	JMP dep_done

	// Save the result to the stack
	STA 2, 1, 3

	// Next, convert the value into octal
	LDA 2, -10, 3
	MOV 2, 2, SNR
	JMP dep_done

	PSH 2, 2
	EJSR string_to_oct
	POP 0, 0

	MOV 1, 1, SZR
	JMP dep_done

	// Put value in AC1, address in AC2
	MOV 2, 1
	LDA 2, 1, 3

	// Store the address
	STA 1, 0, 2

dep_done:
	RTN

	// exam - Examine a value from the AP
	//
	// Parameters:
	// - Stack: pointer to address string
	//
	// NOTE: for testing purposes, this doesn't (yet) talk to the AP
exam:
	SAVE 1

	// First, convert the address into octal
	LDA 2, -11, 3
	MOV 2, 2, SNR
	JMP dep_done

	PSH 2, 2
	EJSR string_to_oct
	POP 0, 0

	MOV 1, 1, SZR
	JMP exam_done

	MOV 2, 0
	ELEF 1, exam_result

	PSH 0, 1
	EJSR oct_to_string
	POP 1, 0

	ELEF 2, exam_result
	EJSR print

	ELEF 2, nl
	EJSR print

exam_done:
	RTN

	var exam_result resv 7
	
	// ============================================================
	// Utility Functions
	// ============================================================

	// cmdtbl - Trigger a command from a command table
	//
	// Parameters:
	// - Stack: the command table
	// - Stack: the command string
	// - Stack: pointer to the stackframe for the command to run
	// - Stack: command stackframe size
	//
	// No return value
	//
	// Stack variables:
	// - Offset 0: current command to test
	//
	// Command table structure:
	// <pointer to NULL terminated command string> <pointer to routine to call>
	// Last entry is defined by a pair of NULL pointers
cmdtbl:
	SAVE 1			// one local: current table entry pointer

	// current = table pointer
	LDA 0, -8, 3
	STA 0, 1, 3

cmdtbl_loop:
	// AC2 = current entry pointer
	LDA 2, 1, 3

	// AC0 = table string pointer (*current)
	LDA 0, 0, 2

	// If NULL → end of table
	MOV 0,0,SNR
	JMP cmdtbl_done

	// ---- strcmp(table_string, command_string) ----

	LDA 1, -7, 3		// command string

	PSH 0,1			// push table string
	EJSR strcmp
	POP 1,0

	// strcmp result in AC2
	// 0 = equal
	MOV 2,2,SZR
	JMP cmdtbl_next

	// ========= MATCH FOUND =========

	// ---- Clone frame template ----
	LDA 2, -6, 3		// AC2 = template pointer
	LDA 1, -5, 3		// AC3 = frame size (counter)

cmdtbl_frame_loop:
	MOV 1, 1, SNR		// if count == 0 → done
	JMP cmdtbl_call

	LDA 0, 0, 2		// AC0 = *template
	PSH 0,0			// push word

	INC 2, 2		// template++

	// decrement AC3 (count--)
	ELEF 0, 1
	SUB 0, 1			// AC3 = AC3 - AC0

	JMP cmdtbl_frame_loop

cmdtbl_call:
	// Load routine pointer: *(current + 1)
	LDA 2, 1, 3		// AC2 = current
	LDA 2, 1, 2		// AC2 = routine pointer

	JSR 0, 2		// indirect call via AC2

	LDA 1, -5, 3

cmdtbl_popparams:
	MOV 1, 1, SNR
	JMP cmdtbl_done		// safety return

	POP 0, 0

	ELEF 0, 1
	SUB 0, 1

	JMP cmdtbl_popparams

cmdtbl_next:
	// current += 2
	LDA 0, 1, 3
	INC 0,0
	INC 0,0
	STA 0, 1, 3
	JMP cmdtbl_loop

cmdtbl_done:
	RTN

	// strtok - Tokenise a string
	//
	// Parameters:
	// - Stack: pointer to the string to tokenise. Modify in place.
	// - Stack: pointer to a buffer in which to emplace substrings.
	// - Stack: Max tokens (buffer must be N + 1 in size).
	//
	// No return value
strtok:
	SAVE 0

	// Check that max tokens isn't 0
	LDA 0, -5, 3
	MOV 0, 0, SNR
	JMP strtok_done

	// Check the string isn't empty
	LDA 2, -7, 3
	LDA 0, 0, 2
	MOV 0, 0, SNR
	JMP strtok_done

strtok_skipspaces:
	// Compare to space
	ELEF 1, 040
	SUB 0, 1, SZR
	JMP strtok_found_nonspace

	INC 2, 2
	LDA 0, 0, 2
	JMP strtok_skipspaces

strtok_found_nonspace:
	MOV 0, 0, SNR
	JMP strtok_done

	// Store the start of the next string in the string pointer
	STA 2, -7, 3

	// Also store it in the table
	MOV 2, 1
	LDA 2, -6, 3
	STA 1, 0, 2

	// Move to the entry in the table
	INC 2, 2
	STA 2, -6, 3

strtok_find_end_of_current_string:
	// If it's a space, we've found the end of the current token
	ELEF 1, 040
	SUB 0, 1, SNR
	JMP strtok_foundspace

	// If it's a NULL, we've found the end of the whole string
	MOV 0, 0, SNR
	JMP strtok_done

	// Else, increment by a character and go again
	LDA 2, -7, 3
	INC 2, 2
	STA 2, -7, 3
	LDA 0, 0, 2

	JMP strtok_find_end_of_current_string

strtok_foundspace:
	// Mark the current character as NULL
	LDA 2, -7, 3
	XOR 0, 0
	STA 0, 0, 2

	// Increment by a character
	LDA 2, -7, 3
	INC 2, 2
	STA 2, -7, 3
	LDA 0, 0, 2

	// Find the start of the next token
	JMP strtok_skipspaces

strtok_done:
	// Set the pointer to 0, and return
	LDA 2, -6, 3
	XOR 0, 0
	STA 0, 0, 2

	RTN

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

stack_exhausted:	
	HALT

stack_top:	
