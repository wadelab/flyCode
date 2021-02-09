#!/bin/bash
 echo "Content-type: text/html"
 echo "" 
echo "<html><head><title>Bash as CGI" 
echo "</title></head><body>" 
echo "<h1>Hello world</h1>"

echo "Hello, World.<br>" # prints out "Hello, World."

# Use $1 to get the first argument:
echo "argument"
echo $1
echo "<br>now trying CRF.py <br>"
/home/pi/git/flyCode/collectData/flyPi/pi.sh
echo "now tried"
echo $?
echo "</body></html>"
