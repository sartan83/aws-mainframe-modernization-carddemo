#!/usr/bin/env python3
"""One time migration of the CardDemo sample data from a 16 digit card
number to a 17 digit card number.

Every existing 16 digit card number is left padded with a single '0' so
that it stays a valid card number under the new 17 digit layout. Record
lengths are preserved by dropping the last byte of the trailing FILLER of
each record layout, exactly like the COBOL copybooks do.

This is a one time migration: running it twice would pad the card number
twice. Use --check to report what would be rewritten without touching any
file.

Usage:
    python3 scripts/migrate_card_num_17.py [--check]
"""

import argparse
import os
import sys

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ASCII_DIR = os.path.join(REPO, "app", "data", "ASCII")
EBCDIC_DIR = os.path.join(REPO, "app", "data", "EBCDIC")

# Zero based offset of the card number inside each fixed length record.
CARD_FILE = 0     # CVACT02Y  CARD-NUM
XREF_FILE = 0     # CVACT03Y  XREF-CARD-NUM
TRAN_FILE = 262   # CVTRA05Y  TRAN-CARD-NUM / CVTRA06Y DALYTRAN-CARD-NUM

# Fixed length files: name -> (record length, card offset, trim filler).
# The ASCII cross reference extract carries no trailing FILLER, so its
# records grow by one byte instead of borrowing from the filler.
FLAT_FILES = {
    "carddata.txt": (150, CARD_FILE, True),
    "cardxref.txt": (36, XREF_FILE, False),
    "dailytran.txt": (350, TRAN_FILE, True),
    "AWS.M2.CARDDEMO.CARDDATA.PS": (150, CARD_FILE, True),
    "AWS.M2.CARDDEMO.CARDXREF.PS": (50, XREF_FILE, True),
    "AWS.M2.CARDDEMO.DALYTRAN.PS": (350, TRAN_FILE, True),
    "AWS.M2.CARDDEMO.DALYTRAN.PS.INIT": (350, TRAN_FILE, True),
}

# CVEXPORT multi record layout: 40 byte header + 460 byte data area. Only
# the record types carrying a card number are shifted.
EXPORT_FILE = "AWS.M2.CARDDEMO.EXPORT.DATA.PS"
EXPORT_RECLEN = 500
EXPORT_HEADER = 40
EXPORT_CARD_OFFSET = {
    "X": EXPORT_HEADER + 0,    # EXP-XREF-CARD-NUM
    "D": EXPORT_HEADER + 0,    # EXP-CARD-NUM
    "T": EXPORT_HEADER + 252,  # EXP-TRAN-CARD-NUM
}


def pad_record(record, offset, zero, trim):
    """Insert a zero at offset, borrowing a byte from the trailing filler."""
    tail = record[offset:-1] if trim else record[offset:]
    return record[:offset] + zero + tail


def migrate_flat(path, reclen, offset, trim, ebcdic, check):
    with open(path, "rb") as handle:
        data = handle.read()
    # The ASCII files are line oriented, the EBCDIC files are not.
    newline = b"\n" if data.endswith(b"\n") else b""
    stride = reclen + len(newline)
    if len(data) % stride:
        raise SystemExit("%s is not a multiple of %d bytes" % (path, stride))
    zero = b"\xf0" if ebcdic else b"0"
    out = bytearray()
    changed = 0
    for start in range(0, len(data), stride):
        record = pad_record(data[start:start + reclen], offset, zero, trim)
        changed += 1
        out += record + newline
    if changed and not check:
        with open(path, "wb") as handle:
            handle.write(bytes(out))
    return changed


def migrate_export(path, check):
    with open(path, "rb") as handle:
        data = handle.read()
    if len(data) % EXPORT_RECLEN:
        raise SystemExit("%s is not a multiple of %d bytes"
                         % (path, EXPORT_RECLEN))
    zero = b"\xf0"
    types = {key.encode("cp037"): offset
             for key, offset in EXPORT_CARD_OFFSET.items()}
    out = bytearray()
    changed = 0
    for start in range(0, len(data), EXPORT_RECLEN):
        record = data[start:start + EXPORT_RECLEN]
        offset = types.get(record[:1])
        if offset is not None:
            record = pad_record(record, offset, zero, True)
            changed += 1
        out += record
    if changed and not check:
        with open(path, "wb") as handle:
            handle.write(bytes(out))
    return changed


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()

    total = 0
    for name, (reclen, offset, trim) in sorted(FLAT_FILES.items()):
        for directory in (ASCII_DIR, EBCDIC_DIR):
            path = os.path.join(directory, name)
            if not os.path.exists(path):
                continue
            changed = migrate_flat(path, reclen, offset, trim,
                                   directory == EBCDIC_DIR, args.check)
            total += changed
            print("%-60s %6d records" % (os.path.relpath(path, REPO), changed))

    export = os.path.join(EBCDIC_DIR, EXPORT_FILE)
    if os.path.exists(export):
        changed = migrate_export(export, args.check)
        total += changed
        print("%-60s %6d records" % (os.path.relpath(export, REPO), changed))

    print("%d records" % total)
    return 0


if __name__ == "__main__":
    sys.exit(main())
