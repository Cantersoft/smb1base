
.segment "RENDER"

clabel InitScreen
clabel SetupIntermediate
clabel WriteTopStatusLine
clabel WriteBottomStatusLine
clabel DisplayTimeUp
clabel ResetSpritesAndScreenTimer
clabel DisplayIntermediate
clabel AreaParserTaskControl
clabel GetAreaPalette
clabel GetBackgroundColor
clabel GetAlternatePalette1
clabel DrawTitleScreen
clabel ClearBuffersDrawIcon
clabel WriteTopScore

;-------------------------------------------------------------------------------------

.proc ScreenRoutines

  lda ScreenRoutineTask        ;run one of the following subroutines
  jsr JumpEngine

  .word InitScreen
  .word SetupIntermediate
  .word WriteTopStatusLine
  .word WriteBottomStatusLine
  .word DisplayTimeUp
  .word ResetSpritesAndScreenTimer
  .word DisplayIntermediate
  .word ResetSpritesAndScreenTimer
  .word AreaParserTaskControl
  .word GetAreaPalette
  .word GetBackgroundColor
  .word GetAlternatePalette1
  .word DrawTitleScreen
  .word ClearBuffersDrawIcon
  .word WriteTopScore
.endproc


;-------------------------------------------------------------------------------------
InitScreen:
  lda Mirror_PPUMASK
  and #%00011000
  beq :+
    rts
  :
  farcall MoveAllSpritesOffscreen ;initialize all sprites including sprite #0
  jsr InitializeNameTables    ;and erase both name and attribute tables
  lda OperMode
  beq NextSubtask             ;if mode still 0, do not load
  ldx #$03                    ;into buffer pointer
  jmp SetVRAMAddr_A
  ; implicit rts

GetAreaPalette:
  ldy AreaType             ;select appropriate palette to load
  ldx AreaPalette,y        ;based on area type
SetVRAMAddr_A:
  stx VRAM_Buffer_AddrCtrl ;store offset into buffer control
NextSubtask:
  jmp IncSubtask           ;move onto next task
AreaPalette:
  .byte $01, $02, $03, $04


;-------------------------------------------------------------------------------------
InitializeNameTables:

  lda PPUSTATUS            ;reset flip-flop
  lda Mirror_PPUCTRL       ;load mirror of ppu reg $2000
  ora #%00001000            ;set sprites for first 4k and background for second 4k
  and #%11101000            ;make sure to keep sprites and bg switched
  sta PPUCTRL         ;write contents of A to PPU register 1
  sta Mirror_PPUCTRL       ;and its mirror
  lda #$24                  ;set vram address to start of name table 1
  jsr WriteNTAddr
  lda #$20                  ;and then set it to name table 0
WriteNTAddr:
  sta PPUADDR
  lda #$00
  sta PPUADDR
  ldx #$04                  ;clear name table with blank tile #24
  ldy #$c0
  lda #$24
InitNTLoop:
  sta PPUDATA              ;count out exactly 768 tiles
  dey
  bne InitNTLoop
  dex
  bne InitNTLoop
  ldy #64                   ;now to clear the attribute table (with zero this time)
  txa
  sta VRAM_Buffer1_Offset   ;init vram buffer 1 offset
  sta VRAM_Buffer1          ;init vram buffer 1
InitATLoop:
  sta PPUDATA
  dey
  bne InitATLoop
  sta HorizontalScroll      ;reset scroll variables
  sta VerticalScroll
  jmp InitScroll  ;initialize scroll registers to zero

;-------------------------------------------------------------------------------------

WriteTopStatusLine:
  lda #$00          ;select main status bar
  jsr WriteGameText ;output it
  jmp IncSubtask    ;onto the next task
  ;implicit rts

;-------------------------------------------------------------------------------------

SetupIntermediate:
  lda BackgroundColorCtrl  ;save current background color control
  pha                      ;and player status to stack
    lda PlayerStatus
    pha
      lda #$00                 ;set background color to black
      sta PlayerStatus         ;and player status to not fiery
      lda #$02                 ;this is the ONLY time background color control
      sta BackgroundColorCtrl  ;is set to less than 4
      jsr GetPlayerColors
    pla                      ;we only execute this routine for
    sta PlayerStatus         ;the intermediate lives display
  pla                      ;and once we're done, we return bg
  sta BackgroundColorCtrl  ;color ctrl and player status from stack
  jmp IncSubtask           ;then move onto the next task

;-------------------------------------------------------------------------------------
WriteBottomStatusLine:

  jsr GetSBNybbles        ;write player's score and coin tally to screen
  ldx VRAM_Buffer1_Offset
  lda #$20                ;write address for world-area number on screen
  sta VRAM_Buffer1,x
  lda #$73
  sta VRAM_Buffer1+1,x
  lda #$03                ;write length for it
  sta VRAM_Buffer1+2,x
  ldy WorldNumber         ;first the world number
  iny
  tya
  sta VRAM_Buffer1+3,x
  lda #$28                ;next the dash
  sta VRAM_Buffer1+4,x
  ldy LevelNumber         ;next the level number
  iny                     ;increment for proper number display
  tya
  sta VRAM_Buffer1+5,x    
  lda #$00                ;put null terminator on
  sta VRAM_Buffer1+6,x
  txa                     ;move the buffer offset up by 6 bytes
  clc
  adc #$06
  sta VRAM_Buffer1_Offset
  jmp IncSubtask

;-------------------------------------------------------------------------------------

ResetSpritesAndScreenTimer:
  lda ScreenTimer             ;check if screen timer has expired
  bne NoReset                 ;if not, branch to leave
  farcall MoveAllSpritesOffscreen ;otherwise reset sprites now

ResetScreenTimer:
  lda #$07                    ;reset timer again
  sta ScreenTimer
  inc ScreenRoutineTask       ;move onto next task
NoReset:
  rts

;-------------------------------------------------------------------------------------

.proc DrawPlayer_Intermediate
;   ldx #$05                       ;store data into zero page memory
; PIntLoop:
;     lda IntermediatePlayerData,x   ;load data to display player as he always
;     sta R2 ,x                      ;appears on world/lives display
;     dex
;     bpl PIntLoop                   ;do this until all data is loaded
;   ldx #$b8                       ;load offset for small standing
;   ldy #$04                       ;load sprite data offset
;   jsr              ;draw player accordingly
;   lda Sprite_Attributes+36       ;get empty sprite attributes
;   ora #%01000000                 ;set horizontal flip bit for bottom-right sprite
;   sta Sprite_Attributes+32       ;store and leave
  lda #METASPRITE_SMALL_MARIO_STANDING
  sta ObjectMetasprite
  lda #CHR_SMALLMARIO
  sta PlayerChrBank
  inc ReloadCHRBank
  lda IntermediatePlayerData+0
  sta SprObject_Y_Position
  lda IntermediatePlayerData+1
  sta PlayerFacingDir
  lda IntermediatePlayerData+2
  sta SprObject_SprAttrib
  lda IntermediatePlayerData+3
  sta SprObject_X_Position
  lda ScreenLeft_PageLoc
  sta SprObject_PageLoc
  lda #1
  sta SprObject_Y_HighPos
  rts
