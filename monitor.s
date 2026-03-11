	dev TTI = 010
	dev TTO = 011
	dev FPU = 054

	const FN_STOP    = 0100000
	const FN_START   = 0040000
	const FN_CONT    = 0020000
	const FN_STEP    = 0010000
	const FN_RESET   = 0004000
	const FN_EXAM    = 0002000
	const FN_DEP     = 0001000
	const FN_BREAK   = 0000400
	const FN_INC_TMA = 0000300
	const FN_INC_DPA = 0000200
	const FN_INC_MA  = 0000100
	const FN_WORD3   = 0000060
	const FN_WORD2   = 0000040
	const FN_WORD1   = 0000020

	const FN_REG_PSA      = 00
	const FN_REG_SPD      = 01
	const FN_REG_MA       = 02
	const FN_REG_TMA      = 03
	const FN_REG_DPA      = 04
	const FN_REG_SPFN     = 05
	const FN_REG_APSTATUS = 06
	const FN_REG_DA       = 07

	const FN_MEM_SP   = 005
	const FN_MEM_PS   = 010
	const FN_MEM_INBS = 011
	const FN_MEM_DPX  = 013
	const FN_MEM_DPY  = 014
	const FN_MEM_MD   = 015
	const FN_MEM_TM   = 017

	const CMD_REG_SR = 0021000
	const CMD_REG_FN = 0022000
	const CMD_REG_LT = 0023000
	const CMD_PIO    = 0000030
	const CMD_WR     = 0000001

	org 040
	var stackptr = stack_top
	var frameptr = stack_top
	var stacklim = stack_top + 02000
	var exhaustedptr = stack_exhausted

	org 0100

start:
	NIOS TTI
	NIOP FPU
	NIOS FPU

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

	var banner = "Eclipse FPS100 Resident Monitor v0.1\r\nAuthored by Venos\r\n\nType `h` for help\r\n\n" packed
	var prompt = "> " packed
	var nl = "\r\n" packed
	var space = " " packed
	var reg_not_found = "Register not found\r\n" packed
	var mem_not_found = "Memory not found\r\n" packed
	var out_of_range = "Value is too large for the register you're putting it in\r\n" packed
	var syntax_error = "Syntax error\r\n" packed

	var help_top_level_string = "Eclipse FPS100 Resident Monitor v0.1\r\n\
Available commands:\r\n\
- d\tDeposit a value into a register\r\
- x\tExamine a register\r\
- dm\tDeposit memory\r\
- xm\tExamine memory\r\
- run\tRun the AP\r\
- h\tThis help\r\n\
To get command specific help, use `h [COMMAND]`.\r\n" packed

	var help_deposit_string = "Eclipse FPS100 Resident Monitor v0.1\r\nd - Deposit Register\r\n\
Syntax:	`d [REGISTER] [VALUE]`\r\n\
REGISTER\tThe register in which to deposit. Possible values are:\r\
- psa\t\tProgram source address register\t\t12 bits\r\
- spd\t\tS-Pad destination address register\t4 bits\r\
- ma\t\tMain data memory address register\t16 bits\r\
- tma\t\tTable memory address register\t\t16 bits\r\
- dpa\t\tData pad address register\t\t6 bits\r\
- apstatus\tFPS internal status register\t\t16 bits\r\
- da\t\tDevice address register\t\t\t8 bits\r\n\
VALUE\tThe value to deposit in octal. This is range checked.\r\n" packed

	var help_examine_string = "Eclipse FPS100 Resident Monitor v0.1\r\nx - Examine Register\r\n\
Syntax:	`x [REGISTER]`\r\n\
REGISTER\tThe register to examine. Possible values are:\r\
- psa\t\tProgram source address register\t\t\t12 bits\r\
- spd\t\tS-Pad destination address register\t\t4 bits\r\
- ma\t\tMain data memory address register\t\t16 bits\r\
- tma\t\tTable memory address register\t\t\t16 bits\r\
- dpa\t\tData pad address register\t\t\t6 bits\r\
- spfn\t\tS-Pad functoin currently enabled. Examine only.\t16 bits\r\
- apstatus\tFPS internal status register\t\t\t16 bits\r\
- da\t\tDevice address register\t\t\t\t8 bits\r\n" packed

	var help_examine_memory_string = "Eclipse FPS100 Resident Monitor v0.1\r\nxm - Examine Memory\r\n\
Syntax:	`xm [MEMORY] [ADDRESS] [COUNT]`\r\n\
MEMORY\tThe memory to read from. Possible values are:\r\
- sp\tS-Pad data\r\
- ps\tProgram source memory\r\
- dpx\tData Pad X\r\
- dpy\tData Pad Y\r\
- md\tMain data memory\r\
- tm\tTable memory\r\n\
ADDRESS\tThe address to start reading from.\r\
COUNT\tThe number of consecutive 64 bit words to read.\r\n\
Examine memory will read COUNT 64 bit words, starting at ADDRESS. Each one shall be output on the console.\r\n" packed

	var help_deposit_memory_string = "Eclipse FPS100 Resident Monitor v0.1\r\ndm - Deposit Memory\r\n\
Syntax:	`dm [MEMORY] [ADDRESS]`\r\n\
MEMORY\tThe memory to write to. Possible values are:\r\
- sp\tS-Pad data\r\
- ps\tProgram source memory\r\
- dpx\tData Pad X\r\
- dpy\tData Pad Y\r\
- md\tMain data memory\r\
- tm\tTable memory\r\n\
ADDRESS\tThe address to start writing from.\r\n\
Deposit memory will start a new prompt mode, which expects a 64 bit number, spread across 4 16-bit octal numbers.\r\n\
For each set of 4 numbers entered, the data represented will be written to the memory at the current address. The address will then be incremented.\r\n\
Upon successful writing, deposit memory will be ready for another data. To exit this mode, enter an empty line.\r\n" packed

	var help_run_string = "Eclipse FPS100 Resident Monitor v0.1\r\nrun - Run the AP\r\n\
Syntax:	`run [ADDRESS]`\r\n\
Start the AP at ADDRESS, and wait for it to halt before returning.\r\n" packed

	// ============================================================
	// Commands
	// ============================================================
	var deposit_command_name = "d"
	var examine_command_name = "x"
	var deposit_memory_command_name = "dm"
	var examine_memory_command_name = "xm"
	var run_command_name = "run"
	var help_command_name = "h"

