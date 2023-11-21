
The apapche server runs its process as www-data, and calls cgi-bin/test.cgi
This is allowed to call /home/pi/pi.sh which in turn executes python mcp.py 

install files from pi's directory to the Apache web server

sudo cp startpage.html /var/www/html/index.html
sudo cp diskfree.sh /var/www/cgi-bin/
sudo cp test.cgi /var/www/cgi-bin/
sudo chmod ugo+w /var/www/html/data/
