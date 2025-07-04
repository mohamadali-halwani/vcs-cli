#!/bin/bash
# vcs.sh - Local Vim Cheat Sheet Command Line Interface app vcs-cli.

set -e

CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/vcs"
CHEAT_URL="https://raw.githubusercontent.com/rtorr/vim-cheat-sheet/master/locales/en_us.json"
JSON_FILE="$CACHE_DIR/vcs.json"
TSV_FILE="$CACHE_DIR/vcs.tsv"
MAP_FILE="$(dirname "$0")/mapping.tsv"
CACHE_DAYS=7

# Color definitions
RESET=$(tput sgr0)
BOLD=$(tput bold)
UNDERLINE=$(tput smul)
DIM=$(tput dim)

# Main colors
COL_HEADER=$(tput setaf 4)    # Blue
COL_CMD=$(tput setaf 6)       # Cyan
COL_DESC=$(tput setaf 7)      # White
COL_SEP=$(tput setaf 8)       # Gray
COL_SECTION=$(tput setaf 5)   # Magenta
COL_HIGHLIGHT=$(tput setaf 3) # Yellow
COL_SPECIAL=$(tput setaf 2)   # Green

# Color disable support
NO_COLOR=${NO_COLOR:-""}
if [ -n "$NO_COLOR" ]; then
    RESET="" BOLD="" UNDERLINE="" DIM=""
    COL_HEADER="" COL_CMD="" COL_DESC="" COL_SEP=""
    COL_SECTION="" COL_HIGHLIGHT="" COL_SPECIAL=""
fi

usage() {
    cat << EOF
${BOLD}${COL_HEADER}Usage:${RESET} $(basename "$0") [OPTIONS]

Options:
  ${COL_CMD}--search${RESET} TERM       ${COL_DESC}Search commands matching TERM${RESET}
  ${COL_CMD}--category${RESET} NAME     ${COL_DESC}Show commands for category NAME${RESET}
  ${COL_CMD}--categories${RESET}        ${COL_DESC}List all categories${RESET}
  ${COL_CMD}--all${RESET}              ${COL_DESC}Display full cheat sheet${RESET}
  ${COL_CMD}--help${RESET}             ${COL_DESC}Show this help${RESET}
EOF
}

pager() {
    if command -v bat >/dev/null 2>&1; then
        bat --paging=always
    elif command -v less >/dev/null 2>&1; then
        less -R
    else
        cat
    fi
}

list_categories() {
    if [[ ! -f "$TSV_FILE" ]]; then
        echo "${COL_SPECIAL}Error:${RESET} File not found: ${COL_HIGHLIGHT}$TSV_FILE${RESET}" >&2
        return 1
    fi

    printf "\n%b%s%b\n" "${BOLD}${COL_SECTION}" "Available Categories:" "$RESET"
    printf "%b%s%b\n" "${COL_SEP}" "━━━━━━━━━━━━━━━━━" "$RESET"
    
    cut -f1 "$TSV_FILE" | sort | uniq | while read -r category; do
        printf "  %b%s%b\n" "${BOLD}${COL_HEADER}" "$category" "$RESET"
    done
    printf "\n"
}

show_category() {
    local cat="$1"
    if ! grep -q "^${cat}	" "$TSV_FILE"; then
        echo "${COL_SPECIAL}Error:${RESET} Unknown category: ${COL_HIGHLIGHT}$cat${RESET}" >&2
        return 1
    fi
    
    awk -F'\t' -v cat="$cat" \
        -v h="${BOLD}${COL_SECTION}" \
        -v c="${COL_CMD}" \
        -v d="${COL_DESC}" \
        -v s="${COL_SEP}" \
        -v r="${RESET}" \
        -v u="${UNDERLINE}" '
        $1 == cat {
            if (!shown) {
                print ""
                print h "━━━━ " u $1 u " ━━━━" r
                print ""
                shown=1
            }
            printf "  %s%-25s%s %s║%s %s%s%s\n", c, $2, r, s, r, d, $3, r
        }
    ' "$TSV_FILE"
}

