                    !cpu 6510
; ==============================================================================
ENABLE              = 0x20
ENABLE_JMP          = 0x4C
DISABLE             = 0x2C
OP_RTS              = 0x60
OP_NOP              = 0xEA

BLACK               = 0x00
WHITE               = 0x01
RED                 = 0x02
CYAN                = 0x03
PURPLE              = 0x04
GREEN               = 0x05
BLUE                = 0x06
YELLOW              = 0x07
ORANGE              = 0x08
BROWN               = 0x09
PINK                = 0x0A
DARK_GREY           = 0x0B
GREY                = 0x0C
LIGHT_GREEN         = 0x0D
LIGHT_BLUE          = 0x0E
LIGHT_GREY          = 0x0F

NUMSONGS            = 6
; ------------------------------------------------------------------------------
;                   BADLINEs (0xD011 default)
;                   -------------------------
;                   00 : 0x33
;                   01 : 0x3B
;                   02 : 0x43
;                   03 : 0x4B
;                   04 : 0x53
;                   05 : 0x5B
;                   06 : 0x63
;                   07 : 0x6B
;                   08 : 0x73
;                   09 : 0x7B
;                   10 : 0x83
;                   11 : 0x8B
;                   12 : 0x93
;                   13 : 0x9B
;                   14 : 0xA3
;                   15 : 0xAB
;                   16 : 0xB3
;                   17 : 0xBB
;                   18 : 0xC3
;                   19 : 0xCB
;                   20 : 0xD3
;                   21 : 0xDB
;                   22 : 0xE3
;                   23 : 0xEB
;                   24 : 0xF3
; ------------------------------------------------------------------------------
IRQ_LINE00          = 0x00
IRQ_LINE01          = 0x74
IRQ_LINE02          = 0xBC
IRQ_LINE03          = 0xF8
NUM_IRQS            = 4
; ------------------------------------------------------------------------------
                    !macro irq_lines_tab {
                        !byte IRQ_LINE00, IRQ_LINE01, IRQ_LINE02, IRQ_LINE03
                    }
; ------------------------------------------------------------------------------
                    !macro irq_tab {
                        !byte <irq00, <irq01, <irq02, <irq03
                        !byte >irq00, >irq01, >irq02, >irq03
                    }
; ==============================================================================
zp_start            = 0x02
irq_ready_top       = zp_start
irq_ready_bot       = irq_ready_top+1
savea               = irq_ready_bot+1
savex               = savea+1
savey               = savex+1
save1               = savey+1
frame_ct_0          = save1+1
frame_ct_1          = frame_ct_0+1
frame_ct_2          = frame_ct_1+1
decrunch_flag       = frame_ct_2+1
tune_end_flag       = decrunch_flag+1
zp_end              = tune_end_flag+1
; ==============================================================================
KEY_CRSRUP          = 0x91
KEY_CRSRDOWN        = 0x11
KEY_CRSRLEFT        = 0x9D
KEY_CRSRRIGHT       = 0x1D
KEY_RETURN          = 0x0D
KEY_STOP            = 0x03

getin               = 0xFFE4
keyscan             = 0xEA87
; ==============================================================================
code_start          = 0x2400
code_exo            = 0x0900
vicbank0            = 0x0000
vicbank1            = 0xC000
charset0            = vicbank0+0x1000
charset1            = vicbank1+0x0000
vidmem0             = vicbank0+0x0400
vidmem1             = vicbank1+0x0800
bitmap0             = vicbank1+0x2000
sprite_data         = vicbank0+0x0800
sprite_base         = <((sprite_data-vicbank0)/0x40)
dd00_val0           = <!(vicbank0/0x4000) & 3
dd00_val1           = <!(vicbank1/0x4000) & 3
d018_val0           = <(((vidmem0-vicbank0)/0x400) << 4)+ <(((charset0-vicbank0)/0x800) << 1)
d018_val1           = <(((vidmem1-vicbank1)/0x400) << 4)+ <(((charset1-vicbank1)/0x800) << 1)
d018_val2           = <(((vidmem1-vicbank1)/0x400) << 4)+ <(((bitmap0-vicbank1)/0x800) << 1)
music_init          = 0x1000
music_play          = music_init+3
music_fade          = 0x113D
; ==============================================================================
                    !macro flag_set .flag {
                        lda #1
                        sta .flag
                    }
                    !macro flag_clear .flag {
                        lda #0
                        sta .flag
                    }
                    !macro flag_get .flag {
                        lda .flag
                    }
; ==============================================================================
                    !zone DECRUNCH
                    *= code_exo
