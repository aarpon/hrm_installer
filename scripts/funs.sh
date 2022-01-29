declare -A dbms=( ["mysql"]="MySQL" ["mysql-server"]="MySQL" ["mariadb"]="MariaDB" ["pgsql"]="PostgreSQL" ["postgresql"]="PostgreSQL" ["postgres"]="PostgreSQL")

function catch() {
#As per Tino @ https://stackoverflow.com/questions/11027679/capture-stdout-and-stderr-into-different-variables
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

function abort() {
    echo -e "$1\nAborting HRM installation."
    exit 1
}

function errcheck() {
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

function sedconf() {
    # set a line in a text file based on a pattern
    # sedconf 'the_file.txt' '^some_variable_name=.*' 'some_variable_name="new value"'
    if [ -f "$1" ] ; then
        if [[ ! -z $(grep "$2" "$1") ]]; then
            sed -i -e "s|$2|$3|" "$1"
        else
            # If we can't find the pattern, we append to the new line and output a warning
            echo -e "\e[1;43mCould not find pattern >>>$2<<< in $1\e[0m"
            echo "$3" >> $1
        fi
    fi
}

function rmline() {
    # remove a line based on a pattern
    # rmline 'the_file.txt' '^some_variable_name=.*'
    if [ -f "$1" ] ; then
        if [[ ! -z $(grep "$2" "$1") ]]; then
            sed -i -e "/^$2/d" "$1"
        else
            # If we can't find the pattern, output a warning
            echo -e "\e[1;43mCould not find pattern >>>$2<<< in $1\e[0m"
        fi
    fi
}

function getconf() {
    # get a variable value defined in a text file. $1: the file, $2 the variable. To use it:
    # REPLY=$(getconf 'the_file.txt' '^some_variable_name=.*') && myvar=$REPLY
    if [ -f "$1" ] ; then
        match=$(grep -m 1 "$2" "$1")
        if [[ ! -z $match ]]; then
            # Here we found the pattern
            echo ${match#*=} | xargs
        else
            exit 1
        fi
    else
        exit 1
    fi
}

function diffconf() {
    # diff between $1=orig and $2=changed files for $3=pattern, if different then return value from changed
    # REPLY=$(diffconf 'orig_file.txt' 'changed_file.txt' '^some_variable_name=.*') && myvar=$REPLY
    REPLY=$(getconf "$1" "$3") && var1=$REPLY || exit 1
    REPLY=$(getconf "$2" "$3") && var2=$REPLY || exit 1
    if [[ $var2 != $var1 ]]; then
        echo $var2
        exit 0
    fi
    exit 1
}

function ver() {
    # https://stackoverflow.com/a/37939589
    # Used for comparing version strings
    echo "$@" | awk -F. '{ printf("%d%03d%03d", $1,$2,$3); }';
}
