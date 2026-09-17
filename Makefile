# Host-side driver. Every target that needs a tool runs it in the container, so
# nothing but the native ZEsarUX app (later) is installed on the Mac. The shape -
# certs, image, doctor, check-<name>, toolchain-diff - follows anotherworld-next
# and wolf3d-next.

DC      := docker compose
# PYTHONUNBUFFERED, because a checker that is KILLED loses everything still
# sitting in stdio's buffer.
RUN     := $(DC) run --rm -e PYTHONUNBUFFERED=1 tools
BUILD   := build
AW      ?= $(HOME)/src/anotherworld-next
WOLF3D  ?= $(HOME)/src/wolf3d-next

# Machine-local settings, never committed. FETCH_VIA names a relay for networks
# that block Spectrum Computing, e.g.
#   FETCH_VIA := ssh -o BatchMode=yes user@host
-include local.mk
FETCH_VIA ?=

# Headless ZEsarUX running the ORIGINAL game as a Spectrum 128K. ZRCP on 10010
# so it can run beside the other projects' emulators (10000, 10001).
ZRCP_PORT := 10010
ZESARUX128 := zesarux --vo null --ao null --machine 128k --enable-remoteprotocol \
                      --remoteprotocol-port $(ZRCP_PORT) --enable-breakpoints \
                      --nosplash --noconfigfile --snap data/athena128.z80
# The PATCHED native build (wolf3d-next's three DMA patches). The older projects'
# `make play` points at the Homebrew cask in ~/Applications, which is not patched.
NATIVE_ZESARUX ?= $(HOME)/src/zesarux-patched/src/zesarux

.PHONY: check-arcade-capture check-art check-levels e7 check-options e6 check-render check-sprites check-scroll e2 e3 e4 arcade-assets nex-arcade oracle-nex-arcade poses check-mapping c2 check-classic-sound check-arcade-sound check-pace-arcade e5 help certs image doctor shell fetch check-data provenance html gfx check-gfx worlds check-worlds check-audit toolchain-diff \
        orig-passes check-hz60 check-pace e1 check-capture capture c1 \
        rzx-end check-orig orig play-orig bank-exec scripts ctl-bootstrap skool ctl \
        check-ctl check-reasm coverage g2 oracle-stream nex oracle-nex check-play \
        check-oracle check-cspect g3 play clean distclean

