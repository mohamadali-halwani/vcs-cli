#!/bin/bash
# vimcheat.sh - Local Vim cheat sheet terminal app

set -e

CHEAT_URL="https://raw.githubusercontent.com/rtorr/vim-cheat-sheet/master/locales/en_us.json"
CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/vimcheat"
JSON_FILE="$CACHE_DIR/vimcheat.json"
TSV_FILE="$CACHE_DIR/vimcheat.tsv"
CACHE_DAYS=7

# colour definitions
RESET=$(tput sgr0)
BOLD=$(tput bold)
COL_HEADER=$(tput setaf 4)
COL_CMD=$(tput setaf 6)
COL_DESC=$(tput setaf 7)

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
  jq -r 'def order:["global","cursorMovement","insertMode","editing","markingText","visualCommands","registers","marks","macros","cutAndPaste","indentText","exiting","searchAndReplace","searchMultipleFiles","tabs","workingWithMultipleFiles","diff"]; order[] as $k | (.[ $k ]? // empty) as $cat | select($cat|type=="object" and has("commands")) | $cat.title as $t | $cat.commands | to_entries[] | [$t, .key, .value] | @tsv' "$JSON_FILE" > "$TSV_FILE"
}

list_categories() {
  cut -f1 "$TSV_FILE" | uniq | while read -r c; do
    printf "%b%s%b\n" "${BOLD}${COL_HEADER}" "$c" "$RESET"
  done
}

show_category() {
  local cat="$1"
  grep -i -Fq "$cat"$'\t' "$TSV_FILE" || { echo "Unknown category: $cat" >&2; return 1; }
  awk -F"\t" -v cat="$cat" -v h="${BOLD}${COL_HEADER}" -v c="${COL_CMD}" -v d="${COL_DESC}" -v r="${RESET}" '
    tolower($1)==tolower(cat){
      if(!shown){print h $1 r; print h "--------------------" r; shown=1}
      printf "  %s%-15s%s - %s%s%s\n", c,$2,r,d,$3,r
    }
  ' "$TSV_FILE"
}

show_all() {
  awk -F"\t" -v h="${BOLD}${COL_HEADER}" -v c="${COL_CMD}" -v d="${COL_DESC}" -v r="${RESET}" '
    NR==1 || $1!=prev {
      if(NR>1) print "";
      print h $1 r;
      print h "--------------------" r;
      prev=$1
    }
    {
      printf "  %s%-15s%s - %s%s%s\n", c,$2,r,d,$3,r
    }
  ' "$TSV_FILE"
}

search_cmd() {
  grep -i "$1" "$TSV_FILE" | awk -F"\t" -v h="${BOLD}${COL_HEADER}" -v c="${COL_CMD}" -v d="${COL_DESC}" -v r="${RESET}" '{printf "%s%-20s%s | %s%-15s%s - %s%s%s\n",h,$1,r,c,$2,r,d,$3,r}'
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
