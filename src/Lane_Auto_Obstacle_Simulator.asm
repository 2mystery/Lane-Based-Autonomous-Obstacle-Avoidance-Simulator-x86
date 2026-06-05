; ================================================================
; Lane-Based Autonomous Obstacle Avoidance Simulator
; DOSBox graphics version for EMU8086 / MASM-style assemblers
;
; Video mode: 13h, 320x200, 256 colors
; Drawing: direct writes to A000:0000 for DOSBox
;
; Controls:
;   P                          : pause / resume
;   + / -                      : speed up / slow down
;   R                          : restart
;   ESC                        : quit
; ================================================================

.MODEL SMALL
.STACK 100H

.DATA
    titleMsg      db '<x86 AUTO DRIVING SIMULATOR>',0
    helpMsg       db 'P PAUSE  +/- SPEED  R RESET  ESC QUIT',0
    scoreMsg      db 'SCORE ',0
    hpMsg         db 'HP ',0
    spdMsg        db 'SPD ',0
    targetMsg     db 'TGT ',0
    pausedMsg     db ' PAUSED ',0
    overMsg       db ' GAME OVER - R TO RESET ',0

    riskMsg       db 'RISK ',0
    r1Msg         db 'L1 ',0
    r2Msg         db 'L2 ',0
    r3Msg         db 'L3 ',0

    carLane       db 1
    targetLane    db 1
    pausedFlag    db 0
    quitFlag      db 0
    gameOverFlag  db 0
    health        db 5
    speedLevel    db 3
    frameWait     db 1
    pixelStep     db 1
    decision      db 0
    redrawFlag    db 1

    score         dw 0
    rngSeed       dw 0A317h

    laneX         dw 100, 160, 220
    obsLane       db 0, 2, 1, 0, 2, 1
    obsY          dw 32, 58, 84, 110, 136, 162
    prevCarLane   db 1
    prevObsLane   db 0, 2, 1, 0, 2, 1
    prevObsY      dw 32, 58, 84, 110, 136, 162

    risk1         dw 0
    risk2         dw 0
    risk3         dw 0

    rectW         dw 0
    rectColor     db 0
    numColor      db 0
    numBuffer     db 6 dup(0)

.CODE

MAIN PROC
    mov ax, @DATA
    mov ds, ax

    call SetGraphicsMode
    call SeedRandom
    call ResetGame

MainLoop:
    call PollKeyboard

    cmp byte ptr [quitFlag], 1
    je ExitProgram

    cmp byte ptr [pausedFlag], 1
    je SkipUpdate

    cmp byte ptr [gameOverFlag], 1
    je SkipUpdate

    call UpdateWorld

SkipUpdate:
    call DrawFrame
    call WaitFrame
    jmp MainLoop

ExitProgram:
    mov ax, 0003h
    int 10h
    mov ah, 4Ch
    int 21h
MAIN ENDP

; ================================================================
; Setup
; ================================================================
SetGraphicsMode PROC
    mov ax, 0013h
    int 10h
    ret
SetGraphicsMode ENDP

SeedRandom PROC
    push ax
    push cx
    push dx

    mov ah, 00h
    int 1Ah
    mov word ptr [rngSeed], dx

    pop dx
    pop cx
    pop ax
    ret
SeedRandom ENDP

ResetGame PROC
    mov byte ptr [carLane], 1
    mov byte ptr [targetLane], 1
    mov byte ptr [pausedFlag], 0
    mov byte ptr [quitFlag], 0
    mov byte ptr [gameOverFlag], 0
    mov byte ptr [health], 5
    mov byte ptr [speedLevel], 3
    mov byte ptr [frameWait], 1
    mov byte ptr [pixelStep], 1
    mov byte ptr [decision], 0
    mov byte ptr [redrawFlag], 1

    mov word ptr [score], 0

    mov byte ptr [obsLane], 0
    mov byte ptr [obsLane+1], 2
    mov byte ptr [obsLane+2], 1
    mov byte ptr [obsLane+3], 0
    mov byte ptr [obsLane+4], 2
    mov byte ptr [obsLane+5], 1

    mov word ptr [obsY], 32
    mov word ptr [obsY+2], 58
    mov word ptr [obsY+4], 84
    mov word ptr [obsY+6], 110
    mov word ptr [obsY+8], 136
    mov word ptr [obsY+10], 162

    mov byte ptr [prevCarLane], 1
    mov byte ptr [prevObsLane], 0
    mov byte ptr [prevObsLane+1], 2
    mov byte ptr [prevObsLane+2], 1
    mov byte ptr [prevObsLane+3], 0
    mov byte ptr [prevObsLane+4], 2
    mov byte ptr [prevObsLane+5], 1

    mov word ptr [prevObsY], 32
    mov word ptr [prevObsY+2], 58
    mov word ptr [prevObsY+4], 84
    mov word ptr [prevObsY+6], 110
    mov word ptr [prevObsY+8], 136
    mov word ptr [prevObsY+10], 162
    ret