help:
	@echo "make certs          extract the corporate TLS-inspection CA for the image"
	@echo "make image          build the toolchain container"
	@echo "make doctor         report tool versions from inside the container"
	@echo "make fetch          download and verify YOUR game files into data/ (host)"
	@echo "make check-data     G0: the files are the dump, recording and tape we measured"
	@echo "make provenance     G0: the snapshot is the original tape's game, byte for byte"
	@echo "make rzx-end        G1: play the whole recording; pictures, snapshots, code map"
	@echo "make check-orig     G1: the original runs in headless ZEsarUX as a 128K"
	@echo "make orig           headless original with ZRCP on 127.0.0.1:$(ZRCP_PORT)"
	@echo "make play-orig      play the original in the native (patched) ZEsarUX"
	@echo "make gfx            PNG sheets of every graphic from your files (build/gfx; never publish)"
	@echo "make check-gfx      D2: the play area is rebuilt from the map in all seven worlds"
	@echo "make worlds         pictures of all seven worlds' maps (build/worlds; never publish)"
	@echo "make check-worlds   D3: every world's play area is its map plus play's changes"
	@echo "make check-audit    D7: the disassembly is complete (titles, entries, data references, operands)"
	@echo "make html           local HTML disassembly from your snapshot (never publish it)"
	@echo "make bank-exec      G2: does code ever run at \$$C000 from a bank other than 0?"
	@echo "make scripts        G2: scripted runs of the original (menu, keys, game over)"
	@echo "make skool          regenerate work/*.skool from src/*.ctl and YOUR snapshot"
	@echo "make ctl            write work/*.skool back to src/*.ctl (after annotating)"
	@echo "make check-ctl      G2: ctl -> skool -> ctl loses nothing; no game bytes in src/"
	@echo "make check-reasm    G2: all eight banks rebuilt byte for byte, two ways"
	@echo "make coverage       G2: what no run executed, sorted by evidence"
	@echo "make g2             everything G2, in order"
	@echo "make nex            build/athena.nex: the original, rebuilt, as a Next program"
	@echo "make check-play     G3/E1: athena.nex runs the original at 28 MHz with the engine (Next)"
	@echo "make oracle-stream  G3: every value the game took from outside, from the recording"
	@echo "make check-oracle   G3: the recording replayed through the port at 3.5 and 28 MHz"
	@echo "make check-cspect   G3: athena.nex runs in CSpect too (opens a window briefly)"
	@echo "make check-pace     E1: the port keeps the original's pace (after check-oracle); 60 Hz ticks"
	@echo "make e1             E1: check-play, check-oracle, check-pace"
	@echo "make check-capture  C1: arcade frames rebuilt from a MAME capture log, pixel for pixel"
	@echo "make capture        C1: a play-through capture log (CAPTURE_BOT=tools/arcade/bot.lua for the bot)"
	@echo "make check-render   E2: the play area on Layer 2, pixel for pixel, through the whole recording"
	@echo "make check-sprites  E3: every sprite on hardware sprites, exactly; the image cache never runs out"
	@echo "make check-scroll   E4: Layer 2's offset glides, and mid-glide frames are exact"
	@echo "make arcade-assets  C2/E5: the arcade art and sound from YOUR arcade set (build/assets; never publish)"
	@echo "make poses          C2: the arcade player's poses on cue (MAME)"
	@echo "make check-mapping  C2: the mapping covers the art bible and shows in the game, exactly"
	@echo "make check-classic-sound  E5: classic mode plays the original's sound, note for note"
	@echo "make check-arcade-capture E5: every cue's capture is the arcade's own, and repeatable"
	@echo "make check-arcade-sound   E5: the arcade sound plays as converted, loops, at the right moments"
	@echo "make check-pace-arcade    E5: the arcade build keeps the original's pace"
	@echo "make check-options  E6: the pad, the options screen, presets, levers, fixes, classic mode, the SD card"
	@echo "make check-art      H: David's hand-made cells (data/art) against the art bible"
	@echo "make check-levels   E7: all three build levels build and play"
	@echo "make play           play build/athena.nex in CSpect"
	@echo "make toolchain-diff has the shared toolchain drifted from anotherworld-next?"

certs:
	@mkdir -p certs
	@security find-certificate -a -c "caadmin.netskope.com" -p /Library/Keychains/System.keychain > certs/netskope-root.crt
	@security find-certificate -a -c "ca.zellis.eu.goskope.com" -p /Library/Keychains/System.keychain > certs/netskope-zellis.crt
	@echo "certs/ populated from the system keychain"

image: certs
	$(DC) build

doctor:
	@echo "=== host ==="
	@echo "docker context: $$(docker context show)"
	@docker version --format 'docker server: {{.Server.Version}} ({{.Server.Arch}})'
	@echo "=== toolchain image ==="
	@$(RUN) sh tools/doctor.sh

shell:
	$(RUN) bash

$(BUILD):
	mkdir -p $(BUILD)

# ---- G0: the game files -----------------------------------------------------
# Host side, standard library only: the relay (if any) is reached from the Mac.
fetch:
	python3 tools/fetch.py $(if $(FETCH_VIA),--via "$(FETCH_VIA)")

check-data:
	python3 tools/checkdata.py data

provenance: | $(BUILD)
	$(RUN) python3 tools/provenance.py

# ---- G1: the original game, and the recording ----------------------------------
rzx-end: | $(BUILD)
	$(RUN) python3 tools/rzxwalk.py

check-orig: | $(BUILD)
	@mkdir -p $(BUILD)/g1
	$(RUN) sh -c '$(ZESARUX128) >/tmp/zesarux.log 2>&1 & python3 tools/checkorig.py'

# Leaves the headless original running with ZRCP published to the host.
orig:
	$(DC) run --rm --service-ports tools $(ZESARUX128)

play-orig:
	@test -x "$(NATIVE_ZESARUX)" || { echo "no native ZEsarUX at $(NATIVE_ZESARUX)"; exit 1; }
	"$(NATIVE_ZESARUX)" --noconfigfile --machine 128k --zoom 2 --snap "$(CURDIR)/data/athena128.z80"

# ---- G2: the disassembly's skeleton ------------------------------------------
# The control files in src/ ARE the disassembly. `make skool` regenerates the full
# skool files (which contain every instruction, so they live in work/, never in
# git); annotate there, then `make ctl` writes the control files back.
BANKS := 1 3 4 6 7

