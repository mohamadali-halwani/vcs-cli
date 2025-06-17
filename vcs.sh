#!/bin/bash
# vimcheat.sh - Local Vim cheat sheet terminal app

set -e

CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/vimcheat"
CHEAT_URL="https://raw.githubusercontent.com/rtorr/vim-cheat-sheet/master/locales/en_us.json"
JSON_FILE="$CACHE_DIR/vimcheat.json"
TSV_FILE="$CACHE_DIR/vimcheat.tsv"
MAP_FILE="$(dirname "$0")/mapping.tsv"
CACHE_DAYS=7

# colour definitions
RESET=$(tput sgr0)
BOLD=$(tput bold)
COL_HEADER=$(tput setaf 4)
COL_CMD=$(tput setaf 6)
COL_DESC=$(tput setaf 7)
COL_SEP=$(tput setaf 8)

usage() {
  printf "%bUsage:%b %s [OPTIONS]\n\n" "${BOLD}${COL_HEADER}" "${RESET}" "$0"
  printf "  %b--search%b TERM       %bSearch commands matching TERM%b\n" "$COL_CMD" "$RESET" "$COL_DESC" "$RESET"
  printf "  %b--category%b NAME     %bShow commands for category NAME%b\n" "$COL_CMD" "$RESET" "$COL_DESC" "$RESET"
  printf "  %b--categories%b        %bList all categories%b\n" "$COL_CMD" "$RESET" "$COL_DESC" "$RESET"
  printf "  %b--all%b               %bDisplay full cheat sheet%b\n" "$COL_CMD" "$RESET" "$COL_DESC" "$RESET"
  printf "  %b--help%b              %bShow this help%b\n" "$COL_CMD" "$RESET" "$COL_DESC" "$RESET"
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
  
  # Convert JSON keys to human-readable commands and create TSV
  jq -r '
    def humanize_key:
      gsub("Plus"; " + ") |
      gsub("Ctrl"; "Ctrl") |
      gsub("Alt"; "Alt") |
      gsub("Shift"; "Shift") |
      gsub("Esc"; "Esc") |
      gsub("Tab"; "Tab") |
      gsub("Enter"; "Enter") |
      gsub("Space"; "Space") |
      gsub("Backspace"; "Backspace") |
      gsub("Delete"; "Delete") |
      gsub("Insert"; "Insert") |
      gsub("Home"; "Home") |
      gsub("End"; "End") |
      gsub("PageUp"; "Page Up") |
      gsub("PageDown"; "Page Down") |
      gsub("Up"; "↑") |
      gsub("Down"; "↓") |
      gsub("Left"; "←") |
      gsub("Right"; "→") |
      gsub("zero"; "0") |
      gsub("caret"; "^") |
      gsub("dollar"; "$") |
      gsub("semicolon"; ";") |
      gsub("comma"; ",") |
      gsub("dot"; ".") |
      gsub("percent"; "%") |
      gsub("tilde"; "~") |
      gsub("backtick"; "`") |
      gsub("quote"; "\"") |
      gsub("apostrophe"; "'\''") |
      gsub("openCurlyBrace"; "{") |
      gsub("closeCurlyBrace"; "}") |
      gsub("openSquare"; "[") |
      gsub("closeSquare"; "]") |
      gsub("openParen"; "(") |
      gsub("closeParen"; ")") |
      gsub("lessThan"; "<") |
      gsub("greaterThan"; ">") |
      gsub("forwardSlash"; "/") |
      gsub("backslash"; "\\\\") |
      gsub("questionMark"; "?") |
      gsub("exclamation"; "!") |
      gsub("at"; "@") |
      gsub("hashtag"; "#") |
      gsub("asterisk"; "*") |
      gsub("ampersand"; "&") |
      gsub("pipe"; "|") |
      gsub("colon"; ":");
      
    def order:["global","cursorMovement","insertMode","editing","markingText","visualCommands","registers","marks","macros","cutAndPaste","indentText","exiting","searchAndReplace","searchMultipleFiles","tabs","workingWithMultipleFiles","diff"]; 
    order[] as $k | 
    (.[ $k ]? // empty) as $cat | 
    select($cat|type=="object" and has("commands")) | 
    $cat.title as $t | 
    $cat.commands | 
    to_entries[] | 
    [$t, (.key | humanize_key), .value] | 
    @tsv
  ' "$JSON_FILE" > "$TSV_FILE"
  
  if [ -f "$MAP_FILE" ]; then
    # Use proper field separator handling in awk
    awk -F '\t' '
      NR==FNR {map[$1]=$2; next} 
      {
        if(map[$2]) $2=map[$2]; 
        print $1 "\t" $2 "\t" $3
      }
    ' "$MAP_FILE" "$TSV_FILE" > "$TSV_FILE.tmp" && mv "$TSV_FILE.tmp" "$TSV_FILE"
  fi
}

list_categories() {
    # Check if TSV file exists
    if [[ ! -f "$TSV_FILE" ]]; then
        echo "Error: File not found: $TSV_FILE" >&2
        return 1
    fi

    # Extract, sort, and print unique categories with formatting
    cut -f1 "$TSV_FILE" | uniq | while read -r c; do
        printf "%b%s%b\n" "${BOLD}${COL_HEADER}" "$c" "$RESET"
    done
}

show_category() {
  local cat="$1"
  # Use proper field separator for grep
  grep -F "$(printf '%s\t' "$cat")" "$TSV_FILE" | head -1 > /dev/null || { echo "Unknown category: $cat" >&2; return 1; }
  
  awk -F"\t" -v cat="$cat" -v h="${BOLD}${COL_HEADER}" -v c="${COL_CMD}" -v d="${COL_DESC}" -v s="${COL_SEP}" -v r="${RESET}" '
    BEGIN{IGNORECASE=1}
    $1==cat {
      if(!shown){print h $1 r; print h "--------------------" r; shown=1}
      printf "  %s%-15s%s %s- %s%s%s\n", c, $2, r, s, d, $3, r
    }
  ' "$TSV_FILE"
}

show_all() {
  awk -F"\t" -v h="${BOLD}${COL_HEADER}" -v c="${COL_CMD}" -v d="${COL_DESC}" -v s="${COL_SEP}" -v r="${RESET}" '
    NR==1 || $1!=prev {
      if(NR>1) print "";
      print h $1 r;
      print h "--------------------" r;
      prev=$1
    }
    {
      printf "  %s%-15s%s %s- %s%s%s\n", c,$2,r,s,d,$3,r
    }
  ' "$TSV_FILE"
}

search_cmd() {
  grep -i "$1" "$TSV_FILE" | awk -F"\t" -v h="${BOLD}${COL_HEADER}" -v c="${COL_CMD}" -v d="${COL_DESC}" -v s="${COL_SEP}" -v r="${RESET}" '
    BEGIN{IGNORECASE=1}
    {printf "%s%-20s%s %s| %s%-15s%s %s- %s%s%s\n", h, $1, r, s, c, $2, r, s, d, $3, r}
  '
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
