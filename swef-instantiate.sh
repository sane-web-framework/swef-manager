#!/usr/bin/env bash

# Copy and rename config.*.GENERIC from all projects
# to config.* in project swef-instance
# Directory paths are mirrored


function instantiate_error_msg {
    # Report an error message to both stdout and stderr
    echo "$1" | tee /dev/stderr
}



function instantiate_exit {
    # Return user to original working directory and exit with status code
    if [ "$1" != "0" ]
    then
        echo "Error $1"
    fi
    cd "$returnDir"
    exit "$1"
}
returnDir="$(pwd)"



# Identify directories and log file
cd "$(dirname "$0")"
cd ..
projectsDir="$(pwd)"
logFile="$projectsDir/swef-instantiate.log"
stamp=$(date '+%Y%m%d%H%M%S')
echo "========" > "$logFile"
echo "Time: $stamp" >> "$logFile"
instanceDir="$projectsDir/swef-instance"
if [ ! -d "$instanceDir" ]
then
    instantiate_error_msg "Project directory not found: $instanceDir"
    instantiate_exit 102
fi

# Loop through projects
cd "$projectsDir"
for dir in $(ls -1 -d *)
do
    if [ ! -d "$projectsDir/$dir" ]
    then
        continue
    fi
    if [ "$dir" = "swef-instance" ]
    then
        continue
    fi
    cd "$projectsDir/$dir"
    for file in $(find . -iname config.*.GENERIC | grep -v '/.swef')
    do
        # Create directory path and config file (if missing)
        mkdir -p "$instanceDir/$(dirname "$file")"
        cp -n "$file" "$instanceDir/${file::-8}"
    done
done
cd  "$projectsDir"
for file in $(find "$instanceDir" -type f)
do
    ls -l "$file"
done
instantiate_exit 0