exomizer:           !src "exodecrunch.asm"
exod_get_crunched_byte:
                    lda opbase + 1
                    bne nowrap
                    dec opbase + 2
nowrap:             dec opbase + 1
; change the $ffff to point to the byte immediately following the last
; byte of the crunched file data (mem command)
opbase:             lda 0xFFFF
                    rts
; ------------------------------------------------------------------------------
decrunch_song:      ldx song_pointer
                    lda song_playlist,x
                    bpl +
                    lda #0x00
                    sta song_pointer
+                   tax
                    stx .xsav+1
                    lda song_end_tab_lo,x
                    sta opbase+1
                    lda song_end_tab_hi,x
                    sta opbase+2
                    jsr exod_decrunch
.xsav:              ldx #0x00
                    lda song_time_tab_lo,x
                    sta .src_time+1
                    lda song_time_tab_hi,x
                    sta .src_time+2
                    ldx #3
.src_time:          lda 0x0000,x
                    sta vidmem1+(15*40)+35,x
                    lda .empty_time,x
                    sta vidmem1+(15*40)+28,x
                    dex
                    bpl .src_time
                    inc song_pointer
                    lda #ENABLE
                    sta enable_display
                    sta enable_cycle
                    rts
.empty_time:        !scr "0:00"
; ==============================================================================
                    !zone FRAME_COUNT
framecounter:       clc
                    lda frame_ct_0
                    adc #1
                    sta frame_ct_0
                    lda frame_ct_1
                    adc #0
                    sta frame_ct_1
                    lda frame_ct_2
                    adc #0
                    sta frame_ct_2
                    rts
; ==============================================================================
                    !zone BASICFADE
                    BASICFADE_SPEED = 0x04
basicfade:          lda 0xD020
                    and #0x0F
                    tax
                    lda .colfade_wh_tab_lo,x
                    sta .src_d020+1
                    lda .colfade_wh_tab_hi,x
                    sta .src_d020+2
                    lda 0xD021
                    and #0x0F
                    tax
                    lda .colfade_wh_tab_lo,x
                    sta .src_d021+1
                    lda .colfade_wh_tab_hi,x
                    sta .src_d021+2
                    ; fade 0xD020 / 0xD021 seperate to white first
                    ldy #0x00
-                   ldx #BASICFADE_SPEED
                    jsr .wait_top_x
                    jsr .set_d020
                    jsr .set_d021
                    iny
.ct:                lda #0x02
                    bne -
                    ; and then both to black
                    ldy #0xFF
-                   iny
                    ldx #BASICFADE_SPEED
                    jsr .wait_top_x
                    lda .colfade_bl_tab,y
                    sta 0xD020
                    sta 0xD021
                    bpl -
                    lda #0x0B
                    sta 0xD011
                    rts
; ------------------------------------------------------------------------------
.set_d020:          nop
.src_d020:          lda 0x0000,y
                    sta 0xD020
                    bpl +
                    lda #OP_RTS
                    sta .set_d020
                    dec .ct+1
+                   rts
; ------------------------------------------------------------------------------
.set_d021:          nop
.src_d021:          lda 0x0000,y
                    sta 0xD021
                    bpl +
                    lda #OP_RTS
                    sta .set_d021
                    dec .ct+1
+                   rts
; ------------------------------------------------------------------------------
; color fade tables
; see "Colfade Doc" by veto: https://csdb.dk/release/?id=132276
; ------------------------------------------------------------------------------
.colfade_bl_tab:    !byte 0x01, 0x0D, 0x03, 0x0C, 0x04, 0x02, 0x09, 0xF0
.colfade_wh_tab0:   !byte 0x00, 0x06, 0x0B, 0x04, 0x0C, 0x03, 0x0D, 0xF1
.colfade_wh_tab1:   !byte 0x09, 0x02, 0x08, 0x0A, 0x0F, 0x07, 0xF1
.colfade_wh_tab2:   !byte 0x05, 0x03, 0x0D, 0xF1
.colfade_wh_tab3:   !byte 0x0E, 0x03, 0x0D, 0xF1
.colfade_wh_tab_lo: !byte <(.colfade_wh_tab0+0)     ; 0x00 BLACK
                    !byte <(.colfade_wh_tab0+7)     ; 0x01 WHITE
                    !byte <(.colfade_wh_tab1+1)     ; 0x02 RED
                    !byte <(.colfade_wh_tab0+5)     ; 0x03 CYAN
                    !byte <(.colfade_wh_tab0+3)     ; 0x04 PURPLE
                    !byte <(.colfade_wh_tab2+0)     ; 0x05 GREEN
                    !byte <(.colfade_wh_tab0+1)     ; 0x06 BLUE
                    !byte <(.colfade_wh_tab1+5)     ; 0x07 YELLOW
                    !byte <(.colfade_wh_tab1+2)     ; 0x08 ORANGE
                    !byte <(.colfade_wh_tab1+0)     ; 0x09 BROWN
                    !byte <(.colfade_wh_tab1+3)     ; 0x0A PINK
                    !byte <(.colfade_wh_tab0+2)     ; 0x0B DARK_GREY
                    !byte <(.colfade_wh_tab0+4)     ; 0x0C GREY
                    !byte <(.colfade_wh_tab0+6)     ; 0x0D LIGHT_GREEN
                    !byte <(.colfade_wh_tab3+0)     ; 0x0E LIGHT_BLUE
                    !byte <(.colfade_wh_tab1+4)     ; 0x0F LIGHT_GREY
