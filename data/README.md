# data/ - your own copy of the game

Nothing in this directory is committed except this file. `make fetch` fills it
and verifies every file against digests published by the Internet Archive and
ZXDB; if you already have the files, put them here under these names and
`make fetch` will verify them without downloading.

| File | What | Where it comes from |
|---|---|---|
| `athena128.z80` | 128K snapshot (World of Spectrum `ATHEN128.Z80`) | archive.org |
| `athena.rzx` | Rafal's full 128K playthrough recording | archive.org (RZX Archive) |
| `athena128.tzx` | Imagine's original 128K tape (`Athena - 128k.tzx`) | Spectrum Computing `Athena.tzx.zip` |

If your network blocks Spectrum Computing, set `FETCH_VIA` in `local.mk` to a
command that runs curl elsewhere (for example `ssh user@host`); the digest check
makes the route irrelevant to trust. See `docs/provenance.md`.
