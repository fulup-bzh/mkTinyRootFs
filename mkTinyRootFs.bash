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
  echo "ERROR:  $1"
  echo "Syntax: $0 config=distrib.conf target=/tmp/myDistrib [verbose=1]" >&2
  exit 1
}

### --- start main ------

EvalArgs "$@"

# Test for Mandatory arguments
for PARAM in config target
do
 eval VALUE=\$${PARAM}
 if test "$VALUE" = ""
 then
   FatalError "Missing mandatory parameter"
 fi
done

# store input params for later usage
CONFIG="$config"
SYSROOT="$target"

# Read user configuration
if test -f $CONFIG
then
  source $CONFIG
else
  FatalError "[$CONFIG] not found"
fi

# if needed create target dir, wipe if exist
mkdir -p $SYSROOT && rm -rf $SYSROOT/*

# Source script functions
for FUNCTIONS in $BASEDIR/*.func $BASEDIR/Script/*.func
do
 if test -f $FUNCTIONS
 then
 . $FUNCTIONS
 fi
done


# Check Sysroot is not pointing on '/' (hoops)
ROOT_INODE=`ls -id / | awk '{print $1}'`
DEST_INAME=`ls -id ${SYSROOT} | awk '{print $1}'`
if test $ROOT_INODE -eq $DEST_INAME
then
 FatalError "target=$SYSROOT point on system /"
fi

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

  # Generate SSH key
  # echo Generation of SSH keypair
  # keygen