top_level_command_table:
	dw deposit_command_name,        dep
	dw examine_command_name,        exam
	dw deposit_memory_command_name, depmem
	dw examine_memory_command_name, exammem
	dw run_command_name,            run
	dw help_command_name,           help
	dw 0, 0

	var psa      = "psa"
	var spd      = "spd"
	var ma       = "ma"
	var tma      = "tma"
	var dpa      = "dpa"
	var spfn     = "spfn"
	var apstatus = "apstatus"
	var da       = "da"

	var sp       = "sp"
	var ps       = "ps"
	var dpx      = "dpx"
	var dpy      = "dpy"
	var md       = "md"
	var tm       = "tm"

reg_max_tbl:
	dw psa,      0007777
	dw spd,      0000017
	dw ma,       0177777
	dw tma,      0177777
	dw dpa,      0000077
	dw apstatus, 0177777
	dw da,       0000377

dep_tbl:
	dw psa,      FN_DEP | FN_REG_PSA
	dw spd,      FN_DEP | FN_REG_SPD
	dw ma,       FN_DEP | FN_REG_MA
	dw tma,      FN_DEP | FN_REG_TMA
	dw dpa,      FN_DEP | FN_REG_DPA
	dw apstatus, FN_DEP | FN_REG_APSTATUS
	dw da,       FN_DEP | FN_REG_DA
	dw 0, 0

exam_tbl:
	dw psa,      FN_EXAM | FN_REG_PSA
	dw spd,      FN_EXAM | FN_REG_SPD
	dw ma,       FN_EXAM | FN_REG_MA
	dw tma,      FN_EXAM | FN_REG_TMA
	dw dpa,      FN_EXAM | FN_REG_DPA
	dw spfn,     FN_EXAM | FN_REG_SPFN
	dw apstatus, FN_EXAM | FN_REG_APSTATUS
	dw da,       FN_EXAM | FN_REG_DA
	dw 0, 0

