#
# zaw-src-calibre
#
# zaw source for calibre library books
#

function zaw-src-calibre() {
    emulate -L zsh
    setopt local_options extended_glob null_glob

    if which calibredb > /dev/null 2>&1; then
        calibredb list --sort-by title | tail +2 | while read id rest; do
            candidates+=("${id}")
            cand_descriptions+=("${rest}")
        done
    else
        candidates=("Calibre or Calibre command line tools are not installed")
    fi
    actions=("zaw-open-book" "zaw-show-metadata" "zaw-callback-append-to-buffer")
    act_descriptions=("open book" "show metadata" "append to edit buffer")
}

function zaw-show-metadata() {
    BUFFER="calibredb show_metadata \"${(q)1}\""
    zle accept-line
}

function zaw-open-book() {
    emulate -L zsh

    local open bookid format temp_dir
    case "${(L)OSTYPE}" in
        linux*|*bsd*) open="xdg-open" ;;
        darwin*)      open="open" ;;
        *)            open="xdg-open" ;; # TODO: what is the best fallback?
    esac

    bookid="${(q)1}"

    # TODO: Figure out if there's a way to open it directly from the calibre
    # source location because these temporary files can't be cleaned up
    # deterministically as they are opened for use.

    temp_dir="${TMPDIR:-${TEMP:-${TMP:-/tmp}}}/zaw-source-calibre"
    if ! mkdir -p "$temp_dir" ; then
        echo "Could not create temporary directory $temp_dir"
        return
    fi
    for format in pdf epub rtf doc docx chm mht ps ppt pptx txt djvu mobi lit ; do
        calibredb export --formats $format --to-dir="$temp_dir" --replace-whitespace --dont-update-metadata --dont-write-opf --dont-save-cover --template="$bookid" "$bookid"
        if [ -f "$temp_dir/${bookid}.${format}" ]; then
            BUFFER="${open} '$temp_dir/${bookid}.${format}'"
            zle accept-line
            break
        fi
    done
    # Delete files older than a month. Nobody keeps books opens for more than a month, right? Right?
    find "${temp_dir}/" -type f -mtime -30 -delete > /dev/null 2>&1 &!
}
if declare -f -F zaw-register-src ; then
    zaw-register-src -n calibre zaw-src-calibre
else
    echo "zaw (https://github.com/zsh-users/zaw) is not loaded, Please load it first"
    return
fi