ResetGame ENDP

ApplySpeed PROC
    push ax

    mov al, [speedLevel]
    cmp al, 1
    je SpeedOne
    cmp al, 2
    je SpeedTwo
    cmp al, 3
    je SpeedThree
    cmp al, 4
    je SpeedFour

    mov byte ptr [frameWait], 1
    mov byte ptr [pixelStep], 3
    jmp SpeedDone

SpeedOne:
    mov byte ptr [frameWait], 4
    mov byte ptr [pixelStep], 1
    jmp SpeedDone

SpeedTwo:
    mov byte ptr [frameWait], 3
    mov byte ptr [pixelStep], 1
    jmp SpeedDone

SpeedThree:
    mov byte ptr [frameWait], 1
    mov byte ptr [pixelStep], 1
    jmp SpeedDone

SpeedFour:
    mov byte ptr [frameWait], 1
    mov byte ptr [pixelStep], 2

SpeedDone:
    pop ax
    ret
ApplySpeed ENDP

; ================================================================
; Keyboard
; ================================================================
PollKeyboard PROC
    push ax

KeyLoop:
    mov ah, 01h
    int 16h
    jz KeyDone

    mov ah, 00h
    int 16h

    cmp al, 27
    je KeyEsc

    cmp al, 'p'
    je KeyPause
    cmp al, 'P'
    je KeyPause

    cmp al, 'r'
    je KeyRestart
    cmp al, 'R'
    je KeyRestart

    cmp al, '+'
    je KeyFaster
    cmp al, '='
    je KeyFaster
    cmp al, '-'
    je KeySlower

    jmp KeyLoop

KeyEsc:
    mov byte ptr [quitFlag], 1
    jmp KeyDone

KeyPause:
    cmp byte ptr [pausedFlag], 0
    je PauseOn
    mov byte ptr [pausedFlag], 0
    mov byte ptr [redrawFlag], 1
    jmp KeyLoop
PauseOn:
    mov byte ptr [pausedFlag], 1
    jmp KeyLoop

KeyRestart:
    call ResetGame
    jmp KeyLoop

KeyFaster:
    cmp byte ptr [speedLevel], 5
    jae KeyLoop
    inc byte ptr [speedLevel]
    call ApplySpeed
    jmp KeyLoop

KeySlower:
    cmp byte ptr [speedLevel], 1
    jbe KeyLoop
    dec byte ptr [speedLevel]
    call ApplySpeed
    jmp KeyLoop

KeyDone:
    pop ax
    ret
PollKeyboard ENDP

; ================================================================
; Game logic
; ================================================================
UpdateWorld PROC
    mov byte ptr [decision], 0
    call MoveObstacles
    call ComputeRisks
    call AutoAvoid
    call CheckCollision
    ret
UpdateWorld ENDP

MoveObstacles PROC
    push ax
    push bx
    push cx
    push di

    xor di, di
    mov cx, 6

MoveObsLoop:
    mov al, [pixelStep]
    xor ah, ah
    add word ptr [obsY+di], ax
    cmp word ptr [obsY+di], 180
    jbe MoveObsNext

    mov word ptr [obsY+di], 30
    call NextRandomLane
    mov bx, di
    shr bx, 1
    mov byte ptr [obsLane+bx], al
    add word ptr [score], 5