.colfade_wh_tab_hi: !byte >(.colfade_wh_tab0+0)     ; 0x00 BLACK
                    !byte >(.colfade_wh_tab0+7)     ; 0x01 WHITE
                    !byte >(.colfade_wh_tab1+1)     ; 0x02 RED
                    !byte >(.colfade_wh_tab0+5)     ; 0x03 CYAN
                    !byte >(.colfade_wh_tab0+3)     ; 0x04 PURPLE
                    !byte >(.colfade_wh_tab2+0)     ; 0x05 GREEN
                    !byte >(.colfade_wh_tab0+1)     ; 0x06 BLUE
                    !byte >(.colfade_wh_tab1+5)     ; 0x07 YELLOW
                    !byte >(.colfade_wh_tab1+2)     ; 0x08 ORANGE
                    !byte >(.colfade_wh_tab1+0)     ; 0x09 BROWN
                    !byte >(.colfade_wh_tab1+3)     ; 0x0A PINK
                    !byte >(.colfade_wh_tab0+2)     ; 0x0B DARK_GREY
                    !byte >(.colfade_wh_tab0+4)     ; 0x0C GREY
                    !byte >(.colfade_wh_tab0+6)     ; 0x0D LIGHT_GREEN
                    !byte >(.colfade_wh_tab3+0)     ; 0x0E LIGHT_BLUE
                    !byte >(.colfade_wh_tab1+4)     ; 0x0F LIGHT_GREY
; ------------------------------------------------------------------------------
.wait_top:          bit 0xD011
                    bpl .wait_top
-                   bit 0xD011
                    bmi -
                    rts
; ------------------------------------------------------------------------------
; .wait_top_x
; ------------+---+-------------------------------------------------------------
; input:      | X | number of frames to wait
; ------------+---+-------------------------------------------------------------
.wait_top_x:        jsr .wait_top
                    dex
                    bpl .wait_top_x
                    rts
; ==============================================================================
                    !zone IRQ
                    !align 255,0
irq:                sta savea               ; 03  10  (07+03)
                    stx savex               ; 03  13
                    sty savey               ; 03  16
                    lda 0x01                ; 03  19
                    sta save1               ; 03  22
                    lda #<.irq_timing       ; 02  24
                    sta 0xFFFE              ; 04  26
                    lda #>.irq_timing       ; 02  28
                    sta 0xFFFF              ; 04  32
                    inc 0xD012              ; 06  38
                    asl 0xD019              ; 06  44
                    tsx                     ; 02  46
                    cli                     ; 02  48
                    !fi 8, 0xEA             ; 02  64  (08*02)
.irq_timing:        txs
                    ldx #0x08
-                   dex
                    bne -
                    bit 0xEA
                    nop
irq_plus_cmp:       lda #<IRQ_LINE00+1
                    cmp 0xD012
                    beq irq_next
irq_next:           jmp irq00
; ------------------------------------------------------------------------------
irq_end:            lda 0xD012
-                   cmp 0xD012
                    beq -
.irq_index:         ldx #0x00
                    lda irq_tab,x
                    sta irq_next+1
                    lda irq_tab+NUM_IRQS,x
                    sta irq_next+2
                    lda irq_lines,x
                    sta 0xD012
                    sta irq_plus_cmp+1
                    inc irq_plus_cmp+1
                    inc .irq_index+1
                    lda .irq_index+1
irq_num_cmp:        cmp #NUM_IRQS
                    bne +
                    lda #0x00
                    sta .irq_index+1
+                   lda #<irq
                    sta 0xFFFE
                    lda #>irq
                    sta 0xFFFF
                    asl 0xD019
                    lda save1
                    sta 0x01
                    lda savea
                    ldx savex
                    ldy savey
                    rti
