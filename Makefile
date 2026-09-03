PREFIX ?= /usr/local
BINDIR ?= $(PREFIX)/bin
MANDIR ?= $(PREFIX)/share/man

LUAJIT ?= luajit
CONFIG_DIR ?= $(HOME)/.config/f3n2wm

.PHONY: all install uninstall clean config run test docs deps setup

all: check-deps

check-deps:
	@command -v $(LUAJIT) >/dev/null 2>&1 || { echo "Error: luajit not found. Please install luajit."; exit 1; }
	@pkg-config --exists x11 2>/dev/null || { echo "Error: libx11 not found. Please install libx11-dev."; exit 1; }
	@pkg-config --exists xinerama 2>/dev/null || { echo "Error: libxinerama not found. Please install libxinerama-dev."; exit 1; }

install: all
	@mkdir -p $(DESTDIR)$(BINDIR)
	@cp init.lua $(DESTDIR)$(BINDIR)/f3n2wm
	@chmod +x $(DESTDIR)$(BINDIR)/f3n2wm
	@mkdir -p $(DESTDIR)$(MANDIR)/man1
	@cp f3n2wm.1 $(DESTDIR)$(MANDIR)/man1/ 2>/dev/null || true
	@echo "f3n2wm installed to $(DESTDIR)$(BINDIR)/f3n2wm"

uninstall:
	@rm -f $(DESTDIR)$(BINDIR)/f3n2wm
	@rm -f $(DESTDIR)$(MANDIR)/man1/f3n2wm.1
	@echo "f3n2wm uninstalled"

config:
	@mkdir -p $(CONFIG_DIR)
	@mkdir -p $(CONFIG_DIR)/layouts
	@if [ ! -f $(CONFIG_DIR)/f3n2wm.toml ]; then \
		cp f3n2wm.toml $(CONFIG_DIR)/f3n2wm.toml; \
		echo "Default config installed to $(CONFIG_DIR)/f3n2wm.toml"; \
	else \
		echo "Config already exists at $(CONFIG_DIR)/f3n2wm.toml"; \
	fi
	@for f in layouts/*.lua; do \
		if [ ! -f "$(CONFIG_DIR)/$$f" ]; then \
			cp "$$f" "$(CONFIG_DIR)/$$f"; \
		fi; \
	done

run: all
	@$(LUAJIT) init.lua $(CURDIR)

test:
	@echo "Checking Lua syntax..."
	@for f in init.lua lib/*.lua layouts/*.lua; do \
		$(LUAJIT) -bl "$$f" > /dev/null 2>&1 && echo "OK: $$f" || echo "FAIL: $$f"; \
	done

docs:
	@echo "Generating documentation..."
	@mkdir -p $(DESTDIR)$(PREFIX)/share/doc/f3n2wm
	@if [ -d docs ]; then \
		cp -r docs $(DESTDIR)$(PREFIX)/share/doc/f3n2wm/; \
	fi
	@cp README.md $(DESTDIR)$(PREFIX)/share/doc/f3n2wm/
	@echo "Documentation installed"

deps:
	@echo "Installing dependencies..."
	@if command -v apt-get >/dev/null 2>&1; then \
		sudo apt-get update && sudo apt-get install -y luajit libx11-dev libxinerama-dev rofi alacritty; \
	elif command -v pacman >/dev/null 2>&1; then \
		sudo pacman -S --noconfirm luajit libx11 libxinerama rofi alacritty; \
	elif command -v dnf >/dev/null 2>&1; then \
		sudo dnf install -y luajit-devel libX11-devel libXinerama-devel rofi alacritty; \
	elif command -v zypper >/dev/null 2>&1; then \
		sudo zypper install -y luajit-devel libX11-devel libXinerama-devel rofi alacritty; \
	elif command -v xbps-install >/dev/null 2>&1; then \
		sudo xbps-install -Sy luajit libX11-devel libXinerama-devel rofi alacritty; \
	elif command -v apk >/dev/null 2>&1; then \
		sudo apk add luajit-dev libx11-dev libxinerama-dev rofi alacritty; \
	elif command -v emerge >/dev/null 2>&1; then \
		sudo emerge dev-lang/luajit x11-libs/libX11 x11-libs/libXinerama x11-misc/rofi x11-terms/alacritty; \
	elif command -v brew >/dev/null 2>&1; then \
		brew install luajit xquartz; \
	else \
		echo "Please install: luajit, libX11, libXinerama, rofi, alacritty"; \
	fi

setup:
	@bash scripts/setup.sh

check:
	@python scripts/check_syntax.py