IntermediatePlayerData:
  .byte $58, $01, $00, $60 ; , $ff, $04

.endproc


.proc DisplayIntermediate
  lda OperMode                 ;check primary mode of operation
  beq NoInter                  ;if in title screen mode, skip this
  cmp #MODE_GAMEOVER           ;are we in game over mode?
  beq GameOverInter            ;if so, proceed to display game over screen
  lda AltEntranceControl       ;otherwise check for mode of alternate entry
  bne NoInter                  ;and branch if found
  ldy AreaType                 ;check if we are on castle level
  cpy #$03                     ;and if so, branch (possibly residual)
  beq PlayerInter
  lda DisableIntermediate      ;if this flag is set, skip intermediate lives display
  bne NoInter                  ;and jump to specific task, otherwise
PlayerInter:
  jsr DrawPlayer_Intermediate  ;put player in appropriate place for
  lda #0
  ldy #0
  ldx ObjectMetasprite
  farcall DrawMetasprite
  lda #$01                     ;lives display, then output lives display to buffer
OutputInter:
  jsr WriteGameText
  jsr ResetScreenTimer
  lda #$00
  sta DisableScreenFlag        ;reenable screen output
  rts
GameOverInter:
  lda #$12                     ;set screen timer
  sta ScreenTimer
  lda #$03                     ;output game over screen to buffer
  jsr WriteGameText
  jmp IncModeTask_B
NoInter:
  lda #$08                     ;set for specific task and leave
  sta ScreenRoutineTask
  rts
.endproc

;-------------------------------------------------------------------------------------

DisplayTimeUp:
  lda GameTimerExpiredFlag  ;if game timer not expired, increment task
  beq NoTimeUp              ;control 2 tasks forward, otherwise, stay here
  lda #$00
  sta GameTimerExpiredFlag  ;reset timer expiration flag
  lda #$02                  ;output time-up screen to buffer
  jmp DisplayIntermediate::OutputInter
NoTimeUp:
  inc ScreenRoutineTask     ;increment control task 2 tasks forward
  jmp IncSubtask

;-------------------------------------------------------------------------------------

.proc AreaParserTaskControl
  inc DisableScreenFlag     ;turn off screen
  farcall AreaParserTaskLoop
  dec ColumnSets            ;do we need to render more column sets?
  bpl OutputCol
    inc ScreenRoutineTask     ;if not, move on to the next task
OutputCol:
  lda #$06                  ;set vram buffer to output rendered column set
  sta VRAM_Buffer_AddrCtrl  ;on next NMI
  rts
.endproc

;-------------------------------------------------------------------------------------
;$00 - used as temp counter in GetPlayerColors
GetBackgroundColor:
  ldy BackgroundColorCtrl   ;check background color control
  beq NoBGColor             ;if not set, increment task and fetch palette
  lda BGColorCtrl_Addr-4,y  ;put appropriate palette into vram
  sta VRAM_Buffer_AddrCtrl  ;note that if set to 5-7, $0301 will not be read
NoBGColor:
  inc ScreenRoutineTask     ;increment to next subtask and plod on through    
  ;fallthrough

GetPlayerColors:
  ldx VRAM_Buffer1_Offset  ;get current buffer offset
  ldy #$00
  lda CurrentPlayer        ;check which player is on the screen
  beq ChkFiery
  ldy #$04                 ;load offset for luigi
ChkFiery:
  lda PlayerStatus         ;check player status
  cmp #$02
  bne StartClrGet          ;if fiery, load alternate offset for fiery player
  ldy #$08
StartClrGet:
  lda #$03                 ;do four colors
  sta R0 
ClrGetLoop:
  lda PlayerColors,y       ;fetch player colors and store them
  sta VRAM_Buffer1+3,x     ;in the buffer
  iny
  inx
  dec R0 
  bpl ClrGetLoop
SetBGColor2:  
  ldx VRAM_Buffer1_Offset  ;load original offset from before
  ldy BackgroundColorCtrl  ;if this value is four or greater, it will be set
  bne SetBGColor           ;therefore use it as offset to background color
  ldy AreaType             ;otherwise use area type bits from area offset as offset
SetBGColor:
  lda BackgroundColors,y   ;to background color instead
  sta VRAM_Buffer1+3,x
  lda #$3f                 ;set for sprite palette address
  sta VRAM_Buffer1,x       ;save to buffer
  lda #$10
  sta VRAM_Buffer1+1,x		;Set color of background elements? (bushes/hills)
  lda #$04                 ;write length byte to buffer
  sta VRAM_Buffer1+2,x
  lda #$00                 ;now the null terminator
  sta VRAM_Buffer1+7,x
  txa                      ;move the buffer pointer ahead 7 bytes
  clc                      ;in case we want to write anything else later
  adc #$07
SetVRAMOffset:
  sta VRAM_Buffer1_Offset  ;store as new vram buffer offset
  rts

BGColorCtrl_Addr:
      .byte $00, $09, $0a, $04

BackgroundColors:
      .byte $22, $21, $0f, $0f ;used by area type if bg color ctrl not set
      .byte $0f, $22, $0f, $0f ;used by background color control if set
		
		;x, world bg, intermediate color, x
		;x, x, x, x

PlayerColors:
      .byte $21, $16, $27, $18 ;mario's colors
      .byte $22, $30, $27, $19 ;luigi's colors
      .byte $22, $37, $27, $16 ;fiery (used by both)


;-------------------------------------------------------------------------------------

GetAlternatePalette1:
  lda AreaStyle            ;check for mushroom level style
  cmp #$01
  bne NoAltPal
  lda #$0b                 ;if found, load appropriate palette

SetVRAMAddr_B:
  sta VRAM_Buffer_AddrCtrl
NoAltPal:
  jmp IncSubtask           ;now onto the next task

;-------------------------------------------------------------------------------------

;$00 - vram buffer address table low
;$01 - vram buffer address table high

DrawTitleScreen:
  lda OperMode                 ;are we in title screen mode?
  bne IncModeTask_B            ;if not, exit
  lda #TitleScreenDataOffset   ;set buffer transfer control to $0300,
  jmp SetVRAMAddr_B            ;increment task and exit

;-------------------------------------------------------------------------------------

WriteTopScore:
  lda #$fa           ;run display routine to display top score on title
  jsr UpdateNumber
IncModeTask_B:
  inc OperMode_Task  ;move onto next mode
  rts
;-------------------------------------------------------------------------------------