mem_tbl:
	dw sp,  FN_REG_SPD
	dw ps,  FN_REG_TMA
	dw dpx, FN_REG_DPA
	dw dpy, FN_REG_DPA
	dw md,  FN_REG_MA
	dw tm,  FN_REG_TMA

mem_memtbl:
	dw sp,  FN_MEM_SP
	dw ps,  FN_MEM_PS
	dw dpx, FN_MEM_DPX
	dw dpy, FN_MEM_DPY
	dw md,  FN_MEM_MD
	dw tm,  FN_MEM_TM

mem_inctbl:
	dw sp,  0
	dw ps,  FN_INC_TMA
	dw dpx, FN_INC_DPA
	dw dpy, FN_INC_DPA
	dw md,  FN_INC_MA
	dw tm,  FN_INC_TMA

help_tbl:
	dw deposit_command_name, help_deposit_string
	dw examine_command_name, help_examine_string
	dw deposit_memory_command_name, help_deposit_memory_string
	dw examine_memory_command_name, help_examine_memory_string
	dw run_command_name, help_run_string
	dw 0, 0

help:
	SAVE 0

	ELEF 0, help_tbl
	LDA 1, -11, 3
	PSH 0, 1
	EJSR gettbl
	POP 0, 0
	POP 0, 0

	MOV 1, 1, SZR
	JMP help_top_level

	// The string pointer is already in register 2
	EJSR print
	RTN

help_top_level:
	ELEF 2, help_top_level_string
	EJSR print
	RTN

	// run - Run the AP
	//
	// Parameters:
	// - Stack: the start address
run:
	SAVE 0

	LDA 2, -11, 3
	MOV 2, 2, SNR
	JMP run_syntax_error

	PSH 2, 2
	EJSR string_to_oct
	POP 0, 0

	MOV 1, 1, SZR
	JMP run_syntax_error

	STA 2, 2, 3

	// Set the start address
	MOV 2, 0
	ELEF 1, CMD_REG_SR | CMD_PIO | CMD_WR
	DOA 1, FPU
	DOB 0, FPU

	// Set to run
	ELEF 0, FN_START
	ELEF 1, CMD_REG_FN | CMD_PIO | CMD_WR
	DOA 1, FPU
	DOB 0, FPU

run_wait:
	ELEF 1, CMD_REG_FN | CMD_PIO
	DOA 1, FPU
	DIB 0, FPU

	ELEF 1, FN_STOP
	AND 0, 1, SNR

	JMP run_wait

	RTN

run_not_found:	
	ELEF 2, mem_not_found
	EJSR print
	RTN

run_syntax_error:
	ELEF 2, syntax_error
	EJSR print
	RTN

	var depmem_in_str resv 30
	var depmem_in_tokens resv 5

	// depmem - Deposit values into the AP memory
	//
	// Parameters:
	// - Stack: pointer to memory name string
	// - Stack: pointer to address string
	//
	// Inputs:
	// - Data to deposit - 4 consecutive, space separated 16 bit values
	// - On finished, empty line
	//
	// Stack variables:
	// - Offset 1: the register to use
	// - Offset 2: the starting address
	// - Offset 3: the old register value
	// - Offset 4: the memory to use
	// - Offset 5: the inc value to use
depmem_syntax_error_2:
	EJMP depmem_syntax_error
depmem_not_found_2:
	EJMP depmem_not_found
