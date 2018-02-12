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
    path="$1"
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
    for item in $(ls -1 -d "$path"/*)
    do
        build_find_paths "$item"
    done
}



# Check for target directory argument
if [ ! $1 ]
then
    echo "SWEF directory path must be given"
    build_exit 102
fi



# Create target directory (must not exist)
find "$1" > /dev/null 2>&1
if [ "$?" = "0" ]
then
    echo "Path already exists: $1"
    build_exit 103
fi
mkdir "$1"



# Identify directories and log file
cd "$1"
targetDir="$(pwd)"
cd "$returnDir"
cd "$(dirname "$0")"
cd ..
projectsDir="$(pwd)"
tmpFile="$projectsDir/.swef-build.tmp"
manifest="$targetDir/.swef-manifest"
echo "# Build manifest @ time=$(date '+%Y%m%d%H%M%S')" > "$manifest"


# Loop through project types
for projectType in swefland vendorland userland
do

    # Loop through projects
    cd "$projectsDir"
    for dir in $(ls -1 -d *)
    do

        # Ignore paths that are not directories
        if [ ! -d "$projectsDir/$dir" ]
        then
             continue
        fi

        # Ignore project if current loop is swefland and project is not
        if [ "$projectType" = "swefland" ] && [ ! -f  "$projectsDir/$dir/.swef-type-swef" ]
        then
             continue
        fi

        # Ignore project if current loop is vendorland and project is not
        if [ "$projectType" = "vendorland" ] && [ ! -f  "$projectsDir/$dir/.swef-type-vendor" ]
        then
             continue
        fi

        # Ignore project if current loop is userland and project is not
        if [ "$projectType" = "userland" ]
        then
            if [ -f "$projectsDir/$dir/.swef-type-swef" ] || [ -f  "$projectsDir/$dir/.swef-type-vendor" ]
            then
                continue
            fi
        fi

        # Ignore project if no .swef-build file
        if [ ! -f "$projectsDir/$dir/.swef-build" ]
        then
            echo "# Ignored $projectsDir/$dir ($projectsDir/$dir/.swef-build not a file)" >> "$manifest"
            echo "Ignoring $projectsDir/$dir"
            continue
        fi

        # Build directories and links
        cd "$projectsDir/$dir"
        build_find_paths . >> "$tmpFile"
        cd "$targetDir"
        for linkedPath in $(cat "$tmpFile")
        do
            mkdir -p "$targetDir/$(dirname "$linkedPath")"
            rm -f "$targetDir/$linkedPath"
            ln -s "$projectsDir/$dir/$linkedPath" "$targetDir/$linkedPath"
            chm="$(ls -l -d "$projectsDir/$dir/$linkedPath" | awk '{print $1}')"
            printf "%-50s %-2s %-10s %-1s\n" "$linkedPath" "->" "$chm" "..../$dir/$linkedPath" >> "$manifest"
        done

    done

done



# Delete temporary file, display the manifest and exit
rm -f "$tmpFile"
echo -n "Manifest is in $manifest. View with less now? [y/n] "
read -n1 -s choose
echo ""
if [ "$choose" = "y" ]
then
    less "$manifest"
fi
build_exit 0