ClearBuffersDrawIcon:
  lda OperMode               ;check game mode
  bne IncModeTask_B          ;if not title screen mode, leave
  ldx #$00                   ;otherwise, clear buffer space
TScrClear:
  sta VRAM_Buffer1-1,x
  sta VRAM_Buffer1-1+$100,x
  dex
  bne TScrClear
  jsr DrawMushroomIcon       ;draw player select icon
IncSubtask:
  inc ScreenRoutineTask      ;move onto next task
  rts

;-------------------------------------------------------------------------------------

cproc DrawMushroomIcon
  ldy #$07                ;read eight bytes to be read by transfer routine
IconDataRead:
  lda MushroomIconData,y  ;note that the default position is set for a
  sta VRAM_Buffer1-1,y    ;1-player game
  dey
  bpl IconDataRead
  lda NumberOfPlayers     ;check number of players
  beq ExitIcon            ;if set to 1-player game, we're done
  lda #$24                ;otherwise, load blank tile in 1-player position
  sta VRAM_Buffer1+3
  lda #$2a                ;then load shroom icon tile in 2-player position
  sta VRAM_Buffer1+5
ExitIcon:
  rts
MushroomIconData:
  .byte $07, $22, $49, $83, $2a, $24, $24, $00
.endproc


;-------------------------------------------------------------------------------------
cproc WriteGameText
  pha                      ;save text number to stack
    asl
    tay                      ;multiply by 2 and use as offset
    cpy #$04                 ;if set to do top status bar or world/lives display,
    bcc LdGameText           ;branch to use current offset as-is
    cpy #$08                 ;if set to do time-up or game over,
    bcc Chk2Players          ;branch to check players
    ldy #$08                 ;otherwise warp zone, therefore set offset
Chk2Players:
    lda NumberOfPlayers      ;check for number of players
    bne LdGameText           ;if there are two, use current offset to also print name
    iny                      ;otherwise increment offset by one to not print name
LdGameText:
    ldx GameTextOffsets,y    ;get offset to message we want to print
    ldy #$00
GameTextLoop:
    lda GameText,x           ;load message data
    cmp #$ff                 ;check for terminator
    beq EndGameText          ;branch to end text if found
    sta VRAM_Buffer1,y       ;otherwise write data to buffer
    inx                      ;and increment increment
    iny
    bne GameTextLoop         ;do this for 256 bytes if no terminator found
EndGameText:
    lda #$00                 ;put null terminator at end
    sta VRAM_Buffer1,y
  pla                      ;pull original text number from stack
  tax
  cmp #$04                 ;are we printing warp zone?
  bcs PrintWarpZoneNumbers
  dex                      ;are we printing the world/lives display?
  bne CheckPlayerName      ;if not, branch to check player's name
  lda NumberofLives        ;otherwise, check number of lives
  clc                      ;and increment by one for display
  adc #$01
  cmp #10                  ;more than 9 lives?
  bcc PutLives
  sbc #10                  ;if so, subtract 10 and put a crown tile
  ; jroweboy: I added +4 to each of these to account for the new position in VRAM Buffer
  ; because I moved the attribute writes to the start to prevent glitches with that.
  ldy #$9f                 ;next to the difference...strange things happen if
  sty VRAM_Buffer1+7+4       ;the number of lives exceeds 19
PutLives:
  sta VRAM_Buffer1+8+4
  ldy WorldNumber          ;write world and level numbers (incremented for display)
  iny                      ;to the buffer in the spaces surrounding the dash
  sty VRAM_Buffer1+19+4
  ldy LevelNumber
  iny
  sty VRAM_Buffer1+21+4      ;we're done here
  rts
CheckPlayerName:
  lda NumberOfPlayers    ;check number of players
  beq ExitChkName        ;if only 1 player, leave
  lda CurrentPlayer      ;load current player
  dex                    ;check to see if current message number is for time up
  bne ChkLuigi
  ldy OperMode           ;check for game over mode
  cpy #MODE_GAMEOVER
  beq ChkLuigi
  eor #%00000001         ;if not, must be time up, invert d0 to do other player
ChkLuigi:
  lsr
  bcc ExitChkName        ;if mario is current player, do not change the name
    ldy #$04
NameLoop:
      lda LuigiName,y        ;otherwise, replace "MARIO" with "LUIGI"
      sta VRAM_Buffer1+3+8,y
      dey
      bpl NameLoop           ;do this until each letter is replaced
ExitChkName:
  rts

PrintWarpZoneNumbers:
  sbc #$04               ;subtract 4 and then shift to the left
  asl                    ;twice to get proper warp zone number
  asl                    ;offset
  tax
  ldy #$00
WarpNumLoop:
    lda WarpZoneNumbers,x  ;print warp zone numbers into the
    sta VRAM_Buffer1+27,y  ;placeholders from earlier
    inx
    iny                    ;put a number in every fourth space
    iny
    iny
    iny
    cpy #$0c
    bcc WarpNumLoop
  lda #$2c               ;load new buffer pointer at end of message
  jmp SetVRAMOffset


endcproc

GameText:
TopStatusBarLine:
  .byte $23, $c0, $7f, $aa ; attribute table data, clears name table 0 to palette 2
  .byte $23, $c2, $01, $ea ; attribute table data, used for coin icon in status bar
  .byte $20, $43, $05, "MARIO"
  .byte $20, $52, $0b, "WORLD  TIME"
  .byte $20, $68, $05, "0  ", $2e, $29 ; score trailing digit and coin display
  .byte $ff ; end of data block

WorldLivesDisplay:
  .byte $23, $dc, $01, $ba ; attribute table data for crown if more than 9 lives
  .byte $21, $cd, $07, $24, $24 ; cross with spaces used on
  .byte $29, $24, $24, $24, $24 ; lives display
  .byte $21, $4b, $09, "WORLD  - "
  .byte $22, $0c, $47, $24 ; possibly used to clear time up
  .byte $ff

TwoPlayerTimeUp:
  .byte $21, $cd, $05, "MARIO"
OnePlayerTimeUp:
  .byte $22, $0c, $07, "TIME UP"
  .byte $ff

TwoPlayerGameOver:
  .byte $21, $cd, $05, "MARIO"
OnePlayerGameOver:
  .byte $22, $0b, $09, "GAME OVER"
  .byte $ff

WarpZoneWelcome:
  .byte $25, $84, $15, "WELCOME TO WARP ZONE!"
  .byte $26, $25, $01, $24         ; placeholder for left pipe
  .byte $26, $2d, $01, $24         ; placeholder for middle pipe
  .byte $26, $35, $01, $24         ; placeholder for right pipe
  .byte $27, $d9, $46, $aa         ; attribute data
  .byte $27, $e1, $45, $aa
  .byte $ff

LuigiName:
  .byte "LUIGI"

WarpZoneNumbers:
  .byte "432", $00         ; warp zone numbers, note spaces on middle
  .byte " 5 ", $00         ; zone, partly responsible for
  .byte "876", $00         ; the minus world