depmem:
	SAVE 5

	// First, get which register we're using
	ELEF 0, mem_tbl
	LDA 1, -11, 3
	MOV 1, 1, SNR
	JMP depmem_syntax_error_2

	PSH 0, 1
	EJSR gettbl
	POP 0, 0
	POP 0, 0

	MOV 1, 1, SZR
	JMP depmem_not_found_2
	STA 2, 1, 3

	// Next, get which memory we're using
	ELEF 0, mem_memtbl
	LDA 1, -11, 3
	PSH 0, 1
	EJSR gettbl
	POP 0, 0
	POP 0, 0

	MOV 1, 1, SZR
	JMP depmem_not_found_2
	STA 2, 4, 3

	// Next, get which inc value to use
	ELEF 0, mem_inctbl
	LDA 1, -11, 3
	PSH 0, 1
	EJSR gettbl
	POP 0, 0
	POP 0, 0

	MOV 1, 1, SZR
	JMP depmem_not_found_2
	STA 2, 5, 3

	// Next, convert the starting address
	LDA 2, -10, 3
	MOV 2, 2, SNR
	JMP depmem_syntax_error_2

	PSH 2, 2
	EJSR string_to_oct
	POP 0, 0

	MOV 1, 1, SZR
	JMP depmem_syntax_error_2

	STA 2, 2, 3

	// Read the register as was
	LDA 0, 1, 3
	ELEF 1, FN_EXAM
	IOR 1, 0

	ELEF 1, CMD_REG_FN | CMD_PIO | CMD_WR
	DOA 1, FPU
	DOB 0, FPU

	ELEF 1, CMD_REG_LT | CMD_PIO
	DOA 1, FPU
	DIB 0, FPU

	STA 0, 3, 3

	// Set the new value, in order to start writing to memory
	LDA 0, 1, 3
	ELEF 1, FN_DEP
	IOR 1, 0

	ELEF 1, CMD_REG_SR | CMD_PIO | CMD_WR
	DOA 1, FPU
	DOB 0, FPU

	LDA 0, 2, 3
	ELEF 1, CMD_REG_FN | CMD_PIO | CMD_WR
	DOA 1, FPU
	DOB 0, FPU

depmem_write_64:	
	// Read in the next line
	ELEF 0, depmem_in_str
	PSH 0, 0
	EJSR input
	POP 0, 0

	ELEF 2, depmem_in_str
	LDA 0, 0, 2
	MOV 0, 0, SNR
	JMP depmem_done

	ELEF 0, depmem_in_str
	ELEF 1, depmem_in_tokens
	ELEF 2, 4
	PSH 0, 2
	EJSR strtok
	POP 2, 0

	// Convert each value from octal
	ELEF 2, depmem_in_tokens

	LDA 0, 3, 2
	PSH 0, 0
	EJSR string_to_oct
	POP 0, 0

	MOV 1, 1, SZR
	JMP depmem_done

	PSH 2, 2

	LDA 0, 2, 2
	PSH 0, 0
	EJSR string_to_oct
	POP 0, 0

	MOV 1, 1, SZR
	JMP depmem_done

	PSH 2, 2

	LDA 0, 1, 2
	PSH 0, 0
	EJSR string_to_oct
	POP 0, 0

	MOV 1, 1, SZR
	JMP depmem_done

	PSH 2, 2

	LDA 0, 0, 2
	PSH 0, 0
	EJSR string_to_oct
	POP 0, 0

	MOV 1, 1, SZR
	JMP depmem_done

	PSH 2, 2

	// Write the value out
	POP 0, 0
	ELEF 1, CMD_REG_SR | CMD_PIO | CMD_WR
	DOA 1, FPU
	DOB 0, FPU

	LDA 0, 4, 3
	ELEF 1, FN_DEP
	IOR 1, 0
	ELEF 1, CMD_REG_FN | CMD_PIO | CMD_WR
	DOA 1, FPU
	DOB 0, FPU

	POP 0, 0
	ELEF 1, CMD_REG_SR | CMD_PIO | CMD_WR
	DOA 1, FPU
	DOB 0, FPU

	LDA 0, 4, 3
	ELEF 1, FN_DEP | FN_WORD1
	IOR 1, 0
	ELEF 1, CMD_REG_FN | CMD_PIO | CMD_WR
	DOA 1, FPU
	DOB 0, FPU

	POP 0, 0
	ELEF 1, CMD_REG_SR | CMD_PIO | CMD_WR
	DOA 1, FPU
	DOB 0, FPU

	LDA 0, 4, 3
	ELEF 1, FN_DEP | FN_WORD2
	IOR 1, 0
	ELEF 1, CMD_REG_FN | CMD_PIO | CMD_WR
	DOA 1, FPU
	DOB 0, FPU

	POP 0, 0
	ELEF 1, CMD_REG_SR | CMD_PIO | CMD_WR
	DOA 1, FPU
	DOB 0, FPU

	LDA 0, 4, 3
	LDA 1, 5, 3
	IOR 1, 0
	ELEF 1, FN_DEP | FN_WORD3
	IOR 1, 0
	ELEF 1, CMD_REG_FN | CMD_PIO | CMD_WR
	DOA 1, FPU
	DOB 0, FPU

	JMP depmem_write_64