irq_tab:            +irq_tab
irq_lines:          +irq_lines_tab
; ------------------------------------------------------------------------------
                    !align 255,0
irq00:              +flag_set irq_ready_top
                    lda #BLACK
                    sta 0xD020
                    sta 0xD021
                    lda #dd00_val1
                    sta 0xDD00
                    lda #d018_val1
                    sta 0xD018
                    lda #0x08
                    sta 0xD016
                    lda #0x1B
                    sta 0xD011
                    jsr framecounter
enable_display:     bit display
                    jmp irq_end
; ------------------------------------------------------------------------------
irq01:              ldx #09
-                   dex
                    bpl -
                    nop
                    lda #GREY
                    sta 0xD020
                    sta 0xD021
                    ldx #09
-                   dex
                    bpl -
                    nop
                    lda #DARK_GREY
                    sta 0xD020
                    sta 0xD021
                    jmp irq_end
; ------------------------------------------------------------------------------
irq02:              ldx #09
-                   dex
                    bpl -
                    nop
                    lda #LIGHT_BLUE
                    sta 0xD020
                    sta 0xD021
                    ldx #09
-                   dex
                    bpl -
                    nop
                    lda #BLUE
                    sta 0xD020
                    sta 0xD021
                    lda #d018_val2
                    sta 0xD018
                    lda #0x18
                    sta 0xD016
                    lda #0x3B
                    sta 0xD011
enable_music:       bit music_play
enable_timer:       bit timer_increase
enable_timer_check: bit timer_check
                    jmp irq_end
; ------------------------------------------------------------------------------
irq03:              ldx #09
-                   dex
                    bpl -
                    nop
                    lda #DARK_GREY
                    sta 0xD020
                    sta 0xD021
                    ldx #09
-                   dex
                    bpl -
                    nop
                    lda #BLACK
                    sta 0xD020
                    sta 0xD021
enable_fadein:      jsr fade_in
                    +flag_set irq_ready_bot
                    jmp irq_end
; ==============================================================================
                    *= code_start
                    lda #0x7F
                    sta 0xDC0D
                    lda #0x35
                    sta 0x01
                    lda #0x1B
                    sta 0xD011
; ==============================================================================
                    !zone INIT
init_code:          jsr init_nmi
                    jsr init_zp
                    jsr basicfade
                    jsr init_vic
                    jsr init_irq
                    jmp mainloop
; ------------------------------------------------------------------------------
init_irq:           lda irq_lines
                    sta 0xD012
                    sta irq_plus_cmp+1
                    inc irq_plus_cmp+1
                    lda #<irq
                    sta 0xFFFE
                    lda #>irq
                    sta 0xFFFF
                    lda #0x0B
                    sta 0xD011
                    lda #0x01
                    sta 0xD019
                    sta 0xD01A
                    rts
; ------------------------------------------------------------------------------
init_music:         lda #0x00
                    tax
                    tay
                    jsr music_init
                    rts
; ------------------------------------------------------------------------------
init_nmi:           lda #<nmi
                    sta 0x0318
                    sta 0xFFFA
                    lda #>nmi
                    sta 0x0319
                    sta 0xFFFB
                    rts
; ------------------------------------------------------------------------------
init_vic:           lda #dd00_val0
                    sta 0xDD00
                    lda #d018_val0
                    sta 0xD018
                    ldx #0x00
