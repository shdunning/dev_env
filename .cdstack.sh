# maximum size of directory stack
: ${CDSTACKSIZE:=36}

# restore stack elements from saved file, if any
if [ -r ~/.cdstack ] ; then
    read CDSTACK < ~/.cdstack
fi

# newer bashes appear to do 'cd -P' on login, but if part
# of your $HOME is symlinked (ie, your $HOME is /home/david
# but /home is a symlink to /usr/home) this symlink will
# mess up initial cdstack printing of $HOME as '~', but
# cd'ing to your symlinked $HOME seems to clear this up
#builtin cd

alias cd=cdstack
cdstack()
{
    local dir new sep
    local cnt indx total=0
    local IFS=: PS3= HOME=${HOME%/}

    # count all elements in the stack
    for dir in $CDSTACK ; do
        total=$(( $total + 1 ))
    done

    # typing 'cd .' means print the stack
    # since stack elements are stored with $HOME expanded
    # let's normalize $HOME into shorter tilde ~ notation
    if [ "$1" = "." ] ; then

        if [ $total -eq 0 ] ; then
            echo "Stack empty" >&2
            return 1
        fi

        new= sep=
        for dir in $CDSTACK ; do
            case "$dir" in "$HOME"/*)
                # normalize into ~ notation
                dir="~${dir#$HOME}"
            esac
            new="$new$sep$dir"
            sep="$IFS"
        done

        # use 'select' for nice multi-column numbered output
        select dir in $new ; do
            :
        done < /dev/null 2>&1

        return 0

    fi

    # typing 'cd -n' means chdir to nth element in stack
    # note how we assume '-n' is the first positional argument
    # eg, on bash 2.0 and above, 'cd [-L|-P] -n' won't work
    # see 'man bash' for explanation of other cd options
    case "$1" in -[1-9]*)

        if [ $total -eq 0 ] ; then
            echo "Stack empty" >&2
            return 1
        fi

        indx=${1#-}
        if [ $indx -gt $total ] ; then
            echo "Stack element out of range" >&2
            return 1
        fi

        cnt=0 new=
        for dir in $CDSTACK ; do
            cnt=$(( $cnt + 1 ))
            if [ $cnt -eq $indx ] ; then
                # found nth element
                new="$dir"
                break
            fi
        done

        # install nth element as positional argument
        set -- "$new"

    esac

    # change to new directory as requested
    builtin cd "$@" || return $?

    # build temporary stack, popping old cwd
    # also remove duplicates and other clutter
    new= sep=
    for dir in $CDSTACK ; do
        [ "$dir" = "" ] && continue
        [ "$dir" = "." ] && continue
        [ "$dir" = "$PWD" ] && continue
        [ "$dir" = "$HOME" ] && continue
        [ "$dir" = "$OLDPWD" ] && continue
        case :"$dir": in *:"$new":*)
            # found duplicate
            continue
        esac
        new="$new$sep$dir"
        sep="$IFS"
    done

    # now push old cwd onto top of stack
    # but never push home or cwd, those are clutter
    if [ "$OLDPWD" != "$HOME" -a "$OLDPWD" != "$PWD" ] ; then
        new="$OLDPWD$sep$new"
    fi

    # copy temporary stack to $CDSTACK variable
    # trimming stack to first $CDSTACKSIZE elements
    CDSTACK= cnt=0 sep=
    for dir in $new ; do
        cnt=$(( $cnt + 1 ))
        if [ $cnt -le $CDSTACKSIZE ] ; then
            CDSTACK="$CDSTACK$sep$dir"
            sep="$IFS"
        fi
    done

    return 0
}
# vim: ft=sh ai et ts=4 sts=4 sw=4