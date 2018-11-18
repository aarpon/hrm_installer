#As per Tino @ https://stackoverflow.com/questions/11027679/capture-stdout-and-stderr-into-different-variables
function catch()
{
eval "$({
__2="$(
  { __1="$("${@:3}")"; } 2>&1;
  ret=$?;
  printf '%q=%q\n' "$1" "$__1" >&2;
  exit $ret
  )"
ret="$?";
printf '%s=%q\n' "$2" "$__2" >&2;
printf '( exit %q )' "$ret" >&2;
} 2>&1 )";
}

function abort()
{
        echo -e "$1\nAborting HRM installation."
        exit 1
}

function errcheck()
{
        [ $? ] && abort "$1"
}

function readkey() {
    # Read a single keypress and return it as lower-case. Optionally, the
    # prompt can be set by providing a string as 1st positional parameter.
    if [ -n "$1" ] ; then
        _PROMPT="$1"
    else
        _PROMPT="> "
    fi
    read -p "$_PROMPT" -n 1
    echo $REPLY | tr '[A-Z]' '[a-z]'
    unset _PROMPT
}

function readkey_choice() {
    # Ask the user for pressing one of two keys (case insensitive). If not
    # specified otherwise, 'y' and 'n' are the default keys.
    [ -n "$1" ] && CH1="$1" || CH1="y"
    [ -n "$2" ] && CH2="$2" || CH2="n"
    unset REPLY
    while [ "$REPLY" != "$CH1" ] && [ "$REPLY" != "$CH2" ] ; do
        REPLY=$(readkey " [$CH1/$CH2] ")
    done
    echo $REPLY
    unset REPLY CH1 CH2
}

function readstring() {
    # Show a preset string that can be changed or accepted.
    # Do not accept empty return values.
    while [ -z "$REPLY" ] ; do
        read -p '> ' -e -i "$1"
    done
    echo $REPLY
}

function getvalidpath() {
    file_path=""
    while [ ! -f "$file_path" ] ; do
        file_path=$(readstring "$1")
    done
    echo $file_path
}

function waitconfirm() {
    # Display a message and wait for the user to confirm by pressing 'y'.
    echo "Press [y] to continue, [Ctrl]-[C] to abort."
    while ! [ "$(readkey)" == "y" ] ; do
        echo
    done
}

function sedconf()
{
	sed -i -e "s|$2|$3|" "$1"
}

