# Athena Next build toolchain.
#
# ---------------------------------------------------------------------------
# PROVENANCE. Everything from FROM down to the ZEsarUX stage is a copy of
# anotherworld-next's Dockerfile at commit d6f2736 (itself a copy of
# wolf3d-next's), kept byte-identical so the numbers measured there stay
# comparable here and Docker reuses its cached layers. tools/zrcp.py and the
# three ZEsarUX patches are copied too; `make toolchain-diff` reports drift.
#
# What is NEW here is the last stage: SkoolKit, the disassembler this port is
# built on. There is no source for Athena, so the game's own binary is the
# reference and SkoolKit is how we read it.
# ---------------------------------------------------------------------------
#
# Native arm64 build (no emulation). Disposable: `docker image rm athena-next-tools`.

FROM debian:bookworm-slim

ENV DEBIAN_FRONTEND=noninteractive

# Corporate TLS inspection (Netskope) re-signs every HTTPS connection, so the
# image needs the same root CA the Mac already trusts or `git clone` fails.
# `make certs` extracts it from the system keychain; the dir is gitignored, and
# an empty one is harmless off the corporate network.
COPY certs/ /usr/local/share/ca-certificates/

RUN apt-get update && apt-get install -y --no-install-recommends \
        build-essential ca-certificates git make cmake pkg-config \
        autoconf automake libtool python3 \
        libncurses-dev libssl-dev zlib1g-dev \
    && update-ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Pinned to the exact commits the numbers were measured against. Upstream
# sjasmplus and ZEsarUX have no clean release tags, so a commit pin is the only
# way to keep timing runs reproducible.
ARG SJASMPLUS_REF=8c87edd
ARG HDFMONKEY_REF=76d400f
ARG ZESARUX_REF=f02514f

# --- sjasmplus (z00m128 fork): Z80N assembler, emits .nex directly ------------
RUN git clone https://github.com/z00m128/sjasmplus.git /tmp/sjasmplus \
    && git -C /tmp/sjasmplus checkout -q "$SJASMPLUS_REF" \
    && git -C /tmp/sjasmplus submodule update --init --recursive \
    && make -C /tmp/sjasmplus -j"$(nproc)" \
    && make -C /tmp/sjasmplus install PREFIX=/usr/local \
    && (cd /tmp/sjasmplus && git rev-parse --short HEAD > /usr/local/share/sjasmplus.commit) \
    && rm -rf /tmp/sjasmplus

# --- hdfmonkey: build/edit the FAT SD-card image ------------------------------
RUN git clone https://github.com/gasman/hdfmonkey.git /tmp/hdfmonkey \
    && cd /tmp/hdfmonkey \
    && git checkout -q "$HDFMONKEY_REF" \
    && (test -x ./configure || autoreconf -i) \
    && ./configure && make -j"$(nproc)" && make install \
    && git rev-parse --short HEAD > /usr/local/share/hdfmonkey.commit \
    && cd / && rm -rf /tmp/hdfmonkey

# --- z88dk is NOT built here, and that is deliberate --------------------------
# It lives in its own pinned image and the Makefile's `cc:` target runs it there.
# Two reasons, both found by trying the alternative:
#
#   1. It cannot be built here. SDCC refuses to compile its Z80 register
#      allocator against Boost below 1.79 (SDCC bug #3772) and bookworm ships
#      1.74, so `zsdcc` - which -clib=sdcc_iy requires - fails on ANY
#      architecture on this base, not just arm64. Only trixie carries 1.83.
#   2. It does not need to be. Upstream's z88dk/z88dk image has an arm64 variant
#      with `z88dk-zsdcc` in it, which corrects the assumption that the prebuilt
#      image is amd64-only and that Rosetta was required.
#
# That image is Alpine and musl-linked, so its binaries cannot simply be COPYed
# into this glibc image - hence a separate pinned image rather than a stage.
#
# The happy consequence is that this file stays a near-exact copy of
# wolf3d-next's, which is what makes `make toolchain-diff` worth running.