search_cmd() {
    local term="$1"
    printf "\n%b%s%b\n" "${BOLD}${COL_SECTION}" "Search Results:" "${RESET}"
    printf "%b%s%b\n\n" "${COL_SEP}" "━━━━━━━━━━━━━" "${RESET}"
    
    grep -i "$term" "$TSV_FILE" | \
    awk -F'\t' \
        -v h="${BOLD}${COL_SECTION}" \
        -v c="${COL_CMD}" \
        -v d="${COL_DESC}" \
        -v s="${COL_SEP}" \
        -v r="${RESET}" \
        -v hl="${COL_HIGHLIGHT}" '
        {
            printf "%s%s%s%s%s\n", h, "Found in: ", hl, $1, r
            printf "  %s%-25s%s %s║%s %s%s%s\n\n", c, $2, r, s, r, d, $3, r
        }
    '
}


show_all() {
    awk -F'\t' \
        -v h="${BOLD}${COL_SECTION}" \
        -v c="${COL_CMD}" \
        -v d="${COL_DESC}" \
        -v s="${COL_SEP}" \
        -v r="${RESET}" \
        -v u="${UNDERLINE}" '
        NR==1 || $1!=prev {
            if(NR>1) print "\n"
            print h "┏━━━━━━━━━━━━━━━━━━━━━━━━━┓" r
            print h "┃" r "      " h u $1 r h "      " h "┃" r
            print h "┗━━━━━━━━━━━━━━━━━━━━━━━━━┛" r
            prev=$1
        }
        {
            cmd = $2
            desc = $3
            # Remove any HTML tags from description
            gsub(/<[^>]*>/, "", desc)
            printf "  %s%-25s%s %s║%s %s%s%s\n", c, cmd, r, s, r, d, desc, r
        }
    ' "$TSV_FILE"
}

