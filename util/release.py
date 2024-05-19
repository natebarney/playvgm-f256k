#!/usr/bin/env python3

import os
from typing import List
from zipfile import ZipFile, ZIP_DEFLATED

def make_release(files: List[str], version: str):

    with ZipFile(f"playvgm-{version}.zip", "w", ZIP_DEFLATED) as zipfp:

        for file in files:
            basename = os.path.basename(file)
            with open(file, "rb") as infp, zipfp.open(basename, "w") as outfp:
                outfp.write(infp.read())

if __name__ == "__main__":

    import argparse

    parser = argparse.ArgumentParser()
    parser.add_argument("version")
    args = parser.parse_args()

    make_release(
        [
            "LICENSE",
            "README.md",
            os.path.join("util", "convert.py"),
            "playvgm.pgx",
        ],
        args.version,
    )
