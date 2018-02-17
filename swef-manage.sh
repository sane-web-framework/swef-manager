#!/usr/bin/env bash

if [ "$(id -u)" = "0" ]
then
    echo "Refusing to run as root user" | tee /dev/stderr
    exit 101
fi

# Pass on arguments to the script denoted by the first argument

returnDir="$(pwd)"
if [ -L "$0" ]
then
    cd "$(dirname $0)/swef-manager"
else
    cd "$(dirname $0)"
fi
prog="./swef-$1.sh"

if [ ! "$1" ]
then
    cd "$returnDir"
    echo "101 No option given" >> /dev/stderr
    exit 102
fi

if [ "$1" = "manage" ]
then
    cd "$returnDir"
    echo "102 Invalid option" >> /dev/stderr
    exit 103
fi

if [ "$(echo "$1" | grep /)" ]
then
    cd "$returnDir"
    echo "103 Invalid option" >> /dev/stderr
    exit 104
fi

if [ ! -f "$prog" ]
then
    cd "$returnDir"
    echo "104 Invalid option" >> /dev/stderr
    exit 105
fi

shift
"$prog" "$@"
cd "$returnDir"

