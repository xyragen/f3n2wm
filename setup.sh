#!/bin/bash
# f3n2wm setup

set -e

CONFIG_DIR="$HOME/.config/f3n2wm"
CONFIG_FILE="$CONFIG_DIR/f3n2wm.toml"

detect_pkg_manager() {
    if command -v apt-get &>/dev/null; then echo "apt"
    elif command -v pacman &>/dev/null; then echo "pacman"
    elif command -v dnf &>/dev/null; then echo "dnf"
    elif command -v zypper &>/dev/null; then echo "zypper"
    elif command -v xbps-install &>/dev/null; then echo "xbps"
    elif command -v apk &>/dev/null; then echo "apk"
    elif command -v emerge &>/dev/null; then echo "emerge"
    else echo "unknown"; fi
}

check_installed() { command -v "$1" &>/dev/null; }

install_deps() {
    case "$(detect_pkg_manager)" in
        apt)
            sudo apt-get update
            sudo apt-get install -y xinit luajit libx11-dev libxinerama-dev rofi alacritty
            ;;
        pacman)
            sudo pacman -S --noconfirm xorg-xinit luajit libx11 libxinerama rofi alacritty
            ;;
        dnf)
            sudo dnf install -y xorg-x11-xinit luajit-devel libX11-devel libXinerama-devel rofi alacritty
            ;;
        zypper)
            sudo zypper install -y xinit luajit-devel libX11-devel libXinerama-devel rofi alacritty
            ;;
        xbps)
            sudo xbps-install -Sy xinit luajit libX11-devel libXinerama-devel rofi alacritty
            ;;
        apk)
            sudo apk add xinit luajit-dev libx11-dev libxinerama-dev rofi alacritty
            ;;
        emerge)
            sudo emerge x11-apps/xinit dev-lang/luajit x11-libs/libX11 x11-libs/libXinerama x11-misc/rofi x11-terms/alacritty
            ;;
        *)
            echo "Unsupported package manager"
            exit 1
            ;;
    esac
}

setup_config() {
    mkdir -p "$CONFIG_DIR/layouts"
    [ ! -f "$CONFIG_FILE" ] && cp f3n2wm.toml "$CONFIG_FILE"
    for f in layouts/*.lua; do
        [ ! -f "$CONFIG_DIR/layouts/$(basename "$f")" ] && cp "$f" "$CONFIG_DIR/layouts/$(basename "$f")"
    done
}

install_wm() {
    sudo cp init.lua /usr/local/bin/f3n2wm
    sudo chmod +x /usr/local/bin/f3n2wm
    sudo mkdir -p /usr/local/share/man/man1
    sudo cp f3n2wm.1 /usr/local/share/man/man1/ 2>/dev/null || true
}

setup_xinitrc() {
    if [ -f "$HOME/.xinitrc" ]; then
        cp "$HOME/.xinitrc" "$HOME/.xinitrc.bak"
    fi
    echo "exec f3n2wm" > "$HOME/.xinitrc"
}

full_setup() {
    install_deps
    setup_config
    install_wm
    setup_xinitrc
}

show_menu() {
    printf "\033[2J\033[H"
    echo "f3n2wm setup"
    echo "------------"
    echo ""
    echo "Dependencies:"
    echo "  [1] xinit         $(check_installed startx && echo "(installed)" || echo "(missing)")"
    echo "  [2] luajit        $(check_installed luajit && echo "(installed)" || echo "(missing)")"
    echo "  [3] rofi          $(check_installed rofi && echo "(installed)" || echo "(missing)")"
    echo "  [4] alacritty     $(check_installed alacritty && echo "(installed)" || echo "(missing)")"
    echo ""
    echo "Configuration:"
    [ -f "$CONFIG_FILE" ] && echo "  [5] config  (exists)" || echo "  [5] config  (missing)"
    [ -f "$HOME/.xinitrc" ] && grep -q "f3n2wm" "$HOME/.xinitrc" 2>/dev/null && echo "  [6] xinitrc (configured)" || echo "  [6] xinitrc (not configured)"
    echo ""
    echo "Package manager: $(detect_pkg_manager)"
    echo ""
    echo "  [i] install deps"
    echo "  [c] setup config"
    echo "  [x] setup xinitrc"
    echo "  [a] full setup"
    echo "  [q] quit"
    echo ""
    printf "Choose: "
}

tui_mode() {
    while true; do
        show_menu
        read -r choice
        case "$choice" in
            5) setup_config; read ;;
            6) setup_xinitrc; read ;;
            i|I) install_deps; read ;;
            c|C) setup_config; read ;;
            x|X) setup_xinitrc; read ;;
            a|A) full_setup; read ;;
            q|Q) exit 0 ;;
        esac
    done
}

case "$1" in
    --auto|-a) full_setup ;;
    --help|-h) echo "Usage: ./setup.sh [--auto]"; exit 0 ;;
    *) tui_mode ;;
esac