; This file is for the FamiStudio Sound Engine and was generated by FamiStudio
; Project uses FamiTracker tempo, you must set FAMISTUDIO_USE_FAMITRACKER_TEMPO = 1.
; Volume track is used, you must set FAMISTUDIO_USE_VOLUME_TRACK = 1.

.if FAMISTUDIO_CFG_C_BINDINGS
.export _music_data_starman=music_data_starman
.endif

music_data_starman:
	.byte 1
	.word @instruments
	.word @samples-4
; 00 : Starman
	.word @song0ch0
	.word @song0ch1
	.word @song0ch2
	.word @song0ch3
	.word @song0ch4
	.word 266,221

.export music_data_starman
.global FAMISTUDIO_DPCM_PTR

@instruments:
	.word @env4,@env3,@env5,@env0 ; 00 : Noise short
	.word @env1,@env3,@env5,@env0 ; 01 : Noise long
	.word @env9,@env2,@env7,@env0 ; 02 : SqWoobble
	.word @env6,@env3,@env8,@env0 ; 03 : Long instrumental

@env0:
	.byte $00,$c0,$7f,$00,$02
@env1:
	.byte $00,$cc,$04,$c0,$00,$03
@env2:
	.byte $cc,$cc,$c0,$c0,$00,$00
@env3:
	.byte $c0,$7f,$00,$01
@env4:
	.byte $00,$cc,$c0,$00,$02
@env5:
	.byte $7f,$00,$00
@env6:
	.byte $00,$c5,$c3,$c4,$c5,$c5,$c6,$10,$c5,$05,$c4,$05,$c3,$02,$c2,$c2,$c1,$c0,$00,$11
@env7:
	.byte $c1,$7f,$00,$00
@env8:
	.byte $c0,$c2,$00,$01
@env9:
	.byte $0c,$ca,$c6,$c7,$c7,$c5,$c7,$c2,$04,$c1,$00,$09,$c1,$c0,$0f,$c0,$00,$0f

@samples:

@song0ch0:
	.byte $46, $02
@song0ch0loop:
	.byte $7a, $84
@song0ref6:
	.byte $21, $89, $21, $89, $21, $89, $1e, $83, $21, $89, $21, $89, $1e, $83, $21, $83, $1e, $83, $21, $89, $21, $89, $21, $89
	.byte $21, $89, $1c, $83, $21, $89, $21, $89, $1c, $83, $21, $83, $1c, $83, $21, $89
	.byte $41, $28
	.word @song0ref6
	.byte $42
	.word @song0ch0loop
@song0ch1:
@song0ch1loop:
	.byte $7d, $84
@song0ref55:
	.byte $1a, $89, $1a, $89, $1a, $8f, $1c, $83, $00, $83, $1c, $8f, $1c, $89, $1c, $89, $19, $89, $19, $89, $19, $8f, $19, $83
	.byte $00, $83, $19, $8f, $19, $89, $19, $89
	.byte $41, $20
	.word @song0ref55
	.byte $42
	.word @song0ch1loop
@song0ch2:
@song0ch2loop:
	.byte $86
@song0ref95:
	.byte $0e, $89, $26, $89, $0e, $89, $26, $89, $10, $89, $28, $89, $10, $89, $28, $89, $15, $89, $21, $89, $15, $89, $21, $89
	.byte $15, $89, $21, $89, $15, $89, $21, $89
	.byte $41, $20
	.word @song0ref95
	.byte $42
	.word @song0ch2loop
@song0ch3:
@song0ch3loop:
	.byte $7f, $80
@song0ref136:
	.byte $15, $89, $79, $1e, $85, $1e, $81, $76, $82, $1e, $89, $78, $80, $1e, $85, $1e, $81, $7f, $15, $89, $79, $1e, $85, $1e
	.byte $81, $76, $82, $1e, $89, $78, $80, $1e, $85, $1e, $81, $7f
	.byte $41, $18
	.word @song0ref136
	.byte $7f
	.byte $41, $18
	.word @song0ref136
	.byte $7f
	.byte $41, $18
	.word @song0ref136
	.byte $42
	.word @song0ch3loop
@song0ch4:
@song0ch4loop:
	.byte $df, $df, $df, $df, $42
	.word @song0ch4loop
