#!/usr/bin/python3

#import cgi
#import cgitb
#cgitb.enable()

from multiprocessing import Process
import subprocess
from subprocess import DEVNULL
import os

def do_stimuli():
    subprocess.Popen (['/home/pi/git/flyCode/collectData/flyPi/pi.sh'], stdin=subprocess.DEVNULL, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)


def write_status_page():
    print ( "Content-type:text/html\r\n\r\n" )
    print ( "<html><head>" )
    print ( "<title>Sstarting to sample from fly Pi"  )
    print ( "</title>" )
    print ( "<meta http-equiv=\"refresh\" content=\"15;URL='http://raspberrypi2.local/data/status.html'\" />" )
    print ( "</head><body>" )
    print ( "<h1>Python loading up ... (takes about 20 s)</h1>" )

    #print (( "Hello, World.<br>" # prints out "Hello, World."

    # Use $1 to get the first argument:
    print ( "argument is " )
    print ( os.environ.get( 'QUERY_STRING' ))
    #set +m


    #env 
    print ( "</body></html>" , flush=True)
	

if __name__ == '__main__':
    p = Process(target=write_status_page())
    p.daemon = True
    p.start()

    p2 = Process(target=do_stimuli())
    p2.daemon = True
    p2.start()
    
    
    
