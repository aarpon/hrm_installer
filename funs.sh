function abort()
{
        echo -e "$1\nAborting HRM installation."
        exit 1
}

function errcheck()
{
        [ $? ] && abort "$1"
}

function packages_missing()
{
        pkglist=$1
        pkgsmissing=`dpkg --get-selections $pkglist 2>&1 | grep "No packages found matching" | cut -c 28- | sed "s/\.$//"`
        echo $pkgsmissing
}

function install_packages()
{
        aptitude install "$1"
}

function readkey()
{
	read
	ans=`echo "$REPLY" | cut -c 1 | tr '[A-Z]' '[a-z]'`
	echo $ans
}

function readstring()
{
	read -e -i "$1"
	echo $REPLY
}

function mysqlcmd()
{
	mysql -h localhost -u $1 -p$2 -e "$3"
}

function pgsqlcmd()
{
	su postgres -c "psql -c \"$1\""
}

function sedconf()
{
	sed -i -e "s|$2|$3|" "$1"
}
