;*** HD + MUSIC
;*** MiniStartup by Photon ***
	INCDIR	"NAS:AMIGA/CODE/KONEY/"
	SECTION	"Code",CODE
	INCLUDE	"Blitter-Register-List.S"
	INCLUDE	"PhotonsMiniWrapper1.04!.S"
	INCLUDE	"PT12_OPTIONS.i"
	INCLUDE	"P6112-Play-stripped.i"
;********** Constants **********
w=640		;screen width, height, depth
h=512
bpls=3		;handy values:
bpl=w/16*2	;byte-width of 1 bitplane line (80)
bwid=bpls*bpl	;byte-width of 1 pixel line (all bpls)
;*************
MODSTART_POS=0		; start music at position # !! MUST BE EVEN FOR 16BIT
;*************

;********** Demo **********	; Demo-specific non-startup code below.
Demo:	;a4=VBR, a6=Custom Registers Base addr
	;*--- init ---*
	MOVE.L	#VBint,$6C(A4)
	MOVE.W	#%1110000000100000,INTENA
	;** SOMETHING INSIDE HERE IS NEEDED TO MAKE MOD PLAY! **
	;move.w	#%1110000000000000,INTENA	; Master and lev6	; NO COPPER-IRQ!
	MOVE.W	#%1000011111100000,DMACON

	;*--- clear screens ---*
	lea	SCREEN1,a1
	bsr.w	ClearScreen
	lea	SCREEN2,a1
	bsr.w	ClearScreen
	bsr	WaitBlitter
	;*--- start copper ---*
	lea	SCREEN1,a0
	moveq	#bpl,d0
	lea	BplPtrs+2,a1
	moveq	#bpls-1,d1
	bsr.w	PokePtrs

	; #### Point LOGO sprites
	LEA	SpritePointers,A1	; Puntatori in copperlist
	MOVE.L	#SPRT_K,D0	; indirizzo dello sprite in d0
	MOVE.W	D0,6(A1)
	SWAP	D0
	MOVE.W	D0,2(A1)

	ADDQ.W	#8,A1
	MOVE.L	#SPRT_O,D0	; indirizzo dello sprite in d0
	MOVE.W	D0,6(A1)
	SWAP	D0
	MOVE.W	D0,2(A1)

	ADDQ.W	#8,A1
	MOVE.L	#SPRT_N,D0	; indirizzo dello sprite in d0
	MOVE.W	D0,6(A1)
	SWAP	D0
	MOVE.W	D0,2(A1)

	ADDQ.W	#8,A1
	MOVE.L	#SPRT_Y,D0	; indirizzo dello sprite in d0
	MOVE.W	D0,6(A1)
	SWAP	D0
	MOVE.W	D0,2(A1)

	ADDQ.W	#8,A1
	MOVE.L	#SPRT_E,D0	; indirizzo dello sprite in d0
	MOVE.W	D0,6(A1)
	SWAP	D0
	MOVE.W	D0,2(A1)
	; #### Point LOGO sprites

	;---  Call P61_Init  ---
	MOVEM.L	D0-A6,-(SP)
	LEA	MODULE,A0
	SUB.L	A1,A1
	SUB.L	A2,A2
	MOVE.W	#MODSTART_POS,P61_InitPos	; TRACK START OFFSET
	JSR	P61_Init
	MOVEM.L (SP)+,D0-A6
	;---  Call P61_Init  ---

	MOVE.L	#Copper,$80(A6)

	MOVE.W	#$8000,VPOSW	; RESETS LOF (from EAB)

;********************  main loop  ********************
MainLoop:
	move.w	#$12c,d0		;No buffering, so wait until raster
	bsr.w	WaitRaster	;is below the Display Window.
	;*--- swap buffers ---*
	movem.l	DrawBuffer(PC),a2-a3
	exg	a2,a3
	movem.l	a2-a3,DrawBuffer	;draw into a2, show a3
	;*--- show one... ---*
	move.l	a3,a0
	move.l	#bpl*h,d0
	lea	BplPtrs+2,a1
	moveq	#bpls-1,d1
	bsr.w	PokePtrs
	;*--- ...draw into the other(a2) ---*
	move.l	a2,a1
	;bsr	ClearScreen
	bsr	WaitBlitter

	; ** CODE FOR HI-RES ** FROM Lezione11l6.S ********************
	MOVE.L	KONEY,D3		; Indirizzo bitplane
	MOVE.W	VPOSR,D7
	BTST	#15,D7
	BNE.S	.skipLine		; Se si, tocca alle linee dispari
	ADD.L	#bpl,D3		; Oppure aggiungi la lunghezza di una linea
	.skipLine:

	; ** CODE FOR HI-RES **************************************
	MOVE.L	D3,DrawBuffer
	;CLR.W	$100		; DEBUG | w 0 100 2
	;CLR.W	$100		; THIS IS NEEDED FOR HI-RES... LOL!!
	; do stuff here :)

	;move.w	$000,$DFF18E	; metti VHPOSR in COLOR00 (lampeggio!!)
	;bsr.w	__DUMMY		; Stampa le linee di testo sullo schermo
	;move.w	$222,$DFF18E	; metti VHPOSR in COLOR00 (lampeggio!!)
	;bsr.w	__DUMMY		; Stampa le linee di testo sullo schermo

	;*--- main loop end ---*
	BTST	#6,$BFE001
	BNE.S	.DontShowRasterTime
	MOVE.W	#$0F0,$180(A6)	; show rastertime left down to $12c
	.DontShowRasterTime:
	BTST	#2,$DFF016	; POTINP - RMB pressed?
	BNE.W	MainLoop		; then loop
	;*--- exit ---*
	;    ---  Call P61_End  ---
	MOVEM.L D0-A6,-(SP)
	JSR P61_End
	MOVEM.L (SP)+,D0-A6
	RTS
