#!/usr/bin/env bash

# Pass on arguments to the script denoted by the first argument

returnDir="$(pwd)"
if [ -L "$0" ]
then
    cd "$(dirname $0)/swef-manager"
else
    cd "$(dirname $0)"
fi
progDir="$(pwd)"
cd "$returnDir"
case "$1" in
build)
        errorCode=101
        ;;
instantiate)
        errorCode=102
        ;;
*)
        if [ "$1" = "" ]
        then
            echo "No option given" >> /dev/stderr
        else
            echo "Invalid option" >> /dev/stderr
        fi
        exit 100
        ;;
esac
prog="$progDir/swef-$1.sh"
shift
"$prog" "$@"
