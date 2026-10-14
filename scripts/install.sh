#!/bin/bash

set -euo pipefail

REPO_URL="https://github.com/l6t9/lampshell.git"
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
CONFIG_NAME="lampshell"
QS_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/quickshell"
TARGET="$QS_DIR/$CONFIG_NAME"

RUNTIME_PKGS=(
    qt6-base
    qt6-declarative
    matugen
    wl-clipboard
    brightnessctl
    ddcutil
    slurp
    ttf-material-symbols-variable
    noto-fonts-emoji
)

BUILD_PKGS=(
    cmake
    ninja
    gcc
)

AUR_PKGS=(
    quickshell-git
    ttf-google-sans
)

DRY_RUN=0
AUTO_START=1

for arg in "$@"; do
    case "$arg" in
        --dry-run) DRY_RUN=1 ;;
        --no-start) AUTO_START=0 ;;
        -h | --help)
            cat <<EOF
usage: install.sh [options]

  --dry-run   print what would happen without changing anything
  --no-start  install and build, but do not launch the shell
EOF
            exit 0
            ;;
        *) printf 'install.sh: unknown option %s\n' "$arg" >&2; exit 2 ;;
    esac
done

say() { printf '\033[1;35mlampshell\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33mlampshell\033[0m %s\n' "$*" >&2; }
die() { printf '\033[1;31mlampshell\033[0m %s\n' "$*" >&2; exit 1; }

run() {
    if [ "$DRY_RUN" -eq 1 ]; then
        printf '  [dry-run] %s\n' "$*"
        return 0
    fi
    "$@"
}

missing() {
    local name
    for name in "$@"; do
        pacman -Qq "$name" >/dev/null 2>&1 || printf '%s\n' "$name"
    done
}

as_root() {
    if [ "$(id -u)" -eq 0 ]; then
        "$@"
    else
        sudo "$@"
    fi
}

install_arch_pkgs() {
    local want=()
    mapfile -t want < <(missing "$@")
    [ "${#want[@]}" -eq 0 ] && return 0

    say "installing: ${want[*]}"
    if [ "$DRY_RUN" -eq 1 ]; then
        printf '  [dry-run] pacman -S --needed --noconfirm %s\n' "${want[*]}"
        return 0
    fi
    as_root pacman -S --needed --noconfirm "${want[@]}"
}

install_aur_pkgs() {
    local helper="" helper_cmd=()
    for candidate in paru yay pikaur; do
        if command -v "$candidate" >/dev/null 2>&1; then
            helper="$candidate"
            break
        fi
    done

    if [ -n "$helper" ]; then
        local want=()
        mapfile -t want < <(missing "${AUR_PKGS[@]}")
        [ "${#want[@]}" -eq 0 ] && return 0

        say "installing from the AUR with $helper: ${want[*]}"
        if [ "$DRY_RUN" -eq 1 ]; then
            printf '  [dry-run] %s -S --needed --noconfirm %s\n' "$helper" "${want[*]}"
            return 0
        fi
        "$helper" -S --needed --noconfirm "${want[@]}"
        return 0
    fi

    warn "quickshell-git is an AUR package and no AUR helper was found."
    warn "Install one of paru, yay or pikaur and re-run, otherwise the shell"
    warn "cannot start: it requires the git build of quickshell."
}

[ "$(uname -s)" = "Linux" ] || die "only Linux is supported"

if ! command -v pacman >/dev/null 2>&1; then
    die "no pacman found. This installer is Arch based; the dependencies and
package names here will not be right elsewhere."
fi

printf '\n'
say "installing runtime dependencies"
install_arch_pkgs "${RUNTIME_PKGS[@]}"

printf '\n'
say "installing build dependencies"
install_arch_pkgs "${BUILD_PKGS[@]}"

printf '\n'
say "installing quickshell"
install_aur_pkgs

if [ "$DRY_RUN" -eq 0 ] && ! command -v quickshell >/dev/null 2>&1; then
    die "quickshell is still not on PATH after installing, cannot continue"
fi

printf '\n'
if [ -d "$TARGET/.git" ]; then
    say "checkout already present at $TARGET, leaving it alone"
else
    if [ -e "$TARGET" ] && [ -n "$(ls -A "$TARGET" 2>/dev/null)" ]; then
        die "$TARGET exists and is not a git checkout. Move it aside and re-run."
    fi
    say "cloning into $TARGET"
    if [ "$DRY_RUN" -eq 1 ]; then
        printf '  [dry-run] git clone %s %s\n' "$REPO_URL" "$TARGET"
    else
        mkdir -p "$QS_DIR"
        git clone "$REPO_URL" "$TARGET"
    fi
fi

if [ "$DRY_RUN" -eq 0 ]; then
    chmod +x "$TARGET/scripts/lampshell"
fi

printf '\n'
say "building the native plugin"
if [ "$DRY_RUN" -eq 1 ]; then
    printf '  [dry-run] %s/scripts/lampshell plugin\n' "$TARGET"
else
    "$TARGET/scripts/lampshell" plugin
fi

printf '\n'
if [ "$DRY_RUN" -eq 1 ]; then
    printf '  [dry-run] sudo ln -sf %s /usr/local/bin/lampshell\n' "$TARGET/scripts/lampshell"
elif ! as_root ln -sf "$TARGET/scripts/lampshell" /usr/local/bin/lampshell 2>/dev/null; then
    warn "could not put lampshell on your PATH"
    warn "run:  sudo ln -sf $TARGET/scripts/lampshell /usr/local/bin/lampshell"
    warn "or just call $TARGET/scripts/lampshell directly"
fi

if [ "$AUTO_START" -eq 1 ]; then
    printf '\n'
    if [ "$DRY_RUN" -eq 1 ]; then
        printf '  [dry-run] %s/scripts/lampshell start\n' "$TARGET"
    else
        say "starting the shell"
        "$TARGET/scripts/lampshell" start
    fi
fi

install_update_hook() {
    local updater="/usr/local/bin/lampshell-git-update"
    local hookdir="/usr/share/libalpm/hooks"
    local hook="$hookdir/90-lampshell.hook"

    if [ ! -d "$hookdir" ]; then
        warn "no pacman hook directory, skipping"
        warn "run 'lampshell update' yourself to pull changes"
        return 0
    fi

    if [ "$DRY_RUN" -eq 1 ]; then
        printf '  [dry-run] would install %s and %s\n' "$updater" "$hook"
        return 0
    fi

    as_root install -Dm755 "$SCRIPT_DIR/lampshell-git-update" "$updater"
    as_root install -Dm644 "$SCRIPT_DIR/lampshell-pacman-hook.hook" "$hook"

    say "every pacman transaction will now pull and rebuild Lampshell"
    printf '  that covers %s and %s\n' "cachy-update" "paru -Syu"
}

printf '\n'
say "done"
if [ "$DRY_RUN" -eq 0 ]; then
    printf '  \033[1mlampshell status\033[0m to check on it, \033[1mlampshell update\033[0m to pull changes\n'
fi

printf '\n'
if [ "$DRY_RUN" -eq 1 ]; then
    reply="y"
elif [ -t 0 ]; then
    printf 'Let system updates keep Lampshell current, so you never have to run\n'
    printf 'lampshell update yourself? [Y/n] '
    read -r reply
else
    reply="n"
fi
case "$reply" in
    [nN] | [nN][oO]) printf '  skipped\n' ;;
    *) install_update_hook ;;
esac
