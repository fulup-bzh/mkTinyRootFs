#!/usr/bin/env bash

# (C) Copyright 2005 by Fulup Ar Foll
# 
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License version 2 as 
# published by the Free Software Foundation.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
#

# Include generic shell functions
BASEDIR=`dirname $0`
SYSROOT=/tmp/mkDiskless/$1
CONFIG=$1

# check we are running as root
if test "$UID" != "0"
then
 echo ERROR: must be run as ROOT
 exit
fi


# include config
if test -f $BASEDIR/$1.conf
then
 . $BASEDIR/$1.conf
else
 echo ERROR: $1.conf not found
 exit 1
fi

for FUNCTIONS in $BASEDIR/*.func $BASEDIR/Script/*.func
do
 if test -f $FUNCTIONS
 then
 . $FUNCTIONS
 fi
done

if [ -z "$SYSROOT" ] ; then
    echo
    echo "$0 - create a minimal SuSE installation into a directory"
    echo
    echo "Usage:"
    echo "$0 SYSROOT:"
    echo "SYSROOT: directory where you want to install to"
    exit 1
fi

mkdir -p ${SYSROOT}/etc/sysconfig

# main starting point of script

  # clean dependency list
  rm -f $SYSROOT/files.lst

  # Copy file from template
  cp -R Template/* $SYSROOT/.

  # scan binaries to find dependancies
  ScanBIN "$BINLIST"
  CopyBIN 

  # copy share, etc, ... files
  CopyShared

  # Copy Kernel Module
  CopyModules
  chroot $SYSROOT modprobe -a

  # Generate SSH key
  echo Generation of SSH keypair
  keygen

  # Create tty Devices
  mkDevNode

  # Generate a ramdow seed
  random_seed=$SYSROOT/var/lib/misc/random-seed
  mkdir -p `dirname $random_seed`
  dd if=/dev/urandom of=$random_seed count=1 bs=512 2>/dev/null

  # build initramfs
  echo Build of initramfs
  (cd $SYSROOT; find . -print | cpio -o -Hnewc) | gzip > ./$CONFIG-initramfs.gz

  # copy to final destination
  mkdir -p /var/lib/xen/images
  echo installing initrd in /var/lib/xen/images/$CONFIG-initramfs.gz
  cp ./$CONFIG-initramfs.gz /var/lib/xen/images/.
