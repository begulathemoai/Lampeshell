#!/usr/bin/env bash
set -euo pipefail

WALL_DIR="${1:-}"
THUMB_DIR="${2:-}"

if [[ -z "$WALL_DIR" || -z "$THUMB_DIR" ]]; then
    echo "Usage: $0 <wall_dir> <thumb_dir>" >&2
    exit 1
fi

if [[ ! -d "$WALL_DIR" ]]; then
    echo "Wall dir does not exist: $WALL_DIR" >&2
    exit 1
fi

if ! command -v ffmpeg >/dev/null 2>&1; then
    if command -v notify-send >/dev/null 2>&1; then
        notify-send -u critical "Wallpaper Widget" "ffmpeg is missing! Please install it to generate thumbnails."
    fi
    exit 0
fi

mkdir -p "$THUMB_DIR" || exit 1

exec 200>"$THUMB_DIR/.thumb_lock"
flock -n 200 || exit 0

find "$THUMB_DIR" -maxdepth 1 -name "*.tmp.jpg" -delete

declare -A valid_thumbs

while IFS= read -r -d '' wallfile; do
    filename="${wallfile##*/}"
    valid_thumbs["${filename}.jpg"]=1
done < <(find "$WALL_DIR" -maxdepth 1 -type f \
    \( -iname "*.png" -o -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.webp" \) -print0)

while IFS= read -r -d '' thumb; do
    thumbname="${thumb##*/}"
    if [[ -z "${valid_thumbs[$thumbname]+_}" ]]; then
        rm -f "$thumb"
    fi
done < <(find "$THUMB_DIR" -maxdepth 1 -name "*.jpg" -print0)

export THUMB_DIR
find "$WALL_DIR" -maxdepth 1 -type f \
    \( -iname "*.png" -o -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.webp" \) -print0 | \
    xargs -0 -n 1 -P 4 bash -c '
        set -euo pipefail
        img="$1"
        filename="${img##*/}"
        thumb="$THUMB_DIR/${filename}.jpg"
        tmp_thumb="$THUMB_DIR/${filename}.tmp.jpg"

        if [ ! -f "$thumb" ]; then
            nice -n 19 ionice -c 3 ffmpeg -y -v quiet -threads 1 -i "$img" \
                -vf "scale=640:-1:flags=lanczos" -q:v 3 "$tmp_thumb" \
            && mv "$tmp_thumb" "$thumb" \
            || rm -f "$tmp_thumb"
        fi
    ' _
