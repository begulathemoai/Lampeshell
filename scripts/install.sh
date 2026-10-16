#!/bin/bash

set -euo pipefail

if [ -z "${BASH_VERSION:-}" ]; then
    printf 'install.sh: needs bash, re-executing\n' >&2
    if [ -f "$0" ] && head -c 2 "$0" 2>/dev/null | grep -q '#!'; then
        exec bash "$0" "$@"
    fi
    exec bash /dev/stdin "$@"
fi

REPO_URL="https://github.com/l6t9/lampshell.git"
CONFIG_NAME="lampshell"
QS_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/quickshell"
TARGET="$QS_DIR/$CONFIG_NAME"

RUNTIME_PKGS=(
    qt6-base
    qt6-declarative
    hyprland
    matugen
    jq
    git
    curl
    wl-clipboard
    grim
    imagemagick
    brightnessctl
    ddcutil
    gammastep
    slurp
    libqalculate
    playerctl
    cliphist
    gpu-screen-recorder
    hyprlock
    libnotify
    ffmpeg
    networkmanager
    bluez-utils
    wireplumber
    swappy
    ttf-material-symbols-variable
    noto-fonts-emoji
)

BUILD_PKGS=(
    cmake
    ninja
    gcc
)

AUR_PKGS=(
    qt6-m3shapes-git
)

FISH_PKGS=(
    fish
    eza
    zoxide
    direnv
)

DRY_RUN=0
AUTO_START=1
INSTALL_FISH=1
INSTALL_UPDATE_HOOK=1

for arg in "$@"; do
    case "$arg" in
        --dry-run) DRY_RUN=1 ;;
        --no-start) AUTO_START=0 ;;
        --no-fish) INSTALL_FISH=0 ;;
        --no-update-hook) INSTALL_UPDATE_HOOK=0 ;;
        -h | --help)
            cat <<EOF
usage: install.sh [options]

  --dry-run   print what would happen without changing anything
  --no-start  install and build, but do not launch the shell
  --no-fish   leave your fish config alone (greeting, colours)
  --no-update-hook  do not install the pacman update hook
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
    local helper=""
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

    warn "no AUR helper found; skipping optional AUR packages: ${AUR_PKGS[*]}"
}

has_quickshell() {
    command -v qs >/dev/null 2>&1 || command -v quickshell >/dev/null 2>&1
}

install_quickshell() {
    has_quickshell && return 0

    if pacman -Si quickshell >/dev/null 2>&1; then
        install_arch_pkgs quickshell
    else
        local helper=""
        for candidate in paru yay pikaur; do
            if command -v "$candidate" >/dev/null 2>&1; then
                helper="$candidate"
                break
            fi
        done
        if [ -z "$helper" ]; then
            if [ "$DRY_RUN" -eq 1 ]; then
                printf '  [dry-run] install an AUR helper, then install quickshell-git\n'
                return 0
            fi
            die "quickshell is unavailable in the configured repositories and no AUR helper was found; install paru, yay, or pikaur"
        fi
        say "installing quickshell-git from the AUR with $helper"
        [ "$DRY_RUN" -eq 1 ] || "$helper" -S --needed --noconfirm quickshell-git
    fi

    [ "$DRY_RUN" -eq 1 ] || has_quickshell || die "quickshell installed unsuccessfully; expected qs or quickshell on PATH"
}