bank-exec: | $(BUILD)
	$(RUN) python3 tools/bankexec.py

scripts: | $(BUILD)
	$(RUN) sh -c 'for s in tools/scripts/*.py; do python3 tools/scriptplay.py $$s || exit 1; done; python3 tools/mergemaps.py'

ctl-bootstrap:
	$(RUN) python3 tools/mkctl.py

skool:
	@mkdir -p work
	$(RUN) sh -c 'sna2skool.py -H -c src/athena.ctl data/athena128.z80 > work/athena.skool 2>/dev/null && \
		for n in $(BANKS); do sna2skool.py -H -p $$n -c src/bank$$n.ctl data/athena128.z80 > work/bank$$n.skool 2>/dev/null || exit 1; done'

ctl:
	$(RUN) sh -c 'skool2ctl.py -h work/athena.skool > src/athena.ctl && \
		for n in $(BANKS); do skool2ctl.py -h work/bank$$n.skool > src/bank$$n.ctl || exit 1; done'

check-ctl:
	$(RUN) python3 tools/checkctl.py

# ---- D2: graphics -----------------------------------------------------------------
# PNG sheets of every graphic, from YOUR files (never commit or publish them).
gfx:
	python3 tools/extract_gfx.py

# The play area is rebuilt from the map and cell tables in all seven world snapshots.
check-gfx:
	python3 tools/checkgfx.py

# ---- D3: level data -------------------------------------------------------------------
# Whole-map pictures of all seven worlds from YOUR snapshot (never commit or publish them).
worlds:
	python3 tools/render_world.py

# Every world's play area is its pristine map plus the changes play made to it.
check-worlds:
	python3 tools/checkworlds.py

# ---- D7: completeness ----------------------------------------------------------------
# Every block titled and described; every entry, data reference and rewritten operand explained.
check-audit:
	python3 tools/disasm_audit.py

# Local HTML disassembly from YOUR snapshot (it contains the game's bytes: never publish it).
html: skool
	rm -rf build/html
	$(RUN) skool2html.py -H -q -d build/html work/athena.skool src/athena.ref
	@echo "open build/html/athena/index.html"

check-reasm: | $(BUILD)
	$(RUN) python3 tools/reasm.py

coverage: | $(BUILD)
	python3 tools/coverage.py

g2: bank-exec scripts skool check-ctl check-reasm coverage

# ---- G3: the original as a Next program, and the oracle -------------------------
# Headless ZEsarUX as a Next (TBBlue). --emulatorspeed lets the forty-minute
# recording replay faster than real time.
ZESARUX_NEXT := zesarux --vo null --ao null --machine tbblue --enable-remoteprotocol \
                        --remoteprotocol-port $(ZRCP_PORT) --enable-breakpoints \
                        --tbblue-max-turbo-rom 8 --tbblue-max-turbo-everywhere 8 \
                        --nosplash --noconfigfile
ORACLE_SPEED ?= 2000
CSPECT ?= $(HOME)/src/cspect

nex: | $(BUILD)
	@test -f build/g2/plain/bank0.bin || { echo "run make check-reasm first"; exit 1; }
	@test -f build/g3/play_gen.asm || { echo "run make oracle-stream first"; exit 1; }
	$(RUN) sjasmplus --nologo --msg=war -DSPEED=3 src/next/athena.asm

oracle-stream: | $(BUILD)
	$(RUN) python3 tools/mkstream.py

oracle-nex: | $(BUILD)
	$(RUN) sh -c 'sjasmplus --nologo --msg=war -DSPEED=0 -DORACLE src/next/athena.asm && \
		sjasmplus --nologo --msg=war -DSPEED=3 -DORACLE src/next/athena.asm'

check-play: nex
	$(RUN) sh -c '$(ZESARUX_NEXT) >/tmp/zesarux.log 2>&1 & sleep 3; python3 tools/checknex.py play'

check-oracle: oracle-nex
	$(RUN) sh -c '$(ZESARUX_NEXT) --emulatorspeed $(ORACLE_SPEED) >/tmp/zesarux.log 2>&1 & sleep 3; \
		python3 -u tools/checknex.py oracle build/g3/athena-oracle-35.nex 7200'
	$(RUN) sh -c '$(ZESARUX_NEXT) --emulatorspeed $(ORACLE_SPEED) >/tmp/zesarux.log 2>&1 & sleep 3; \
		python3 -u tools/checknex.py oracle build/g3/athena-oracle-28.nex 7200'

