{
----------------------------------------------------------------------------------------------------
    Filename:       core.con.sh110x.spin
    Description:    SH110x-specific constants
    Author:         Jesse Burt
    Started:        Jan 25, 2025
    Updated:        Jan 25, 2025
    Copyright (c) 2025 - See end of file for terms of use.
----------------------------------------------------------------------------------------------------
}

CON


    ' timings
    TPOR                = 20_000                ' power-on-reset
    TRW                 = 10                    ' reset low pulse width
    T2                  = 12                    ' reset falling edge to display-on command (min)
    T3                  = 100_000               ' after display-on command

    ' I2C
    I2C_MAX_FREQ        = 400_000               ' max according to datasheet
    SLAVE_ADDR          = $3C << 1
    CTRLBYTE_CMD        = $00
    CTRLBYTE_DATA       = $40

    ' SPI
    SPI_MAX_FREQ        = 10_000_000            ' max according to datasheet
    SPI_MODE            = 3


    FOSC_MIN            = 540
    FOSC_MAX            = 1080


    ' command set
    SET_COLADDR_L       = $00
    SET_COLADDR_H       = $10
    MEM_ADDRMODE        = $20

    CONTRAST            = $81

    SEG_MAP0            = $a0
    SEG_MAP127          = $a1
    RAMDISP_ON          = $a4
    ENTDISP_ON          = $a5
    DISP_NORM           = $a6
    DISP_INVERT         = $a7
    SETMUXRATIO         = $a8

    DCDC_CTRL_MD        = $ad
    DCDC_CTRL_MD_MASK   = $8f
        DC_SWF          = 1
        DC_ENA          = 0
        DC_SWF_BITS     = %111
        DC_SWF_MASK     = (DC_SWF_BITS << DC_SWF) ^ DCDC_CTRL_MD_MASK
        DC_ENA_MASK     = 1 ^ DCDC_CTRL_MD_MASK

    DISP_OFF            = $ae
    DISP_ON             = $af

    SET_PAGEADDR        = $b0

    COMDIR_NORM         = $c0
    COMDIR_RMAP         = $c8

    SETDISPOFFS         = $d3

    SETOSCFREQ          = $d5
    SETOSCFREQ_MASK     = $ff
        OSCFREQ         = 4
        CLKDIV          = 0
        OSCFREQ_BITS    = %1111
        CLKDIV_BITS     = %1111
        OSCFREQ_MASK    = (OSCFREQ_BITS << OSCFREQ) ^ SETOSCFREQ_MASK
        CLKDIV_MASK     = (CLKDIV_BITS << CLKDIV) ^ SETOSCFREQ_MASK

    SETPRECHARGE        = $d9
        DISCHARGE_PER   = 4
        PRECHARGE_PER   = 0
        PERIOD_BITS     = %1111

    SETVCOMDESEL        = $db
        VCOMH           = 0

    DISP_STLINE         = $dc

    RD_MODIFY_WR        = $e0
    NOOP                = $e3
    RD_MODIFY_WR_END    = $ee


PUB null()
' This is not a top-level object


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