depmem_done:
	// Restore the old value
	LDA 0, 1, 3
	ELEF 1, FN_DEP
	IOR 1, 0

	ELEF 1, CMD_REG_FN | CMD_PIO | CMD_WR
	DOA 1, FPU
	DOB 0, FPU

	LDA 0, 3, 3
	ELEF 1, CMD_REG_FN | CMD_PIO | CMD_WR
	DOA 1, FPU
	DOB 0, FPU

	RTN

depmem_skip:
	RTN

depmem_not_found:	
	ELEF 2, mem_not_found
	EJSR print
	RTN

depmem_syntax_error:
	ELEF 2, syntax_error
	EJSR print
	RTN

	// exammem - Examine values from the AP memory
	//
	// Parameters:
	// - Stack: pointer to memory name string
	// - Stack: pointer to address string
	// - Stack: number of words to examine
	//
	// Stack variables:
	// - Offset 1: the register to use
	// - Offset 2: the starting address
	// - Offset 3: the old register value
	// - Offset 4: the memory to use
	// - Offset 5: the inc value to use
	// - Offset 6: the number of values to read
	// - Offset 7: the number of values read so far
exammem_syntax_error_2:
	EJMP exammem_syntax_error
exammem_not_found_2:
	EJMP exammem_not_found
exammem_skip_2:
	EJMP exammem_skip
exammem:
	SAVE 7

	// First, get which register we're using
	ELEF 0, mem_tbl

	LDA 1, -11, 3
	MOV 1, 1, SNR
	JMP exammem_syntax_error_2

	PSH 0, 1
	EJSR gettbl
	POP 0, 0
	POP 0, 0

	MOV 1, 1, SZR
	JMP exammem_not_found_2
	STA 2, 1, 3

	// Next, get which memory we're using
	ELEF 0, mem_memtbl
	LDA 1, -11, 3
	PSH 0, 1
	EJSR gettbl
	POP 0, 0
	POP 0, 0

	MOV 1, 1, SZR
	JMP exammem_not_found_2
	STA 2, 4, 3

	// Next, get which inc value to use
	ELEF 0, mem_inctbl
	LDA 1, -11, 3
	PSH 0, 1
	EJSR gettbl
	POP 0, 0
	POP 0, 0

	MOV 1, 1, SZR
	JMP exammem_not_found_2
	STA 2, 5, 3

	// Next, convert the starting address
	LDA 2, -10, 3
	MOV 2, 2, SNR
	JMP exammem_syntax_error_2

	PSH 2, 2
	EJSR string_to_oct
	POP 0, 0

	MOV 1, 1, SZR
	JMP exammem_syntax_error_2

	STA 2, 2, 3

	// Convert the number of values to read
	LDA 2, -9, 3
	MOV 2, 2, SNR
	JMP exammem_skip_2

	PSH 2, 2
	EJSR string_to_oct
	POP 0, 0

	MOV 1, 1, SZR
	JMP exammem_syntax_error_2

	STA 2, 6, 3

	// Read the register as was
	LDA 0, 1, 3
	ELEF 1, FN_EXAM
	IOR 1, 0

	ELEF 1, CMD_REG_FN | CMD_PIO | CMD_WR
	DOA 1, FPU
	DOB 0, FPU

	ELEF 1, CMD_REG_LT | CMD_PIO
	DOA 1, FPU
	DIB 0, FPU

	STA 0, 3, 3

	// Set the new value, in order to start writing to memory
	LDA 0, 1, 3
	ELEF 1, FN_DEP
	IOR 1, 0

	ELEF 1, CMD_REG_SR | CMD_PIO | CMD_WR
	DOA 1, FPU
	DOB 0, FPU

	LDA 0, 2, 3
	ELEF 1, CMD_REG_FN | CMD_PIO | CMD_WR
	DOA 1, FPU
	DOB 0, FPU

	// Set current count = 0
	XOR 0, 0
	STA 0, 7, 3

