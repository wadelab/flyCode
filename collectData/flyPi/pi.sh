#!/bin/bash

echo "welcome to Pi-Land from user"
whoami
echo "<br>"

#export DISPLAY=:0; lxterminal &
#sudo -u pi

PATH=/home/pi/venv/bin:$PATH
HOME=/home/pi/www-data

echo "path is"
echo  $PATH
echo "<br>"

which python
echo "<br>"

echo "home is " 
echo $HOME
echo "<br>"

export HOME
export DISPLAY=:0 

echo "starting.... <BR>"
python /home/pi/git/flyCode/collectData/flyPi/CRF.py 2>&1


echo "<BR><BR>now done <br>"
echo "result "
echo $?
