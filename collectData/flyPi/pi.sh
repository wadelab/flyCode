#!/bin/bash

echo "welcome to Pi-Land from user"
whoami
echo "<br>"

#export DISPLAY=:0; lxterminal &

PATH=/home/pi/venv/bin:$PATH
HOME=/home/pi/www-data

if [ -z "$QUERY_STRING" ]; then 
	echo "QUERY_STRING is not set"
	QUERY_STRING="GAL4=TH&UAS=homz&Age=7&Disco=Y&org=none&col=blue&bri=255&F1=12&F2=15&filename=2021_02_09_15h43m24"

else 
	echo "QUERY_STRING is set" 
fi
#QUERY_STRING="GAL4=TH&UAS=homz&Age=7&Disco=Y&org=none&col=blue&bri=255&F1=12&F2=15&filename=2021_02_09_15h43m24"

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

echo "starting.... <BR>"
python /home/pi/git/flyCode/collectData/flyPi/mcp.py 2>&1 &

echo "<BR><BR>now done <br>"
echo "result "
echo $?
