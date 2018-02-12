#!/usr/bin/env bash

echo "Still building"
exit 0


if [ "$(id -u)" != "0" ]
then
    echo "You must be root user to run $0"
    exit 101
fi


webGroup=$(ps ax o uid,user,group,comm | grep -E 'apache|httpd' | grep -v '^\s*0\s' | grep -v grep | head -n 1 | awk '{print $3;}')

echo usermod -a -G $webGroup $USER

echo chgrp -R $webGroup "./*"

exit 0