# --- ZEsarUX, headless: cycle-accurate timing truth ---------------------------
# No X, no SDL. Driven over ZRCP (its telnet debug protocol) on port 10000.
#
# PATCHED, and this is the one place the emulator is not upstream's. The three
# patches are wolf3d-next's, unchanged; see that project's Dockerfile for what
# each does and which check proves it. In short: prescalar.patch makes the DMA
# honour its transfer rate, readback.patch makes the DMA's registers readable,
# and autorestart.patch implements WR5 bit 5.
#
# This port depends on them much less than wolf3d-next does - it uses no DMA for
# polygon spans at all - but the page copy still goes through the DMA, so the
# timing patch still matters for that one operation.
COPY tools/zesarux/prescalar.patch tools/zesarux/readback.patch tools/zesarux/autorestart.patch /tmp/
RUN git clone https://github.com/chernandezba/zesarux.git /opt/zesarux-src \
    && git -C /opt/zesarux-src checkout -q "$ZESARUX_REF" \
    && git -C /opt/zesarux-src apply /tmp/prescalar.patch \
    && git -C /opt/zesarux-src apply /tmp/readback.patch \
    && git -C /opt/zesarux-src apply /tmp/autorestart.patch \
    && (cd /opt/zesarux-src && git rev-parse --short HEAD > /usr/local/share/zesarux.commit \
        && for p in prescalar readback autorestart; do \
             echo "+tools/zesarux/$p.patch" >> /usr/local/share/zesarux.commit; done) \
    && cd /opt/zesarux-src/src \
    && ./configure --prefix=/usr/local --disable-caca --disable-aa \
    && make -j"$(nproc)" && make install \
    && rm -rf /opt/zesarux-src/src/*.o

# --- SkoolKit: disassembler, RZX player, Z80 simulator ------------------------
# Pinned to the 10.1 release tarball and checked against the sha256 GitHub
# publishes for it. SkoolKit runs from where it is unpacked; the C simulator
# (csimulator, ccmiosimulator) is optional but ~15x faster, and rzxplay.py
# over a 40-minute recording needs it, so the extensions are built in place and
# `make doctor` fails if they are missing.
ARG SKOOLKIT_VERSION=10.1
ARG SKOOLKIT_SHA256=1993873d486d716962f1fbab457d92646b8fc8d07978e618df75761d7bc1d64f
RUN apt-get update && apt-get install -y --no-install-recommends \
        curl xz-utils python3-dev python3-setuptools \
    && rm -rf /var/lib/apt/lists/* \
    && curl -fsSL -o /tmp/skoolkit.tar.xz \
        "https://github.com/skoolkid/skoolkit/releases/download/${SKOOLKIT_VERSION}/skoolkit-${SKOOLKIT_VERSION}.tar.xz" \
    && echo "${SKOOLKIT_SHA256}  /tmp/skoolkit.tar.xz" | sha256sum -c - \
    && tar -xJf /tmp/skoolkit.tar.xz -C /opt \
    && ln -s "/opt/skoolkit-${SKOOLKIT_VERSION}" /opt/skoolkit \
    && (cd /opt/skoolkit && python3 setup.py build_ext -i >/tmp/skoolkit-build.log 2>&1) \
    && python3 -c "import sys; sys.path.insert(0,'/opt/skoolkit'); import skoolkit.csimulator, skoolkit.ccmiosimulator" \
    && echo "${SKOOLKIT_VERSION} sha256:${SKOOLKIT_SHA256}" > /usr/local/share/skoolkit.version \
    && rm -f /tmp/skoolkit.tar.xz
ENV PATH="/opt/skoolkit:${PATH}" \
    PYTHONPATH="/opt/skoolkit"

# --- MAME: the arcade capture (C1) ---------------------------------------------
# Debian bookworm's MAME 0.251, with its Lua scripting (the capture taps the arcade
# main CPU's writes and reads the video memory every frame, headless). It runs only
# the player's own arcade set from data/arcade/ (docs/licence.md).
RUN apt-get update && apt-get install -y --no-install-recommends mame \
    && rm -rf /var/lib/apt/lists/* \
    && /usr/games/mame -version > /usr/local/share/mame.version
ENV PATH="${PATH}:/usr/games"

WORKDIR /work
CMD ["/bin/bash"]
