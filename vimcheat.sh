#!/bin/bash
# vimcheat.sh - Local Vim cheat sheet terminal app

set -e

CHEAT_URL="https://raw.githubusercontent.com/rtorr/vim-cheat-sheet/master/locales/en_us.json"
CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/vimcheat"
JSON_FILE="$CACHE_DIR/vimcheat.json"
TSV_FILE="$CACHE_DIR/vimcheat.tsv"
CACHE_DAYS=7

usage() {
  cat <<USAGE
Usage: $0 [--search TERM] [--category NAME] [--categories] [--all] [--help]

  --search TERM       Search commands matching TERM
  --category NAME     Show commands for category NAME
  --categories        List all categories
  --all               Display full cheat sheet
  --help              Show this help
USAGE
}

pager() {
  if command -v bat &>/dev/null; then
    bat --paging=always
  elif command -v less &>/dev/null; then
    less -R
  else
    cat
  fi
}

fetch_data() {
  mkdir -p "$CACHE_DIR"
  if [ ! -f "$JSON_FILE" ] || [ $(($(date +%s) - $(stat -c %Y "$JSON_FILE" 2>/dev/null))) -ge $((CACHE_DAYS*24*3600)) ]; then
    if ! curl -fsSL "$CHEAT_URL" -o "$JSON_FILE"; then
      echo "Failed to download cheat sheet" >&2
      exit 1
    fi
  fi
  jq -r 'to_entries[] | select(.value|type=="object" and has("commands")) | .value.title as $t | .value.commands | to_entries[] | [$t, .key, .value] | @tsv' "$JSON_FILE" > "$TSV_FILE"
}

list_categories() {
  cut -f1 "$TSV_FILE" | uniq
}

show_category() {
  awk -F"\t" -v cat="$1" 'tolower($1)==tolower(cat){printf "  %s - %s\n",$2,$3}' "$TSV_FILE"
}

show_all() {
  awk -F"\t" '{if(NR==1||$1!=prev){if(NR>1)print"";print $1":";prev=$1}printf "  %s - %s\n",$2,$3}' "$TSV_FILE"
}

search_cmd() {
  grep -i "$1" "$TSV_FILE" | awk -F"\t" '{printf "%s | %s - %s\n",$1,$2,$3}'
}

main() {
  case "$1" in
    --search)
      shift; fetch_data; search_cmd "$1" ;;
    --category)
      shift; fetch_data; show_category "$1" ;;
    --categories)
      fetch_data; list_categories ;;
    --all)
      fetch_data; show_all | pager ;;
    --help|"")
      usage ;;
    *)
      echo "Unknown option: $1" >&2; usage; exit 1 ;;
  esac
}

main "$@"
