#!/usr/bin/env bash

# BUILD A SWEF WEB DIRECTORY OF SYMBOLIC LINKS TO DISPARATE SWEF PROJECTS


function build_chmod {
    for d in $(find . -type d | grep -v /\.swef | grep -v \/.git | grep -v ^\./app/log/)
    do
        chmod 750 "$d"
    done
}



function build_error_msg {
    # Report an error message to both stdout and stderr
    echo "$1" | tee /dev/stderr
}



function build_exit {
    # Return user to original working directory and exit with status code
    if [ "$1" != "0" ]
    then
        echo "Error $1"
    fi
    cd "$returnDir"
    exit "$1"
}
returnDir="$(pwd)"



function build_find_paths {
    # Recursively identify symbolic links within a directory
    local item=""
    local path="$1"
    if [ ! -d "$path" ]
    then
        # This path is a file target
        echo "$path"
        return
    fi
    if [ -f "$path/.swef-link" ]
    then
        # This path is a directory target (all nested paths are in this project)
        echo "$path"
        return
    fi
    for item in $(ls -1a "$path")
    do
        if [ "$item" = "." ] || [ "$item" = ".." ]
        then
            continue
        fi
        if [ "$(echo $item | grep ^\.swef)" ] || [ "$(echo $item | grep \.git)" ]
        then
            continue
        fi
        build_find_paths "$path/$item"
    done
}



function build_ug {
    if [ "$1" = "" ]
    then
        echo -n $USER:
        ps ax o uid,user,group,comm | grep -v grep | grep -E 'apache|httpd|nginx' | grep -v '^\s*0\s' | head -n 1 | awk '{print $3;}'
        return
    fi
    echo $1
}



function build_ug_chmod {
    for d in ./app/log ./app/lookup ./app/phrases ./media/content
    do
        chmod 770 "$d"
    done
    for d in $(ls -1 -d ./media/content/*)
    do
        if [ -d "$d" ]
        then
            chmod 770 "$d"
        fi
    done
}



function build_ug_grp {
    echo $2
}



function build_ug_seek {
    ls -l . | awk '{print $3 ":" $4}' | grep "$1" | head -n 1
}



function build_ug_usr {
    echo $1
}



function build_ug_suggest {
    usr="$(build_ug_usr $(echo $1 | tr ":" "\n"))"
    grp="$(build_ug_grp $(echo $1 | tr ":" "\n"))"
    echo "# ----------------------------------------"
    echo "# Give server write permissions like this:"
    echo "usermod -a -G $grp $usr"
    echo "cd \"$2\""
    echo "chown -R $1 app/log"
    echo "chown -R $1 app/lookup"
    echo "chown -R $1 app/phrases"
    echo "chown -R $1 media/content"
    echo "# ----------------------------------------"
}



# Identify directories and log file
if [ "$1" ]
then
    if [ ! -d "$1" ]
    then
        build_error_msg "$1 is not a directory"
        build_exit 101
    fi
    cd "$1"
else
    cd "$(dirname "$0")/../swef-www"
fi
targetDir="$(pwd)"
cd "$returnDir"
echo -n "Sure you want to delete and rebuild $targetDir? [y/n] "
read -n1 -s choose
echo ""
if [ "$choose" != "y" ]
then
    echo "Aborted on user request"
    build_exit 0
fi
rm -rf "$targetDir"
mkdir "$targetDir"
cd "$(dirname "$0")/.."
umbrellaDir="$(pwd)"
tmpFile="$umbrellaDir/.swef-build.tmp"
manifest="$targetDir/.swef-manifest"
echo "# BUILD MANIFEST @ time=$(date '+%Y%m%d%H%M%S')" > "$manifest"
echo "REBUILDING SYMLINKS IN $targetDir POINTING AT:"



# Loop through project types
for projectType in instanceland swefland vendorland userland
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

        # Ignore project if current loop is instanceland and project is not
        if [ "$projectType" = "instanceland" ] && [ ! -f  "$umbrellaDir/$dir/.swef-type-instance" ]
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
            if [ -f "$umbrellaDir/$dir/.swef-type-instance" ]
            then
                continue
            fi
            if [ -f "$umbrellaDir/$dir/.swef-type-swef" ]
            then
                continue
            fi
            if [ -f  "$umbrellaDir/$dir/.swef-type-vendor" ]
            then
                continue
            fi
        fi

        echo "--------"
        echo "# --------" >> "$manifest"

        # Ignore project if no .swef-build file
        if [ ! -f "$umbrellaDir/$dir/.swef-build" ]
        then
            echo "Ignored $umbrellaDir/$dir ($umbrellaDir/$dir/.swef-build not a file)"
            echo "# Ignored $umbrellaDir/$dir ($umbrellaDir/$dir/.swef-build not a file)" >> "$manifest"
            continue
        fi

        # Build directories and links
        cd "$umbrellaDir/$dir"
        pwd
        build_chmod
        if [ "$projectType" = "instanceland" ]
        then
            instanceDir="$(pwd)"
            build_ug_chmod
            if [ ! "$(build_ug_seek $(build_ug "$1"))" ]
            then
                suggestUg=1
            fi
        fi
        echo "--------"
        echo "# $umbrellaDir/$dir" >> "$manifest"
        echo "# --------" >> "$manifest"
        echo -n "" > "$tmpFile"
        build_find_paths . >> "$tmpFile"
        cd "$targetDir"
        for linkedPath in $(cat "$tmpFile")
        do
            echo $linkedPath
            mkdir -p "$targetDir/$(dirname "$linkedPath")"
            rm -f "$targetDir/$linkedPath"
            ln -s "$umbrellaDir/$dir/$linkedPath" "$targetDir/$linkedPath"
            chm="$(ls -l -d "$umbrellaDir/$dir/$linkedPath" | awk '{print $1}')"
            printf "%-50s %-2s %-10s %-1s\n" "$linkedPath" "->" "$chm" "$dir/$linkedPath" >> "$manifest"
        done
        rm "$tmpFile"
        # For readability
        sleep 1
    done

done



# Complete manifest
if [ "$instanceDir" ]
then
    cmds="$(build_ug_suggest $(build_ug "$1") "$instanceDir")"
    echo "$cmds" >> "$manifest"
    if [ "$suggestUg" ]
    then
        echo "$cmds"
    fi
fi



# Display the manifest and exit
echo -n "Manifest is in $manifest. View with less now? [y/n] "
read -n1 -s choose
echo ""
if [ "$choose" = "y" ]
then
    less "$manifest"
fi
build_exit 0


