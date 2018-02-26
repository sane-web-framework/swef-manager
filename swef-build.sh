#!/usr/bin/env bash

# BUILD A SWEF WEB DIRECTORY OF SYMBOLIC LINKS TO DISPARATE SWEF PROJECTS


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
echo "# Build manifest @ time=$(date '+%Y%m%d%H%M%S')" > "$manifest"
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
            if [ -f "$umbrellaDir/$dir/.swef-type-swef" ] || [ -f  "$umbrellaDir/$dir/.swef-type-vendor" ]
            then
                continue
            fi
        fi

        # Ignore project if no .swef-build file
        if [ ! -f "$umbrellaDir/$dir/.swef-build" ]
        then
            echo "# Ignored $umbrellaDir/$dir ($umbrellaDir/$dir/.swef-build not a file)" >> "$manifest"
            echo "Ignoring $umbrellaDir/$dir"
            continue
        fi

        # Build directories and links
        cd "$umbrellaDir/$dir"
        echo "--------"
        pwd
        echo "--------"
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



# Display the manifest and exit
echo -n "Manifest is in $manifest. View with less now? [y/n] "
read -n1 -s choose
echo ""
if [ "$choose" = "y" ]
then
    less "$manifest"
fi
build_exit 0