check-cspect: check-play
	python3 tools/checkcspect.py

g3: oracle-stream nex check-play check-cspect check-oracle

# ---- E1: pace at 28 MHz ---------------------------------------------------------
orig-passes: | $(BUILD)
	$(RUN) python3 tools/origpasses.py

check-hz60: nex
	$(RUN) sh -c '$(ZESARUX_NEXT) >/tmp/zesarux.log 2>&1 & sleep 3; python3 tools/checknex.py hz60'

# check-oracle records the port's pass lengths (build/e1/pace-35.json, pace-28.json).
check-pace: orig-passes check-hz60
	@test -f build/e1/pace-28.json || { echo "run make check-oracle first"; exit 1; }
	python3 tools/checkpace.py

e1: check-play check-oracle check-pace

# ---- E2-E4: the play area, the sprites and the scroll on the Next's layers ------
# Each replays the recording through the 28 MHz oracle build and samples as it goes.
ORACLE_28 = $(ZESARUX_NEXT) --emulatorspeed $(ORACLE_SPEED) >/tmp/zesarux.log 2>&1 & sleep 3;

check-render: oracle-nex
	$(RUN) sh -c '$(ORACLE_28) python3 -u tools/checkrender.py'

check-sprites: oracle-nex
	$(RUN) sh -c '$(ORACLE_28) python3 -u tools/checksprites.py'

check-scroll: oracle-nex
	$(RUN) sh -c '$(ORACLE_28) python3 -u tools/checkscroll.py'

e2: check-render
e3: check-sprites
e4: check-scroll

# ---- C2 and E5 with the arcade set (optional; these need data/arcade/athena.zip) -
# The arcade art and sound, made from the player's own set; builds with -DARCADE need a
# 2MB Next.
arcade-assets: | $(BUILD)
	$(RUN) sh -c 'python3 tools/arcade/mkmapping.py && python3 tools/arcade/mksound.py'

nex-arcade: arcade-assets
	$(RUN) sjasmplus --nologo --msg=war -DSPEED=3 -DARCADE src/next/athena.asm

oracle-nex-arcade: arcade-assets
	$(RUN) sjasmplus --nologo --msg=war -DSPEED=3 -DORACLE -DARCADE src/next/athena.asm

# The arcade player's poses on cue, for the mapping (tools/arcade/poses.lua).
poses: | $(BUILD)
	@mkdir -p build/c2/poses
	$(RUN) sh -c 'CAPTURE_OUT=build/c2/poses/poses.bin CAPTURE_FRAMES=4600 CAPTURE_BOT=tools/arcade/poses.lua \
		mame athena -rompath data/arcade -homepath /tmp/mame -cfg_directory /tmp/mame/cfg \
		-nvram_directory /tmp/mame/nvram -video none -sound none -nothrottle -skip_gameinfo \
		-autoboot_script tools/arcade/capture.lua >/dev/null 2>&1; true'

check-mapping: oracle-nex-arcade
	$(RUN) sh -c '$(ORACLE_28) python3 -u tools/checkmapping.py'

c2: check-mapping

c3: check-mapping

# Classic sound: the original machine and the port, heard through ZEsarUX's audio file.
CLASSIC_RECORD = zesarux --vo null --ao null --aofile /work/build/e5/classic/$$m.raw $$args \
	--enable-remoteprotocol --remoteprotocol-port $(ZRCP_PORT) --nosplash --noconfigfile >/tmp/zesarux.log 2>&1 & sleep 3; \
	python3 -u tools/checkclassic.py record $$m
check-classic-sound: nex
	@mkdir -p build/e5/classic
	$(RUN) sh -c 'm=128k; args="--machine 128k"; $(CLASSIC_RECORD)'
	$(RUN) sh -c 'm=128k-b; args="--machine 128k"; $(CLASSIC_RECORD)'
	$(RUN) sh -c 'm=next; args="--machine tbblue --tbblue-max-turbo-rom 8 --tbblue-max-turbo-everywhere 8"; $(CLASSIC_RECORD)'
	$(RUN) sh -c 'm=next-b; args="--machine tbblue --tbblue-max-turbo-rom 8 --tbblue-max-turbo-everywhere 8"; $(CLASSIC_RECORD)'
	python3 tools/checkclassic.py compare

