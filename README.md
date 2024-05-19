# PlayVGM

This is a (so-far) rudimentary player for OPL2/OPL3 VGM files on the
[Foenix F256K](https://c256foenix.com/product-category/f256-products/f256k/).

## Music Files

You can find VGM files to use with this at [vgmrips.net](https://vgmrips.net/),
specifically the [YMF262](https://vgmrips.net/packs/chip/ymf262) (OPL3) and
[YM3812](https://vgmrips.net/packs/chip/ym3812) (OPL2) sections.

The player doesn't yet know how to parse VGM or GD3 headers, nor can it handle
compressed VGZ files, so any files downloaded from the links above need to be
uncompressed and have their headers stripped. The included python script
[`convert.py`](util/convert.py) can be used to do this.

## Usage

At some point I may add a nicer text UI, but for now, to use the player,
first load the processed VGM file into memory at `$010000`, and then invoke
the player, like this:

```
bload "example.bin", $010000
/- playvgm.pgx
```

Currently, the player will loop forever until the computer is reset.

## Building

The player was written using [ca65](https://cc65.github.io/doc/ca65.html)
assembly syntax. To build it, you will need the following build dependencies
to be installed:

* [cc65](https://cc65.github.io/) (really just `ca65` and `ld65` are required)
* [Python 3](https://www.python.org/) (for generating dependency files)
* [GNU Make](https://www.gnu.org/software/make/)

Once these are installed (and available on your shell's search path), you can
build the player by navigating to the repository root and issuing the command:

```
make
```

This will produce the player binary in a file named `playvgm.pgx`.
