#!/bin/sh
# http://e2guardian.org/
# Migration and installation script 
# FredB 2013

PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

E2_ETC_PATHS=/etc/e2guardian
E2_LOG_PATH=/var/log/e2guardian
E2_BIN=../src/e2guardian
STARTPATH=`pwd`

##  DG ## 

POSS_DG_ETC_PATHS="/etc /usr/local/etc /opt/etc"  # add any others

# Make sure only root can run this script

if [ "$(id -u)" != "0" ]; then
   echo "This script must be run as root" 
   exit 1
fi

# Make sure a binary exist

if [ ! -f $E2_BIN ]; then
   echo "No binary, compile first - need Make -" 
   exit 1
fi

# Make sure Linux

os=`uname -s`
if (test $os != "linux" && test $os != "Linux" )
then 
	echo "Sorry Linux only"
	exit 1
fi

# Make sure PATH

path="pwd"
if (test $path != "/tmp")
then
	echo "Please put the e2guardian (compile source) directory in /tmp before installation"
	exit 1
fi	

is_initial_configuration () { 	
        mkdir -p $E2_ETC_PATHS
	mkdir -p $E2_LOG_PATH 
	cp logrotate.d/e2guardian /etc/logrotate.d/
	cp $E2_BIN /usr/sbin/
	cp basic/* $E2_ETC_PATHS
# rights
	chown -Rf e2guardian $E2_ETC_PATHS
	chmod -Rf 700 $E2_ETC_PATHS
	
	chown -Rf e2guardian $E2_LOG_PATH
	chmod -Rf 700 $E2_LOG_PATH
	
	chmod 755 /usr/sbin/e2guardian  
	echo "Done"
}

is_migration_configuration () {
	echo "save and remove DG"
	mv -f $DG_ETC $DG_ETC".back"
	mv -f $DG_LOG $DG_LOG".back"

        if [update-rc.d 2>/dev/null]; then
                update-rc.d -f dansguardian remove
        elif [ chkconfig 2>/dev/null ]; then
              chkconfig e2guardian off
        else
                echo "DG init script still present, you MUST remove it after"
        fi

	# Make e2guardian configuration
	is_initial_configuration
	cp -Rf $DG_ETC".back"/* $E2_ETC_PATHS
	chown -Rf e2guardian $E2_ETC_PATHS
	if [ -f $E2_ETC_PATHS/dansguardian.conf ]; then	
		cd $E2_ETC_PATHS
		for i in *.* ; do sed -i 's/dansguardian/e2guardian/g' $i ; done
		for i in *.* ; do sed -i 's/dansguardian/e2guardian/g' $i ; done
		for i in dansguardian*;do mv $i e2guardian${i#dansguardian} ;done
		cd $STARTPATH
	fi	
}

# Installing e2guardian init conf
echo "Installing generic e2guardian conf files"
echo "You have to configure e2guardian after"
echo "If some options seems missing take a look at http://e2guardian.org/"
sleep 3

useradd -r e2guardian 2>/dev/null

# No dg here ?
#search for DG config directory
for p in ${POSS_DG_ETC_PATHS}
do
    if [ -e ${p}/dansguardian/dansguardian.conf ]
    then
          export DG_ETC=${p}/dansguardian
	  cd $DG_ETC
          DG_LOG=`grep "loglocation" dansguardian.conf | grep = | cut -d "'" -f2`
	  export DG_LOG
	
	  cd $STARTPATH
          echo "DansGuardian configuration file found at: ${p}/dansguardian/dansguardian.conf"
	  is_migration_configuration
	  echo "DG is present, you MUST remove it after"
          break
    fi
done


if [ ! -f DG_ETC=${p}/dansguardian/dansguardian.conf ]; then	
	is_initial_configuration
fi

# RCLeveling :
echo "Enabling rclevel for e2guardian" 
if [ update-rc.d 2>/dev/null ]; then 
	cp init.d/e2guardian-rc.d /etc/init.d/e2guardian
	update-rc.d e2guardian start 99 2 3 4 5 . stop 21 0 1 6 .
elif [ chkconfig 2>/dev/null ]; then
		cp init.d/e2guardian-chk /etc/init.d/e2guardian
		chkconfig e2guardian on 
else
	echo "ed2guardian is installed but init script is missing"

fi

