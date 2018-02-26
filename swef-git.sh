#!/usr/bin/env bash

# BUILD A SWEF WEB DIRECTORY OF SYMBOLIC LINKS TO DISPARATE SWEF PROJECTS


function git_error_msg {
    # Report an error message to both stdout and stderr
    echo "$1" > /dev/stderr
}



function git_exit {
    # Return user to original working directory and exit with status code
    if [ "$1" != "0" ]
    then
        git_error_msg "Error $1"
    fi
    cd "$returnDir"
    exit "$1"
}
returnDir="$(pwd)"



if [ "$1" != "status" ]
then
    git_error_msg "./swef git status"
    git_exit 101
fi


# Identify directories
cd "$(dirname "$0")/.."
umbrellaDir="$(pwd)"



# Loop through project types
for projectType in swefland vendorland userland
do

    # Loop through projects
    cd "$umbrellaDir"
    for dir in $(ls -1 -d *)
    do

        # Ignore paths that are not directories
        if [ ! -d "$umbrellaDir/$dir" ]
        then
             continue
        fi

        # Ignore project if current loop is swefland and project is not
        if [ "$projectType" = "swefland" ] && [ ! -f  "$umbrellaDir/$dir/.swef-type-swef" ]
        then
             continue
        fi

        # Ignore project if current loop is vendorland and project is not
        if [ "$projectType" = "vendorland" ] && [ ! -f  "$umbrellaDir/$dir/.swef-type-vendor" ]
        then
             continue
        fi

        # Ignore project if current loop is userland and project is not
        if [ "$projectType" = "userland" ]
        then
            if [ -f "$umbrellaDir/$dir/.swef-type-swef" ] || [ -f  "$umbrellaDir/$dir/.swef-type-vendor" ]
            then
                continue
            fi
        fi

        # Ignore project if no .git directory
        if [ ! -d "$umbrellaDir/$dir/.git" ]
        then
            echo "Ignoring $umbrellaDir/$dir (has no .git directory)"
            continue
        fi

        # Show git status
        cd "$umbrellaDir/$dir"
        check="$(git status | grep "nothing to commit, working directory clean")"
        if [ ! "$check" ]
        then
            echo "--------"
            echo "Git status for $dir:"
            git status
        fi
    done

done


git_exit 0