-                   lda #0x00
                    sta bitmap0+0x0000,x
                    sta bitmap0+0x0100,x
                    sta bitmap0+0x0200,x
                    sta bitmap0+0x0300,x
                    sta bitmap0+0x0400,x
                    sta bitmap0+0x0500,x
                    sta bitmap0+0x0600,x
                    sta bitmap0+0x0700,x
                    sta bitmap0+0x0800,x
                    sta bitmap0+0x0900,x
                    sta bitmap0+0x0A00,x
                    sta bitmap0+0x0B00,x
                    sta bitmap0+0x0C00,x
                    sta bitmap0+0x0D00,x
                    sta bitmap0+0x0E00,x
                    sta bitmap0+0x0F00,x
                    sta bitmap0+0x1000,x
                    sta bitmap0+0x1100,x
                    sta bitmap0+0x1200,x
                    sta bitmap0+0x1300,x
                    sta bitmap0+0x1400,x
                    sta bitmap0+0x1500,x
                    sta 0xD800+0x000,x
                    sta 0xD800+0x100,x
                    sta 0xD800+0x200,x
                    sta 0xD800+0x2E8,x
                    sta vidmem1+0x000,x
                    sta vidmem1+0x100,x
                    sta vidmem1+0x200,x
                    sta vidmem1+0x2E8,x
                    lda bitmap_src+0x0000,x
                    sta bitmap0+0x1540,x
                    lda bitmap_src+0x0100,x
                    sta bitmap0+0x1640,x
                    lda bitmap_src+0x0200,x
                    sta bitmap0+0x1740,x
                    lda bitmap_src+0x0300,x
                    sta bitmap0+0x1840,x
                    lda bitmap_src+0x0400,x
                    sta bitmap0+0x1940,x
                    lda bitmap_src+0x0500,x
                    sta bitmap0+0x1A40,x
                    lda bitmap_src+0x0600,x
                    sta bitmap0+0x1B40,x
                    lda bitmap_src+0x0700,x
                    sta bitmap0+0x1C40,x
                    lda bitmap_src+0x0800,x
                    sta bitmap0+0x1D40,x
                    lda bitmap_src+0x0900,x
                    sta bitmap0+0x1E40,x
                    lda charset_src+0x000,x
                    sta charset1+0x000,x
                    lda charset_src+0x100,x
                    sta charset1+0x100,x
                    lda charset_src+0x200,x
                    sta charset1+0x200,x
                    lda charset_src+0x300,x
                    sta charset1+0x300,x
                    inx
                    beq +
                    jmp -
+                   ldy #0x00
-                   lda song_playlist,y
                    bmi ++
                    tax
                    lda song_title_tab_lo,x
                    sta .src_tit+1
                    lda song_title_tab_hi,x
                    sta .src_tit+2
                    ldx #0x0D
.src_tit:           lda 0x0000,x
.dst_tit:           sta vidmem_src+(10*40+5),x
                    dex
                    bpl .src_tit
                    clc
                    lda .dst_tit+1
                    adc #0x28
                    sta .dst_tit+1
                    bcc +
                    inc .dst_tit+2
+                   iny
                    jmp -
++                  rts
; ------------------------------------------------------------------------------
init_zp:            lda #0x00
                    ldx #zp_start
-                   sta 0x00,x
                    inx
                    bne -
                    rts
; ==============================================================================
                    !zone NMI
nmi:                lda #0x37               ; restore 0x01 standard value
                    sta 0x01
                    lda #0                  ; if AR/RR present
                    sta 0xDE00              ; reset will lead to menu
                    jmp 0xFCE2              ; reset
; ==============================================================================
                    !zone WAIT
wait_irq_top:       +flag_clear irq_ready_top
-                   +flag_get irq_ready_top
                    beq -
                    rts
; --------------------------------------------------------------------------------
wait_irq_bot:       +flag_clear wait_irq_bot
-                   +flag_get wait_irq_bot
                    beq -
                    rts
; ==============================================================================
                    !zone MAINLOOP
mainloop:           jsr wait_irq_top
enable_cycle:       bit do_cycle
                    jsr keyboard_get
                    +flag_get decrunch_flag
                    beq mainloop
                    +flag_clear decrunch_flag
                    jsr decrunch_song
                    jsr init_music
                    lda #ENABLE
                    sta enable_music
                    sta enable_timer
                    sta enable_timer_check
                    jmp mainloop
; ==============================================================================
                    !zone FADE
                    FADEIN_SPEED = 0x06
                    FADEIN_DELAY = 0x2F
fade_in:            lda #FADEIN_DELAY
                    beq +
                    dec fade_in+1
                    rts
+                   lda #FADEIN_SPEED
                    sta fade_in+1
.ysav:              ldy #24
                    ldx #0x27
.src_vid:           lda vidmem_src,x
.dst_vid:           sta vidmem1,x
.src_col:           lda colram_src,x
.dst_col:           sta 0xD800,x
                    dex
                    bpl .src_vid
                    clc
                    lda .src_vid+1
                    adc #0x28
                    sta .src_vid+1
                    bcc +
                    inc .src_vid+2
                    clc
+                   lda .src_col+1
                    adc #0x28
                    sta .src_col+1
                    bcc +
                    inc .src_col+2
                    clc
+                   lda .dst_vid+1
                    adc #0x28
                    sta .dst_vid+1
                    sta .dst_col+1
                    bcc +
                    inc .dst_vid+2
                    inc .dst_col+2
+                   dey
                    bpl +
                    lda #DISABLE
                    sta enable_fadein
                    lda #ENABLE
                    sta enable_display
                    +flag_set decrunch_flag
+                   sty .ysav+1
                    rts
; ==============================================================================
                    !zone DISPLAY
display:            lda #CYAN
                    jsr color_song_playing
                    jsr cursor
                    rts
