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
        git_error_msg $1
    fi
    cd "$returnDir"
    exit $1
}
returnDir="$(pwd)"


function git_push {
    cd ..
    instanceDir="$(ls -1 -d swef-instance-* | head -n 1)"
    echo "Using $(pwd)/$instanceDir/.swef/swef-git-push.cfg..."
    if [ ! -f "./$instanceDir/.swef/swef-git-push.cfg" ]
    then
        git_error_msg "Configuration not found"
        git_exit 101
    fi
    while read -r line
    do
        if [ ! "$line" ]
        then
            continue
        fi
        if [ "${line:0:1}" = "#" ]
        then
            continue
        fi
        dir=$(echo $line | awk '{print $2}')
        cmd="$(echo $line | cut --delimiter=" " --fields=3-)"
        echo -n "$dir/ [ $cmd ] See status, do that or abort? [s/y/n/a] "
        read -n 1 ok < /dev/tty
        echo ""
        if [ "$ok" = "s" ]
        then
            echo "--------"
            cd $dir
            git status
            cd ..
            echo "--------"
            echo -n "$dir/ [ $cmd ] Do that or abort? [y/n/a] "
            read -n 1 ok < /dev/tty
            echo ""
        fi
        if [ "$ok" = "a" ]
        then
            return
        fi
        if [ "$ok" != "y" ]
        then
            continue
        fi
        cd $dir
        if [ "$(echo $cmd | grep "commit$")" ]
        then
            read -e -p "Commit message:" -i "Swef multi-project update $(date +%Y/%m/%d-%H:%M:%S)" msg
            $cmd -m "$msg"
        else
            $cmd
        fi
        cd ..
    done < ./$instanceDir/.swef/swef-git-push.cfg
}


function git_status {
    # Loop through project types
    cd ..
    for projectType in swefland vendorland userland
    do
        # Loop through projects
        for dir in $(ls -1 -d *)
        do
            # Ignore paths that are not directories
            if [ ! -d "$dir" ]
            then
                 continue
            fi
            # Ignore project if current loop is swefland and project is not
            if [ "$projectType" = "swefland" ] && [ ! -f  "$dir/.swef-type-swef" ]
            then
                 continue
            fi
            # Ignore project if current loop is vendorland and project is not
            if [ "$projectType" = "vendorland" ] && [ ! -f  "$dir/.swef-type-vendor" ]
            then
                 continue
            fi
            # Ignore project if current loop is userland and project is not
            if [ "$projectType" = "userland" ]
            then
                if [ -f "$dir/.swef-type-swef" ] || [ -f  "$dir/.swef-type-vendor" ]
                then
                    continue
                fi
            fi
            echo "--------"
            # Ignore project if no .git directory
            if [ ! -d "$dir/.git" ]
            then
                echo "Ignoring $dir (has no .git directory)"
                continue
            fi
            # Show git status
            cd "$dir"
            check="$(git status | grep "nothing to commit, working directory clean")"
            if [ "$check" ]
            then
                echo "$dir - nothing to commit, working directory clean"
            else
                echo "$dir - git status:"
                git status
                sleep 1
            fi
            cd ..
        done
    done
}


if [ "$1" = "status" ]
then
    git_status
    git_exit 0
fi


if [ "$1" = "push" ]
then
    git_push
    git_exit 0
fi