GameTextOffsets:
  .byte TopStatusBarLine-GameText, TopStatusBarLine-GameText
  .byte WorldLivesDisplay-GameText, WorldLivesDisplay-GameText
  .byte TwoPlayerTimeUp-GameText, OnePlayerTimeUp-GameText
  .byte TwoPlayerGameOver-GameText, OnePlayerGameOver-GameText
  .byte WarpZoneWelcome-GameText, WarpZoneWelcome-GameText


.proc SetupPipeTransitionOverlay
  rts
;   sta InPipeTransition
;   beq ClearTransition
;   cmp #1
;   beq IsDownPipe
;   cmp #2
;   beq IsRightPipe
;   ; fallthrough
; RisingEntrance:
;   lda #$90 + 32
;   sta PipeYPosition
;   jmp IsDownPipe
; ClearTransition:
;   ; reset the color for the palette back to the original
;   lda #$27
;   jmp SetPaletteColor
;   ; rts
; IsRightPipe:
;   lda Player_X_Position   ;get player's horizontal coordinate
;   clc
;   adc #$08 + 16                ;add eight pixels
;   and #$f0                ;mask out low nybble to give 16-pixel correspondence
;   sta PipeXPosition
;   lda Player_Y_Position
;   sta PipeYPosition
;   jmp ChangeColorToBackground
; IsDownPipe:
;   lda RelativePlayerPosition
;   sta PipeXPosition
;   ; fallthrough
; ChangeColorToBackground:
;   ldy BackgroundColorCtrl
;   bne :+
;     ldy AreaType
; :
;   lda BackgroundColors,y   ;to background color instead
;   ; jmp SetPaletteColor
;   ; fallthrough
; SetPaletteColor:
;   ldx VRAM_Buffer1_Offset
;   sta VRAM_Buffer1+3,x
;   lda #$3f
;   sta VRAM_Buffer1+0,x
;   lda #$1b
;   sta VRAM_Buffer1+1,x
;   lda #1
;   sta VRAM_Buffer1+2,x
;   lda #0
;   sta VRAM_Buffer1+4,x
;   lda VRAM_Buffer1_Offset
;   clc 
;   adc #4
;   sta VRAM_Buffer1_Offset
;   rts
.endproc


;-------------------------------------------------------------------------------------
GiveOneCoin:
  lda #$01               ;set digit modifier to add 1 coin
  sta DigitModifier+PlayerCoinLastIndex    ;to the current player's coin tally
  ldx CurrentPlayer      ;get current player on the screen
  ldy CoinTallyOffsets,x ;get offset for player's coin tally
  ldx #PlayerCoinLastIndex
  jsr DigitsMathRoutine  ;update the coin tally
  inc CoinTally          ;increment onscreen player's coin amount
  lda CoinTally
  cmp #100               ;does player have 100 coins yet?
  bne CoinPoints         ;if not, skip all of this
  lda #$00
  sta CoinTally          ;otherwise, reinitialize coin amount
  inc NumberofLives      ;give the player an extra life
  lda #Sfx_ExtraLife
  sta Square2SoundQueue  ;play 1-up sound

CoinPoints:
  lda #$02               ;set digit modifier to award
  sta DigitModifier+PlayerScoreLastIndex-1    ;200 points to the player

AddToScore:
  ldx CurrentPlayer      ;get current player
  ldy ScoreOffsets,x     ;get offset for player's score
  ldx #PlayerScoreLastIndex
  jsr DigitsMathRoutine  ;update the score internally with value in digit modifier

GetSBNybbles:
  ldy CurrentPlayer      ;get current player
  lda StatusBarNybbles,y ;get nybbles based on player, use to update score and coins

UpdateNumber:
  jsr PrintStatusBarNumbers ;print status bar numbers based on nybbles, whatever they be
  ldy VRAM_Buffer1_Offset   
  lda VRAM_Buffer1-6,y      ;check highest digit of score
  bne NoZSup                ;if zero, overwrite with space tile for zero suppression
  lda #$24
  sta VRAM_Buffer1-6,y
NoZSup:
  ldx ObjectOffset          ;get enemy object buffer offset
  rts
      
CoinTallyOffsets:
  .byte (Player1CoinDisplay + PlayerCoinLastIndex - DisplayDigits)
  .byte (Player2CoinDisplay + PlayerCoinLastIndex - DisplayDigits)

ScoreOffsets:
  .byte (Player1ScoreDisplay + PlayerScoreLastIndex - DisplayDigits)
  .byte (Player2ScoreDisplay + PlayerScoreLastIndex - DisplayDigits)

StatusBarNybbles:
  .byte $02, $13


;-------------------------------------------------------------------------------------
.proc UpdateTopScore
  ldx #5                 ;start with mario's score
  jsr TopScoreCheck
  ldx #5 + 6             ;now do luigi's score
TopScoreCheck:
  ldy #5                 ;start with the lowest digit
  sec           
GetScoreDiff:
  lda PlayerScoreDisplay,x ;subtract each player digit from each high score digit
  sbc TopScoreDisplay,y    ;from lowest to highest, if any top score digit exceeds
  dex                      ;any player digit, borrow will be set until a subsequent
  dey                      ;subtraction clears it (player digit is higher than top)
  bpl GetScoreDiff      
  bcc NoTopSc              ;check to see if borrow is still set, if so, no new high score
  inx                      ;increment X and Y once to the start of the score
  iny
CopyScore:
  lda PlayerScoreDisplay,x ;store player's score digits into high score memory area
  sta TopScoreDisplay,y
  inx
  iny
  cpy #$06                 ;do this until we have stored them all
  bcc CopyScore
NoTopSc:
  rts
.endproc

;-------------------------------------------------------------------------------------
;$00 - temp store for offset control bit
;$01 - temp vram buffer offset
;$02 - temp store for vertical high nybble in block buffer routine
;$03 - temp adder for high byte of name table address
;$04, $05 - name table address low/high
;$06, $07 - block buffer address low/high

.proc RemoveCoin_Axe
  ldy #VRAM_Buffer2 - VRAM_Buffer1 + 1 ;set low byte so offset points to $0341
  lda #$03                 ;load offset for default blank metatile
  ldx AreaType             ;check area type
  bne :+                   ;if not water type, use offset
    lda #$04                 ;otherwise load offset for blank metatile used in water
:
  jsr PutBlockMetatile     ;do a sub to write blank metatile to vram buffer
  lda #$06
  sta VRAM_Buffer_AddrCtrl ;set vram address controller to $0341 and leave
  rts
.endproc

DestroyBlockMetatile:
  lda #$00       ;force blank metatile if branched/jumped to this point
