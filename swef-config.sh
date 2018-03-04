#!/usr/bin/env bash


function config_error_msg {
    # Report an error message to both stdout and stderr
    echo "$1" >> /dev/stderr
}


function config_exit {
    # Return user to original working directory and exit with status code
    if [ "$1" != "0" ]
    then
        config_error_msg $1
    fi
    cd "$returnDir"
    exit $1
}
returnDir="$(pwd)"


function config_instance_dir {
    ls -1 -d "$(dirname $0)/../swef-instance-"* | head -n 1
}


cd "$(config_instance_dir)"
echo "$(pwd):"
find "./.swef" -iname *.cfg | awk '{print "    ",$1;}'
find "./app/config" -type f | grep -v /\.swef | grep -v /\.git | awk '{print "    ",$1;}'
config_exit 0

