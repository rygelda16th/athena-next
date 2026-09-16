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

.PHONY: help certs image doctor shell fetch check-data provenance toolchain-diff \
        clean distclean

help:
	@echo "make certs          extract the corporate TLS-inspection CA for the image"
	@echo "make image          build the toolchain container"
	@echo "make doctor         report tool versions from inside the container"
	@echo "make fetch          download and verify YOUR game files into data/ (host)"
	@echo "make check-data     G0: the files are the dump, recording and tape we measured"
	@echo "make provenance     G0: the snapshot is the original tape's game, byte for byte"
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