check-arcade-capture: | $(BUILD)
	$(RUN) python3 -u tools/checksound.py capture

check-arcade-sound: nex-arcade oracle-nex-arcade
	$(RUN) python3 tools/checksound.py static
	$(RUN) sh -c '$(ZESARUX_NEXT) --emulatorspeed $(ORACLE_SPEED) >/tmp/zesarux.log 2>&1 & sleep 3; python3 -u tools/checksound.py player'
	$(RUN) sh -c '$(ORACLE_28) python3 -u tools/checksound.py moments'

# The arcade build's pace: its effects run silent at 28 MHz and are credited as 3.5 MHz.
check-pace-arcade: oracle-nex-arcade orig-passes
	$(RUN) sh -c '$(ORACLE_28) python3 -u tools/checknex.py oracle build/g3/athena-oracle-28-arcade.nex 7200'
	python3 tools/checkpace.py build/e1/pace-28-arcade.json

e5: check-classic-sound check-arcade-capture check-arcade-sound check-pace-arcade

# ---- E6: controls and options (play builds) -------------------------------------
check-options: nex
	@mkdir -p build/e6
	$(RUN) python3 -u tools/checkoptions.py

e6: check-play check-options

# ---- H and E7: David's hand-made art, and the three build levels ----------------
check-art: | $(BUILD)
	$(RUN) python3 tools/artimport.py

check-levels: | $(BUILD)
	$(RUN) python3 -u tools/checklevels.py

e7: check-levels

# ---- C1: the arcade capture (the arcade set is optional; these need it) ---------
check-capture: | $(BUILD)
	$(RUN) python3 tools/checkcapture.py

# A play-through log: CAPTURE_BOT=tools/arcade/bot.lua for the bot, or run MAME with a
# window and tools/arcade/capture.lua where a person can play.
CAPTURE_FRAMES ?= 72000
capture: | $(BUILD)
	@mkdir -p build/c1/play
	$(RUN) sh -c 'CAPTURE_OUT=build/c1/play/capture.bin CAPTURE_FRAMES=$(CAPTURE_FRAMES) CAPTURE_BOT=$(CAPTURE_BOT) \
		mame athena -rompath data/arcade -homepath /tmp/mame -cfg_directory /tmp/mame/cfg \
		-nvram_directory /tmp/mame/nvram -snapshot_directory build/c1/play/snap -video none -sound none \
		-nothrottle -skip_gameinfo -autoboot_script tools/arcade/capture.lua >/dev/null 2>&1; true'

c1: check-capture

play: nex
	cp build/athena.nex $(CSPECT)/sd/ATHENA.NEX
	cd $(CSPECT)/CSpect && mono CSpect.exe -w3 -basickeys -mouse -zxnext -nextrom -mmc=../sd/ ../sd/ATHENA.NEX

# ---- drift check --------------------------------------------------------------
# The shared files are copied from anotherworld-next rather than submoduled.
# This is what stops that being invisible.
SHARED := tools/zrcp.py tools/zesarux/prescalar.patch \
          tools/zesarux/readback.patch tools/zesarux/autorestart.patch
toolchain-diff:
	@test -d $(AW) || { echo "no anotherworld-next checkout at $(AW)"; exit 1; }
	@rc=0; for f in $(SHARED); do \
		if diff -q "$$f" "$(AW)/$$f" >/dev/null 2>&1; then \
			echo "  same      $$f"; \
		else \
			echo "  DRIFTED   $$f"; diff -u "$(AW)/$$f" "$$f" | head -20; rc=1; \
		fi; done; \
	a=$$(sed -n '/^FROM /,/^# --- SkoolKit/p' Dockerfile | grep -v '^# --- SkoolKit'); \
	b=$$(sed -n '/^FROM /,/^WORKDIR/p' $(AW)/Dockerfile | grep -v '^WORKDIR'); \
	if [ "$$(printf '%s' "$$a" | sed '/^$$/d')" = "$$(printf '%s' "$$b" | sed '/^$$/d')" ]; then \
		echo "  same      Dockerfile (FROM .. ZEsarUX stages)"; \
	else \
		echo "  DRIFTED   Dockerfile (FROM .. ZEsarUX stages)"; rc=1; \
	fi; \
	exit $$rc

clean:
	rm -rf $(BUILD)

distclean: clean
	-docker image rm athena-next-tools