WriteBlockMetatile:
  ldy #$03                ;load offset for blank metatile
  cmp #$00                ;check contents of A for blank metatile
  beq UseBOffset          ;branch if found (unconditional if branched from 8a6b)
  ldy #$00                ;load offset for brick metatile w/ line
  cmp #$58
  beq UseBOffset          ;use offset if metatile is brick with coins (w/ line)
  cmp #$51
  beq UseBOffset          ;use offset if metatile is breakable brick w/ line
  iny                     ;increment offset for brick metatile w/o line
  cmp #$5d
  beq UseBOffset          ;use offset if metatile is brick with coins (w/o line)
  cmp #$52
  beq UseBOffset          ;use offset if metatile is breakable brick w/o line
  iny                     ;if any other metatile, increment offset for empty block
UseBOffset:
  tya                     ;put Y in A
  ldy VRAM_Buffer1_Offset ;get vram buffer offset
  iny                     ;move onto next byte
  jsr PutBlockMetatile    ;get appropriate block data and write to vram buffer
MoveVOffset:
  dey                     ;decrement vram buffer offset
  tya                     ;add 10 bytes to it
  clc
  adc #10
  jmp SetVRAMOffset       ;branch to store as new vram buffer offset
PutBlockMetatile:
  stx R0                ;store control bit from SprDataOffset_Ctrl
  sty R1                ;store vram buffer offset for next byte
  asl
  asl                   ;multiply A by four and use as X
  tax
  ldy #$20              ;load high byte for name table 0
  lda R6                ;get low byte of block buffer pointer
  cmp #$d0              ;check to see if we're on odd-page block buffer
  bcc SaveHAdder        ;if not, use current high byte
  ldy #$24              ;otherwise load high byte for name table 1
SaveHAdder:
  sty R3                ;save high byte here
  and #$0f              ;mask out high nybble of block buffer pointer
  asl                   ;multiply by 2 to get appropriate name table low byte
  sta R4                ;and then store it here
  lda #$00
  sta R5                ;initialize temp high byte
  lda R2                ;get vertical high nybble offset used in block buffer routine
  clc
  adc #$20              ;add 32 pixels for the status bar
  asl
  rol R5                ;shift and rotate d7 onto d0 and d6 into carry
  asl
  rol R5                ;shift and rotate d6 onto d0 and d5 into carry
  adc R4                ;add low byte of name table and carry to vertical high nybble
  sta R4                ;and store here
  lda R5                ;get whatever was in d7 and d6 of vertical high nybble
  adc #$00              ;add carry
  clc
  adc R3                ;then add high byte of name table
  sta R5                ;store here
  ldy R1                ;get vram buffer offset to be used
  ;fallthrough
RemBridge:
  lda BlockGfxData,x    ;write top left and top right
  sta VRAM_Buffer1+2,y  ;tile numbers into first spot
  lda BlockGfxData+1,x
  sta VRAM_Buffer1+3,y
  lda BlockGfxData+2,x  ;write bottom left and bottom
  sta VRAM_Buffer1+7,y  ;right tiles numbers into
  lda BlockGfxData+3,x  ;second spot
  sta VRAM_Buffer1+8,y
  lda R4 
  sta VRAM_Buffer1,y    ;write low byte of name table
  clc                   ;into first slot as read
  adc #$20              ;add 32 bytes to value
  sta VRAM_Buffer1+5,y  ;write low byte of name table
  lda R5                ;plus 32 bytes into second slot
  sta VRAM_Buffer1-1,y  ;write high byte of name
  sta VRAM_Buffer1+4,y  ;table address to both slots
  lda #$02
  sta VRAM_Buffer1+1,y  ;put length of 2 in
  sta VRAM_Buffer1+6,y  ;both slots
  lda #$00
  sta VRAM_Buffer1+9,y  ;put null terminator at end
  ldx R0                ;get offset control bit here
  rts                   ;and leave

BlockGfxData:
  .byte $47, $47, $48, $48
  .byte $48, $48, $48, $48
  .byte $AE, $AF, $BE, $BF
  .byte $24, $24, $24, $24
  .byte $26, $26, $26, $26


;-------------------------------------------------------------------------------------
;$00 - temp vram buffer offset
;$01 - temp metatile buffer offset
;$02 - temp metatile graphics table offset
;$03 - used to store attribute bits
;$04 - used to determine attribute table row
;$05 - used to determine attribute table column
;$06 - metatile graphics table address low
;$07 - metatile graphics table address high

RenderAreaGraphics:
  lda CurrentColumnPos         ;store LSB of where we're at
  and #$01
  sta R5
  ldy VRAM_Buffer2_Offset      ;store vram buffer offset
  sty R0
  lda CurrentNTAddr_Low        ;get current name table address we're supposed to render
  sta VRAM_Buffer2+1,y
  lda CurrentNTAddr_High
  sta VRAM_Buffer2,y
  lda #$9a                     ;store length byte of 26 here with d7 set
  sta VRAM_Buffer2+2,y         ;to increment by 32 (in columns)
  lda #$00                     ;init attribute row
  sta R4
  tax
DrawMTLoop: 
  stx R1                       ;store init value of 0 or incremented offset for buffer

  ldy MetatileBuffer,x         ;get metatile number in y
  ldx R0
  lda AreaParserTaskNum        ;get current task number for level processing and check bit 0
  lsr                          ;if the carry is clear, then we are rendering the second row of mtiles, so use the right versions
  bcc @RightSideOfMtile
    ; Rendering the left side of the metatile, so load and store the two tiles for this column
    lda MTileTopLeft,y
    sta VRAM_Buffer2+3,x
    lda MTileBotLeft,y
    sta VRAM_Buffer2+4,x
    jmp @UpdateAttributes
@RightSideOfMtile:
    ; Render the right side tiles and then fallthrough to get the attributes and update them
    lda MTileTopRight,y
    sta VRAM_Buffer2+3,x
    lda MTileBotRight,y
    sta VRAM_Buffer2+4,x
    ; fallthrough
@UpdateAttributes:
  lda MTileAttribute,y
  and #%11000000
  sta R3                       ;store attribute table bits here
  ldy R4                       ;get current attribute row
  lda R5                       ;get LSB of current column where we're at, and
  bne RightCheck               ;branch if set (clear = left attrib, set = right)
    lda R1                       ;get current row we're rendering
    lsr                          ;branch if LSB set (clear = top left, set = bottom left)
    bcs LLeft
      rol R3                       ;rotate attribute bits 3 to the left
      rol R3                       ;thus in d1-d0, for upper left square
      rol R3 
      jmp SetAttrib
RightCheck:
  lda R1                       ;get LSB of current row we're rendering
  lsr                          ;branch if set (clear = top right, set = bottom right)
  bcs NextMTRow
    lsr R3                       ;shift attribute bits 4 to the right
    lsr R3                       ;thus in d3-d2, for upper right square
    lsr R3 
    lsr R3 
    jmp SetAttrib
