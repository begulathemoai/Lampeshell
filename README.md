# Lampshell

| | |
| :---: | :---: |
| ![Theme Variant 1](screenshots/preview1.jpeg) | ![Theme Variant 2](screenshots/preview2.jpeg) |

this is a quickshell config I forked from [octashell](https://github.com/octagonemusic/octashell) (renamed to lampshell), for personal use

very WIP, dont expect anything to work perfectly (yet)

---

###  how to run this

One command. It installs the dependencies, clones the repo, builds the native
services plugin, seeds a default colour palette and starts the shell:

```bash
curl -fsSL https://raw.githubusercontent.com/l6t9/lampshell/main/scripts/install.sh | bash
```

It will ask for your password when it needs to install packages. Add
`--dry-run` to see everything it would do first, or `--no-start` to build
without launching the shell.

Re-running it is safe: packages are only installed when missing, and an
existing checkout is left alone.

####  updating

```bash
lampshell update
```

Pulls new commits, rebuilds the plugin only when the plugin sources actually
changed, and restarts the shell if it was running. It refuses to guess when
your local checkout has diverged and leaves it alone.

####  doing it by hand

Clone, then use `scripts/lampshell`, which builds the plugin on first run and
launches detached:

```bash
git clone https://github.com/l6t9/lampshell.git ~/.config/quickshell
~/.config/quickshell/lampshell/scripts/lampshell start
```

`scripts/lampshell` also drives `restart`, `stop`, `status`, `logs`,
`plugin`, and toggles for the launcher, clipboard, emoji picker and panels.
Put `scripts/` on your `PATH` to call it as `lampshell <command>`.

Running `qs` directly against the config fails with `module
"Lampshell.Services" is not installed`, because the plugin build output is
gitignored and `QML_IMPORT_PATH` is only set by the launcher script.

####  dependencies

Runtime: `quickshell-git` (the git version, not a tagged release),
`qt6-base`, `qt6-declarative` (this also provides `QtQuick.Shapes`),
`hyprland`, `matugen`, `wl-clipboard`, `brightnessctl` or `ddcutil`, `slurp`,
and the fonts `ttf-google-sans`, `ttf-material-symbols-variable`,
`ttf-noto-color-emoji`.

Build, needed once: `cmake`, `ninja`, a C++20 compiler, `qt6-base-devel`,
`qt6-declarative-devel`.

####  packaging

`packaging/PKGBUILD` builds the same shell as a normal Arch package, putting a
`lampshell` command on your `PATH` and the config in `/usr/share/lampshell`.
It is not published to the AUR yet, so build it locally:

```bash
cd ~/.config/quickshell/lampshell && makepkg -si
```

A packaged install is not a git checkout, so `lampshell update` points you at
your package manager instead.

---
