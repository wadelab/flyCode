#!/bin/bash

 echo "Content-type: text/html"
 echo "" 
echo "<html><head>"
echo "<title>Sampling from fly Pi" 
echo "</title>"
echo "<meta http-equiv=\"refresh\" content=\"15;URL='http://biolpc3399.york.ac.uk/data/status.html'\" />"
echo "</head><body"
#echo " onload=\"window.open('http://biolpc3399.york.ac.uk/status.html');\"
echo ">" 
echo "<h1>Stimulated!</h1>"

#echo "Hello, World.<br>" # prints out "Hello, World."

# Use $1 to get the first argument:
#echo "argument is "
#echo $QUERY_STRING
set +m


#env 
echo "</body></html>"


echo "<br>now trying CRF.py <br>"
export QUERY_STRING
exec env QS=$QUERY_STRING /home/pi/git/flyCode/collectData/flyPi/pi.sh 

#echo "now tried"
#echo $?
