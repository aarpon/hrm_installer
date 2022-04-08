#!/bin/bash

context="$(dirname $BASH_SOURCE)"
source "$context/funs.sh"
source "$context/funs-input.sh"

######################### check if we have a valid hucore license ###########################
function validlic()
{
    [[ $bypass == true ]] && return 0

    catch stdout stderr $hucorepath /dev/null
    [[ $stderr =~ "No valid" ]] && return 1 || return 0
}

######################### In interactive mode, ask the user to enter a license string #######

catch stdout stderr $hucorepath /dev/null
sysid=$(echo "$stdout" | grep 'The system ID is') # | awk -F ' ' '{print $5}')
intro="If you do not have a Huygens license, skip this step or email info@svi.nl including the sysid below for a full test license.\n\n$sysid\n"

#TODO Any way to make sure this is the right path?
CONF_LICENSE="/usr/local/svi/huygensLicense"

# When a license string is supplied, run once in non-interactive mode to check whether the license is valid or not
[ -n "$license" ] && interac=false || interac=$interactive

while ! validlic
do
    # Ask for the license string
    license=$(wt_read "$license" --interactive=$interac --title="$title" --message="License string" --intro="$intro"  --allowempty=true)

    # It's OK if just left empty, but warn the user.
    if [ -z "$license" ]; then
        echo "Warning! Add a valid license string to $CONF_LICENSE - $sysid"
        echo "For testing, hucore license check in HRM will be bypassed."
        bypass=true
        break
    fi

    # If not, must start with HuCore and be valid
    if [[ $license == HuCore* ]]; then
        # Add the license to huygensLicense
        echo "$license" >> "$CONF_LICENSE"

        # Check if hucore outputs "No valid..." in stderr
        if validlic; then
            # All good, can exit the while loop
            break
        else
            # License is invalid, so remove the line
            rmline $CONF_LICENSE "$license"
        fi
    fi

    # At this point, the license key is invalid.
    # We exit if in non-interactive mode
    if [ $interactive == false ]; then
        echo "The license string is invalid! - $sysid"
        exit 1
    fi

    # The license key supplied is invalid. Go back to interactive mode for user input
    interac=$interactive
done

