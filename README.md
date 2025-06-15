# Vim Cheat Sheet CLI

This repository includes a small Node example and a Bash script for displaying a
Vim cheat sheet in the terminal.

The **`vimcheat.sh`** script downloads the cheat sheet from the public
[vim-cheat-sheet](https://github.com/rtorr/vim-cheat-sheet) project and lets you
search and view the commands locally.

## Installation

```bash
chmod +x vimcheat.sh
# Optionally move it somewhere in your PATH
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

The old Node example files remain for reference.
