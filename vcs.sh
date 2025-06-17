#!/bin/bash
# vcs.sh - Local Vim Cheat Sheet Command Line Interface app vcs-cli.

set -e

CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/vcs"
CHEAT_URL="https://raw.githubusercontent.com/rtorr/vim-cheat-sheet/master/locales/en_us.json"
JSON_FILE="$CACHE_DIR/vcs.json"
TSV_FILE="$CACHE_DIR/vcs.tsv"
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
  
  # Convert JSON keys to actual vim commands and create TSV
  jq -r '
    def key_to_command:
      # Cursor positioning
      if . == "topCursor" then "zt"
      elif . == "bottomCursor" then "zb" 
      elif . == "centerCursor" then "zz"
      
      # Basic symbols
      elif . == "zero" then "0"
      elif . == "caret" then "^"
      elif . == "dollar" then "$"
      elif . == "semicolon" then ";"
      elif . == "comma" then ","
      elif . == "dot" then "."
      elif . == "percent" then "%"
      elif . == "tilde" then "~"
      elif . == "backtick" then "`"
      elif . == "quote" then "\""
      elif . == "apostrophe" then "'"'"'"
      
      # Brackets and braces
      elif . == "openCurlyBrace" then "{"
      elif . == "closeCurlyBrace" then "}"
      elif . == "openSquare" then "["
      elif . == "closeSquare" then "]"
      elif . == "openParen" then "("
      elif . == "closeParen" then ")"
      elif . == "lessThan" then "<"
      elif . == "greaterThan" then ">"
      elif . == "lessThanLessThan" then "<<"
      elif . == "greaterThanGreaterThan" then ">>"
      elif . == "lessThanPercent" then "<%"
      elif . == "greaterThanPercent" then ">%"
      elif . == "greaterThanib" then ">ib"
      elif . == "greaterThanat" then ">at"
      
      # Slashes and symbols
      elif . == "forwardSlash" then "/"
      elif . == "backslash" then "\\\\"
      elif . == "questionMark" then "?"
      elif . == "exclamation" then "!"
      elif . == "at" then "@"
      elif . == "hashtag" then "#"
      elif . == "asterisk" then "*"
      elif . == "ampersand" then "&"
      elif . == "pipe" then "|"
      elif . == "colon" then ":"
      
      # Numbers and special combinations
      elif . == "fiveG" then "5G"
      elif . == "twoyy" then "2yy"
      elif . == "twodd" then "2dd"
      elif . == "3==" then "3=="
      elif . == "threeToFiveD" then "3,5d"
      elif . == "tenCommaOneD" then "10,1d"
      elif . == "dotCommaDollarD" then ".,$ d"
      elif . == "dotCommaOneD" then ".,1 d"
      elif . == "hashgt" then "#gt"
      
      # Ctrl combinations
      elif test("^[Cc]trl[Pp]lus") then
        gsub("^[Cc]trl[Pp]lus"; "Ctrl+") |
        gsub("Plus"; "+")
      
      # Colon commands
      elif test("^colon") then
        gsub("^colon"; ":") |
        gsub("Plus"; "+") |
        gsub("([a-z])([A-Z])"; "\\1 \\2"; "g") |
        ascii_downcase
      
      # Pattern matching commands
      elif . == "forwardSlashPattern" then "/pattern"
      elif . == "questionMarkPattern" then "?pattern"
      elif . == "backslashVpattern" then "\\vpattern"
      elif . == "colonPercentForwardSlashOldForwardSlashNewForwardSlashg" then ":%s/old/new/g"
      elif . == "colonPercentForwardSlashOldForwardSlashNewForwardSlashgc" then ":%s/old/new/gc"
      elif . == "colonnoh" then ":noh"
      
      # Special cases for various commands
      elif . == "gTilde" then "g~"
      elif . == "cDollar" then "c$"
      elif . == "yDollar" then "y$"
      elif . == "dDollar" then "d$"
      elif . == "=Percent" then "=%"
      elif . == "=iB" then "=iB"
      elif . == "gg=G" then "gg=G"
      elif . == "closeSquarep" then "]p"
      elif . == "closeSquarec" then "]c"
      elif . == "openSquarec" then "[c"
      
      # Registers and marks  
      elif . == "show" then ":reg"
      elif . == "pasteRegisterX" then "\"xp"
      elif . == "yankIntoRegisterX" then "\"xy"
      elif . == "quotePlusy" then "\"+y"
      elif . == "quotePlusp" then "\"+p"
      elif . == "list" then ":marks"
      elif . == "currentPositionA" then "ma"
      elif . == "jumpPositionA" then "'"'"'a"
      elif . == "yankToMarkA" then "y'"'"'a"
      elif . == "backtick0" then "`0"
      elif . == "backtickQuote" then "`\""
      elif . == "backtickDot" then "`."
      elif . == "backtickBacktick" then "``"
      elif . == "colonjumps" then ":jumps"
      elif . == "colonchanges" then ":changes"
      elif . == "gcomma" then "g,"
      elif . == "gsemicolon" then "g;"
      
      # Macros
      elif . == "recordA" then "qa"
      elif . == "stopRecording" then "q"
      elif . == "runA" then "@a"
      elif . == "rerun" then "@@"
      
      # Global commands
      elif . == "helpForKeyword" then ":h keyword"
      elif . == "saveAsFile" then ":sav file"
      elif . == "closePane" then ":q"
      elif . == "colonTerminal" then ":terminal"
      
      # Window/tab management
      elif . == "colonTabNew" then ":tabnew"
      elif . == "colontabmove" then ":tabmove"
      elif . == "colontabc" then ":tabc"
      elif . == "colontabo" then ":tabo"
      elif . == "colontabdo" then ":tabdo command"
      
      # Diff commands  
      elif . == "colonDiffthis" then ":diffthis"
      elif . == "colonDiffupdate" then ":diffupdate"
      elif . == "colonDiffoff" then ":diffoff"
      
      # Pattern replacement for remaining items
      else
        gsub("Plus"; "+") |
        gsub("^colon"; ":") |
        gsub("^Ctrl"; "Ctrl") |
        gsub("^ctrl"; "Ctrl") |
        .
      end;
      
    def order:["global","cursorMovement","insertMode","editing","markingText","visualCommands","registers","marks","macros","cutAndPaste","indentText","exiting","searchAndReplace","searchMultipleFiles","tabs","workingWithMultipleFiles","diff"]; 
    order[] as $k | 
    (.[ $k ]? // empty) as $cat | 
    select($cat|type=="object" and has("commands")) | 
    $cat.title as $t | 
    $cat.commands | 
    to_entries[] | 
    [$t, (.key | key_to_command), .value] | 
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
