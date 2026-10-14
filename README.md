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
without launching the shell. Add `--no-fish` to leave your fish config alone.

It also drops a fish config into `~/.config/fish`: a `config.fish` plus a
`fish_greeting` that prints the Lampshell logo and, if you have it,
`fastfetch`. Your old `~/.config/fish` is copied to `~/.config/fish.bak`
first, and anything else you kept in there is left in place.

Re-running it is safe: packages are only installed when missing, and an
existing checkout is fast-forwarded rather than replaced.

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

`scripts/check-palette` asks the running shell what every colour role resolved
to and compares that against `theme/colors.json`, so a role that silently falls
back to the literal declared in `Theme.qml` shows up as a failure. Pass
`--fresh` to seed `colors.default.json` first, which is what a new install
starts from, then put the previous file back.

Running `qs` directly against the config fails with `module
"Lampshell.Services" is not installed`, because the plugin build output is
gitignored and `QML_IMPORT_PATH` is only set by the launcher script.

####  dependencies

Runtime: `quickshell-git` and `ttf-google-sans` (both AUR, so these need an
AUR helper rather than pacman), `qt6-base`, `qt6-declarative` (this also
provides `QtQuick.Shapes`), `hyprland`, `matugen`, `wl-clipboard`,
`brightnessctl` or `ddcutil`, `slurp`, and the fonts
`ttf-material-symbols-variable` and `noto-fonts-emoji`.

Build, needed once: `cmake`, `ninja` and a C++20 compiler. Arch ships the Qt6
headers inside `qt6-base` and `qt6-declarative` themselves, so there are no
separate `-devel` packages to install.