MoveObsNext:
    add di, 2
    loop MoveObsLoop

    pop di
    pop cx
    pop bx
    pop ax
    ret
MoveObstacles ENDP

ComputeRisks PROC
    push ax
    push bx
    push cx
    push dx
    push si
    push di

    mov word ptr [risk1], 0
    mov word ptr [risk2], 0
    mov word ptr [risk3], 0

    xor si, si
    xor di, di
    mov cx, 6

RiskLoop:
    mov ax, [obsY+di]
    cmp ax, 30
    jb RiskNext
    cmp ax, 180
    ja RiskNext

    sub ax, 28
    mov bl, [obsLane+si]
    cmp bl, 0
    je AddRiskOne
    cmp bl, 1
    je AddRiskTwo
    add word ptr [risk3], ax
    jmp RiskNext

AddRiskOne:
    add word ptr [risk1], ax
    jmp RiskNext

AddRiskTwo:
    add word ptr [risk2], ax

RiskNext:
    inc si
    add di, 2
    loop RiskLoop

    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
ComputeRisks ENDP

AutoAvoid PROC
    push ax
    push bx
    push dx

    mov al, [carLane]
    mov bl, al
    cmp al, 0
    je BaseRiskOne
    cmp al, 1
    je BaseRiskTwo
    mov ax, [risk3]
    jmp CompareAllRisks

BaseRiskOne:
    mov ax, [risk1]
    jmp CompareAllRisks

BaseRiskTwo:
    mov ax, [risk2]

CompareAllRisks:
    mov dx, [risk1]
    cmp dx, ax
    jae CheckRiskTwo
    mov ax, dx
    mov bl, 0

CheckRiskTwo:
    mov dx, [risk2]
    cmp dx, ax
    jae CheckRiskThree
    mov ax, dx
    mov bl, 1

CheckRiskThree:
    mov dx, [risk3]
    cmp dx, ax
    jae RiskChoiceDone
    mov bl, 2

RiskChoiceDone:
    mov byte ptr [targetLane], bl
    mov al, [carLane]
    cmp al, bl
    je AutoHold
    jb AutoGoRight

AutoGoLeft:
    dec byte ptr [carLane]
    mov byte ptr [decision], 1
    jmp AutoDone

AutoGoRight:
    inc byte ptr [carLane]
    mov byte ptr [decision], 2
    jmp AutoDone

AutoHold:
    mov byte ptr [decision], 0

AutoDone:
    pop dx
    pop bx
    pop ax
    ret
AutoAvoid ENDP

CheckCollision PROC
    push ax
    push bx
    push cx
    push si
    push di

    xor si, si
    xor di, di
    mov cx, 6

HitLoop:
    mov al, [obsLane+si]
    cmp al, byte ptr [carLane]
    jne HitNext

    mov ax, [obsY+di]
    cmp ax, 158
    jb HitNext
    cmp ax, 188
    ja HitNext

    mov word ptr [obsY+di], 30
    call NextRandomLane
    mov byte ptr [obsLane+si], al

    cmp byte ptr [health], 0
    je HitNext
    dec byte ptr [health]
    cmp byte ptr [health], 0
    jne HitNext
    mov byte ptr [gameOverFlag], 1

HitNext:
    inc si
    add di, 2
    loop HitLoop

    pop di
    pop si
    pop cx
    pop bx
    pop ax
    ret
CheckCollision ENDP

NextRandomLane PROC
    push bx
    push dx

    mov ax, [rngSeed]
    mov bx, 25173
    mul bx
    add ax, 13849
    mov word ptr [rngSeed], ax

    xor dx, dx
    mov bx, 3
    div bx
    mov al, dl

    pop dx
    pop bx
    ret
NextRandomLane ENDP

; ================================================================
; Drawing
; ================================================================
DrawFrame PROC
    mov ax, 0A000h
    mov es, ax

    cmp byte ptr [redrawFlag], 1
    je DrawFullFrame

    call ErasePreviousSprites
    jmp DrawMovingParts

DrawFullFrame:
    call ClearGfx
    call DrawRoad
    call DrawLaneMarkers
    call DrawStaticHud
    mov byte ptr [redrawFlag], 0

