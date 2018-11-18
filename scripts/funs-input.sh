#!/bin/bash
context="$(dirname $BASH_SOURCE)"
source "$context/argparser.sh"

function wt_read()
{
    local title="Input box"
    local message="Please type in a value:"
    local interactive=false #Interactive input
    local value="" #Default value
    local allowempty=false #Allow empty input
    local password=false #A password box
    local debug=false #Show command line and exits


    declare -A ARGPARSER_MAP
    ARGPARSER_MAP=(
        [i]=interactive
        [d]=debug
        [a]=allowempty
        [p]=password
    )

    parse_args "$@" && rc=$? || rc=$?
    [ -n "$argument1" ] && value=$argument1

    [ -n "$interactive" ] && opti=$interactive
    [ -n "$debug" ] && optd=$debug
    [ -n "$allowempty" ] && opta=$allowempty
    [ -n "$password" ] && optp=$password

    if [ $debug == true ]; then
        echo "---"
        echo "\$opti = $opti" 
        echo "\$optd = $optd" 
        echo "\$opta = $opta" 
        echo "\$optp = $optp" 

        echo "\$interactive = $interactive" 
        echo "\$debug = $debug" 
        echo "\$title = $title" 
        echo "\$message = $message" 
        echo "\$value = $value" 
        echo "\$allowempty = $allowempty" 
        echo "\$password = $password" 
        echo "\$argument1 = $argument1" 
        echo "\$argument2 = $argument2" 
    fi

    if [ $opti == true ]; then
        $password && password="--passwordbox" || password="--inputbox"
        while : ;
        do
            REPLY=$(whiptail "$password" "Enter the $message:" 8 70 "$value" \
                --title "$title" 3>&1 1>&2 2>&3)
            rc=$?
            value=$REPLY
            [ $rc -eq 0 ] && $opta && break 
            [ $rc -eq 1 ] && exit 1
            [ -n "$REPLY" ] && ! $opta && break
        done
    else
        echo "The $message is: $value" >&2
        REPLY=$value
    fi

    echo "$REPLY"
}

function wt_print()
{
    local title="Input box"
    local interactive=false #Interactive input
    local message="" #Default output
    local debug=false #Show command line and exits
    local quit=false #quit after displaying the message


    declare -A ARGPARSER_MAP
    ARGPARSER_MAP=(
        [i]=interactive
        [d]=debug
        [q]=quit
    )

    parse_args "$@" && rc=$? || rc=$?
    [ -n "$argument1" ] && message=$argument1

    [ -n "$interactive" ] && opti=$interactive
    [ -n "$debug" ] && optd=$debug
    [ -n "$quit" ] && optq=$quit


    if [ $optd == true ]; then
        echo "---"
        echo "\$opti = $opti" 
        echo "\$optd = $optd" 
        echo "\$optq = $optq" 

        echo "\$interactive = $interactive" 
        echo "\$debug = $debug" 
        echo "\$quit= $quit" 
        echo "\$title = $title" 
        echo "\$message= $message" 
        echo "\$argument1 = $argument1" 
        echo "\$argument2 = $argument2" 
    fi

    if [ $opti == true ]; then
        whiptail --title "$title" --msgbox "$message" 20 70
    else
        printf "$message\n"
    fi

    if [ $optq == true ]; then 
        exit 1
    fi
}