; ------------------------------------------------------------------------------
color_song_playing: sta .color+1
                    ldx song_playing
                    lda song_vidmem_pt_lo,x
                    sta .dst_colram0+1
                    clc
                    lda song_vidmem_pt_hi,x
                    adc #(0xD8 - >vidmem1)
                    sta .dst_colram0+2
                    ldx #0x12
.color:             lda #0x00
.dst_colram0:       sta 0x0000,x
                    dex
                    bpl .dst_colram0
                    rts
; ------------------------------------------------------------------------------
cursor:             jsr .anim_crsr
                    ldx cursorpos
                    lda song_vidmem_pt_lo,x
                    sta .dst_vidmem1+1
                    sta .dst_colram1+1
                    clc
                    lda song_vidmem_pt_hi,x
                    sta .dst_vidmem1+2
                    adc #(0xD8 - >vidmem1)
                    sta .dst_colram1+2
.mod_blink:         lda #0x1F
.dst_vidmem1:       sta 0x0000
                    lda #WHITE
.dst_colram1:       sta 0x0000
                    rts
.anim_crsr:         lda #0x10
                    beq +
                    dec .anim_crsr+1
                    rts
+                   lda #0x10
                    sta .anim_crsr+1
                    lda .mod_blink+1
                    eor #(0x1F XOR 0x20)
                    sta .mod_blink+1
                    rts
cursorpos:          !byte 0x00
; ==============================================================================
                    !zone KEYBOARD
keyboard_get:       lda #0x36
                    sta 0x01
                    jsr keyscan
                    jsr getin
                    bne +
                    jmp .key_exit
+                   cmp #KEY_CRSRUP
                    bne +
                    jmp .mark_up
+                   cmp #KEY_CRSRDOWN
                    bne +
                    jmp .mark_down
+                   cmp #KEY_RETURN
                    bne +
                    jmp .tune_select
+                   cmp #KEY_STOP
                    bne .key_exit
                    jmp .pause_toggle
.key_exit:          lda #0x35
                    sta 0x01
                    rts
; ------------------------------------------------------------------------------
.mark_down:         lda cursorpos
                    cmp #NUMSONGS-1
                    beq +
                    lda #0x20
                    !for i, 10, 15 {
                        sta vidmem1+(i*40)
                    }
                    inc cursorpos
+                   jmp .key_exit
; ------------------------------------------------------------------------------
.mark_up:           lda cursorpos
                    beq +
                    lda #0x20
                    !for i, 10, 15 {
                        sta vidmem1+(i*40)
                    }
                    dec cursorpos
+                   jmp .key_exit
; ------------------------------------------------------------------------------
.pause_toggle:      lda #0
                    beq .pause
.unpause:           lda #ENABLE
                    sta enable_music
                    sta enable_timer
                    sta enable_timer_check
                    lda #0
                    sta .pause_toggle+1
                    jmp .key_exit
.pause:             jsr wait_irq_bot
                    lda #DISABLE
                    sta enable_music
                    sta enable_timer
                    sta enable_timer_check
                    lda #0
                    sta 0xD404
                    sta 0xD40B
                    sta 0xD412
                    lda #1
                    sta .pause_toggle+1
                    jmp .key_exit
; ------------------------------------------------------------------------------
.tune_select:       lda #DISABLE
                    sta enable_display
                    lda #BLACK
                    jsr color_song_playing
                    lda cursorpos
                    sta song_pointer
                    sta song_playing
                    +flag_set decrunch_flag
                    lda #DISABLE
                    sta enable_music
                    sta enable_timer
                    sta enable_timer_check
                    lda #0
                    sta 0xD404
                    sta 0xD40B
                    sta 0xD412
                    jmp .key_exit
; ==============================================================================
                    !zone COLCYCLE
                    CYCLE_SPEED = 0x04
do_cycle:           lda #CYCLE_SPEED
                    beq +
                    dec do_cycle+1
                    rts
+                   lda #CYCLE_SPEED
                    sta do_cycle+1
                    ldx .coltab_pt
                    lda colortable,x
                    sta .color+1
                    ldx #0x25
.color:             lda #0x00
                    !for i, 0, 7 {
                        sta 0xD800+(i*40)+1,x
                    }
                    dex
                    bmi +
                    jmp .color
+                   inc .coltab_pt
                    rts
.coltab_pt:         !byte 0x00
; ==============================================================================
                    !zone TIMER
timer_increase:     min_cnt_lo = vidmem1+(15*40)+28
                    sec_cnt_hi = vidmem1+(15*40)+30
                    sec_cnt_lo = vidmem1+(15*40)+31
                    dec .framecounter
                    beq +
                    rts
