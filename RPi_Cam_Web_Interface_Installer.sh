#!/bin/bash

# Copyright (c) 2014, Silvan Melchior
# All rights reserved.

# Redistribution and use, with or without modification, are permitted provided
# that the following conditions are met:
#    * Redistributions of source code must retain the above copyright
#      notice, this list of conditions and the following disclaimer.
#    * Neither the name of the copyright holder nor the
#      names of its contributors may be used to endorse or promote products
#      derived from this software without specific prior written permission.

# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY
# DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
# (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
# LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
# ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
# SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

# Description
# This script installs a browser-interface to control the RPi Cam. It can be run
# on any Raspberry Pi with a newly installed raspbian and enabled camera-support.
#
# Edited by jfarcher to work with github

# Configure below the folder name where to install the software to,
#  or leave empty to install to the root of the webserver.
# The folder name must be a subfolder of /var/www/ which will be created
#  accordingly, and must not include leading nor trailing / character.
# The folder name can also be specified as second parameter of this script.
# Default upstream behaviour: rpicamdir="" (installs in /var/www/)

rpicamdir=""

if [ $# -eq 2 ] ; then
        rpicamdir=$2
fi

case "$1" in

  remove)
        sudo killall raspimjpeg
        sudo apt-get remove -y apache2 php5 libapache2-mod-php5 gpac motion
        sudo apt-get autoremove -y

        sudo rm -r /var/www/$rpicamdir/*
        sudo rm /usr/local/bin/raspimjpeg
        sudo rm /etc/raspimjpeg
        sudo cp -r etc/rc_local_std/rc.local /etc/
        sudo chmod 755 /etc/rc.local

        echo "Removed everything"
        ;;

  autostart_yes)
        sudo cp -r etc/rc_local_run/rc.local /etc/
        sudo chmod 755 /etc/rc.local
        echo "Changed autostart"
        ;;

  autostart_no)
        sudo cp -r  etc/rc_local_std/rc.local /etc/
        sudo chmod 755 /etc/rc.local
        echo "Changed autostart"
        ;;

  install)
        sudo killall raspimjpeg
        git pull origin master
        sudo apt-get install -y apache2 php5 libapache2-mod-php5 gpac motion

        sudo mkdir -p /var/www/$rpicamdir/media
        sudo cp -r www/$rpicamdir/* /var/www/$rpicamdir/
        sudo chown -R www-data:www-data /var/www/$rpicamdir
        sudo mknod /var/www/$rpicamdir/FIFO p
        sudo chmod 666 /var/www/$rpicamdir/FIFO

        if [ $rpicamdir == "" ] ; then
                cat etc/apache2/sites-available/default.1 > etc/apache2/sites-available/default
        else
                sed -e "s/www/www\/$rpicamdir/" etc/apache2/sites-available/default.1 > etc/apache2/sites-available/default
        fi
        sudo cp -r etc/apache2/sites-available/default /etc/apache2/sites-available/
        sudo chmod 644 /etc/apache2/sites-available/default
        sudo cp etc/apache2/conf.d/other-vhosts-access-log /etc/apache2/conf.d/other-vhosts-access-log
        sudo chmod 644 /etc/apache2/conf.d/other-vhosts-access-log

        sudo cp -r bin/raspimjpeg /opt/vc/bin/
        sudo chmod 755 /opt/vc/bin/raspimjpeg
        sudo ln -s /opt/vc/bin/raspimjpeg /usr/bin/raspimjpeg

        if [ $rpicamdir == "" ] ; then
                cat etc/raspimjpeg/raspimjpeg.1 > etc/raspimjpeg/raspimjpeg
        else
                sed -e "s/www/www\/$rpicamdir/" etc/raspimjpeg/raspimjpeg.1 > etc/raspimjpeg/raspimjpeg
        fi
        sudo cp -r /etc/raspimjpeg /etc/raspimjpeg.bak
        sudo cp -r etc/raspimjpeg/raspimjpeg /etc/
        sudo chmod 644 /etc/raspimjpeg

        if [ $rpicamdir == "" ] ; then
                cat etc/rc_local_run/rc.local.1 > etc/rc_local_run/rc.local
        else
                sed -e "s/www/www\/$rpicamdir/" etc/rc_local_run/rc.local.1 > etc/rc_local_run/rc.local
        fi
        sudo cp -r /etc/rc.local /etc/rc.local.bak
        sudo cp -r etc/rc_local_run/rc.local /etc/
        sudo chmod 755 /etc/rc.local

        sudo cp -r etc/motion/motion.conf /etc/motion/
        sudo chmod 640 /etc/motion/motion.conf

        echo "Installer finished"
        ;;

  start)
        shopt -s nullglob

        video=-1
        for f in /var/www/$rpicamdir/media/video_*.mp4; do
          video=`echo $f | cut -d '_' -f2 | cut -d '.' -f1`
        done
        video=`echo $video | sed 's/^0*//'`
        video=`expr $video + 1`

        image=-1
        for f in /var/www/$rpicamdir/media/image_*.jpg; do
          image=`echo $f | cut -d '_' -f2 | cut -d '.' -f1`
        done
        image=`echo $image | sed 's/^0*//'`
        image=`expr $image + 1`

        shopt -u nullglob

        sudo mkdir -p /dev/shm/mjpeg
        sudo raspimjpeg -ic $image -vc $video > /dev/null &
        echo "Started"
        ;;

  stop)
        sudo killall raspimjpeg
        echo "Stopped"
        ;;


  *)
        echo "No option selected"
        ;;

esac


