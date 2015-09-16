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

    local open bookid format
    case "${(L)OSTYPE}" in
        linux*|*bsd*)
            open="xdg-open"
            ;;
        darwin*)
            open="open"
            ;;
        *)
            # TODO: what is the best fallback?
            open="xdg-open"
            ;;
    esac

    bookid="${(q)1}"
    if ! mkdir -p /tmp/zaw-calibre ; then
        echo "Could not create directory /tmp/zaw-calibre"
        return
    fi
    for format in pdf epub rtf doc docx chm mht ps ppt pptx txt djvu mobi lit ; do
        calibredb export --formats $format --to-dir=/tmp/zaw-calibre --dont-update-metadata --dont-write-opf --dont-save-cover --template=$bookid $bookid
        if [ -f /tmp/zaw-calibre/${bookid}.${format} ]; then
            BUFFER="${open} \"/tmp/zaw-calibre/${bookid}.${format}\""
            zle accept-line
            break
        fi
    done
}
zaw-register-src -n calibre zaw-src-calibre
