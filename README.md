# sh110x-spin
-------------

This is a P8X32A/Propeller 1, P2X8C4M64P/Propeller 2 driver object for the Sino Wealth SH110x OLED display controller.

**IMPORTANT**: This software is meant to be used with the [spin-standard-library](https://github.com/avsa242/spin-standard-library) (P8X32A) or [p2-spin-standard-library](https://github.com/avsa242/p2-spin-standard-library) (P2X8C4M64P). Please install the applicable library first before attempting to use this code, otherwise you will be missing several files required to build the project.

## Salient Features

* I2C connection at up to approx 400kHz (unenforced)
* SPI connection at fixed 4MHz (P1), up to 10MHz (P2, unenforced)
* Supports up to 128x128px displays
* Display mirroring (horizontal and vertical)
* Display visibility modes: normal, inverted, all pixels on
* Variable contrast
* Low-level display control: Logic voltages, oscillator frequency, addressing mode
* Supports display modules with or without discrete RESET pin
* Integration with the generic bitmap graphics library
* Buffered display or direct-to-display drawing (*see 'Limitations' for direct-to-display*)


## Requirements

P1/SPIN1:
* spin-standard-library
* P1/SPIN1: 1 extra core/cog for the PASM I2C or SPI engine, as applicable
* graphics.common.spinh (provided by spin-standard-library)
* `(WIDTH * HEIGHT) / 8` bytes of RAM for the display, if buffered mode is used (default)

P2/SPIN2:
* p2-spin-standard-library
* graphics.common.spin2h (provided by p2-spin-standard-library)
* `(WIDTH * HEIGHT) / 8` bytes of RAM for the display, if buffered mode is used (default)


## Compiler Compatibility

| Processor | Language | Compiler               | Backend      | Status                |
|-----------|----------|------------------------|--------------|-----------------------|
| P1        | SPIN1    | FlexSpin (6.9.4)       | Bytecode     | OK                    |
| P1        | SPIN1    | FlexSpin (6.9.4)       | Native/PASM  | OK                    |
| P2        | SPIN2    | FlexSpin (6.9.4)       | NuCode       | Not yet implemented   |
| P2        | SPIN2    | FlexSpin (6.9.4)       | Native/PASM2 | Not yet implemented   |

(other versions or toolchains not listed are __not supported__, and _may or may not_ work)


## Hardware Compatibility

* Tested with Adafruit SH1107, 1.12" (P/N 5297)


## Limitations

* Doesn't support parallel interface-connected displays (currently unplanned)
* Unbuffered/Direct-draw operations are limited, due to the nature of serial 1bpp displays. box(), line(), circle and plot() aren't implemented. Don't `#define GFX_DIRECT` if you need these.

