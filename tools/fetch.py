#!/usr/bin/env python3
"""Fetch the player's own copy of Athena into data/ and prove it is the right one.

Nothing this script downloads is ever committed (see docs/licence.md). Every file
is checked against digests published by someone other than us - the Internet
Archive's item metadata and ZXDB's md5/sha512 table - so a file that verifies here
is the same file those catalogues describe, byte for byte.

If you already have the files, put them in data/ under the names below and run
this anyway: it verifies what is there and downloads nothing.

    python3 tools/fetch.py [--via "ssh user@host"]

--via (or FETCH_VIA) runs curl on another machine and streams the bytes back. It
exists because some networks block Spectrum Computing; the digest check makes the
relay irrelevant to trust.
"""

import argparse
import hashlib
import io
import os
import shlex
import subprocess
import sys
import zipfile

DATA = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "data")

# name in data/, source URL, size, {algorithm: digest}, who published the digest.
FILES = [
    {
        "name": "athena128.z80",
        "url": "https://archive.org/download/zx_Athena_1987_Imagine_Software_a_128K/"
               "Athena_1987_Imagine_Software_a_128K.z80",
        "size": 108395,
        "digests": {
            "md5": "93d7ca3c1dbc668593400a7b57ea4e4e",
            "sha512": "2428430c7464c0b853ae2bc277049ad388f6719ed42ff84055e792d345aa1573"
                      "7931b7bf71e7adaeaa9f01d58566f7bf129e1b664dbc03d9440aa2c42a7b5473",
        },
        "published_by": "archive.org item metadata (md5); ZXDB md5hash table for "
                        "Athena128.z80.zip/ATHEN128.Z80 (md5, sha512)",
    },
    {
        "name": "athena.rzx",
        "url": "https://archive.org/download/rzxarchive/athena.rzx",
        "size": 240835,
        "digests": {
            "md5": "6b85f1d4f7635361f72fbaa1ca0d9664",
            "sha1": "33a6ff5ae4ea11608d42185824982d46004eecdc",
        },
        "published_by": "archive.org rzxarchive item metadata",
    },
    {
        "name": "athena128.tzx",
        "url": "https://spectrumcomputing.co.uk/pub/sinclair/games/a/Athena.tzx.zip",
        "member": "Athena - 128k.tzx",
        "digests": {
            "md5": "a82fe06b8600a0fbaedf7b927553b425",
            "sha512": "0bff0ddef21400ff79f96206890420ddcf7e04dfc75969fc212ac9d5c342a454"
                      "7cd12cb63e9ae3ba85269c22c182ea56e3ccf6e03ebeb875bb1307c925130da9",
        },
        "published_by": "ZXDB md5hash table for Athena.tzx.zip/'Athena - 128k.tzx' "
                        "(original Imagine release, SpeedLock 4)",
    },
]


def digests_match(data, want):
    bad = []
    for alg, value in want.items():
        got = hashlib.new(alg, data).hexdigest()
        if got != value:
            bad.append(f"{alg} {got} != {value}")
    return bad


def download(url, via):
    cmd = ["curl", "-fsSL", "--max-time", "120", url]
    if via:
        cmd = shlex.split(via) + [" ".join(shlex.quote(c) for c in cmd)]
    r = subprocess.run(cmd, capture_output=True)
    if r.returncode != 0:
        raise RuntimeError(f"curl exit {r.returncode}: {r.stderr.decode(errors='replace').strip()}")
    return r.stdout


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--via", default=os.environ.get("FETCH_VIA", ""))
    args = ap.parse_args()
    os.makedirs(DATA, exist_ok=True)
    failed = 0
    for f in FILES:
        path = os.path.join(DATA, f["name"])
        if os.path.exists(path):
            data = open(path, "rb").read()
            bad = digests_match(data, f["digests"])
            if not bad:
                print(f"  ok        {f['name']} (already present)")
                continue
            print(f"  MISMATCH  {f['name']} is present but is not the expected file:")
            for b in bad:
                print(f"            {b}")
            failed += 1
            continue
        tries = [("direct", "")] + ([("via", args.via)] if args.via else [])
        data = None
        for how, via in tries:
            try:
                raw = download(f["url"], via)
            except RuntimeError as e:
                print(f"  {how:9s} {f['name']}: {e}")
                continue
            if "member" in f:
                try:
                    raw = zipfile.ZipFile(io.BytesIO(raw)).read(f["member"])
                except (zipfile.BadZipFile, KeyError) as e:
                    # A proxy's block page arrives as HTML, not a zip.
                    print(f"  {how:9s} {f['name']}: not the expected zip ({e})")
                    continue
            bad = digests_match(raw, f["digests"])
            if bad:
                print(f"  {how:9s} {f['name']}: downloaded bytes do not verify ({bad[0]})")
                continue
            data = raw
            print(f"  fetched   {f['name']} ({how}, {len(data):,} bytes)")
            break
        if data is None:
            print(f"  MISSING   {f['name']} - place it in data/ yourself; see data/README.md")
            failed += 1
            continue
        with open(path, "wb") as out:
            out.write(data)
    if failed:
        sys.exit(1)
    print("all game files present and verified against their published digests")


if __name__ == "__main__":
    main()