LLeft:
    lsr R3                       ;shift attribute bits 2 to the right
    lsr R3                       ;thus in d5-d4 for lower left square
NextMTRow:
    inc R4                       ;move onto next attribute row  
SetAttrib:
  lda AttributeBuffer,y        ;get previously saved bits from before
  ora R3                       ;if any, and put new bits, if any, onto
  sta AttributeBuffer,y        ;the old, and store
  inc R0                       ;increment vram buffer offset by 2
  inc R0 
  ldx R1                       ;get current gfx buffer row, and check for
  inx                          ;the bottom of the screen
  cpx #$0d
  bcc DrawMTLoop               ;if not there yet, loop back
            ldy R0                       ;get current vram buffer offset, increment by 3
            iny                          ;(for name table address and length bytes)
            iny
            iny
            lda #$00
            sta VRAM_Buffer2,y           ;put null terminator at end of data for name table
            sty VRAM_Buffer2_Offset      ;store new buffer offset
            inc CurrentNTAddr_Low        ;increment name table address low
            lda CurrentNTAddr_Low        ;check current low byte
            and #%00011111               ;if no wraparound, just skip this part
            bne ExitDrawM
            lda #$80                     ;if wraparound occurs, make sure low byte stays
            sta CurrentNTAddr_Low        ;just under the status bar
            lda CurrentNTAddr_High       ;and then invert d2 of the name table address high
            eor #%00000100               ;to move onto the next appropriate name table
            sta CurrentNTAddr_High
ExitDrawM:  jmp SetVRAMCtrl              ;jump to set buffer to $0341 and leave

;-------------------------------------------------------------------------------------
;$00 - temp attribute table address high (big endian order this time!)
;$01 - temp attribute table address low

RenderAttributeTables:
             lda CurrentNTAddr_Low    ;get low byte of next name table address
             and #%00011111           ;to be written to, mask out all but 5 LSB,
             sec                      ;subtract four 
             sbc #$04
             and #%00011111           ;mask out bits again and store
             sta R1 
             lda CurrentNTAddr_High   ;get high byte and branch if borrow not set
             bcs SetATHigh
             eor #%00000100           ;otherwise invert d2
SetATHigh:   and #%00000100           ;mask out all other bits
             ora #$23                 ;add $2300 to the high byte and store
             sta R0 
             lda R1                   ;get low byte - 4, divide by 4, add offset for
             lsr                      ;attribute table and store
             lsr
             adc #$c0                 ;we should now have the appropriate block of
             sta R1                   ;attribute table in our temp address
             ldx #$00
             ldy VRAM_Buffer2_Offset  ;get buffer offset
AttribLoop:  lda R0 
             sta VRAM_Buffer2,y       ;store high byte of attribute table address
             lda R1 
             clc                      ;get low byte, add 8 because we want to start
             adc #$08                 ;below the status bar, and store
             sta VRAM_Buffer2+1,y
             sta R1                   ;also store in temp again
             lda AttributeBuffer,x    ;fetch current attribute table byte and store
             sta VRAM_Buffer2+3,y     ;in the buffer
             lda #$01
             sta VRAM_Buffer2+2,y     ;store length of 1 in buffer
             lsr
             sta AttributeBuffer,x    ;clear current byte in attribute buffer
             iny                      ;increment buffer offset by 4 bytes
             iny
             iny
             iny
             inx                      ;increment attribute offset and check to see
             cpx #$07                 ;if we're at the end yet
             bcc AttribLoop
             sta VRAM_Buffer2,y       ;put null terminator at the end
             sty VRAM_Buffer2_Offset  ;store offset in case we want to do any more
SetVRAMCtrl: lda #$06
             sta VRAM_Buffer_AddrCtrl ;set buffer to $0341 and leave
             rts

;-------------------------------------------------------------------------------------
;METATILE GRAPHICS TABLE
MTILE_CURRENT_INDEX .set $00
.macro MTileDefine tl, bl, tr, br, attr
.ident(.sprintf("MTILE_TL_%d", MTILE_CURRENT_INDEX)) = tl
.ident(.sprintf("MTILE_BL_%d", MTILE_CURRENT_INDEX)) = bl
.ident(.sprintf("MTILE_TR_%d", MTILE_CURRENT_INDEX)) = tr
.ident(.sprintf("MTILE_BR_%d", MTILE_CURRENT_INDEX)) = br
.ident(.sprintf("MTILE_AT_%d", MTILE_CURRENT_INDEX)) = attr
MTILE_CURRENT_INDEX .set MTILE_CURRENT_INDEX + 1
.endmacro

MTILE_SOLID     = 1 << 0 ; Blocks that are collidable at all
MTILE_CLIMB     = 1 << 1 ; Climbable blocks
MTILE_BUMP      = 1 << 2 ; Solid blocks that also make a bump noise when hitting them with your head
; MTILE_DAMAGE    = 1 << 3 ; unimplemented
; MTILE_KILL      = 1 << 4 ; unimplemented
; MTILE_SWIM      = 1 << 5 ; unimplemented
MTILE_PALETTE_0 = 0 << 6
MTILE_PALETTE_1 = 1 << 6
MTILE_PALETTE_2 = 2 << 6
MTILE_PALETTE_3 = 3 << 6
; TODO: consider making a second batch of table entries for extended attributes
; TODO: update the level format to condense the table (remove the palette from bit 6/7 and renumber the metatiles?)
; could maybe pull this off by changing all of the metatiles in level_tiles.s without touching the level format (so it should still be possible to use existing level editors)

