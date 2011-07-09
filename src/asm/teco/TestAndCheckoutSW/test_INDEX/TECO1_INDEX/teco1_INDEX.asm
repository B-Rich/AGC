; TECO1_INDEX (file:teco1_INDEX.asm)
;
; Version:	1.0
; Author:	John Pultorak
; Date:		9/14/2001
;
; PURPOSE:
; Test and checkout program for the Block 1 Apollo Guidance Computer.
; Tests basic instructions: INDEX.
;
; OPERATION:
; Enters an infinite loop at the end of the test. The A register contains 
; the code for the test that failed, or the PASS code if all tests 
; succeeded. See test codes below.
;
; ERRATA:
; - Written for the AGC4R assembler. The assembler directives and syntax
; differ somewhat from the original AGC assembler.
; - The tests attempt to check all threads, but are not exhaustive.
;
; SOURCES:
; Information on the Block 1 architecture: instruction set, instruction
; sequences, registers, register transfers, control pulses, memory and 
; memory addressing, I/O assignments, interrupts, and involuntary counters
; was obtained from:
;
;	A. Hopkins, R. Alonso, and H. Blair-Smith, "Logical Description 
;		for the Apollo Guidance Computer (AGC4)", R-393, 
;		MIT Instrumentation Laboratory, Cambridge, MA, Mar. 1963.
;
; Supplementary information was obtained from:
;
;	R. Alonso, J. H. Laning, Jr. and H. Blair-Smith, "Preliminary 
;		MOD 3C Programmer's Manual", E-1077, MIT Instrumentation 
;		Laboratory, Cambridge, MA, Nov. 1961.
;
;	B. I. Savage and A. Drake, "AGC4 Basic Training Manual, Volume I", 
;		E-2052, MIT Instrumentation Laboratory, Cambridge, 
;		MA, Jan. 1967.
;
;	E. C. Hall, "MIT's Role in Project Apollo, Volume III, Computer 
;		Subsystem", R-700, MIT Charles Stark Draper Laboratory, 
;		Cambridge, MA, Aug. 1972.
;
;	A. Hopkins, "Guidance Computer Design, Part VI", source unknown.
;
;	A. I. Green and J. J. Rocchio, "Keyboard and Display System Program 
;		for AGC (Program Sunrise)", E-1574, MIT Instrumentation 
;		Laboratory, Cambridge, MA, Aug. 1964.
;
;	E, C. Hall, "Journey to the Moon: The History of the Apollo 
;		Guidance Computer", AIAA, Reston VA, 1996.
;

START		EQU	%00

INDEXtst	EQU	%03	; INDEX check failed

PASS		EQU	%12345	; PASSED all checks
	; ----------------------------------------------

OVFCNTR		EQU	%00034	; overflow counter

	; ----------------------------------------------
	; ERASEABLE MEMORY -- DATA SEGMENT

		ORG	%100	; start of data area
curtest		DS	START	; current test
savQ		DS	%0

	; INDEX test
INDXval		DS	0

	; ----------------------------------------------
	; ENTRY POINTS

	; program (re)start
		ORG	GOPROG
		TC	goMAIN

	; ----------------------------------------------
	; FIXED MEMORY -- SHARED DATA SEGMENT

	; ----------------------------------------------
	; MAIN PROGRAM

goMAIN		EQU	*
		INHINT		; disable interrupts

		TCR	begin

	; Test basic instructions.
		TCR	chkINDEX

	; Passed all tests.
		TCR	finish

fail		EQU	*
		XCH	curtest	; load last passed test into A
		TS	curtest

end		EQU	*
		TC	end	; finished, TC trap

	; ----------------------------------------------
	; INITIALIZE FOR START OF TESTING

STRTcode	DS	START

begin		EQU	*
		XCH	STRTcode
		TS	curtest	; set current test code to START
		RETURN
		
	; ----------------------------------------------
	; TEST INDEX INSTRUCTION SUBROUTINE
	; L:	INDEX	K	(where K != 0025)
	; Verifies the following;
	; - Use the sum of C(L+1) + C(K) as the next instruction
	; -- just as if that sum had been taken from L+1.

INDXcode	DS	INDEXtst	; code for this test
INDXst		DS	5	; somewhere in fixed memory

INDXbas		DS	0	; base address for indexing
		DS	1
		DS	2
		DS	3
		DS	4
		DS	5

chkINDEX	EQU	*
		XCH	Q
		TS	savQ	; save return address

		CAF	INDXcode
		TS	curtest	; set current test code to this test

	; Decrementing loop
	;	- always executes at least once (tests at end of loop)
	;	- loops 'INDXst+1' times; decrements INDXval

		XCH	INDXst	; initialize loop counter

INDXlop		EQU	*
		TS	INDXval

	; perform indexed CAF of values in INDXbas array;
	; index values range from 5 to 0
		INDEX	INDXval
		CAF	INDXbas

	; verify value retrieved using INDEX matches expected value
		COM		; get -A
		AD	INDXval	; put (-A) + expected value in A
		CCS	A	; compare
		TC	fail	; >0 (A < expected value)
		TC	fail	; +0
		TC	fail	; <0 (A > expected value)

		CCS	INDXval	; done?
		TC	INDXlop	; not yet

		XCH	savQ
		TS	Q	; restore return address
		RETURN
	; ----------------------------------------------
	; PASSED ALL TESTS!

PASScode	DS	PASS

finish		EQU	*
		CAF	PASScode
		TS	curtest	; set current test code to PASS
		RETURN

	; ----------------------------------------------
