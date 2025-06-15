# Vim Cheat Sheet CLI

`vimcheat.sh` is a lightweight Bash script that fetches the Vim cheat sheet from the
[vim-cheat-sheet](https://github.com/rtorr/vim-cheat-sheet) project. The data is cached
locally and displayed with colours that mimic the layout of the original page.

## Installation

```bash
chmod +x vimcheat.sh
# Optionally move it somewhere in your PATH
```

On Arch Linux you can build a package from the provided `PKGBUILD`:

```bash
makepkg -si
```

The first run will download the cheat sheet into `~/.cache/vimcheat`.  The cache
is refreshed automatically once a week.

## Usage

```bash
./vimcheat.sh --search "delete"      # Search the cheat sheet
./vimcheat.sh --category "Editing"   # Show all commands in a category
./vimcheat.sh --categories           # List available categories
./vimcheat.sh --all                  # Show the full cheat sheet with paging
```

Add `--help` to see a short summary of the options.

---


## Arch Linux package

The repository ships with a `PKGBUILD` that allows you to build a package for
Arch or derivative distributions. The resulting package installs a `vimcheat`
binary to `/usr/bin`.
