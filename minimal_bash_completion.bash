# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2, or (at your option)
# any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software Foundation,
# Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.

#
# Modifications by stdweird:
#   These are minimal set of functions to make autocompletion and optcomplete work on pre-bash 4.2
#   They are taken from https://github.com/brianzimmer/dotfiles/blob/master/bashcompletion/bash_completion
#   which is version 1.3 of the bash_completion project from http://bash-completion.alioth.debian.org/
#   So these too are GPLv2 or later
#   The functions are wrapped in conditionals to check if the functions already exist or not (eg set via OS environment)
# 

type _quote_readline_by_ref >& /dev/null
if [ $? -ne 0 ]
then # begin _quote_readline_by_ref conditional

# This function quotes the argument in a way so that readline dequoting
# results in the original argument.  This is necessary for at least
# `compgen' which requires its arguments quoted/escaped:
#
#     $ ls "a'b/"
#     c
#     $ compgen -f "a'b/"       # Wrong, doesn't return output
#     $ compgen -f "a\'b/"      # Good (bash-4)
#     a\'b/c
#     $ compgen -f "a\\\\\'b/"  # Good (bash-3)
#     a\'b/c
#
# On bash-3, special characters need to be escaped extra.  This is
# unless the first character is a single quote (').  If the single
# quote appears further down the string, bash default completion also
# fails, e.g.:
#
#     $ ls 'a&b/'
#     f
#     $ foo 'a&b/<TAB>  # Becomes: foo 'a&b/f'
#     $ foo a'&b/<TAB>  # Nothing happens
#
# See also:
# - http://lists.gnu.org/archive/html/bug-bash/2009-03/msg00155.html
# - http://www.mail-archive.com/bash-completion-devel@lists.alioth.\
#   debian.org/msg01944.html
# @param $1  Argument to quote
# @param $2  Name of variable to return result to

_quote_readline_by_ref()
{
    if [[ ${1:0:1} == "'" ]]; then
        if [[ ${BASH_VERSINFO[0]} -ge 4 ]]; then
            # Leave out first character
            printf -v $2 %s "${1:1}"
        else
            # Quote word, leaving out first character
            printf -v $2 %q "${1:1}"
            # Double-quote word (bash-3)
            printf -v $2 %q ${!2}
        fi
    elif [[ ${BASH_VERSINFO[0]} -le 3 && ${1:0:1} == '"' ]]; then
        printf -v $2 %q "${1:1}"
    else
        printf -v $2 %q "$1"
    fi

    # If result becomes quoted like this: $'string', re-evaluate in order to
    # drop the additional quoting.  See also: http://www.mail-archive.com/
    # bash-completion-devel@lists.alioth.debian.org/msg01942.html
    [[ ${!2:0:1} == '$' ]] && eval $2=${!2}
} # _quote_readline_by_ref()

fi # end _quote_readline_by_ref conditional

type _expand >& /dev/null
if [ $? -ne 0 ]
then # begin _expand conditional

