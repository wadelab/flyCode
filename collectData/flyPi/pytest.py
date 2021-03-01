#!/usr/bin/python

#import cgi
#import cgitb
#cgitb.enable()

from multiprocessing import Process
import subprocess
import os



def write_status_page():
    print  "Content-type:text/html\r\n\r\n" 
    print  "<html><head>" 
    print  "<title>Sampling from fly Pi" 
    print  "</title>"
    print  "<meta http-equiv=\"refresh\" content=\"15;URL='http://biolpc3399.york.ac.uk/data/status.html'\" />" 
    print  "</head><body" 
    #print ( " onload=\"window.open('http://biolpc3399.york.ac.uk/status.html');\"
    print  ">"  
    print  "<h1>Stimulated!</h1>" 

    #print ( "Hello, World.<br>" # prints out "Hello, World."

    # Use $1 to get the first argument:
    print  "argument is "
    print  os.environ.get( 'QUERY_STRING' )
    #set +m


    #env 
    print  "</body></html>" 
	

if __name__ == '__main__':
    p = Process(target=write_status_page())
    p.start()
    
    subprocess.Popen (['/home/pi/git/flyCode/collectData/flyPi/pi.sh'])
    
    