+                   lda sec_cnt_lo
                    cmp #0x39
                    bne +++
                    lda #0x2F
                    sta sec_cnt_lo
                    lda sec_cnt_hi
                    cmp #0x35
                    bne ++
                    lda #0x2F
                    sta sec_cnt_hi
                    lda min_cnt_lo
                    cmp #0x39
                    bne +
                    lda #0x2F
                    sta min_cnt_lo
+                   inc min_cnt_lo
++                  inc sec_cnt_hi
+++                 inc sec_cnt_lo
                    lda #50
                    sta .framecounter
                    rts
.framecounter:      !byte 50
; ------------------------------------------------------------------------------
timer_check:        min_end_lo = vidmem1+(15*40)+35
                    sec_end_hi = vidmem1+(15*40)+37
                    sec_end_lo = vidmem1+(15*40)+38
+                   lda min_cnt_lo
                    cmp min_end_lo
                    beq +
                    rts
+                   lda sec_cnt_hi
                    cmp sec_end_hi
                    beq +
                    rts
+                   lda sec_cnt_lo
                    cmp sec_end_lo
                    beq +
                    rts
+                   +flag_set tune_end_flag
                    lda #DISABLE
                    sta enable_timer_check
                    rts
; ==============================================================================
                    !zone EXO_DATA
                    !align 255, 0 ,0
                    !bin "sid/action.exo"
s01_end:            !bin "sid/horror.exo"
s02_end:            !bin "sid/intro.exo"
s03_end:            !bin "sid/movingfwd.exo"
s04_end:            !bin "sid/puzzle.exo"
s05_end:            !bin "sid/sadending.exo"
s06_end:
song_end_tab_lo:    !byte <s01_end
                    !byte <s02_end
                    !byte <s03_end
                    !byte <s04_end
                    !byte <s05_end
                    !byte <s06_end
song_end_tab_hi:    !byte >s01_end
                    !byte >s02_end
                    !byte >s03_end
                    !byte >s04_end
                    !byte >s05_end
                    !byte >s06_end
; ==============================================================================
                    !zone SONGDATA
                    ;     0123456789ABCD
s01_title:          !scr "action level  "     ; 0
s02_title:          !scr "horror level  "     ; 1
s03_title:          !scr "introduction  "     ; 2
s04_title:          !scr "moving forward"     ; 3
s05_title:          !scr "puzzle level  "     ; 4
s06_title:          !scr "sad ending    "     ; 5
song_title_tab_lo:  !byte <s01_title
                    !byte <s02_title
                    !byte <s03_title
                    !byte <s04_title
                    !byte <s05_title
                    !byte <s06_title
song_title_tab_hi:  !byte >s01_title
                    !byte >s02_title
                    !byte >s03_title
                    !byte >s04_title
                    !byte >s05_title
                    !byte >s06_title
; ------------------------------------------------------------------------------
s01_time:           !scr "2:00"
s02_time:           !scr "2:17"
s03_time:           !scr "1:05"
s04_time:           !scr "2:37"
s05_time:           !scr "1:50"
s06_time:           !scr "2:05"
song_time_tab_lo:   !byte <s01_time
                    !byte <s02_time
                    !byte <s03_time
                    !byte <s04_time
                    !byte <s05_time
                    !byte <s06_time
song_time_tab_hi:   !byte >s01_time
                    !byte >s02_time
                    !byte >s03_time
                    !byte >s04_time
                    !byte >s05_time
                    !byte >s06_time
; ------------------------------------------------------------------------------
song_playlist:      !byte 0x02
                    !byte 0x00
                    !byte 0x03
                    !byte 0x01
                    !byte 0x04
                    !byte 0x05
                    !byte 0xFF
; ------------------------------------------------------------------------------
song_vidmem_pt_lo:  !byte <vidmem1+(10*40)
                    !byte <vidmem1+(11*40)
                    !byte <vidmem1+(12*40)
                    !byte <vidmem1+(13*40)
                    !byte <vidmem1+(14*40)
                    !byte <vidmem1+(15*40)
song_vidmem_pt_hi:  !byte >vidmem1+(10*40)
                    !byte >vidmem1+(11*40)
                    !byte >vidmem1+(12*40)
                    !byte >vidmem1+(13*40)
                    !byte >vidmem1+(14*40)
                    !byte >vidmem1+(15*40)
; ------------------------------------------------------------------------------
song_pointer:       !byte 0x00
song_playing:       !byte 0x00
; ==============================================================================
                    !zone GFX_DATA