;********** Demo Routines **********

PokePtrs:				; Generic, poke ptrs into copper list
	.bpll:	
	move.l	a0,d2
	swap	d2
	move.w	d2,(a1)		; high word of address
	move.w	a0,4(a1)		; low word of address
	addq.w	#8,a1		; skip two copper instructions
	add.l	d0,a0		; next ptr
	dbf	d1,.bpll
	rts

ClearScreen:			; a1=screen destination address to clear
	bsr	WaitBlitter
	clr.w	$66(a6)		; destination modulo
	move.l	#$01000000,$40(a6)	; set operation type in BLTCON0/1
	move.l	a1,$54(a6)	; destination address
	move.l	#h*bpls*64+bpl/2,$58(a6)	;blitter operation size
	rts

VBint:				; Blank template VERTB interrupt
	movem.l	d0/a6,-(sp)	; Save used registers
	lea	$dff000,a6
	btst	#5,$1f(a6)	; check if it's our vertb int.
	beq.s	.notvb
	;*--- do stuff here ---*
	moveq	#$20,d0		; poll irq bit
	move.w	d0,$9c(a6)
	move.w	d0,$9c(a6)
	.notvb:	
	movem.l	(sp)+,d0/a6	; restore
	rte

	RTS

__DUMMY:
	LEA	DUMMY,A3		; Indirizzo del bitplane destinazione in a3
	LEA	DUMMY,A2
	CLR	D6
	MOVE.B	#40,D6		; RESET D6
	;ADD.W	#40*115,A3	; POSITIONING

	.loop:			; LOOP KE CICLA LA BITMAP
	;ADD.W	#15,A3
	MOVE.L	(A2),(A3)	
	;ADD.W	#25,A3
	DBRA	D6,.loop

	RTS

;********** Fastmem Data **********
IsLineEven:	DC.W 0
KONEY:		DC.L BG1		; INIT BG
DrawBuffer:	DC.L SCREEN1	; pointers to buffers to be swapped
ViewBuffer:	DC.L SCREEN2
SPR_0_POS:	DC.B $7C		; K
SPR_1_POS:	DC.B $84		; O
SPR_2_POS:	DC.B $8C		; N
SPR_3_POS:	DC.B $94		; E
SPR_4_POS:	DC.B $9C		; Y
;**************************************************************
	SECTION "ChipData",DATA_C	;declared data that must be in chipmem
;**************************************************************

BG1:	INCBIN	"klogo_hd.raw"

MODULE:	INCBIN	"take_em_in.P61"	; code $9100

SPRITES:	INCLUDE	"sprite_KONEY.s"

DUMMY:	DC.L $F0F0F0	

Copper:
	DC.W $1FC,0	;Slow fetch mode, remove if AGA demo.
	DC.W $8E,$2C81	;238h display window top, left
	DC.W $90,$2CC1	;and bottom, right.
	DC.W $92,$3C	;Standard bitplane dma fetch start
	DC.W $94,$D4	;and stop for standard screen.

	DC.W $106,$0C00	;(AGA compat. if any Dual Playf. mode)
	DC.W $108,bpl	;bwid-bpl	;modulos
	DC.W $10A,bpl	;bwid-bpl	;RISULTATO = 80 ?

	DC.W $102,0	;SCROLL REGISTER (AND PLAYFIELD PRI)
	DC.W $104,0	;BplCon2
	;DC.W $100,bpls*$1000+$200	;enable bitplanes
	DC.W $100,%1011001000000100	; BPLCON0 1011 0010 0000 0100

	Palette:	
	DC.W $0180,$0AAA,$0182,$0FFF,$0184,$0888,$0186,$0666
	DC.W $0188,$0444,$018A,$0333,$018C,$0222,$018E,$0515

	BplPtrs:	
	DC.W $E0,0
	DC.W $E2,0
	DC.W $E4,0
	DC.W $E6,0
	DC.W $E8,0
	DC.W $EA,0
	DC.W $EC,0
	DC.W $EE,0
	DC.W $F0,0
	DC.W $F2,0
	DC.W $F4,0
	DC.W $F6,0

	SpritePointers:
	DC.W $120,0,$122,0	; 0
	DC.W $124,0,$126,0	; 1
	DC.W $128,0,$12A,0	; 2
	DC.W $12C,0,$12E,0	; 3
	DC.W $130,0,$132,0	; 4
	DC.W $134,0,$136,0	; 5
	DC.W $138,0,$13A,0	; 6
	DC.W $13C,0,$13E,0	; 7

	DC.W $1A6
	LOGOCOL1:
	DC.W $FFF	; COLOR0-1
	DC.W $1AE
	LOGOCOL2:
	DC.W $FFF	; COLOR2-3
	DC.W $1B6
	LOGOCOL3:
	DC.W $FFF	; COLOR4-5

	DC.W $FFFF,$FFFE	;magic value to end copperlist
_Copper:

;***************************************************************
	SECTION "ChipBuffers",BSS_C	;BSS doesn't count toward exe size
;***************************************************************

SCREEN1:		DS.B h*bwid	; Define storage for buffer 1
SCREEN2:		DS.B h*bwid	; two buffers

END