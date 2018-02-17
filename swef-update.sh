#!/usr/bin/env bash


function update_error_msg {
    # Report an error message to both stdout and stderr
    echo "$1" >> /dev/stderr
}


function update_exit {
    # Return user to original working directory and exit with status code
    if [ "$1" != "0" ]
    then
        echo "Error $1"
    fi
    cd "$returnDir"
    exit "$1"
}
returnDir="$(pwd)"


function update_database {
    if [ ! -d "./$1/.swef/sql" ]
    then
        return
    fi
    echo "Updating $1 SQL" 
    update_pdo_check
    ./swef-manager/swef-sqlup "$1" "$pdoDSN" "$pdoUsr" "$pdoPwd"
}


function update_find {
    part="$1"
    shift
    if [ "$part" = "bundle" ]
    then
        echo $1
        return
    fi
    shift
    if [ "$part" = "package" ]
    then
        echo $1
        return
    fi
    shift
    if [ "$part" = "command" ]
    then
        echo $@
        return
    fi
}


function update_instance_dir {
    ls -1 -d swef-instance-* | head -n 1
}


function update_package_in {
    # Identify package
    package="$(update_find package $@)"
    cmd="$(update_find command $@)"
    if [ ! "$cmd" ]
    then
        mkdir -p "$package"
        return
    fi
    echo "$package: $cmd"
    echo "--------"
    $cmd
    echo "--------"
    echo "... done"
}


function update_package_up {
    # Identify package
    package="$(update_find package $@)"
    cmd="$(update_find command $@)"
    # If missing, attempt to install
    if [ ! -d ./$package ]
    then
        update_error_msg "Package not found: $package"
        return
    fi
    # Database update
    update_database $package
    # No Git to do?
    if [ ! "$cmd" ]
    then
        return
    fi
    # GIT update
    cd ./$package
    echo "$package: $cmd"
    echo "--------"
    $cmd
    echo "--------"
    echo "... done"
    cd ..
}


function update_pdo_check {
    if [ "$pdoOK" ]
    then
        return
    fi
    if [ ! -f "$instanceDir/.swef/swef-pdo.dsn" ]
    then
        echo -n "mysql:host=localhost;dbname=$pdoDB;port=3306;charset=utf8" > "$instanceDir/.swef/swef-pdo.dsn"
    fi
    pdoDSNOld=$(cat "$instanceDir/.swef/swef-pdo.dsn")
    echo "Database DSN: MariDb or MySQL = mysql    PostgreSQL = pgsql    MS-SQL or Sybase = dblib"
    read -p -i "$pdoDSNOld" -e pdoDSN
    echo -n "$pdoDSN" > "$instanceDir/.swef/swef-pdo.dsn"
    if [ ! -f "$instanceDir/.swef/swef-pdo.user" ]
    then
        echo -n "root" > "$instanceDir/.swef/swef-pdo.user"
    fi
    pdoUsrOld=$(cat "$instanceDir/.swef/swef-pdo.user")
    echo -n "Database admin user: "
    read -p -i "$pdoUsrOld" -e pdoUsr
    echo -n "$pdoUsr" > "$instanceDir/.swef/swef-pdo.user"
    echo -n "Database admin password: "
    read -s pdoPwd
    ./swef-manager/swef-pdocheck "$pdoDSN" "$pdoUsr" "$pdoPwd"
    if [ $? != 0 ]
    then
        echo -n "DSN or credentials were incorrect. Try again? [y/n] "
        read yn
        if [ "$yn" = "y" ]
        then
            update_pdo_dsn
        fi
        update_exit 103
    fi
    pdoOK="1"
}
pdoOK=""


function update_install {
    while read -r line
    do
        if [ ! "$line" ]
        then
            continue
        fi
        if [ "${line:0:1}" = "#" ]
        then
            continue
        fi
        if [ "$(update_find package $line)" = "$1" ]
        then
            echo update_package_in $line
            return
        fi
        if [ "$(update_find bundle $line)" != "$1" ]
        then
            continue
        fi
        update_package_in $line
    done < "./$(update_instance_dir)/.swef/swef-git-install.cfg"
}

function update_update {
    while read -r line
    do
        if [ ! "$line" ]
        then
            continue
        fi
        if [ "${line:0:1}" = "#" ]
        then
            continue
        fi
        if [ "$(update_find package $line)" = "$1" ]
        then
            echo update_package $line
            return
        fi
        if [ "$(update_find bundle $line)" != "$1" ]
        then
            continue
        fi
        update_package_up $line
    done < "./$(update_instance_dir)/.swef/swef-git-update.cfg"
}

# Update requested package(s)
if [ ! "$1" ]
then
    echo "Package/bundle not given"
    update_exit 101
fi
cd "$(dirname "$0")/.."
update_install $1
update_update $1
update_exit 0