MTILE_CURRENT_INDEX .set $00
  MTileDefine $24, $24, $24, $24, MTILE_PALETTE_0 ;blank
  MTileDefine $27, $27, $27, $27, MTILE_PALETTE_0 ;black metatile
  MTileDefine $24, $24, $24, $30, MTILE_PALETTE_0 ;bush left
  MTileDefine $31, $25, $32, $25, MTILE_PALETTE_0 ;bush middle
  MTileDefine $24, $33, $24, $24, MTILE_PALETTE_0 ;bush right
  MTileDefine $24, $34, $34, $26, MTILE_PALETTE_0 ;mountain left
  MTileDefine $26, $26, $38, $26, MTILE_PALETTE_0 ;mountain left bottom/middle center
  MTileDefine $24, $35, $24, $36, MTILE_PALETTE_0 ;mountain middle top
  MTileDefine $37, $26, $24, $37, MTILE_PALETTE_0 ;mountain right
  MTileDefine $38, $26, $26, $26, MTILE_PALETTE_0 ;mountain right bottom
  MTileDefine $26, $26, $26, $26, MTILE_PALETTE_0 ;mountain middle bottom
  MTileDefine $24, $44, $24, $44, MTILE_PALETTE_0 ;bridge guardrail
  MTileDefine $24, $CF, $CF, $24, MTILE_PALETTE_0 ;chain
  MTileDefine $3E, $4E, $3F, $4F, MTILE_PALETTE_0 ;tall tree top, top half
  MTileDefine $3E, $4C, $3F, $4D, MTILE_PALETTE_0 ;short tree top
  MTileDefine $4E, $4C, $4F, $4D, MTILE_PALETTE_0 ;tall tree top, bottom half
  MTileDefine $50, $60, $51, $61, MTILE_PALETTE_0 | MTILE_SOLID | MTILE_BUMP ;warp pipe end left, points up
  MTileDefine $52, $62, $53, $63, MTILE_PALETTE_0 | MTILE_SOLID | MTILE_BUMP ;warp pipe end right, points up
  MTileDefine $50, $60, $51, $61, MTILE_PALETTE_0 | MTILE_SOLID | MTILE_BUMP ;decoration pipe end left, points up
  MTileDefine $52, $62, $53, $63, MTILE_PALETTE_0 | MTILE_SOLID | MTILE_BUMP ;decoration pipe end right, points up
  MTileDefine $70, $70, $71, $71, MTILE_PALETTE_0 | MTILE_SOLID | MTILE_BUMP ;pipe shaft left
  MTileDefine $26, $26, $72, $72, MTILE_PALETTE_0 | MTILE_SOLID | MTILE_BUMP ;pipe shaft right
  MTileDefine $59, $69, $5A, $6A, MTILE_PALETTE_0 | MTILE_SOLID | MTILE_BUMP ;tree ledge left edge
  MTileDefine $5A, $6C, $5A, $6C, MTILE_PALETTE_0 | MTILE_SOLID | MTILE_BUMP ;tree ledge middle
  MTileDefine $5A, $6A, $5B, $6B, MTILE_PALETTE_0 | MTILE_SOLID | MTILE_BUMP ;tree ledge right edge
  MTileDefine $A0, $B0, $A1, $B1, MTILE_PALETTE_0 | MTILE_SOLID | MTILE_BUMP ;mushroom left edge
  MTileDefine $A2, $B2, $A3, $B3, MTILE_PALETTE_0 | MTILE_SOLID | MTILE_BUMP ;mushroom middle
  MTileDefine $A4, $B4, $A5, $B5, MTILE_PALETTE_0 | MTILE_SOLID | MTILE_BUMP ;mushroom right edge
  MTileDefine $54, $64, $55, $65, MTILE_PALETTE_0 | MTILE_SOLID | MTILE_BUMP ;sideways pipe end top
  MTileDefine $56, $66, $56, $66, MTILE_PALETTE_0 | MTILE_SOLID | MTILE_BUMP ;sideways pipe shaft top
  MTileDefine $57, $67, $71, $71, MTILE_PALETTE_0 | MTILE_SOLID | MTILE_BUMP ;sideways pipe joint top
  MTileDefine $74, $84, $75, $85, MTILE_PALETTE_0 | MTILE_SOLID | MTILE_BUMP ;sideways pipe end bottom
  MTileDefine $26, $76, $26, $76, MTILE_PALETTE_0 | MTILE_SOLID | MTILE_BUMP ;sideways pipe shaft bottom
  MTileDefine $58, $68, $71, $71, MTILE_PALETTE_0 | MTILE_SOLID | MTILE_BUMP ;sideways pipe joint bottom
  MTileDefine $8C, $9C, $8D, $9D, MTILE_PALETTE_0 | MTILE_SOLID | MTILE_BUMP ;seaplant
  MTileDefine $24, $24, $24, $24, MTILE_PALETTE_0 | MTILE_SOLID | MTILE_BUMP ;blank, used on bricks or blocks that are hit
  MTileDefine $24, $5F, $24, $6F, MTILE_PALETTE_0 | MTILE_SOLID | MTILE_BUMP | MTILE_CLIMB  ;flagpole ball
  MTileDefine $7D, $7D, $7E, $7E, MTILE_PALETTE_0 | MTILE_SOLID | MTILE_BUMP | MTILE_CLIMB  ;flagpole shaft
  MTileDefine $24, $24, $24, $24, MTILE_PALETTE_0 | MTILE_SOLID | MTILE_BUMP | MTILE_CLIMB  ;blank, used in conjunction with vines