exammem_read_64:	
	// Read and convert each value from octal
	LDA 0, 4, 3
	ELEF 1, FN_EXAM
	IOR 1, 0
	ELEF 1, CMD_REG_FN | CMD_PIO | CMD_WR
	DOA 1, FPU
	DOB 0, FPU

	ELEF 1, exam_result
	PSH 0, 1
	EJSR oct_to_string
	POP 1, 0

	ELEF 2, exam_result
	EJSR print_unpacked

	ELEF 2, space
	EJSR print
	
	LDA 0, 4, 3
	ELEF 1, FN_EXAM | FN_WORD1
	IOR 1, 0
	ELEF 1, CMD_REG_FN | CMD_PIO | CMD_WR
	DOA 1, FPU
	DOB 0, FPU

	ELEF 1, exam_result
	PSH 0, 1
	EJSR oct_to_string
	POP 1, 0

	ELEF 2, exam_result
	EJSR print_unpacked

	ELEF 2, space
	EJSR print
	
	LDA 0, 4, 3
	ELEF 1, FN_EXAM | FN_WORD2
	IOR 1, 0
	ELEF 1, CMD_REG_FN | CMD_PIO | CMD_WR
	DOA 1, FPU
	DOB 0, FPU

	ELEF 1, exam_result
	PSH 0, 1
	EJSR oct_to_string
	POP 1, 0

	ELEF 2, exam_result
	EJSR print_unpacked

	ELEF 2, space
	EJSR print
	
	LDA 0, 4, 3
	LDA 1, 5, 3
	IOR 1, 0
	ELEF 1, FN_EXAM | FN_WORD3
	IOR 1, 0
	ELEF 1, CMD_REG_FN | CMD_PIO | CMD_WR
	DOA 1, FPU
	DOB 0, FPU

	ELEF 1, exam_result
	PSH 0, 1
	EJSR oct_to_string
	POP 1, 0

	ELEF 2, exam_result
	EJSR print_unpacked

	ELEF 2, nl
	EJSR print

	// Increment the wordcount
	LDA 0, 7, 3
	INC 0, 0
	STA 0, 7, 3

	// Check if we're done
	LDA 1, 6, 3
	SGT 1, 0
	JMP exammem_done

	JMP exammem_read_64

exammem_done:
	// Restore the old value
	LDA 0, 1, 3
	ELEF 1, FN_DEP
	IOR 1, 0

	ELEF 1, CMD_REG_FN | CMD_PIO | CMD_WR
	DOA 1, FPU
	DOB 0, FPU

	LDA 0, 3, 3
	ELEF 1, CMD_REG_FN | CMD_PIO | CMD_WR
	DOA 1, FPU
	DOB 0, FPU

	RTN

exammem_skip:
	RTN

exammem_not_found:	
	ELEF 2, mem_not_found
	EJSR print
	RTN

exammem_syntax_error:
	ELEF 2, syntax_error
	EJSR print
	RTN

	// dep - Deposit a value into the AP
	//
	// Parameters:
	// - Stack: pointer to register name string
	// - Stack: pointer to value string
	//
	// Stack variables:
	// - Offset 1: register to write to
	// - Offset 2: the value to write
