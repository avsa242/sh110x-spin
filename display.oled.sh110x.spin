{
----------------------------------------------------------------------------------------------------
    Filename:       display.oled.sh110x.spin
    Description:    Driver for Sino Wealth SH110x OLED displays
    Author:         Jesse Burt
    Started:        Jan 25, 2025
    Updated:        Jan 25, 2025
    Copyright (c) 2024 - See end of file for terms of use.
----------------------------------------------------------------------------------------------------
}

#define 1BPP
#define MEMMV_NATIVE bytemove
#include "graphics.common.spinh"

CON

    { /// default I/O settings; these can be overridden in the parent object }
    { display dimensions }
    WIDTH       = 128
    HEIGHT      = 128
    XMAX        = WIDTH-1
    YMAX        = HEIGHT-1
    CENTERX     = WIDTH/2
    CENTERY     = HEIGHT/2

    { I2C }
    SCL         = 28
    SDA         = 29
    RST         = 0
    I2C_FREQ    = 100_000
    I2C_ADDR    = 0

    { SPI }
    CS          = 0
    SCK         = 1
    MOSI        = 2
    DC          = 3
    RST         = 0

    { /// }

    BPP         = 1                             ' bits per pixel/color depth of the display
    BYTESPERPX  = 1 #> (BPP/8)                  ' limit to minimum of 1
    BPPDIV      = BYTESPERPX #> (8 / BPP)       ' limit to range BYTESPERPX .. (8/BPP)
    BUFF_SZ     = (WIDTH * HEIGHT) / BPPDIV
    MAX_COLOR   = (1 << BPP)-1


    SLAVE_WR    = core.SLAVE_ADDR
    SLAVE_RD    = core.SLAVE_ADDR|1


' States for D/C pin
    DATA        = 1
    CMD         = 0

' Display visibility modes
    NORMAL      = 0
    ALL_ON      = 1
    INVERTED    = 2

' Addressing modes
    PAGE        = 0
    VERT        = 1


OBJ

    core:   "core.con.sh110x"
    time:   "time"

#ifdef SH110X_SPI
    spi:    "com.spi.4mhz"                      ' SPI engine

#else

{ default to I2C }
#define SH110X_I2C
    i2c:    "com.i2c"                           ' I2C engine

#endif


VAR

    long _CS, _DC, _RES
    byte _addr_bits
    byte _framebuffer[BUFF_SZ]

    ' shadow registers
    byte _clkfreq_oscdiv, _dcdc_conv


PUB null()
' This is not a top-level object


#ifdef SH110X_I2C
PUB start(): status
' Start using default I/O settings
    return startx(SCL, SDA, RST, I2C_FREQ, I2C_ADDR, WIDTH, HEIGHT, @_framebuffer)


PUB startx(SCL_PIN, SDA_PIN, RES_PIN, I2C_HZ, ADDR_BITS, DISP_WID, DISP_HT, p_disp): status
' Start the driver with custom I/O settings
'   SCL_PIN:    I2C serial clock pin, 0..31
'   SDA_PIN:    I2C serial data pin, 0..31
'   RES_PIN:    display reset pin, 0..31 (optional; use -1 to disable)
'   I2C_HZ:     I2C bus speed in Hz; max official is 400_000 (unenforced)
'   ADDR_BITS:  0, 1
'   DISP_WID:   display width in pixels
'   DISP_HT:    display height in pixels
    if ( lookdown(SCL_PIN: 0..31) and lookdown(SDA_PIN: 0..31) )
        if ( status := i2c.init(SCL_PIN, SDA_PIN, I2C_HZ) )
            time.usleep(core.TPOR)              ' wait for device startup
            _addr_bits := ( (ADDR_BITS <> 0) & 1) << 1
            _RES := RES_PIN                     ' -1 to disable
            reset()
            if ( i2c.present(SLAVE_WR | _addr_bits) )
                _disp_width := DISP_WID
                _disp_height := DISP_HT
                _disp_xmax := _disp_width-1
                _disp_ymax := _disp_height-1
                ' calc display memory usage from dimensions and 1bpp depth
                _buff_sz := (_disp_width * _disp_height) / 8
                _bytesperln := _disp_width * BYTESPERPX
                set_address(p_disp)             ' set display buffer address
#ifdef GFX_DIRECT
                'xxx fixme - this just gets overruled by set_font() in the graphics lib
                'xxx unless it's called before calling this method
                set_putchar(@putchar_90deg_1bpp)
#endif
                return
    ' if this point is reached, something above failed
    ' Re-check I/O pin assignments, bus speed, connections, power
    ' Lastly - make sure you have at least one free core/cog
    return FALSE
#elseifdef SH110X_SPI
PUB start(): status
' Start the driver using default I/O settings
    return startx(CS, SCK, MOSI, DC, RST, WIDTH, HEIGHT, @_framebuffer)


PUB startx(CS_PIN, SCK_PIN, MOSI_PIN, DC_PIN, RES_PIN, DISP_WID, DISP_HT, p_disp): status
' Start the driver with custom I/O settings
'   CS_PIN:     display chip select pin, 0..31
'   SCK_PIN:    SPI serial clock pin, 0..31
'   MOSI_PIN:   SPI master-out slave-in pin, 0..31 (may be labeled SI, SDIN, etc)
'   DC_PIN:     I2C bus speed in Hz; max official is 400_000 (unenforced)
'   RES_PIN:    display reset pin, 0..31 (optional; use -1 to disable)
'   DISP_WID:   display width in pixels
'   DISP_HT:    display height in pixels
'   p_disp:     pointer to display buffer
    if ( lookdown(CS_PIN: 0..31) and lookdown(SCK_PIN: 0..31) and lookdown(MOSI_PIN: 0..31) and ...
        lookdown(DC_PIN: 0..31) )
        if ( status := spi.init(SCK_PIN, MOSI_PIN, -1, core.SPI_MODE) )
            time.usleep(core.TPOR)              ' wait for device startup
            _CS := CS_PIN
            _DC := DC_PIN
            _RES := RES_PIN                     ' -1 to disable
            reset()
            outa[_CS] := 1
            dira[_CS] := 1
            outa[_DC] := 0
            dira[_DC] := 1
            _disp_width := DISP_WID
            _disp_height := DISP_HT
            _disp_xmax := _disp_width-1
            _disp_ymax := _disp_height-1
            ' calc display memory usage from dimensions and 1bpp depth
            _buff_sz := (_disp_width * _disp_height) / 8
            _bytesperln := _disp_width * BYTESPERPX
            set_address(p_disp)                 ' set display buffer address
#ifdef GFX_DIRECT
            set_putchar(@putchar_90deg_1bpp)
#endif
            return
    ' if this point is reached, something above failed
    ' Re-check I/O pin assignments, bus speed, connections, power
    ' Lastly - make sure you have at least one free core/cog
    return FALSE
#endif


PUB stop()
' Stop the driver
    powered(FALSE)
#ifdef SH110X_I2C
    i2c.deinit()
#elseifdef SH110X_SPI
    spi.deinit()
#endif


pub preset_adafruit_1p12_128x128()
' Preset settings:
'   Adafruit 1.12" SH1107, 128x128 (P/N 5297)
    powered(false)
    clk_div(1)
    clk_freq(1080)
    addr_mode(PAGE)
    contrast(31)
    dcdc_switch_freq(550_000)
    dcdc_enabled(false)
    mirror_h(false)
    mirror_v(false)
    disp_start_line(0)
    disp_offset(0)
    precharge_period(2, 2)
    vcomh_voltage(770)
    disp_lines(128)
    visibility(NORMAL)
    time.msleep(100)
    powered(true)


PUB addr_mode(m)
' Set Memory Addressing Mode
'   m:  addressing mode
'       0: Page (default)
'       1: Vertical
    if ( (m == PAGE) or (m == VERT) )
        command(core.MEM_ADDRMODE | m)


#ifdef GFX_DIRECT
PUB bitmap(p_bmap, sx, sy, w, h) | p
' Display bitmap
'   p_bmap:     pointer to bitmap data
'   (sx, sy):   upper-left corner of bitmap
'   (w, h):     dimensions of bitmap data
    repeat p from 0 to (h/8)-1
        set_col(sx)
        set_page( (sy/8)+p )
        data_blk(p_bmap, w)
        p_bmap += w
#endif

#ifdef GFX_DIRECT
PUB box(sx, sy, ex, ey, c, f=false)
#endif

PUB clear(ptn=-1) | p
' Clear the display
'   ptn:    bit pattern to clear display with (optional; default is 0, or solid black)
    if ( ptn < 0 )                              ' if no color is spec'd, just use the current
        ptn := _bgcolor                         '   background color
#ifdef GFX_DIRECT
    repeat p from 0 to _disp_height/8           ' write pattern to every page
        set_page(p)
# ifdef SH110X_SPI
        outa[_DC] := DATA
        outa[_CS] := 0
        spi.wr_bytex(ptn, _disp_width)
        outa[_CS] := 1
# else
        i2c.start()
        i2c.write(SLAVE_WR | _addr_bits)
        i2c.write(core.CTRLBYTE_DATA)
        i2c.wr_bytex(ptn, _disp_width)
        i2c.stop()
# endif
#else
    bytefill(_ptr_drawbuffer, ptn, _buff_sz)
'    longfill(_ptr_drawbuffer, ptn, _buff_sz/4)

#endif


PUB clk_div(d)
' Set display clock divider
'   d:  1..16 (clamped to range; POR default is 1)
    _clkfreq_oscdiv := (_clkfreq_oscdiv & core.CLKDIV_MASK) | ( (0 #> d <# 16)-1)
    command(core.SETOSCFREQ, _clkfreq_oscdiv)


PUB clk_freq(f)
' Set display internal oscillator frequency, in kHz
'   freq:   540, 576, 612, 648, 684, 720, 756, 792, 828, 864, 900, 936, 972, 1008, 1044, 1080
'       (default is 720; specified frequency will be rounded to the nearest valid one)
    _clkfreq_oscdiv :=  (_clkfreq_oscdiv & core.OSCFREQ_MASK) ...
                        | ( ( (core.FOSC_MIN #> f <# core.FOSC_MAX) - 540) / 36) << core.OSCFREQ
    command(core.SETOSCFREQ, _clkfreq_oscdiv)


PUB contrast(l)
' Set Contrast Level
'   l: 0..255 (clamped to range; default: 128)
    command(core.CONTRAST, (0 #> l <# 255) )


PUB dcdc_enabled(e)
' Enable internal DC-DC voltage converter
'   e:  TRUE (non-zero values), FALSE (0)
    _dcdc_conv :=   (_dcdc_conv & core.DC_ENA_MASK) | ...
                    ( ( (e <> 0) & 1) == 1)
    command(core.DCDC_CTRL_MD, _dcdc_conv)


PUB dcdc_switch_freq(f)
' Set internal DC-DC voltage converter switching frequency
'   f:  300_000..650_000 (clamped to range; default: 300_000)
    _dcdc_conv :=   (_dcdc_conv & core.DC_SWF_MASK) | ...
                    ( ( (f-300_000) / 43_750) << core.DC_SWF)
    command(core.DCDC_CTRL_MD, _dcdc_conv)


PUB disp_lines(l)
' Set total number of display lines
'   l:  1..128 (clamped to range; default: 128)
    command(core.SETMUXRATIO, ( (1 #> l <# 128)-1) )


PUB disp_offset(o)
' Set display offset/vertical shift
'   Valid values: 0..127 (default: 0)
'   Any other value sets the default value
    command(core.SETDISPOFFS, (0 #> o <# 127) )


PUB disp_start_line(l)
' Set Display Start Line
'   Valid values: 0..127 (clamped to range; default: 0)
'   Any other value sets the default value
    command(core.DISP_STLINE, (0 #> l <# 127) )


PUB invert_colors(s)
' Invert display colors
    if ( s )
        visibility(INVERTED)
    else
        visibility(NORMAL)


PUB mirror_h(m)
' Mirror display, horizontally
'   m:  TRUE (non-zero), *FALSE (0)
'   NOTE: Takes effect only after next display update
    command(core.COMDIR_NORM | (m <> 0) ? 8 : 0 )


PUB mirror_v(m)
' Mirror display, vertically
'   m:  TRUE (non-zero), *FALSE (0)
'   NOTE: Takes effect only after next display update
    command(core.SEG_MAP0 | ( (m <> 0) & 1) )


PUB plot(x, y, color)
' Plot pixel at (x, y) in color
    if ( (x < 0) or (x > _disp_xmax) or (y < 0) or (y > _disp_ymax) )
        return                                  ' coords out of bounds, ignore
#ifdef GFX_DIRECT
' direct to display
'   (not implemented)
#else
' buffered display
    case color
        1:
            byte[_ptr_drawbuffer][x + (y>>3) * _disp_width] |= (|< (y&7))
        0:
            byte[_ptr_drawbuffer][x + (y>>3) * _disp_width] &= !(|< (y&7))
        -1:
            byte[_ptr_drawbuffer][x + (y>>3) * _disp_width] ^= (|< (y&7))
        other:
            return
#endif


#ifndef GFX_DIRECT
PUB point(x, y): pix_clr
' Get color of pixel at x, y
    x := 0 #> x <# _disp_xmax
    y := 0 #> y <# _disp_ymax

    return (byte[_ptr_drawbuffer][(x + (y >> 3) * _disp_width)] & (1 << (y & 7)) <> 0) * -1
#endif


PUB powered(p)
' Enable display power
'   Valid values: TRUE (non-zero), FALSE (0)
    command( core.DISP_OFF + ( (p <> 0) & 1) )


PUB precharge_period(dp, pp)
' Set display refresh pre-charge period, in display clocks
'   dp: discharge period (1..15; clamped to range; default: 2)
'   pp: precharge period (0..15; clamped to range; default: 2)
    dp := (1 #> dp <# 15) << core.DISCHARGE_PER
    pp := (0 #> pp <# 15)
    command(core.SETPRECHARGE, (dp | pp) )


#ifdef GFX_DIRECT
PUB tx = putchar                                ' these two are aliases to the function pointer
PUB char = putchar                              ' `putchar`, which points to a low-level routine
PUB putchar_90deg_1bpp(ch) | ch_offs
' Low-level character rendering routine
'   For font file definitions with these characteristics:
'   * 90 degrees rotation (landscape)
'   * each glyph word is a column of the glyph, e.g. for 5x8 'A':
'       %01111100
'       %00010010
'       %00010001
'       %00010010
'       %01111100
    if ( (ch < _fnt_cmin) or (ch > _fnt_cmax) ) ' don't waste any time if the char is invalid
        return

    if ( _char_attrs & TERMINAL )
        ' process control characters, don't draw them
        case ch
            LF:
                ' line feed
                _charpx_y += _charcell_h        ' goto next text row
                if ( _charpx_y > _charpx_ymax ) ' if the last row is reached,
                    _charpx_y -= _charcell_h    '   stay there
                return
            CR:
                ' carriage return
                _charpx_x := 0                  ' goto first text column
                return

    ch_offs := _font_addr + (ch * _fnt_width)

    if ( _char_attrs & DRAWBG )                 ' erase the background
        data_blk(_font_addr+(32*_fnt_width), 5)
    bitmap(ch_offs, _charpx_x, _charpx_y, _fnt_width, _fnt_height)
    _charpx_x += _charcell_w                    ' go to next column
    if (_charpx_x > _charpx_xmax)               ' last col?
        _charpx_x := 0                          ' go to first col of
        _charpx_y += _charcell_h                '   next line
        if (_charpx_y > _charpx_ymax)           ' last col of last row?
            _charpx_x := _charpx_y := 0         ' wrap to beginning of disp
#endif


PUB reset()
' Reset the display controller
    if (lookdown(_RES: 0..31))
        outa[_RES] := 1
        dira[_RES] := 1
        time.usleep(3)
        outa[_RES] := 0
        time.usleep(core.TRW)
        outa[_RES] := 1


PUB set_col(c)
' Set display column
'   c: 0..127
    c := 0 #> c <# 127
    command(core.SET_COLADDR_L | (c & $f) )     ' write lower 4 bits, then upper 3 bits of column
    command(core.SET_COLADDR_H | ( (c >> 4) & 7) )


PUB set_page(p)
' Set display page
'   p:  0..15 (clamped to range)
    command(core.SET_PAGEADDR | (0 #> p <# 15) )


PUB show = wr_buffer
' Write display buffer to display


PUB vcomh_voltage(v)
' Set COM output voltage, in millivolts
'   v:  430..834, 1_000 (nearest possible value will be used; POR default is 770)
    v := ( (v * 1_000) / 0_006415)-67           ' scale mV to $00..$3f
    if ( v > 834 )
        v := $40                                ' $40..$ff == 1.000V
    command(core.SETVCOMDESEL, v)

PUB visibility(m)
' Set display visibility
    case m
        NORMAL:
            command(core.RAMDISP_ON)
            command(core.DISP_NORM)
        ALL_ON:
            command(core.RAMDISP_ON | 1)
        INVERTED:
            command(core.DISP_NORM | 1)
        other:
            return

PUB wr_buffer(p_buff=0) | p
' Write a buffer to display
'   p_buff: pointer to buffer to write to display (optional; default writes the internal buffer)
'   NOTE: Does not set position on display
    ifnot ( p_buff )                                ' no buffer specified?
        p_buff := _ptr_drawbuffer                   '   then write the internal display buffer

    repeat p from 0 to (_disp_height/8)-1           ' write every page to the display
        set_col(0)
        set_page(p)
        data_blk(p_buff, _disp_width)
        p_buff += _disp_width


PRI command(c, v=-1) | cmd_pkt, l
' Issue command to device, with optional parameter
'   c:  command
'   v:  single-byte parameter/value (optional; ignored if unused)
    l := 0
    cmd_pkt.byte[l++] := SLAVE_WR | _addr_bits
    cmd_pkt.byte[l++] := core.CTRLBYTE_CMD
    cmd_pkt.byte[l++] := c
    if ( v => 0 )
        cmd_pkt.byte[l++] := v

#ifdef SH110X_SPI
    outa[_DC] := CMD
    outa[_CS] := 0
    spi.wr_byte(c)
    if ( v => 0 )
        spi.wr_byte(v)
    outa[_CS] := 1
#else
    i2c.start()
    i2c.wrblock_lsbf(@cmd_pkt, l)
    i2c.stop()
#endif

PRI data_blk(p_data, len)
' Write a block of graphic data to the screen
'   p_data: pointer to data
'   len:    length of data in bytes
#ifdef SH110X_SPI
    outa[_DC] := DATA
    outa[_CS] := 0
    spi.wrblock_lsbf(p_data, len)
    outa[_CS] := 1
#else
    i2c.start()
    i2c.write(SLAVE_WR | _addr_bits)
    i2c.write(core.CTRLBYTE_DATA)
    i2c.wrblock_lsbf(p_data, len)
    i2c.stop()
#endif


#ifndef GFX_DIRECT
PRI memfill(xs, ys, val, count)
' Fill region of display buffer memory
'   xs, ys: Start of region
'   val: Color
'   count: Number of consecutive memory locations to write
    bytefill(_ptr_drawbuffer + (xs + (ys * _bytesperln)), val, count)
#endif

#include "termwidgets.spinh"


DAT
{
Copyright 2025 Jesse Burt

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and
associated documentation files (the "Software"), to deal in the Software without restriction,
including without limitation the rights to use, copy, modify, merge, publish, distribute,
sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or
substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT
NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT
OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
}

