
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
	JMP .-1
	DIAS 0, TTI

	SKPBZ TTO
	JMP .-1
	DOAS 0, TTO

	// Check if the received byte is \n
	SUB# 0, 1, SNR
	JMP input_done

	// Store the byte, incerement the pointer
	STA 0, 0, 2
	INC 2, 2

	JMP input_loop

input_done:	
	SKPBZ TTO
	JMP .-1

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
	
	// print_unpacked - Print a zero terminated string
	//
	// Parameters:
	// -  AC2: String to print
print_unpacked:
	SAVE 0

print_unpacked_outerloop:
	LDA 0, 0, 2
	MOV 0,0,SNR
	JMP print_unpacked_done

	SKPBZ TTO
	JMP .-1

	DOAS 0, TTO

	INC 2, 2
	JMP print_unpacked_outerloop

print_unpacked_done:	
	SKPBZ TTO
	JMP .-1
	RTN

	// print - Print a zero terminated string
	//
	// Parameters:
	// -  AC2: String to print
print:
	SAVE 0

print_outerloop:
	MOV 2, 1
	MOVZL 1, 1
	LDB 1, 0
	MOV 0,0,SNR
	JMP print_done
	
	SKPBZ TTO
	JMP .-1

	DOAS 0, TTO

	ELEF 0, 1
	IOR 0, 1
	LDB 1, 0
	MOV 0,0,SNR
	JMP print_done

	SKPBZ TTO
	JMP .-1

	DOAS 0, TTO

	INC 2, 2
	JMP print_outerloop

print_done:	
	SKPBZ TTO
	JMP .-1
	RTN
	