fetch_data() {
    mkdir -p "$CACHE_DIR"
    
    if [ ! -f "$JSON_FILE" ] || [ $(($(date +%s) - $(stat -c %Y "$JSON_FILE" 2>/dev/null))) -ge $((CACHE_DAYS*24*3600)) ]; then
        if ! curl -fsSL "$CHEAT_URL" -o "$JSON_FILE"; then
            echo "Failed to download cheat sheet" >&2
            exit 1
        fi
    fi

    jq -r '
        def key_to_command:
            # Cursor movement
            if . == "topCursor" then "zt"
            elif . == "bottomCursor" then "zb"
            elif . == "centerCursor" then "zz"
            
            # Basic symbols
            elif . == "zero" then "0"
            elif . == "caret" then "^"
            elif . == "dollar" then "$"
            elif . == "dot" then "."
            elif . == "percent" then "%"
            elif . == "tilde" then "~"
            elif . == "semicolon" then ";"
            elif . == "comma" then ","
            elif . == "backtick" then "`"
            elif . == "quote" then "\""
            # Note: special handling for apostrophe
            elif . == "apostrophe" then "'\''"
            
            # Exit commands
            elif . == "ZZ" then "ZZ"
            elif . == "ZQ" then "ZQ"
            
            # Special keys
            elif . == "Esc" then "<Esc>"
            elif . == "Ctrl" then "<Ctrl>"
            
            # Registers
            elif . == "quotePlus" then "\"+y"
            elif . == "quotePlusp" then "\"+p"
            elif . == "quoteZero" then "\"0"
            elif . == "quotePercent" then "\"%"
            elif . == "quotePound" then "\"#"
            elif . == "quoteSlash" then "\""
            elif . == "quoteColon" then "\":"
            
            # Replace commands
            elif . == "colonPercentForwardSlashOldForwardSlashNewForwardSlashg" then ":%s/old/new/g"
            elif . == "colonPercentForwardSlashOldForwardSlashNewForwardSlashgc" then ":%s/old/new/gc"
            
            # Tab commands
            elif . == "colonTabNew" then ":tabnew"
            elif . == "colonTabMove" then ":tabmove"
            elif . == "colonTabClose" then ":tabc"
            elif . == "colonTabOnly" then ":tabo"
            elif . == "colonTabDo" then ":tabdo command"
            
            # Buffer commands
            elif . == "colonBnext" then ":bnext"
            elif . == "colonBprev" then ":bprev"
            elif . == "colonBuffers" then ":ls"
            elif . == "colonBdelete" then ":bd"
            
            # Window commands
            elif . == "CtrlWs" then "Ctrl+w s"
            elif . == "CtrlWv" then "Ctrl+w v"
            elif . == "CtrlWw" then "Ctrl+w w"
            elif . == "CtrlWq" then "Ctrl+w q"
            elif . == "CtrlWx" then "Ctrl+w x"
            elif . == "CtrlWEqual" then "Ctrl+w ="
            elif . == "CtrlWh" then "Ctrl+w h"
            elif . == "CtrlWj" then "Ctrl+w j"
            elif . == "CtrlWk" then "Ctrl+w k"
            elif . == "CtrlWl" then "Ctrl+w l"
            elif . == "CtrlWH" then "Ctrl+w H"
            elif . == "CtrlWJ" then "Ctrl+w J"
            elif . == "CtrlWK" then "Ctrl+w K"
            elif . == "CtrlWL" then "Ctrl+w L"
            
            # Diff commands
            elif . == "dp" then "dp"
            elif . == "do" then "do"
            elif . == "colonDiffthis" then ":diffthis"
            elif . == "colonDiffupdate" then ":diffupdate"
            elif . == "colonDiffoff" then ":diffoff"
            
            # Other special cases
            elif . == "gT" then "gT"
            elif . == "gt" then "gt"
            elif . == "colonwqa" then ":wqa"
            elif . == "colonqBang" then ":q!"
            elif . == "colonwsudo" then ":w !sudo tee %"
            elif . == "colonw" then ":w"
            elif . == "colonq" then ":q"
            elif . == "colonwq" then ":wq"
            elif . == "colone" then ":e"
            elif . == "colonsp" then ":sp"
            elif . == "colonvsp" then ":vsp"
            elif . == "colonvertba" then ":vert ba"
            elif . == "colontabba" then ":tab ba"
            elif . == "colonnoh" then ":noh"
            elif . == "colonvimgrep" then ":vimgrep"
            elif . == "coloncn" then ":cn"
            elif . == "coloncp" then ":cp"
            elif . == "coloncopen" then ":copen"
            elif . == "coloncclose" then ":cclose"
            
            # Default handling
            elif test("^Ctrl") then
                gsub("^Ctrl"; "<Ctrl>")
            elif test("^colon") then
                ":" + (.[5:] | ascii_downcase)
            else
                .
            end;

        def order: [
            "global",
            "cursorMovement",
            "insertMode",
            "editing",
            "markingText",
            "visualCommands",
            "registers",
            "marks",
            "macros",
            "cutAndPaste",
            "indentText",
            "exiting",
            "searchAndReplace",
            "searchMultipleFiles",
            "tabs",
            "workingWithMultipleFiles",
            "diff"
        ];

        order[] as $k | 
        (.[$k]? // empty) as $cat | 
        select($cat|type=="object" and has("commands")) | 
        $cat.title as $t | 
        $cat.commands | 
        to_entries[] | 
        [$t, (.key | key_to_command), .value] | 
        @tsv
    ' "$JSON_FILE" > "$TSV_FILE"

    if [ -f "$MAP_FILE" ]; then
        awk -F'\t' '
            NR==FNR {map[$1]=$2; next} 
            {
                if(map[$2]) $2=map[$2]; 
                print $1 "\t" $2 "\t" $3
            }
        ' "$MAP_FILE" "$TSV_FILE" > "$TSV_FILE.tmp" && mv "$TSV_FILE.tmp" "$TSV_FILE"
    fi
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