; ------------------------------------------------------------------------------
vidmem_src:         ; 00 - 07 logo
!byte $00,$1B,$1C,$1D,$1D,$1E,$00,$00,$00,$00,$00,$00,$1B,$1E,$00,$00
!byte $00,$00,$00,$00,$23,$24,$1D,$1D,$25,$00,$00,$00,$26,$28,$1D,$1D
!byte $23,$00,$00,$00,$00,$00,$00,$00,$00,$00,$29,$2A,$3B,$00,$00,$00
!byte $00,$00,$3C,$3D,$3E,$3F,$40,$41,$00,$00,$00,$00,$00,$42,$43,$00
!byte $00,$00,$00,$00,$44,$43,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
!byte $00,$00,$29,$2A,$3B,$45,$46,$47,$47,$48,$29,$2A,$49,$4A,$2A,$3B
!byte $4B,$4C,$47,$4D,$00,$42,$43,$4B,$4E,$00,$4B,$4F,$44,$50,$51,$52
!byte $00,$45,$4F,$00,$00,$4B,$4F,$00,$00,$00,$29,$2A,$3B,$44,$53,$54
!byte $55,$56,$29,$2A,$57,$58,$2A,$3B,$42,$59,$54,$5A,$5B,$42,$43,$42
!byte $5C,$00,$42,$43,$44,$5D,$5E,$5F,$00,$44,$50,$5B,$60,$61,$43,$00
!byte $00,$00,$29,$2A,$3B,$44,$43,$00,$44,$62,$29,$2A,$00,$29,$2A,$3B
!byte $42,$5C,$00,$42,$43,$42,$43,$42,$5C,$00,$42,$43,$44,$63,$47,$47
!byte $4D,$44,$64,$65,$66,$2A,$43,$00,$00,$00,$67,$54,$68,$44,$64,$2A
!byte $69,$6A,$67,$54,$00,$67,$54,$68,$42,$6B,$6C,$6D,$00,$6E,$6F,$42
!byte $6B,$6C,$70,$43,$71,$72,$54,$54,$73,$44,$43,$74,$75,$42,$43,$00
!byte $00,$00,$00,$00,$00,$44,$53,$76,$77,$78,$00,$00,$00,$00,$00,$00
!byte $42,$5C,$00,$00,$00,$00,$00,$42,$5C,$00,$42,$43,$00,$00,$00,$00
!byte $00,$44,$43,$00,$00,$42,$43,$00,$00,$00,$00,$00,$00,$44,$43,$79
!byte $7A,$7B,$00,$00,$00,$00,$00,$00,$42,$5C,$00,$00,$00,$00,$00,$42
!byte $5C,$00,$42,$43,$00,$00,$00,$00,$00,$44,$43,$00,$00,$42,$43,$00
                    !fi 40, 0x00
                    !fi 40, 0x00
                    ;scr "0123456789012345678901234567890123456789"
                    !scr " 01.                                    "
                    !scr " 02.                                    "
                    !scr " 03.                                    "
                    !scr " 04.                                    "
                    !scr " 05.                                    "
                    !scr " 06.                        0:00 / 0:00 "
                    !fi 40, 0x00
                    ; 17 - 24 Bitmap
                    !bin "gfx/mountain.scr",,(17*40)
; ------------------------------------------------------------------------------
colram_src:         ; 00 - 07 logo
                    !for i, 0, 7 {
                        !fi 40, GREY
                    }
                    ; 08 - 16 textarea
                    !for i, 8, 14 {
                        !fi 40, 0x00
                    }
                    !fi 28, 0x00
                    !byte 0x01, 0x0F, 0x01, 0x01
                    !byte 0x00, 0x0C, 0x00
                    !byte 0x0C, 0x0F, 0x0C, 0x0C
                    !byte 0x00
                    !fi 40, 0x00
                    ; 17 - 24 Bitmap
                    !bin "gfx/mountain.col",,(17*40)
; ------------------------------------------------------------------------------
bitmap_src:         !bin "gfx/mountain.bmp",,8*(17*40)
; ------------------------------------------------------------------------------
charset_src:        !bin "gfx/logochars.chr"
; ------------------------------------------------------------------------------
colortable:         !for i, 0, 3 {
                        !fi 16, GREY
                        !byte GREY, GREY, GREY, GREY, 0x0C, 0x03, 0x0D, 0x01
                        !fi 16, 0x01
                        !byte 0x01, 0x0D, 0x03, 0x0C, GREY, GREY, GREY, GREY
                        !fi 16, GREY
                    }

; ==============================================================================
code_end:
