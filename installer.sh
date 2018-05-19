#!/bin/bash

repo="https://github.com/odinvolk/symbiose.git"
zipball="https://github.com/odinvolk/symbiose/master.zip"
dest="symbiose"

if [ -d "$dest" ] ; then
	echo "$dest already exists, skipping download"
else
	echo "Downloading Symbiose..."
	if [ type git >/dev/null 2>&1 ] ; then
		echo "git not found, falling back to zipball"
		wget "$zipball" -O "$dest.zip"
		unzip "$dest.zip"
		mv "symbiose-master" "$dest"
		rm "$dest.zip"
	else
		git clone "$repo" "$dest"
	fi
fi

cd "$dest"

httpdUser=`ps -eo user,args | egrep -v "(root|$USER)" | egrep "(apache|httpd|nginx)" | awk 'FNR<2 {print $1}'`
if [ -z "$httpdUser" ] ; then
	echo >&2 "Could not determine httpd user!"
	echo >&2 "If you plan to use Symbiose with httpd, please see https://github.com/odinvolk/symbiose/wiki/Installing#copying-files-to-the-server"
else
	echo "Detected httpd user: $httpdUser"
	echo "Allowing httpd user to read/write files..."
	if [ type setfacl >/dev/null 2>&1 ] ; then
		echo "setfacl not found, falling back to chown"
		chown -R $httpdUser .
	else
		setfacl -R -m d:u:$httpdUser:rwX,u:$httpdUser:rwX .
	fi
fi

if [ type npm >/dev/null 2>&1 ] ; then
	echo >&2 "npm not found, skipping building"
else
	echo "Building..."
	npm install
	npm run-script build
	cd build
	dest="$dest/build"
fi

echo ""
echo "Symbiose successfully installed in $dest"
echo "To configure it, see https://github.com/odinvolk/symbiose/wiki/Installing#configuration"

if [ -x /usr/sbin/nginx ] ; then
	echo "WARNING: If you're using Nginx, you'll have to update your config: see https://github.com/odinvolk/symbiose/blob/master/nginx.conf"
fi
