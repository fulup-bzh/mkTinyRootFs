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

unset LANG   ;# make sure local language does not create troubles.
BASEDIR=`dirname $0`

Debug()
{
 if test "$debug" = 1
 then
   echo "Debug: $*"
 fi
}

DoIt ()
{
  Debug "DoIt $*"
  if test "$dump" != ""
  then
    TAB=`echo $1 | cut -d' ' -f1`
    if test "$TAB" = "##"  ; then 
        echo "" >> $dump
    fi
    echo "$*" >> $dump
  fi
    
  # echo DoIt $@
  if test "$dummy" != "1"
  then
    eval $*
    if test $? -ne 0
    then
      echo "-- ERR $*"
    fi
  fi
}

EvalArgs()
{

  for arg in "$@"
  do
    if expr 'index' "$arg" '=' '>' '1' >/dev/null
    then
      case "$prefix" in
      1)
         eval "${NAME}_${arg}"
         if test $? != 0
         then
            echo "ERROR: ${NAME}_${arg} contains special character [$@]"
         fi
        ;;
      *)
        eval "${arg}"
        if test $? != 0
        then
           echo "ERROR: ${arg} contains special character [$@]"
        fi
        ;;
      esac
    fi
  done
  prefix=0
}


Verbose() {

  LABEL="$1" ;
  if test "$verbose" = 1
  then
    printf "Verbose -- %-20s: " "$LABEL"
    shift; echo $*
  fi
}

FatalError() {
  echo ******************** (hugs !!!!) ****************
  echo "ERROR:  $1
  echo "Syntax: $0 config=distrib.conf destdir=/tmp/myDistrib target=openvz [root=no verbose=1]" >&2
  exit 1
}

### --- start main ------

EvalArgs "$@"

# Test for Mandatory arguments
for PARAM in config destdir target
do
 eval VALUE=\$${PARAM}
 if test "$VALUE" = ""
 then
   FatalError "Missing mandatory parameter"
 endif
done


# check we are running as root
if test "$root" =! "no"
then
if test "$UID" != "0"
then
 echo ERROR: must unfortunatly be run as ROOT
 exit
fi
fi
 
# store input params for later usage
CONFIG=$config
SYSROOT=$destdir
TARGET=$target

# Read user configuration
if test -f $CONFIG
then
  . $CONFIG
else
  FatalError "$CONFIG.conf not found"
fi

# Source script functions
for FUNCTIONS in $BASEDIR/*.func $BASEDIR/Script/*.func
do
 if test -f $FUNCTIONS
 then
 . $FUNCTIONS
 fi
done


# Make sure we can write in ${SYSROOT}
mkdir -p ${SYSROOT}/etc/sysconfig
if !test -d ${SYSROOT}/etc/sysconfig
then 
  FatalError "Fail to write in ${SYSROOT}"
fi

# Check Sysroot is not pointing on '/' (hoops)
ROOT_INODE=`ls -id / | awk '{print $1}'`
DEST_INAME=`ls -id ${SYSROOT} | awk '{print $1}'`
if test $ROOT_INODE -eq $DEST_INAME
then
 FatalError "destdir=$SYSROOT point on system /"
fi

exit

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
  chroot $SYSROOT depmod -a

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