dep:
	SAVE 2

	// First, get the actual function to run
	ELEF 0, dep_tbl
	LDA 1, -11, 3
	PSH 0, 1
	EJSR gettbl
	POP 0, 0
	POP 0, 0

	MOV 1, 1, SZR
	JMP dep_not_found
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

	STA 2, 2, 3

	// Next, get the maximum for the register in question
	ELEF 0, reg_max_tbl
	LDA 1, -11, 3
	PSH 0, 1
	EJSR gettbl
	POP 0, 0
	POP 0, 0

	// This shouldn't happen, but check it anyway as there might be a bug
	MOV 1, 1, SZR
	JMP dep_not_found

	// If the max is greater than or equal to the value we got, we're valid
	// 2 = 2 - 0
	// max = max - actual
	LDA 0, 2, 3
	SUBZ 0, 2, SNC
	JMP dep_out_of_range

	// Set the switches to the value we wish to write
	ELEF 1, CMD_REG_SR | CMD_PIO | CMD_WR
	DOA 1, FPU
	DOB 0, FPU

	// Write the value
	LDA 0, 1, 3
	ELEF 1, CMD_REG_FN | CMD_PIO | CMD_WR
	DOA 1, FPU
	DOB 0, FPU

dep_done:
	RTN

dep_not_found:
	ELEF 2, reg_not_found
	EJSR print

	RTN

dep_out_of_range:
	ELEF 2, out_of_range
	EJSR print

	RTN

	// exam - Examine a value from the AP
	//
	// Parameters:
	// - Stack: pointer to register name string
	//
	// Stack variables:
	// - Offset 0: register to write to
exam:
	SAVE 1

	// First, get the actual function to run
	ELEF 0, exam_tbl
	LDA 1, -11, 3
	PSH 0, 1
	EJSR gettbl
	POP 0, 0
	POP 0, 0

	MOV 1, 1, SZR
	JMP exam_not_found

	MOV 1, 1, SZR
	JMP exam_done

	// Write the value
	MOV 2, 0
	ELEF 1, CMD_REG_FN | CMD_PIO | CMD_WR
	DOA 1, FPU
	DOB 0, FPU

	ELEF 1, CMD_REG_LT | CMD_PIO
	DOA 1, FPU
	DIB 0, FPU

	ELEF 1, exam_result

	PSH 0, 1
	EJSR oct_to_string
	POP 1, 0

	ELEF 2, exam_result
	EJSR print_unpacked

	ELEF 2, nl
	EJSR print

exam_done:
	RTN

exam_not_found:
	ELEF 2, reg_not_found
	EJSR print

	RTN

	var exam_result resv 7
	
	// ============================================================
	// Utility Functions
	// ============================================================

	// gettbl - Get a value out of a table, according to a string key
	//
	// Parameters:
	// - Stack: the table
	// - Stack: the string
	//
	// Returns:
	// - AC1: is present (0 = success, 1 = fail)
	// - AC2: the value
	//
	// Stack variables:
	// - Offset 0: current entry to test
gettbl:
	SAVE 1

	// Set current table pointer
	LDA 0, -6, 3
	STA 0, 1, 3

gettbl_loop:
	// Set AC0 = current string to test
	LDA 2, 1, 3
	LDA 0, 0, 2

	MOV 0, 0, SNR
	JMP gettbl_notfound

	LDA 1, -5, 3
	PSH 0, 1
	EJSR strcmp
	POP 1, 0

	MOV 2, 2, SNR
	JMP gettbl_found

	// current += 2
	LDA 0, 1, 3
	INC 0,0
	INC 0,0
	STA 0, 1, 3
	JMP gettbl_loop

gettbl_found:
	LDA 2, 1, 3
	LDA 0, 1, 2

	STA 0, -2, 3
	XOR 0, 0
	STA 0, -3, 3

	RTN

gettbl_notfound:
	ELEF 0, 1
	STA 0, -3, 3

	RTN

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
	LDA 1, -7, 3

	PSH 0, 1
	EJSR gettbl

	// Pop twice, because we care about AC1 and AC2
	POP 0, 0
	POP 0, 0

	MOV 1, 1, SZR
	JMP cmdtbl_notfound

	STA 2, 1, 3

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
	LDA 2, 1, 3		// AC2 = routine pointer

	JSR 0, 2		// indirect call via AC2

	LDA 1, -5, 3
	NEG 1, 1
	MSP 1

	RTN

cmdtbl_notfound:
	ELEF 2, notfound_string
	EJSR print

	RTN

	var notfound_string = "Command not found\r\n" packed

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

stack_exhausted:	
	HALT

stack_top:	
