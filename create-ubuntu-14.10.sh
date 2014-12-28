#!/bin/bash
CTID="999"
ARCH="amd64"
VER="utopic"
TMPIP="192.168.2.4"
TMPCT="123456"
VZROOT="/var/lib/vz/private"

echo "cleaning the CT $CTID"
 /usr/sbin/vzctl stop $CTID
 /usr/sbin/vzctl destroy $CTID

echo "debootstrap an $ARCH $VER in CT $CTID"
/usr/sbin/debootstrap --arch $ARCH $VER $VZROOT/$CTID ftp://ftp.ubuntu.com/ubuntu

echo "Unlimited template"
 touch /etc/vz/conf/$CTID.conf
 /usr/sbin/vzctl set $CTID --applyconfig vps.basic --save

 echo "OSTEMPLATE=ubuntu-14.10" >> /etc/vz/conf/$CTID.conf

echo "Set a temporary IP address $TMPIP"
 /usr/sbin/vzctl set $CTID --ipadd $TMPIP --save

echo "Set the OpenDNS server"
 /usr/sbin/vzctl set $CTID --nameserver 8.8.8.8 --nameserver 8.8.8.8 --save

echo "Starting the CT $CTID"
 /usr/sbin/vzctl start 999
sleep 5

echo "Changing the PATH"
 /usr/sbin/vzctl exec $CTID "export PATH=/sbin:/usr/sbin:/bin:/usr/bin"

echo "Changing the sources.list to add non-free"
/usr/sbin/vzctl exec $CTID "echo -e \"deb http://ftp.de.debian.org/debian squeeze main non-free\ndeb http://ftp.de.debian.org/debian-security squeeze/updates main non-free contrib\" > /etc/apt/sources.list"
/usr/sbin/vzctl exec $CTID cat /etc/apt/sources.list

echo "apt-get update"
/usr/sbin/vzctl exec $CTID "apt-get update"

echo "apt-get dist-upgrade"
/usr/sbin/vzctl exec $CTID "apt-get dist-upgrade"

echo "apt-get install software we need"
/usr/sbin/vzctl exec $CTID "apt-get install -y --force-yes ssh less vim bzip2 telnet psmisc  screen ttyrec tshark"

echo "Bash as the default shell"
/usr/sbin/vzctl exec $CTID "rm /bin/sh /bin/sh.distrib ; ln -s /bin/bash /bin/sh"

echo "Configuring locales as EN US UTF8"
/usr/sbin/vzctl exec $CTID "apt-get install locales"
/usr/sbin/vzctl exec $CTID "echo \"en_US.UTF-8 UTF-8\" > /etc/locale.gen"
/usr/sbin/vzctl exec $CTID "ls -l /etc/locale.gen"
/usr/sbin/vzctl exec $CTID "/usr/sbin/locale-gen"

echo "disable getty"
/usr/sbin/vzctl exec $CTID "sed -i -e '/getty/d' /etc/inittab"

echo "Fix /etc/mtab"
/usr/sbin/vzctl exec $CTID "rm -f /etc/mtab"
/usr/sbin/vzctl exec $CTID "ln -s /proc/mounts /etc/mtab"

#echo "Change the timezone"
#/usr/sbin/vzctl exec $CTID "ln -sf /usr/share/zoneinfo/Europe/Berlin /etc/localtime"

echo "apt-get clean"
/usr/sbin/vzctl exec $CTID "apt-get clean"

echo "stoping the CT $CTID"
/usr/sbin/vzctl stop $CTID

echo "unset any IP address"
/usr/sbin/vzctl set $CTID --ipdel all --save

echo "blank the /etc/resolv.conf"
touch $VZROOT/$CTID/etc/resolv.conf

echo "blank the /etc/hostname file"
touch $VZROOT/$CTID/etc/hostname

echo "go to the $CTID directory"
cd /var/lib/vz/private/$CTID

echo "Creating a tar file debian-6.0-$ARCH-minimal.tar.gz"
tar --numeric-owner -zcf /var/lib/vz/template/cache/ubuntu-14.10-$ARCH-minimal.tar.gz .

echo "How big is the generated tar file?"
ls -lh /var/lib/vz/template/cache/ubuntu-14.10-$ARCH-minimal.tar.gz

echo "Testing with a test CTID $TMPCT"
/usr/sbin/vzctl create $TMPCT --ostemplate ubuntu-14.10-$ARCH-minimal

echo "Starting CT $TMPCT"
/usr/sbin/vzctl start 123456
sleep 5

echo "Exec ps aux at CT $TMPCT"
/usr/sbin/vzctl exec $TMPCT ps aux

echo "Stopping $TMPCT"
/usr/sbin/vzctl stop $TMPCT

echo "Destroying $TMPCT"
/usr/sbin/vzctl destroy $TMPCT
rm /etc/vz/conf/$TMPCT.conf.destroyed
