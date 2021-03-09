#!/bin/bash
 echo "Content-type: text/html"
 echo "" 
echo "<html><head><style>"

echo ".p3 {"
echo "  font-family: "Lucida Console", "Courier New", monospace; "
echo "} "
echo "</style>"

echo "<title>Disk free" 
echo "</title></head><body>"
echo "Disk space on main drive:<BR>" 
echo "<p class=\"p3\">"

df | grep root
echo "</p>"

echo "</body></html>"