# This function expands tildes in pathnames
#
_expand()
{
    # FIXME: Why was this here?
    #[ "$cur" != "${cur%\\}" ] && cur="$cur\\"

    # Expand ~username type directory specifications.  We want to expand
    # ~foo/... to /home/foo/... to avoid problems when $cur starting with
    # a tilde is fed to commands and ending up quoted instead of expanded.

    if [[ "$cur" == \~*/* ]]; then
        eval cur=$cur
    elif [[ "$cur" == \~* ]]; then
        cur=${cur#\~}
        COMPREPLY=( $( compgen -P '~' -u "$cur" ) )
        [ ${#COMPREPLY[@]} -eq 1 ] && eval COMPREPLY[0]=${COMPREPLY[0]}
        return ${#COMPREPLY[@]}
    fi
}

fi # end _expand conditional

type _get_comp_words_by_ref >& /dev/null
if [ $? -ne 0 ]
then # begin _get_comp_words_by_ref conditional

# Reassemble command line words, excluding specified characters from the
# list of word completion separators (COMP_WORDBREAKS).
# @param $1 chars  Characters out of $COMP_WORDBREAKS which should
#     NOT be considered word breaks. This is useful for things like scp where
#     we want to return host:path and not only path, so we would pass the
#     colon (:) as $1 here.
# @param $2 words  Name of variable to return words to
# @param $3 cword  Name of variable to return cword to
#
__reassemble_comp_words_by_ref() {
    local exclude i j ref
    # Exclude word separator characters?
    if [[ $1 ]]; then
        # Yes, exclude word separator characters;
        # Exclude only those characters, which were really included
        exclude="${1//[^$COMP_WORDBREAKS]}"
    fi
        
    # Default to cword unchanged
    eval $3=$COMP_CWORD
    # Are characters excluded which were former included?
    if [[ $exclude ]]; then
        # Yes, list of word completion separators has shrunk;
        # Re-assemble words to complete
        for (( i=0, j=0; i < ${#COMP_WORDS[@]}; i++, j++)); do
            # Is current word not word 0 (the command itself) and is word not
            # empty and is word made up of just word separator characters to be
            # excluded?
            while [[ $i -gt 0 && ${COMP_WORDS[$i]} && 
                ${COMP_WORDS[$i]//[^$exclude]} == ${COMP_WORDS[$i]} 
            ]]; do
                [ $j -ge 2 ] && ((j--))
                # Append word separator to current word
                ref="$2[$j]"
                eval $2[$j]=\${!ref}\${COMP_WORDS[i]}
                # Indicate new cword
                [ $i = $COMP_CWORD ] && eval $3=$j
                # Indicate next word if available, else end *both* while and for loop
                (( $i < ${#COMP_WORDS[@]} - 1)) && ((i++)) || break 2
            done
            # Append word to current word
            ref="$2[$j]"
            eval $2[$j]=\${!ref}\${COMP_WORDS[i]}
            # Indicate new cword
            [[ $i == $COMP_CWORD ]] && eval $3=$j
        done
    else
        # No, list of word completions separators hasn't changed;
        eval $2=\( \"\${COMP_WORDS[@]}\" \)
    fi
} # __reassemble_comp_words_by_ref()

# Assign variables one scope above the caller
# Usage: local varname [varname ...] && 
#        _upvars [-v varname value] | [-aN varname [value ...]] ...
# Available OPTIONS:
#     -aN  Assign next N values to varname as array
#     -v   Assign single value to varname
# Return: 1 if error occurs
# See: http://fvue.nl/wiki/Bash:_Passing_variables_by_reference
_upvars() {
    if ! (( $# )); then
        echo "${FUNCNAME[0]}: usage: ${FUNCNAME[0]} [-v varname"\
            "value] | [-aN varname [value ...]] ..." 1>&2
        return 2
    fi
    while (( $# )); do
        case $1 in
            -a*)
                # Error checking
                [[ ${1#-a} ]] || { echo "bash: ${FUNCNAME[0]}: \`$1': missing"\
                    "number specifier" 1>&2; return 1; }
                printf %d "${1#-a}" &> /dev/null || { echo "bash:"\
                    "${FUNCNAME[0]}: \`$1': invalid number specifier" 1>&2
                    return 1; }
                # Assign array of -aN elements
                [[ "$2" ]] && unset -v "$2" && eval $2=\(\"\${@:3:${1#-a}}\"\) && 
                shift $((${1#-a} + 2)) || { echo "bash: ${FUNCNAME[0]}:"\
                    "\`$1${2+ }$2': missing argument(s)" 1>&2; return 1; }
                ;;
            -v)
                # Assign single value
                [[ "$2" ]] && unset -v "$2" && eval $2=\"\$3\" &&
                shift 3 || { echo "bash: ${FUNCNAME[0]}: $1: missing"\
                "argument(s)" 1>&2; return 1; }
                ;;
            *)
                echo "bash: ${FUNCNAME[0]}: $1: invalid option" 1>&2
                return 1 ;;
        esac
    done
}

# @param $1 exclude  Characters out of $COMP_WORDBREAKS which should NOT be
#     considered word breaks. This is useful for things like scp where
#     we want to return host:path and not only path, so we would pass the
#     colon (:) as $1 in this case.  Bash-3 doesn't do word splitting, so this
#     ensures we get the same word on both bash-3 and bash-4.
# @param $2 words  Name of variable to return words to
# @param $3 cword  Name of variable to return cword to
# @param $4 cur  Name of variable to return current word to complete to
# @see ___get_cword_at_cursor_by_ref()
__get_cword_at_cursor_by_ref() {
    local cword words=()
    __reassemble_comp_words_by_ref "$1" words cword

    local i cur2
    local cur="$COMP_LINE"
    local index="$COMP_POINT"
    for (( i = 0; i <= cword; ++i )); do
        while [[
            # Current word fits in $cur?
            "${#cur}" -ge ${#words[i]} &&
            # $cur doesn't match cword?
            "${cur:0:${#words[i]}}" != "${words[i]}"
        ]]; do
            # Strip first character
            cur="${cur:1}"
            # Decrease cursor position
            ((index--))
        done

        # Does found word matches cword?
        if [[ "$i" -lt "$cword" ]]; then
            # No, cword lies further;
            local old_size="${#cur}"
            cur="${cur#${words[i]}}"
            local new_size="${#cur}"
            index=$(( index - old_size + new_size ))
        fi
    done

    if [[ "${words[cword]:0:${#cur}}" != "$cur" ]]; then
        # We messed up. At least return the whole word so things keep working
        cur2=${words[cword]}
    else
        cur2=${cur:0:$index}
    fi

    local "$2" "$3" "$4" && 
        _upvars -a${#words[@]} $2 "${words[@]}" -v $3 "$cword" -v $4 "$cur2"
}


# Get the word to complete and optional previous words.
# This is nicer than ${COMP_WORDS[$COMP_CWORD]}, since it handles cases
# where the user is completing in the middle of a word.
# (For example, if the line is "ls foobar",
# and the cursor is here -------->   ^
# Also one is able to cross over possible wordbreak characters.
# Usage: _get_comp_words_by_ref [OPTIONS] [VARNAMES]
# Available VARNAMES:
#     cur         Return cur via $cur
#     prev        Return prev via $prev
#     words       Return words via $words
#     cword       Return cword via $cword
#
# Available OPTIONS:
#     -n EXCLUDE  Characters out of $COMP_WORDBREAKS which should NOT be 
#                 considered word breaks. This is useful for things like scp
#                 where we want to return host:path and not only path, so we
#                 would pass the colon (:) as -n option in this case.  Bash-3
#                 doesn't do word splitting, so this ensures we get the same
#                 word on both bash-3 and bash-4.
#     -c VARNAME  Return cur via $VARNAME
#     -p VARNAME  Return prev via $VARNAME
#     -w VARNAME  Return words via $VARNAME
#     -i VARNAME  Return cword via $VARNAME
#
# Example usage:
#
#    $ _get_comp_words_by_ref -n : cur prev
#
_get_comp_words_by_ref()
{
    local exclude flag i OPTIND=1
    local cur cword words=()
    local upargs=() upvars=() vcur vcword vprev vwords

    while getopts "c:i:n:p:w:" flag "$@"; do
        case $flag in
            c) vcur=$OPTARG ;;
            i) vcword=$OPTARG ;;
            n) exclude=$OPTARG ;;
            p) vprev=$OPTARG ;;
            w) vwords=$OPTARG ;;
        esac
    done
    while [[ $# -ge $OPTIND ]]; do 
        case ${!OPTIND} in
            cur)   vcur=cur ;;
            prev)  vprev=prev ;;
            cword) vcword=cword ;;
            words) vwords=words ;;
            *) echo "bash: $FUNCNAME(): \`${!OPTIND}': unknown argument" \
                1>&2; return 1
        esac
        let "OPTIND += 1"
    done

    __get_cword_at_cursor_by_ref "$exclude" words cword cur

    [[ $vcur   ]] && { upvars+=("$vcur"  ); upargs+=(-v $vcur   "$cur"  ); }
    [[ $vcword ]] && { upvars+=("$vcword"); upargs+=(-v $vcword "$cword"); }
    [[ $vprev  ]] && { upvars+=("$vprev" ); upargs+=(-v $vprev 
        "${words[cword - 1]}"); }
    [[ $vwords ]] && { upvars+=("$vwords"); upargs+=(-a${#words[@]} $vwords
        "${words[@]}"); }

    (( ${#upvars[@]} )) && local "${upvars[@]}" && _upvars "${upargs[@]}"
}

fi # end _get_comp_words_by_ref conditional