DrawMovingParts:
    call DrawObstacles
    call DrawPlayer
    call DrawDynamicHud

    cmp byte ptr [pausedFlag], 1
    jne NotPausedDraw
    call DrawPauseOverlay
NotPausedDraw:

    cmp byte ptr [gameOverFlag], 1
    jne NotOverDraw
    call DrawGameOverOverlay
NotOverDraw:
    call SaveSpritePositions
    ret
DrawFrame ENDP

ClearGfx PROC
    push ax
    push cx
    push di
    push es

    mov ax, 0A000h
    mov es, ax
    xor di, di
    xor ax, ax
    mov cx, 32000
    cld
    rep stosw

    pop es
    pop di
    pop cx
    pop ax
    ret
ClearGfx ENDP

DrawRoad PROC
    push ax
    push bx
    push cx
    push dx
    push si

    mov bx, 70
    mov dx, 24
    mov cx, 180
    mov si, 168
    mov al, 8
    call DrawRect

    mov bx, 66
    mov dx, 24
    mov cx, 4
    mov si, 168
    mov al, 15
    call DrawRect

    mov bx, 250
    mov dx, 24
    mov cx, 4
    mov si, 168
    mov al, 15
    call DrawRect

    mov bx, 70
    mov dx, 24
    mov cx, 184
    mov si, 3
    mov al, 7
    call DrawRect

    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
DrawRoad ENDP

DrawLaneMarkers PROC
    push ax
    push bx
    push cx
    push dx
    push si
    push di

    mov di, 34

LaneDashLoop:
    cmp di, 184
    ja LaneDashDone

    mov bx, 129
    mov dx, di
    mov cx, 3
    mov si, 9
    mov al, 7
    call DrawRect

    mov bx, 189
    mov dx, di
    mov cx, 3
    mov si, 9
    mov al, 7
    call DrawRect

    add di, 18
    jmp LaneDashLoop

LaneDashDone:
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
DrawLaneMarkers ENDP

DrawObstacles PROC
    push ax
    push bx
    push cx
    push dx
    push si
    push di

    xor si, si
    xor di, di
    mov cx, 6

DrawObsLoop:
    push cx
    push si

    mov al, [obsLane+si]
    call LaneCenterToBX
    sub bx, 12
    mov dx, [obsY+di]
    mov cx, 24
    mov si, 12
    mov al, 4
    call DrawRect

    add bx, 4
    add dx, 3
    mov cx, 16
    mov si, 3
    mov al, 12
    call DrawRect

    pop si
    pop cx
    inc si
    add di, 2
    loop DrawObsLoop

    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
DrawObstacles ENDP

DrawPlayer PROC
    push ax
    push bx
    push cx
    push dx
    push si

    mov al, [carLane]
    call LaneCenterToBX
    sub bx, 12

    mov dx, 170
    mov cx, 24
    mov si, 18
    mov al, 2
    call DrawRect

    add bx, 4
    sub dx, 7
    mov cx, 16
    mov si, 8
    mov al, 10
    call DrawRect

    sub bx, 2
    add dx, 13
    mov cx, 20
    mov si, 4
    mov al, 11
    call DrawRect

    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
DrawPlayer ENDP

ErasePreviousSprites PROC
    push ax
    push bx
    push cx
    push dx
    push si
    push di

    xor si, si
    xor di, di
    mov cx, 6

EraseObsLoop:
    push cx
    push si

    mov al, [prevObsLane+si]
    call LaneCenterToBX
    sub bx, 12
    mov dx, [prevObsY+di]
    mov cx, 24
    mov si, 12
    mov al, 8
    call DrawRect

    pop si
    pop cx
    inc si
    add di, 2
    loop EraseObsLoop

    mov al, [prevCarLane]
    call LaneCenterToBX
    sub bx, 12
    mov dx, 163
    mov cx, 24
    mov si, 25
    mov al, 8
    call DrawRect

    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
ErasePreviousSprites ENDP

SaveSpritePositions PROC
    push ax
    push cx
    push si
    push di

    mov al, [carLane]
    mov byte ptr [prevCarLane], al

    xor si, si
    xor di, di
    mov cx, 6

