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
without launching the shell. Add `--no-fish` to leave your fish config alone,
or `--no-update-hook` to skip the optional pacman update hook.

It is a bash script, but piping it to zsh or another shell is fine, it
re-executes itself under bash rather than failing on `mapfile` or
`BASH_SOURCE`.

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

Fetches the current branch, fast-forwards only, rebuilds the plugin only when
the plugin sources actually changed, and restarts the shell if it was running.
It refuses to run with local changes, a detached HEAD, or a non-fast-forward
branch, so it never overwrites work in progress.

Check the installation with:

```bash
lampshell doctor
```

This reports missing commands for the shell, plugin build, screenshots,
recording, clipboard history, theming, weather, audio, Bluetooth, and other
enabled features.

####  doing it by hand

Clone, then use `scripts/lampshell`, which builds the plugin on first run and
launches detached:

```bash
git clone https://github.com/l6t9/lampshell.git ~/.config/quickshell/lampshell
~/.config/quickshell/lampshell/scripts/lampshell start
```

`scripts/lampshell` also drives `restart`, `stop`, `status`, `logs`,
`plugin`, and toggles for the launcher, clipboard, emoji picker and panels.
Put `scripts/` on your `PATH` to call it as `lampshell <command>`.

`scripts/check-palette` asks the running shell what every colour role resolved
to and compares that against `theme/colors.json`, so a role that silently falls
back to the literal declared in `Theme.qml` shows up as a failure. It also
re-derives the contrast and chroma boost transform and compares that against
what the shell produced. Pass `--fresh` to seed `colors.default.json` first,
which is what a new install starts from, then put the previous file back.

Running `qs` directly against the config fails with `module
"Lampshell.Services" is not installed`, because the plugin build output is
gitignored and `QML_IMPORT_PATH` is only set by the launcher script.

####  dependencies

The installer targets Arch Linux and installs the complete feature set. Core
runtime packages are `quickshell` (or `quickshell-git` through an AUR helper),
`hyprland`, `qt6-base`, `qt6-declarative`, `matugen`, `jq`, `git`, `curl`,
`wl-clipboard`, `grim`, `imagemagick`, `brightnessctl`, `ddcutil`, `slurp`,
`gammastep`, `libqalculate`, `playerctl`, `cliphist`, `gpu-screen-recorder`,
`hyprlock`, `libnotify`, `ffmpeg`, `networkmanager`, `bluez-utils`,
`wireplumber`, and `swappy`.

Fonts are Google Sans (fetched from the Google Fonts API, since the
`ttf-google-sans` AUR package's upstream source is dead),
`ttf-material-symbols-variable`, and `noto-fonts-emoji`. Fish extras add
`fish`, `eza`, `zoxide`, and `direnv` unless `--no-fish` is passed.

The native services plugin needs `cmake`, `ninja`, and a C++20 compiler.
Arch provides the Qt6 headers through `qt6-base` and `qt6-declarative`.
Optional shell integrations such as DDC brightness, NetworkManager, Bluetooth,
recording, weather, and night-light controls degrade gracefully when their
backend is unavailable; `lampshell doctor` shows exactly what is missing.
