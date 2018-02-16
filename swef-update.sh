#!/usr/bin/env bash


function update_error_msg {
    # Report an error message to both stdout and stderr
    echo "$1" | tee /dev/stderr
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
    "$umbrellaDir/swef-manager/swef-pdocheck" "$pdoDSN" "$pdoUsr" "$pdoPwd"
    if [ $? != 0 ]
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
    # Not a Git repository?
    if [ -f "$umbrellaDir/$1/.swef/git-install.sh.GENERIC" ]
    then
        echo "$umbrellaDir/$1/.swef/git-install.sh.GENERIC was not found - not installing" >> /dev/stderr
        return
    fi
    if [ ! -f "$instanceDir/.swef/$1/git-install.sh" ]
    then
        mkdir -p "$instanceDir/.swef/$1"
        cp -p "$umbrellaDir/$1/.swef/git-install.sh.GENERIC" "$instanceDir/.swef/$1/git-install.sh"
    fi
    # Git install
    mkdir "$umbrellaDir/$1"
    cd "$umbrellaDir/$1"
    echo "Installing $1 file system using $instanceDir/.swef/$1/git-install.sh ..."
    echo "--------"
    "$instanceDir/.swef/$1/git-install.sh"
    echo "--------"
    echo "... done"
}


function update_update {
    echo "Updating \"$1\" SQL"
    # Update database
    if [ -d "$umbrellaDir/$1/.swef/sql" ]
    then
        update_pdo_check
        "$umbrellaDir/swef-manager/swef-sqlup" "$1" "$pdoDSN" "$pdoUsr" "$pdoPwd"
    fi
    # If missing, attempt to install
    if [ ! -d "$umbrellaDir/$1" ]
    then
        update_install "$1"
    fi
    # Not a Git repository?
    if [ ! -d $umbrellaDir/$1/.git ]
    then
        return
    fi
    # GIT update script
    if [ ! -f "$umbrellaDir/$1/.swef/git-update.sh.GENERIC" ]
    then
        echo "$umbrellaDir/$1/.swef/git-update.sh.GENERIC was not found - aborting" >> /dev/stderr
        update_exit 105
    fi
    if [ ! -f "$instanceDir/.swef/$1/git-update.sh" ]
    then
        mkdir -p "$instanceDir/.swef/$1"
        cp -p "$umbrellaDir/$1/.swef/git-update.sh.GENERIC" "$instanceDir/.swef/$1/git-update.sh"
    fi
    # Git update
    cd "$umbrellaDir/$1"
    echo "Updating $1 file system using $instanceDir/.swef/$1/git-update.sh ..."
    echo "--------"
    "$instanceDir/.swef/$1/git-update.sh"
    echo "--------"
    echo "... done"
}


# Get directory containing projects
cd "$(dirname "$0")/.."
$umbrellaDir="$(pwd)"


# Ensure that swef-core is installed
if [ ! -d "$umbrellaDir/swef-core" ]
    update_install swef-core
fi


# Enforce project name
if [ ! "$1" ]
then
    echo "Project name not given \"$1\""
    update_exit 102
fi


# Check for "bundles"
case "$1" in
    "typical")
        update_update "swef-core"
        update_update "swef-vanilla"
        update_update "swef-plugin-swefcontent"
        update_update "swef-plugin-sweferror"
        update_update "swef-plugin-sweflog"
        update_update "swef-plugin-swefregistrar"
        update_update "swef-plugin-swefsecurity"
        update_update "swef-instance-$HOSTNAME-$USER"
        ;;
    *)
        update_update "$1"
        ;;
esac


