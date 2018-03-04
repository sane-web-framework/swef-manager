#!/usr/bin/env bash


function file_error_msg {
    # Report an error message to both stdout and stderr
    echo "$1" >> /dev/stderr
}



function file_exit {
    # Return user to original working directory and exit with status code
    if [ "$1" != "0" ]
    then
        file_error_msg $1
    fi
    cd "$returnDir"
    exit $1
}
returnDir="$(pwd)"


cd ..
if [ ! "$1" ]
then
    echo "./swef file ./some-project/some/file.path"
    file_exit 101
fi
if [ -d "$1" ]
then
    echo "./swef file file-or-sym-link"
    file_exit 102
fi
if [ -L "$1" ]
then
    f="$(readlink "$1")"
else
echo "Not a link"
    f="$1"
fi
if [ ! -f "$1" ]
then
    echo "./swef file \"$1\" - file not found"
    file_exit 103
fi

ls -l "$f" | awk '{print $9;}'
file_exit 0

