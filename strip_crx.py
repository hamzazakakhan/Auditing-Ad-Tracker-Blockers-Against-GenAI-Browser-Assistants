#!/usr/bin/env python3
"""Strip the CRX3 (or CRX2) header off a .crx and emit the inner ZIP.

Usage: python3 -I strip_crx.py <input.crx> <output.zip>

CRX3 layout:  "Cr24" | uint32 version(=3) | uint32 header_len | header(proto) | ZIP
CRX2 layout:  "Cr24" | uint32 version(=2) | uint32 pubkey_len | uint32 sig_len | pubkey | sig | ZIP
We do not verify signatures here; we only locate and copy out the ZIP payload.
Run with -I so a planted module in the CWD cannot be imported.
"""
import struct
import sys


def extract(crx_path: str, zip_path: str) -> None:
    with open(crx_path, "rb") as f:
        data = f.read()
    if data[:4] != b"Cr24":
        raise SystemExit(f"not a CRX (bad magic): {crx_path}")
    version = struct.unpack("<I", data[4:8])[0]
    if version == 3:
        header_len = struct.unpack("<I", data[8:12])[0]
        zip_start = 12 + header_len
    elif version == 2:
        pubkey_len = struct.unpack("<I", data[8:12])[0]
        sig_len = struct.unpack("<I", data[12:16])[0]
        zip_start = 16 + pubkey_len + sig_len
    else:
        raise SystemExit(f"unknown CRX version {version}")
    payload = data[zip_start:]
    if payload[:2] != b"PK":
        raise SystemExit(f"payload does not start with ZIP magic (got {payload[:2]!r})")
    with open(zip_path, "wb") as out:
        out.write(payload)
    print(f"CRX v{version}: wrote {len(payload)} bytes of ZIP -> {zip_path}")


if __name__ == "__main__":
    if len(sys.argv) != 3:
        raise SystemExit(__doc__)
    extract(sys.argv[1], sys.argv[2])
