/*
NB - take the SD card out for this to work !!!
 
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
#define SS_SD_CARD   4
#define SS_ETHERNET 53
// is 10 on normal uno

#include <SPI.h>
#include <Ethernet.h>

const int max_data = 32 ;
int myData [max_data];
int iIndex = 0 ;
const int ledPin =  9;

// Enter a MAC address and IP address for your controller below.
// The IP address will be dependent on your local network:
byte mac[] = { 
  0xDE, 0xAD, 0xBE, 0xEF, 0xFE, 0xED };

// Initialize the Ethernet server library
// with the IP address and port you want to use 
// (port 80 is default for HTTP):
EthernetServer server(80);

void setup() {

  // ...
  pinMode(SS_SD_CARD, OUTPUT);
  pinMode(SS_ETHERNET, OUTPUT);
  digitalWrite(SS_SD_CARD, HIGH);  // HIGH means SD Card not active
  digitalWrite(SS_ETHERNET, LOW); // HIGH means Ethernet not active


  // Open serial communications and wait for port to open:
  Serial.begin(38400);
  while (!Serial) {
    ; // wait for serial port to connect. Needed for Leonardo only
  }
  for (int i =0; i < max_data; i++)
  {
    myData[i] = 0;    
  }

  // start the Ethernet connection and the server:
  Ethernet.begin(mac);
  server.begin();
  Serial.print("server is at ");
  Serial.println(Ethernet.localIP());
}


void loop() {
  // listen for incoming clients
  EthernetClient client = server.available();
  if (client) {
    Serial.println("new client");
    // an http request ends with a blank line
    boolean currentLineIsBlank = true;
    while (client.connected()) {
      if (client.available()) {
        char c = client.read();
        Serial.write(c);
        // if you've gotten to the end of the line (received a newline
        // character) and the line is blank, the http request has ended,
        // so you can send a reply
        if (c == '\n' && currentLineIsBlank) {
          // send a standard http response header
          client.println("HTTP/1.1 200 OK");
          client.println("Content-Type: text/html");
          client.println("Connection: close");  // the connection will be closed after completion of the response
          client.println("Refresh: 0.5");  // refresh the page automatically every 5 sec
          client.println();
          client.println("<!DOCTYPE HTML>");
          client.println("<html>");
          client.println("<body>");

          client.println("<canvas id=\"myCanvas\" width=\"640\" height=\"520\" style=\"border:1px solid #d3d3d3;\">");
          client.println("Your browser does not support the HTML5 canvas tag.</canvas>");

          client.println("<script>");

          client.println("var c = document.getElementById(\"myCanvas\");");
          client.println("var ctx = c.getContext(\"2d\");");
          // output the value of each analog input pin
          for (int analogChannel = 1; analogChannel < 2; analogChannel++) {
            int sensorReading = analogRead(analogChannel);
            myData[iIndex] = sensorReading ;
            iIndex ++ ;
            if (iIndex > max_data /10 && iIndex < max_data/2)
            {
              analogWrite(ledPin, 255);
            }
            else
            {
              analogWrite(ledPin, 0);
            }
            if (iIndex >= max_data) iIndex = 0;
            for (int i=0; i < max_data-2; i++)
            {
              //            client.print("analog input ");
              //            client.print(analogChannel);
              //            client.print(" is ");
              //            client.print(myData[i]);
              //            


              client.print("ctx.moveTo("); 
              client.print(i*20); 
              client.print(","); 
              client.print(myData[i]/2); 
              client.println(");");
              client.print("ctx.lineTo("); 
              client.print((i+1)*20); 
              client.print(","); 
              client.print(myData[i+1]/2); 
              client.println(");");
              client.println("ctx.stroke();");
            }
            -  //draw stimulus...
            client.print("ctx.moveTo(");
            client.print((max_data /10)*20);
            client.print(",");
            client.print(30);
            client.println(");");

            client.print("ctx.lineTo(");
            client.print(max_data /2*20);
            client.print(",");
            client.print(30);
            client.println(");");

            client.println("ctx.strokeStyle=\"blue\";");
            //              client.println("ctx.lineWidth=5;");
            client.println("ctx.stroke();");

          }
          client.println("</script>");
          client.println("</body></html>");
          break;
        }
        if (c == '\n') {
          // you're starting a new line
          currentLineIsBlank = true;
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



