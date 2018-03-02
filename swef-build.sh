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



function build_ug_grp {
    ps ax o uid,user,group,comm | grep -v grep | grep -E 'apache|httpd|nginx' | grep -v '^\s*0\s' | head -n 1 | awk '{print $3;}'
}



function build_ug_perms {
    for d in $(find . -type d | grep -v /\.swef | grep -v \/.git | grep -v ^\./app/log/)
    do
        chmod 750 "$d"
    done
    echo "cd \"$(pwd)\"" >> "$tmpPerm"
    for d in ./app/log ./app/lookup ./app/phrases ./media/content
    do
        echo "sudo chown -R $(build_ug_usr):$(build_ug_grp) $d/*" >> "$tmpPerm"
        chmod 770 "$d"
    done
}



function build_ug_usr {
    ps ax o uid,user,group,comm | grep -v grep | grep -E 'apache|httpd|nginx' | grep -v '^\s*0\s' | head -n 1 | awk '{print $2;}'
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
echo -n "" > "$tmpFile"
tmpPerm="$umbrellaDir/.swef-perm.tmp"
echo "# Generate correct permissions like this:" > "$tmpPerm"
echo "sudo usermod -a -G $(build_ug_grp) $USER" > "$tmpPerm"
echo "sudo chown -R $USER:$(build_ug_grp) \"$umbrellaDir\"" >> "$tmpPerm"
manifest="$targetDir/.swef-manifest"
echo "# BUILD MANIFEST @ time=$(date '+%Y%m%d%H%M%S')" > "$manifest"
echo "REBUILDING SYMLINKS IN $targetDir POINTING AT:"



# Loop through project types
for projectType in swefland vendorland userland instanceland
do

    # Web directory symbolic links are overwritten below so a
    # file in a later loop "wins" the link from an earlier one

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

        # Ignore project if current loop is instanceland and project is not
        if [ "$projectType" = "instanceland" ] && [ ! -f  "$umbrellaDir/$dir/.swef-type-instance" ]
        then
             continue
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
        if [ "$projectType" = "instanceland" ]
        then
            instanceDir="$(pwd)"
            build_ug_perms
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
cat "$tmpPerm" >> "$manifest"
cat "$tmpPerm"
rm "$tmpPerm"


# Display the manifest and exit
echo -n "Manifest is in $manifest. View with less now? [y/n] "
read -n1 -s choose
echo ""
if [ "$choose" = "y" ]
then
    less "$manifest"
fi
build_exit 0