SaveSpriteLoop:
    mov al, [obsLane+si]
    mov byte ptr [prevObsLane+si], al
    mov ax, [obsY+di]
    mov word ptr [prevObsY+di], ax
    inc si
    add di, 2
    loop SaveSpriteLoop

    pop di
    pop si
    pop cx
    pop ax
    ret
SaveSpritePositions ENDP

DrawStaticHud PROC
    push ax
    push bx
    push dx
    push si

    mov dh, 0
    mov dl, 1
    mov bl, 15
    lea si, titleMsg
    call PrintString

    mov dh, 1
    mov dl, 1
    mov bl, 14
    lea si, scoreMsg
    call PrintString
    mov ax, [score]
    mov dh, 1
    mov dl, 7
    mov bl, 15
    call PrintNumber

    mov dh, 1
    mov dl, 15
    mov bl, 14
    lea si, hpMsg
    call PrintString
    mov al, [health]
    xor ah, ah
    mov dh, 1
    mov dl, 18
    mov bl, 15
    call PrintNumber

    mov dh, 1
    mov dl, 23
    mov bl, 14
    lea si, spdMsg
    call PrintString
    mov al, [speedLevel]
    xor ah, ah
    mov dh, 1
    mov dl, 27
    mov bl, 15
    call PrintNumber

    mov dh, 2
    mov dl, 1
    mov bl, 11
    lea si, riskMsg
    call PrintString

    mov dh, 2
    mov dl, 7
    mov bl, 14
    lea si, r1Msg
    call PrintString
    mov ax, [risk1]
    mov dh, 2
    mov dl, 10
    mov bl, 15
    call PrintNumber

    mov dh, 2
    mov dl, 16
    mov bl, 14
    lea si, r2Msg
    call PrintString
    mov ax, [risk2]
    mov dh, 2
    mov dl, 19
    mov bl, 15
    call PrintNumber

    mov dh, 2
    mov dl, 25
    mov bl, 14
    lea si, r3Msg
    call PrintString
    mov ax, [risk3]
    mov dh, 2
    mov dl, 28
    mov bl, 15
    call PrintNumber

    mov dh, 1
    mov dl, 31
    mov bl, 14
    lea si, targetMsg
    call PrintString
    mov al, [targetLane]
    inc al
    xor ah, ah
    mov dh, 1
    mov dl, 35
    mov bl, 15
    call PrintNumber

    mov dh, 24
    mov dl, 0
    mov bl, 7
    lea si, helpMsg
    call PrintString

    pop si
    pop dx
    pop bx
    pop ax
    ret
DrawStaticHud ENDP

DrawDynamicHud PROC
    push ax
    push bx
    push cx
    push dx
    push si

    mov bx, 56
    mov dx, 8
    mov cx, 48
    mov si, 8
    mov al, 0
    call DrawRect

    mov bx, 144
    mov dx, 8
    mov cx, 16
    mov si, 8
    mov al, 0
    call DrawRect

    mov bx, 216
    mov dx, 8
    mov cx, 16
    mov si, 8
    mov al, 0
    call DrawRect

    mov bx, 280
    mov dx, 8
    mov cx, 8
    mov si, 8
    mov al, 0
    call DrawRect

    mov bx, 80
    mov dx, 16
    mov cx, 32
    mov si, 8
    mov al, 0
    call DrawRect

    mov bx, 152
    mov dx, 16
    mov cx, 32
    mov si, 8
    mov al, 0
    call DrawRect

    mov bx, 224
    mov dx, 16
    mov cx, 32
    mov si, 8
    mov al, 0
    call DrawRect

    mov ax, [score]
    mov dh, 1
    mov dl, 7
    mov bl, 15
    call PrintNumber

    mov al, [health]
    xor ah, ah
    mov dh, 1
    mov dl, 18
    mov bl, 15
    call PrintNumber

    mov al, [speedLevel]
    xor ah, ah
    mov dh, 1
    mov dl, 27
    mov bl, 15
    call PrintNumber

    mov al, [targetLane]
    inc al
    xor ah, ah
    mov dh, 1
    mov dl, 35
    mov bl, 15
    call PrintNumber

    mov ax, [risk1]
    mov dh, 2
    mov dl, 10
    mov bl, 15
    call PrintNumber

    mov ax, [risk2]
    mov dh, 2
    mov dl, 19
    mov bl, 15
    call PrintNumber

    mov ax, [risk3]
    mov dh, 2
    mov dl, 28
    mov bl, 15
    call PrintNumber

    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
