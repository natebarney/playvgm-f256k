#!/usr/bin/env python3

import gzip
import logging
import os
import struct
from typing import BinaryIO

LOGGER = logging.getLogger("convert")
MAGIC = b"Vgm "

# format documented at https://vgmrips.net/wiki/VGM_Specification
def read_vgm(file: BinaryIO) -> bytes:

    # get VGM version
    file.seek(0x08, os.SEEK_SET)
    version = struct.unpack("<I", file.read(4))[0]

    # get GD3 offset
    file.seek(0x14, os.SEEK_SET)
    gd3_offset = struct.unpack("<I", file.read(4))[0]
    if gd3_offset != 0:
        gd3_offset += 0x14

    # get VGM data offset
    if version < 0x150:
        vgm_offset = 0x40
    else:
        file.seek(0x34, os.SEEK_SET)
        vgm_offset = struct.unpack("<I", file.read(4))[0]
        if vgm_offset == 0:
            vgm_offset = 0x40
        else:
            vgm_offset += 0x34

    # read and return the VGM data
    file.seek(vgm_offset, os.SEEK_SET)
    if gd3_offset != 0:
        return file.read(gd3_offset - vgm_offset)
    return file.read()

def convert(inputfile: str, outputfile: str):

    with open(inputfile, "rb") as infp:
        magic = infp.read(len(MAGIC))
        if magic != MAGIC:
            infp.seek(0, os.SEEK_SET)
            with gzip.open(inputfile, "rb") as gzfp:
                magic = gzfp.read(len(MAGIC))
                if magic != MAGIC:
                    raise ValueError("Invalid magic")
                data = read_vgm(gzfp)
        else:
            data = read_vgm(infp)

    with open(outputfile, "wb") as outfp:
        outfp.write(data)

if __name__ == "__main__":

    import argparse

    logging.basicConfig(level=logging.WARNING)

    parser = argparse.ArgumentParser()
    parser.add_argument("input", help="Input VGM or VGZ file")
    parser.add_argument("output", help="Output BIN file")
    args = parser.parse_args()


    try:
        convert(args.input, args.output)
    except (gzip.BadGzipFile, ValueError):
        LOGGER.error("Invalid VGM or VGZ file")
