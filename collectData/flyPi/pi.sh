#!/bin/bash

echo "welcome to Pi-Land from user"
whoami
echo "<br>"

#export DISPLAY=:0; lxterminal &

PATH=/home/pi/venv/bin:$PATH
HOME=/home/pi/www-data

if [ -z "$QUERY_STRING" ]; then 
	echo "QUERY_STRING is not set"
	QUERY_STRING="GAL4=eG4&UAS=GFP&Age=7&stim=quick&message=Any+comment+goes+here.%0D%0A&filename=2023_11_21_13h59m40"
else 
	echo "QUERY_STRING is set" 
fi
#QUERY_STRING="GAL4=eG4&UAS=GFP&Age=7&stim=quick&message=Any+comment+goes+here.%0D%0A&filename=2023_11_21_13h59m40"

echo "path is"
echo  $PATH
echo "<br>"

which python
echo "<br>"

echo "home is " 
echo $HOME
echo "<br>"

echo "query is"
echo $QUERY_STRING
echo "<BR>"

export HOME
export DISPLAY=:0 
export QUERY_STRING
xset -display :0 dpms force on

#get right version of python and .py installs
source /home/pi/venv/bin/activate
echo "starting.... <BR>"
python /home/pi/git/flyCode/collectData/flyPi/mcp.py 2>&1 &

echo "<BR><BR>now done <br>"
echo "result "
echo $?
