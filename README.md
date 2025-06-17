# Vim Cheat Sheet CLI

`vcs.sh` is a lightweight Bash script that fetches the Vim cheat sheet from the [vim-cheat-sheet](https://github.com/rtorr/vim-cheat-sheet) project.
The data is cached locally and displayed with colours via `tput`.  A mapping of
key names ensures special characters like `]c` are shown exactly as they appear
on the website.

## Installation

```bash
chmod +x vcs.sh
# Optionally move it somewhere in your PATH
```

On Arch Linux you can build a package from the provided `PKGBUILD`:

```bash
makepkg -si
```

The first run will download the cheat sheet into `~/.cache/vcs`.  The cache
is refreshed automatically once a week.

## Usage

```bash
vcs --search "delete"      # Search the cheat sheet
vcs --category "Editing"   # Show all commands in a category
vcs --categories           # List available categories
vcs --all                  # Show the full cheat sheet with paging
vcs --help                 # Display a short summary of the options 
```
---

## Arch Linux package

The repository ships with a `PKGBUILD` that allows you to build a package for Arch or derivative distributions. 
The resulting package installs a `vcs` binary to `/usr/bin`.
