#!/bin/bash
 echo "Content-type: text/html"
 echo "" 
echo "<html><head><title>Sampling from fly Pi" 
echo "</title></head><body>" 
echo "<h1>Stimulated!</h1>"

#echo "Hello, World.<br>" # prints out "Hello, World."

# Use $1 to get the first argument:
#echo "argument is "
#echo $QUERY_STRING
export QUERY_STRING

#env 

echo "<br>now trying CRF.py <br>"
/home/pi/git/flyCode/collectData/flyPi/pi.sh &
echo "now tried"
echo $?
echo "</body></html>"
