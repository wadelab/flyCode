/*
  Web Server
 
 A simple web server that shows the value of the analog input pins.
 using an Arduino Wiznet Ethernet shield. 
 
 Circuit:
 * Ethernet shield attached to pins 10, 11, 12, 13
 * Analog inputs attached to pins A0 through A5 (optional)
 
 created 18 Dec 2009
 by David A. Mellis
 modified 9 Apr 2012
 by Tom Igoe
 
 */

#include <SPI.h>
#include <Ethernet.h>
 // include the SD library:
#include <SD.h>
#include <Arduino.h>

// Enter a MAC address and IP address for your controller below.
// The IP address will be dependent on your local network:
byte mac[] = { 
  0xDE, 0xAD, 0xBE, 0xEF, 0xFE, 0xED };
//IPAddress ip(192,168,1,177);

// Initialize the Ethernet server library
// with the IP address and port you want to use 
// (port 80 is default for HTTP):
EthernetServer server(80);
EthernetClient client ;
const char comma = ',';
bool SD_in_Use = false ;
String MyInputString = String(30);

void setup() {
 // Open serial communications and wait for port to open:
  Serial.begin(38400);
   while (!Serial) {
    ; // wait for serial port to connect. Needed for Leonardo only
  }


  // start the Ethernet connection and the server:
  Ethernet.begin(mac);
  server.begin();
  Serial.print("server is at ");
  Serial.println(Ethernet.localIP());
  
    Serial.println("Initializing SD card...");
  Serial.println ("<BR>");
  // On the Ethernet Shield, CS is pin 4. It's set as an output by default.
  // Note that even if it's not used as the CS pin, the hardware SS pin 
  // (10 on most Arduino boards, 53 on the Mega) must be left as an output 
  // or the SD library functions will not work. 
   pinMode(10, OUTPUT);   
   SD_in_Use = SD.begin(4);
  if (!SD_in_Use) 
  {
    Serial.println("initialization failed!");
  }
}

unsigned int ReadInt (File f)
{
      union{
       unsigned int i;
       byte b[2];
       } u;
      for (int i = 0; i < 2; i++)
       {
          u.b[i] = f.read();
       }        
       f.read(); // swallow the comma
       unsigned int myI = u.i;
       return myI ;
}

unsigned long ReadUL (File f)
{
      union{
       unsigned long i;
       char b[4];
       } u;
      for (int i = 0; i < 4; i++)
       {
          u.b[i] = f.read();
       }  
       f.read(); // swallow he comma
       unsigned long myI = u.i;
       return myI ;
}

void ReadOutFile(String str)
{
        
    int lf = 10;
    char hdr[80];
    // make a char aarry 
    // Length (with one extra character for the null terminator)
    int str_len = str.length() + 1;     
    // Prepare the character array (the buffer) 
    char char_array [str_len];  
    for (int i =0; i < str_len; i++)
      {
        char_array[i]=0;
      }  
    // Copy it over 
    str.toCharArray(char_array, str_len);
    Serial.print("chars are ");
    Serial.println(char_array) ;
    File ReadFile = SD.open(char_array);

  // if the file is available, write to it:
  if (ReadFile) 
  {
    //read the header

    int iRead = ReadFile.readBytesUntil(lf, hdr, 80);
    hdr[iRead] = '\0';  
    client.println(hdr);
    client.println ("<BR>");
    
    // now read the rest of the file
    while (ReadFile.available()) 
	{
          for (int i = 0; i <3; i++)
            {
         //hi, lo, comma
              int iTmp = ReadInt (ReadFile);
              client.print(iTmp);
              client.print(comma);
              }
                 //hi, lo, hi, lo, comma 4 bytes...
              client.print(ReadUL (ReadFile));
              client.print(comma);      
              client.println ("<BR>");
    }
    ReadFile.close();
  }  
  // if the file isn't open, pop up an error:
  else 
  {
    client.print("error opening " );
    client.println (str);
    client.println ("<BR>");
  } 
}

void ServePage(String s) 
{
    printHTMLheader();
    ReadOutFile (s);
    client.println("bye !<br>");            
    client.println("</html>");          
    // give the web browser time to receive the data
    delay(1);
    // close the connection:
    client.stop();
    Serial.println("client disonnected");
     // end of respond to client
}

void printHTMLheader ()
{       
    client.println("HTTP/1.1 200 OK");
    client.println("Content-Type: text/html");
    client.println("Connection: close");  // the connection will be closed after completion of the response
    	  //client.println("Refresh: 5");  // refresh the page automatically every 5 sec
    client.println();
    client.println("<!DOCTYPE HTML>");
    client.println("<html>");
}

void printDirectory(File dir, int numTabs) 
{
  printHTMLheader ();
  while(true) {
     
     File entry =  dir.openNextFile();
     if (! entry) {
       // no more files
       //Serial.println("**nomorefiles**");
                 client.println("bye !<br>");       
         
          client.println("</html>");          
    // give the web browser time to receive the data
    delay(1);
    // close the connection:
    client.stop();
    Serial.println("client disonnected");
       break;
     }
     for (uint8_t i=0; i<numTabs; i++) {
       client.print('\t');
     }
     client.print("<a href=\"./?FILE=");
     client.print(entry.name());
     client.print("\">");
     client.print(entry.name());
     client.print("</a>");
     if (entry.isDirectory()) {
       client.println("/ <BR>");
       //printDirectory(entry, numTabs+1);
     } else {
       // files have sizes, directories do not
       client.print("\t\t");
       client.println(entry.size(), DEC);
       client.println ("<BR>");
     }
     entry.close();
   }
}

void loop() {
  // listen for incoming clients
  client = server.available();
  if (client) {
    Serial.println("new client");
    // an http request ends with a blank line
    boolean currentLineIsBlank = true;
    while (client.connected()) 
    {
      if (client.available()) 
      {
        char c = client.read();
         if (MyInputString.length() < 30) {
          MyInputString.concat(c);
        }
        Serial.write(c);
        // if you've gotten to the end of the line (received a newline
        // character) and the line is blank, the http request has ended,
        // so you can send a reply
        if (c == '\n' ) 
        {
          // find if we want to play a file
          int fPOS = MyInputString.indexOf("FILE=");
          int aPOS = MyInputString.indexOf(" HTTP") ; //, fPOS);
          if (fPOS > 0)
          {
            Serial.print("request is " );
            Serial.print(MyInputString);
            Serial.println(";;;");
            String sFile = MyInputString.substring(fPOS+5,aPOS) ;
            Serial.print(sFile);
            Serial.println (" now well try to show");
            ServePage(sFile);
          }
          else
          {
           File root = SD.open("/");
         printDirectory (root, 0);
          }
          //ServePage (client);
        }
        if (c == '\n') {
          // you're starting a new line
          currentLineIsBlank = true;
          MyInputString = "";
        } 
        else if (c != '\r') {
          // you've gotten a character on the current line
          currentLineIsBlank = false;
        }
      }
    }
    // give the web browser time to receive the data
    delay(1);
    // close the connection:
    client.stop();
    Serial.println("client disonnected");
  }
}



