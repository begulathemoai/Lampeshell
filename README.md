# Lampshell

| | |
| :---: | :---: |
| ![Theme Variant 1](screenshots/preview1.jpeg) | ![Theme Variant 2](screenshots/preview2.jpeg) |

this is a quickshell config I forked from [octashell](https://github.com/octagonemusic/octashell) (renamed to lampshell), for personal use

very WIP, dont expect anything to work perfectly (yet)

---

###  how to run this

The shell needs quickshell and a C++ toolchain. `scripts/lampshell start`
builds the native services plugin on first run, seeds a default colour
palette, and launches the shell detached.

**Runtime dependencies**

- `quickshell-git` — the git version, not a tagged release
- `qt6-base`, `qt6-declarative` (this also provides `QtQuick.Shapes`)
- `hyprland` — supplies `hyprctl` and `hyprlock`
- `matugen` — derives the colour scheme from the wallpaper
- `wl-clipboard` — clipboard history
- `brightnessctl` or `ddcutil` — backlight control
- `slurp` — region selection
- fonts: `ttf-google-sans`, `ttf-material-symbols-variable`, `ttf-noto-color-emoji`

**Build dependencies** — needed once, for the plugin

- `cmake`, `ninja`, a C++20 compiler
- `qt6-base-devel`, `qt6-declarative-devel`

Then:

```bash
git clone https://github.com/l6t9/lampshell.git ~/.config/quickshell
~/.config/quickshell/lampshell/scripts/lampshell start
```

Put `scripts/` on your `PATH` if you want to drive it as `lampshell
<command>` — `restart`, `stop`, `status`, `logs`, `plugin`, and toggles for
the launcher, clipboard, emoji picker and panels.

Note that running `qs` directly against the config will fail with `module
"Lampshell.Services" is not installed`, because the plugin build output is
gitignored and `QML_IMPORT_PATH` is only set by the launcher script.

---
