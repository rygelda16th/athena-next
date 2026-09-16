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

.PHONY: help certs image doctor shell fetch check-data provenance toolchain-diff \
        rzx-end check-orig orig play-orig clean distclean

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