MTILE_CURRENT_INDEX .set $40
  MTileDefine $7D, $7D, $7E, $7E, MTILE_PALETTE_1 ;vertical rope
  MTileDefine $5C, $24, $5C, $24, MTILE_PALETTE_1 ;horizontal rope
  MTileDefine $24, $7D, $5D, $6D, MTILE_PALETTE_1 ;left pulley
  MTileDefine $5E, $6E, $24, $7E, MTILE_PALETTE_1 ;right pulley
  MTileDefine $24, $24, $24, $24, MTILE_PALETTE_1 ;blank used for balance rope
  MTileDefine $77, $48, $78, $48, MTILE_PALETTE_1 ;castle top
  MTileDefine $48, $48, $27, $27, MTILE_PALETTE_1 ;castle window left
  MTileDefine $48, $48, $48, $48, MTILE_PALETTE_1 ;castle brick wall
  MTileDefine $27, $27, $48, $48, MTILE_PALETTE_1 ;castle window right
  MTileDefine $79, $48, $7A, $48, MTILE_PALETTE_1 ;castle top w/ brick
  MTileDefine $7B, $27, $7C, $27, MTILE_PALETTE_1 ;entrance top
  MTileDefine $27, $27, $27, $27, MTILE_PALETTE_1 ;entrance bottom
  MTileDefine $73, $73, $73, $73, MTILE_PALETTE_1 ;green ledge stump
  MTileDefine $3A, $4A, $3B, $4B, MTILE_PALETTE_1 ;fence
  MTileDefine $3C, $3C, $3D, $3D, MTILE_PALETTE_1 ;tree trunk
  MTileDefine $A6, $4E, $A7, $4F, MTILE_PALETTE_1 ;mushroom stump top
  MTileDefine $4E, $4E, $4F, $4F, MTILE_PALETTE_1 ;mushroom stump bottom
  MTileDefine $47, $48, $47, $48, MTILE_PALETTE_1 | MTILE_SOLID ;breakable brick w/ line 
  MTileDefine $48, $48, $48, $48, MTILE_PALETTE_1 | MTILE_SOLID ;breakable brick 
  MTileDefine $47, $48, $47, $48, MTILE_PALETTE_1 | MTILE_SOLID ;breakable brick (not used)
  MTileDefine $82, $92, $83, $93, MTILE_PALETTE_1 | MTILE_SOLID ;cracked rock terrain
  MTileDefine $47, $48, $47, $48, MTILE_PALETTE_1 | MTILE_SOLID ;brick with line (power-up)
  MTileDefine $47, $48, $47, $48, MTILE_PALETTE_1 | MTILE_SOLID ;brick with line (vine)
  MTileDefine $47, $48, $47, $48, MTILE_PALETTE_1 | MTILE_SOLID ;brick with line (star)
  MTileDefine $47, $48, $47, $48, MTILE_PALETTE_1 | MTILE_SOLID ;brick with line (coins)
  MTileDefine $47, $48, $47, $48, MTILE_PALETTE_1 | MTILE_SOLID ;brick with line (1-up)
  MTileDefine $48, $48, $48, $48, MTILE_PALETTE_1 | MTILE_SOLID ;brick (power-up)
  MTileDefine $48, $48, $48, $48, MTILE_PALETTE_1 | MTILE_SOLID ;brick (vine)
  MTileDefine $48, $48, $48, $48, MTILE_PALETTE_1 | MTILE_SOLID ;brick (star)
  MTileDefine $48, $48, $48, $48, MTILE_PALETTE_1 | MTILE_SOLID ;brick (coins)
  MTileDefine $48, $48, $48, $48, MTILE_PALETTE_1 | MTILE_SOLID ;brick (1-up)
  MTileDefine $24, $24, $24, $24, MTILE_PALETTE_1 | MTILE_SOLID ;hidden block (1 coin)
  MTileDefine $24, $24, $24, $24, MTILE_PALETTE_1 | MTILE_SOLID ;hidden block (1-up)
  MTileDefine $80, $90, $81, $91, MTILE_PALETTE_1 | MTILE_SOLID | MTILE_BUMP ;solid block (3-d block)
  MTileDefine $B6, $B7, $B6, $B7, MTILE_PALETTE_1 | MTILE_SOLID | MTILE_BUMP ;solid block (white wall)
  MTileDefine $45, $24, $45, $24, MTILE_PALETTE_1 | MTILE_SOLID | MTILE_BUMP ;bridge
  MTileDefine $86, $96, $87, $97, MTILE_PALETTE_1 | MTILE_SOLID | MTILE_BUMP ;bullet bill cannon barrel
  MTileDefine $88, $98, $89, $99, MTILE_PALETTE_1 | MTILE_SOLID | MTILE_BUMP ;bullet bill cannon top
  MTileDefine $94, $94, $95, $95, MTILE_PALETTE_1 | MTILE_SOLID | MTILE_BUMP ;bullet bill cannon bottom
  MTileDefine $24, $24, $24, $24, MTILE_PALETTE_1 | MTILE_SOLID | MTILE_BUMP ;blank used for jumpspring
  MTileDefine $24, $48, $24, $48, MTILE_PALETTE_1 | MTILE_SOLID | MTILE_BUMP ;half brick used for jumpspring
  MTileDefine $8A, $9A, $8B, $9B, MTILE_PALETTE_1 | MTILE_SOLID | MTILE_BUMP ;solid block (water level, green rock)
  MTileDefine $24, $48, $24, $48, MTILE_PALETTE_1 | MTILE_SOLID | MTILE_BUMP ;half brick (???)
  MTileDefine $54, $64, $55, $65, MTILE_PALETTE_1 | MTILE_SOLID | MTILE_BUMP ;water pipe top
  MTileDefine $74, $84, $75, $85, MTILE_PALETTE_1 | MTILE_SOLID | MTILE_BUMP ;water pipe bottom
  MTileDefine $24, $5F, $24, $6F, MTILE_PALETTE_1 | MTILE_SOLID | MTILE_BUMP | MTILE_CLIMB ;flag ball (residual object)

MTILE_CURRENT_INDEX .set $80
  MTileDefine $24, $24, $24, $30, MTILE_PALETTE_2 ;cloud left
  MTileDefine $31, $25, $32, $25, MTILE_PALETTE_2 ;cloud middle
  MTileDefine $24, $33, $24, $24, MTILE_PALETTE_2 ;cloud right
  MTileDefine $24, $24, $40, $24, MTILE_PALETTE_2 ;cloud bottom left
  MTileDefine $41, $24, $42, $24, MTILE_PALETTE_2 ;cloud bottom middle
  MTileDefine $43, $24, $24, $24, MTILE_PALETTE_2 ;cloud bottom right
  MTileDefine $46, $26, $46, $26, MTILE_PALETTE_2 ;water/lava top
  MTileDefine $26, $26, $26, $26, MTILE_PALETTE_2 ;water/lava
  MTileDefine $8E, $9E, $8F, $9F, MTILE_PALETTE_2 | MTILE_SOLID | MTILE_BUMP ;cloud level terrain
  MTileDefine $39, $49, $39, $49, MTILE_PALETTE_2 | MTILE_SOLID | MTILE_BUMP ;bowser's bridge

MTILE_CURRENT_INDEX .set $c0
  MTileDefine $A8, $B8, $A9, $B9, MTILE_PALETTE_3 | MTILE_SOLID ;question block (coin)
  MTileDefine $A8, $B8, $A9, $B9, MTILE_PALETTE_3 | MTILE_SOLID ;question block (power-up)
  MTileDefine $AA, $BA, $AB, $BB, MTILE_PALETTE_3 | MTILE_SOLID ;coin
  MTileDefine $AC, $BC, $AD, $BD, MTILE_PALETTE_3 | MTILE_SOLID ;underwater coin
  MTileDefine $AE, $BE, $AF, $BF, MTILE_PALETTE_3 | MTILE_SOLID | MTILE_BUMP ;empty block
  MTileDefine $CB, $CD, $CC, $CE, MTILE_PALETTE_3 | MTILE_SOLID | MTILE_BUMP ;axe


; Create the actual metatile tables.
; TODO page align them to save a cycle someday lul
MTileTopLeft:
.repeat 256, I
.if .defined(.ident(.sprintf("MTILE_TL_%d", I)))
  .byte .ident(.sprintf("MTILE_TL_%d", I))
.else
  .byte $00
.endif
.endrepeat

MTileBotLeft:
.repeat 256, I
.if .defined(.ident(.sprintf("MTILE_BL_%d", I)))
  .byte .ident(.sprintf("MTILE_BL_%d", I))
.else
  .byte $00
.endif
.endrepeat

MTileTopRight:
.repeat 256, I
.if .defined(.ident(.sprintf("MTILE_TR_%d", I)))
  .byte .ident(.sprintf("MTILE_TR_%d", I))
.else
  .byte $00
.endif
.endrepeat

MTileBotRight:
.repeat 256, I
.if .defined(.ident(.sprintf("MTILE_BR_%d", I)))
  .byte .ident(.sprintf("MTILE_BR_%d", I))
.else
  .byte $00
.endif
.endrepeat

; THIS TABLE IS IN FIXED MEMORY since its loaded for both level loading and collision code
.segment "FIXED"
MTileAttribute:
.repeat 256, I
.if .defined(.ident(.sprintf("MTILE_AT_%d", I)))
  .byte .ident(.sprintf("MTILE_AT_%d", I))
.else
  .byte $00
.endif
.endrepeat