DrawDynamicHud ENDP

DrawPauseOverlay PROC
    push ax
    push bx
    push cx
    push dx
    push si

    mov bx, 116
    mov dx, 90
    mov cx, 88
    mov si, 20
    mov al, 1
    call DrawRect

    mov dh, 12
    mov dl, 15
    mov bl, 15
    lea si, pausedMsg
    call PrintString

    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
DrawPauseOverlay ENDP

DrawGameOverOverlay PROC
    push ax
    push bx
    push cx
    push dx
    push si

    mov bx, 72
    mov dx, 88
    mov cx, 176
    mov si, 24
    mov al, 4
    call DrawRect

    mov dh, 12
    mov dl, 8
    mov bl, 15
    lea si, overMsg
    call PrintString

    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
DrawGameOverOverlay ENDP

; Input: BX=x, DX=y, CX=width, SI=height, AL=color
DrawRect PROC
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    push es

    mov byte ptr [rectColor], al
    mov word ptr [rectW], cx

    mov ax, 0A000h
    mov es, ax

    mov ax, dx
    mov di, ax
    shl di, 8
    mov ax, dx
    shl ax, 6
    add di, ax
    add di, bx

DrawRectRow:
    cmp si, 0
    je DrawRectDone
    mov cx, word ptr [rectW]
    mov al, byte ptr [rectColor]
    cld
    rep stosb
    add di, 320
    sub di, word ptr [rectW]
    dec si
    jmp DrawRectRow

DrawRectDone:
    pop es
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
DrawRect ENDP

; Input: AL=lane index, Output: BX=center x
LaneCenterToBX PROC
    push ax
    xor ah, ah
    shl ax, 1
    mov bx, ax
    mov bx, word ptr [laneX+bx]
    pop ax
    ret
LaneCenterToBX ENDP

; ================================================================
; Text output in mode 13h
; ================================================================
; Input: DH=row, DL=col, SI=zero-terminated string, BL=color
PrintString PROC
    push ax
    push bx
    push cx
    push dx
    push si

    mov ah, 02h
    mov bh, 0
    int 10h

TextLoop:
    lodsb
    cmp al, 0
    je TextDone
    mov ah, 0Eh
    mov bh, 0
    int 10h
    jmp TextLoop

TextDone:
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
PrintString ENDP

; Input: AX=number, DH=row, DL=col, BL=color
PrintNumber PROC
    push ax
    push bx
    push cx
    push dx
    push si
    push di

    mov byte ptr [numColor], bl
    mov di, dx
    lea si, numBuffer+5
    mov byte ptr [si], 0
    mov bx, 10

    cmp ax, 0
    jne NumberLoop

    dec si
    mov byte ptr [si], '0'
    jmp NumberPrint

NumberLoop:
    xor dx, dx
    div bx
    add dl, '0'
    dec si
    mov byte ptr [si], dl
    cmp ax, 0
    jne NumberLoop

NumberPrint:
    mov dx, di
    mov bl, byte ptr [numColor]
    call PrintString

    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
PrintNumber ENDP

; ================================================================
; Frame timing
; ================================================================
WaitFrame PROC
    push ax
    push cx
    push dx

    mov cl, [frameWait]
    xor ch, ch

WaitFrameLoop:
    call WaitRetrace
    call PollKeyboard
    cmp byte ptr [quitFlag], 1
    je WaitFrameDone
    loop WaitFrameLoop

WaitFrameDone:
    pop dx
    pop cx
    pop ax
    ret
WaitFrame ENDP

WaitRetrace PROC
    push ax
    push dx

    mov dx, 03DAh

WaitRetraceEnd:
    in al, dx
    test al, 08h
    jnz WaitRetraceEnd

WaitRetraceStart:
    in al, dx
    test al, 08h
    jz WaitRetraceStart

    pop dx
    pop ax
    ret
WaitRetrace ENDP

END MAIN