install_google_sans() {
    if fc-list : family 2>/dev/null | tr ',' '\n' | grep -qx "Google Sans"; then
        return 0
    fi

    local fontdir="${XDG_DATA_HOME:-$HOME/.local/share}/fonts"
    if [ "$DRY_RUN" -eq 1 ]; then
        printf '  [dry-run] fetch Google Sans (400/500/700) from the Google Fonts API into %s and run fc-cache\n' "$fontdir"
        return 0
    fi

    say "installing Google Sans from the Google Fonts API"
    local css
    css=$(curl -fsS -m 15 -A "Mozilla/4.0" \
        "https://fonts.googleapis.com/css2?family=Google+Sans:wght@400;500;700") || {
        warn "could not fetch the Google Sans stylesheet;"
        warn "the shell will fall back to another font"
        return 0
    }

    local tmp url weight name
    tmp=$(mktemp -d)
    while read -r weight url; do
        case "$weight" in
            400) name=Regular ;;
            500) name=Medium ;;
            700) name=Bold ;;
            *) continue ;;
        esac
        curl -fsS -m 30 -o "$tmp/GoogleSans-$name.ttf" "$url" || {
            warn "could not download Google Sans $name"
            rm -rf "$tmp"
            return 0
        }
    done < <(printf '%s\n' "$css" | awk '
        /font-weight:/ { w = $2; gsub(/;/, "", w) }
        /src: url/ { if (match($0, /https:[^)]+/)) print w, substr($0, RSTART, RLENGTH) }
    ')

    if ! ls "$tmp"/*.ttf >/dev/null 2>&1; then
        warn "the Google Sans stylesheet had no usable font URLs"
        rm -rf "$tmp"
        return 0
    fi

    mkdir -p "$fontdir"
    cp "$tmp"/*.ttf "$fontdir/"
    rm -rf "$tmp"
    fc-cache -f "$fontdir" >/dev/null 2>&1 || true
    say "installed Google Sans into $fontdir"
}

deploy_fish() {
    local src="$TARGET/extras/fish"
    local conf="${XDG_CONFIG_HOME:-$HOME/.config}"
    local dest="$conf/fish"
    local userconf="$conf/lampshell"

    if [ ! -d "$src" ]; then
        warn "no extras/fish in the checkout, skipping the fish config"
        return 0
    fi

    if [ "$DRY_RUN" -eq 1 ]; then
        printf '  [dry-run] back up %s to %s.bak, then copy %s into it\n' "$dest" "$dest" "$src"
        printf '  [dry-run] touch %s/user-config.fish\n' "$userconf"
        return 0
    fi

    if [ -e "$dest" ]; then
        rm -rf "$dest.bak"
        cp -a "$dest" "$dest.bak"
        say "backed up $dest to $dest.bak"
    fi

    mkdir -p "$dest"
    cp -a "$src/." "$dest/"

    mkdir -p "$userconf"
    touch "$userconf/user-config.fish"

    say "installed the fish greeting and colours into $dest"
}

[ "$(uname -s)" = "Linux" ] || die "only Linux is supported"

if ! command -v pacman >/dev/null 2>&1; then
    die "no pacman found. This installer is Arch based; the dependencies and
package names here will not be right elsewhere."
fi

if [ "$(id -u)" -ne 0 ] && ! command -v sudo >/dev/null 2>&1; then
    die "sudo is required to install Arch packages"
fi

printf '\n'
say "installing runtime dependencies"
install_arch_pkgs "${RUNTIME_PKGS[@]}"
install_google_sans

printf '\n'
say "installing build dependencies"
install_arch_pkgs "${BUILD_PKGS[@]}"

printf '\n'
say "installing quickshell"
install_quickshell
install_aur_pkgs

if [ "$INSTALL_FISH" -eq 1 ]; then
    printf '\n'
    say "installing fish dependencies"
    install_arch_pkgs "${FISH_PKGS[@]}"
fi

printf '\n'
if [ -d "$TARGET/.git" ]; then
    say "existing checkout at $TARGET, refreshing it"
    if [ "$DRY_RUN" -eq 1 ]; then
        printf '  [dry-run] git -C %s pull --ff-only\n' "$TARGET"
    else
        if [ -n "$(git -C "$TARGET" status --porcelain 2>/dev/null)" ]; then
            die "$TARGET has local changes; commit or stash them before running the installer again"
        fi
        git -C "$TARGET" pull --ff-only
    fi
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

if [ "$INSTALL_FISH" -eq 1 ]; then
    printf '\n'
    say "installing the fish config"
    deploy_fish
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

install_update_hook() {
    local updater="/usr/local/bin/lampshell-git-update"
    local hookdir="/usr/share/libalpm/hooks"
    local hook="$hookdir/90-lampshell.hook"
    local repo_file="/etc/lampshell/repo"

    if [ ! -d "$hookdir" ]; then
        warn "no pacman hook directory, skipping"
        warn "run 'lampshell update' yourself to pull changes"
        return 0
    fi

    if [ "$DRY_RUN" -eq 1 ]; then
        printf '  [dry-run] would install %s, %s and %s\n' "$updater" "$hook" "$repo_file"
        return 0
    fi

    if [ ! -f "$TARGET/scripts/lampshell-git-update" ] || [ ! -f "$TARGET/scripts/lampshell-pacman-hook.hook" ]; then
        warn "updater or hook missing from $TARGET/scripts, skipping"
        return 0
    fi

    as_root install -Dm755 "$TARGET/scripts/lampshell-git-update" "$updater"
    as_root install -Dm644 "$TARGET/scripts/lampshell-pacman-hook.hook" "$hook"
    tmp_repo=$(mktemp)
    printf '%s\n' "$TARGET" > "$tmp_repo"
    as_root install -Dm644 "$tmp_repo" "$repo_file"
    rm -f "$tmp_repo"

    say "every pacman transaction will now pull and rebuild Lampshell"
    printf '  that covers %s and %s\n' "cachy-update" "paru -Syu"
}

if [ "$INSTALL_UPDATE_HOOK" -eq 1 ]; then
    printf '\n'
    say "installing the updater hook"
    install_update_hook
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

printf '\n'
say "done"
if [ "$DRY_RUN" -eq 0 ]; then
    printf '  \033[1mlampshell status\033[0m to check on it, \033[1mlampshell update\033[0m to pull changes\n'
fi

printf '\n'
