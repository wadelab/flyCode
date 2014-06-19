#include <FixFFT.h>

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
#include <SD.h>

const int max_graph_data = 32 ;
int myGraphData [max_graph_data];
int iIndex = 0 ;
const int ledPin =  9;
const int analogPin = 1 ;

const int maxContrasts = 9 ;
const float F1contrast[] = {
  5.0, 10.0, 30.0, 70.0, 100.0,  5.0, 10.0, 30.0, 70.0 }; 
const float F2contrast[] = {
  0.0,  0.0,  0.0,  0.0,   0.0, 30.0, 30.0, 30.0, 30.0 };
int contrastOrder[ maxContrasts ]; 
int iThisContrast = 0 ;

int freq1 = 12 ; // flicker of LED Hz
int freq2 = 15 ; // flicker of LED Hz
// as of 18 June, maxdata of 2048 is too big for the mega....
const int max_data = 1024  ;
unsigned int time_stamp [max_data] ;
int erg_in [max_data];
long sampleCount = 0;        // will store number of A/D samples taken
long interval = 4;           // interval (5ms) at which to - 2 ms is also ok in this version
unsigned long last_time = 0; 
unsigned long timing_too_fast = 0 ;



const int MaxInputStr = 230 ;
String MyInputString = String(MaxInputStr+1);
String MyOldInputString = String(MaxInputStr+1);

// Enter a MAC address and IP address for your controller below.
// The IP address will be dependent on your local network:
byte mac[] = { 
  0xDE, 0xAD, 0xBE, 0xEF, 0xFE, 0xED };

// Initialize the Ethernet server library
// with the IP address and port you want to use 
// (port 80 is default for HTTP):
EthernetServer server(80);
EthernetClient client ;

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
  for (int i =0; i < max_graph_data; i++)
  {
    myGraphData[i] = 0;    
  }

  // start the Ethernet connection and the server:
  Ethernet.begin(mac);
  server.begin();
  Serial.print("server is at ");
  Serial.println(Ethernet.localIP());

doShuffle();
}

void doShuffle()
{
for (int i = 0; i < maxContrasts; i++)
{
contrastOrder[i] = i ;
}

///Knuth-Fisher-Yates shuffle algorithm.

for (int i = maxContrasts - 1; i > 0; i--)
{
int n = random(i + 1);
Swap(contrastOrder[i], contrastOrder[n]);
}
}

void USE_SDCARD()
{
  digitalWrite(SS_SD_CARD, LOW);  // HIGH means SD Card not active
  digitalWrite(SS_ETHERNET, HIGH); // HIGH means Ethernet not active
}
void USE_ETHERNET()
{
  digitalWrite(SS_SD_CARD, HIGH);  // HIGH means SD Card not active
  digitalWrite(SS_ETHERNET, LOW); // HIGH means Ethernet not active
}

void sendHeader ()
{
  // send a standard http response header
  client.println("HTTP/1.1 200 OK");
  client.println("Content-Type: text/html");
  client.println("Connection: close");  // the connection will be closed after completion of the response
  client.println();
  client.println("<!DOCTYPE HTML>");
  client.println("<html>");
  client.println("<body>");
}

void sendFooter()
{
  client.println("</body></html>");
}


void serve_dir ()
{
  USE_SDCARD();
  Serial.println("Init SD.");
  if (!SD.begin(4)) 
  {
    Serial.println("bad SD!");
    return;
  }
  File root = SD.open("/");
  String s = printDirectory(root, 0);
  Serial.println(s);
  root.close();

  USE_ETHERNET();
  sendHeader();
  client.println(s);
  sendFooter();
}

void run_graph()
{
  sendHeader () ;

  client.println("<canvas id=\"myCanvas\" width=\"640\" height=\"520\" style=\"border:1px solid #d3d3d3;\">");
  client.println("Your browser does not support the HTML5 canvas tag.</canvas>");

  client.println("<script>");

  // script to reload ...
  client.println("var myVar = setInterval(function(){myTimer()}, 400);"); //mu sec
  client.println("function myTimer() {");
  client.println("location.reload(true);");
  client.println("};");

  client.println("function myStopFunction() {");
  client.println("clearInterval(myVar); }");
  client.println("");



  client.println("var c = document.getElementById(\"myCanvas\");");
  client.println("var ctx = c.getContext(\"2d\");");
  // output the value of each analog input pin
  for (int analogChannel = 1; analogChannel < 2; analogChannel++) {
    int sensorReading = analogRead(analogChannel);
    myGraphData[iIndex] = sensorReading ;
    iIndex ++ ;
    if (iIndex > max_graph_data /10 && iIndex < max_graph_data/2)
    {
      analogWrite(ledPin, 255);
    }
    else
    {
      analogWrite(ledPin, 0);
    }
    if (iIndex >= max_graph_data) iIndex = 0;
    for (int i=0; i < max_graph_data-2; i++)
    {
      client.print("ctx.moveTo("); 
      client.print(i*20); 
      client.print(","); 
      client.print(myGraphData[i]/2); 
      client.println(");");
      client.print("ctx.lineTo("); 
      client.print((i+1)*20); 
      client.print(","); 
      client.print(myGraphData[i+1]/2); 
      client.println(");");
      client.println("ctx.stroke();");
    }
    //draw stimulus...
    client.print("ctx.moveTo(");
    client.print((max_graph_data /10)*20);
    client.print(",");
    client.print(30);
    client.println(");");

    client.print("ctx.lineTo(");
    client.print(max_graph_data /2*20);
    client.print(",");
    client.print(30);
    client.println(");");

    client.println("ctx.strokeStyle=\"blue\";");
    //              client.println("ctx.lineWidth=5;");
    client.println("ctx.stroke();");

  }
  client.println("</script>");
  client.println("<BR><BR><button onclick=\"myStopFunction()\">Stop display</button>");
  client.println("To run a flicker test please stop and then load <A HREF=\"http://biolpc22.york.ac.uk/cje2/form.html\"> form.html</A>  ");

  sendFooter();

}

String printDirectory(File dir, int numTabs) {
  while(true) {
    String sDIR ;
    File entry =  dir.openNextFile();
    if (! entry) {
      // no more files
      sDIR += ("**nomorefiles**");
      break;
    }
    for (uint8_t i=0; i<numTabs; i++) {
      sDIR +=('\t');
    }
    Serial.print(entry.name());
    if (entry.isDirectory()) {
      sDIR +=("/");
      sDIR += printDirectory(entry, numTabs+1);
    } 
    else {
      // files have sizes, directories do not
      sDIR +=("\t\t");
      sDIR +=(entry.size(), DEC);
    }
    entry.close();
  }
}

void serve_dummy()
{
  sendHeader();
  client.println("Dummy page; <BR> To run a flicker test please load <A HREF=\"http://biolpc22.york.ac.uk/cje2/form.html\"> form.html</A>  ");
  sendFooter() ;
}

int br_Now(double t)
{
int randomnumber = contrastOrder[iThisContrast];
  return int(sin((t/1000.0)*PI*2.0*double(freq1))*1.270 * F1contrast[randomnumber] + sin((t/1000.0)*PI*2.0*double(freq2))*1.270 * F1contrast[randomnumber])+127;
}



void collectData ()
{
  const long presamples = 102;
  long mean = 0;


  sampleCount = -presamples ;
  while (sampleCount < max_data)
  {
    unsigned long now_time = millis();
    if (now_time < last_time + interval)
    {
      timing_too_fast ++ ;
    }
    else
    {
      // Initial test showed it could write this to the card at 12 ms intervals
      last_time = now_time ;
      if (sampleCount ==0)
      {
        mean = mean / presamples ;
      }
      if (sampleCount >=0)
      {
        // read  sensor 
        erg_in[sampleCount] = analogRead(analogPin) - mean ; // subtract 512 so we get it in the range... 
        time_stamp[sampleCount] = (now_time) ;
      }
      else
      {
        mean = mean + long(analogRead(analogPin));
      }

      int intensity = br_Now(now_time) ;
      //brightness[sampleCount] = int(intensity) ;
      analogWrite(ledPin, intensity);

      sampleCount ++ ;
    }
  }
  // now done with sampling....
  sampleCount ++ ;  
  analogWrite(ledPin, 127);
  //writeFile("datalog.dat");
  iThisContrast ++;
  if (iThisContrast > maxContrasts) iThisContrast = 0 ;
}

void flickerPage(String sCommand, bool RedoPage)
{
  Serial.println ("Sampling at :" + String(sampleCount));
  sendHeader();
  if (!RedoPage) 
  {
    client.println("<script>");

    // script to reload ...
    client.println("var myVar = setInterval(function(){myTimer()}, 4500);"); //mu sec
    client.println("function myTimer() {");
    client.println("location.reload(true);");
    client.println("};");

    client.println("function myStopFunction() {");
    client.println("clearInterval(myVar); }");
    client.println("");
    client.println("</script>");
    client.println("Acquiring, " + String(sampleCount) + " samples so far <BR>"  + sCommand + "<BR> please wait....");
    sampleCount = -102 ; //implies collectData(); 
  }
  else
  {
     
    // retrieve the flicker rates we sampled with...
    int randomnumber = contrastOrder[iThisContrast];
    client.println("Data acquired at " + String(freq1) + " Hz with contrast " + String(int(F1contrast[randomnumber])) + 
      " and " + String(freq2) + " Hz with contrast " + String(int(F2contrast[randomnumber])) +" % <BR> " + sCommand + "<BR>");
    client.println("No, time, brightness, analog in <BR>");
    for (int i = 0; i < max_data; i++)
    {
      // make a string for assembling the data to log:
      String dataString = String(i);
      dataString += ", ";

      dataString += String(time_stamp[i]-time_stamp[0]);
      dataString += ", ";

      dataString += String(br_Now(time_stamp[i]));
      dataString += ", ";

      dataString += String(erg_in[i]);
      dataString += "<BR>";

      client.println(dataString);
    }
  }
  sendFooter() ;


}


void loop() {
  if (sampleCount < 0) 
  {
    collectData();
  }
  // listen for incoming clients
  client = server.available();
  if (client) {
    Serial.println("new client");
    // an http request ends with a blank line
    while (client.connected()) {
      if (client.available()) {
        char c = client.read();
        if (MyInputString.length() < MaxInputStr)
        {
          MyInputString.concat(c);
        }

        //Serial.write(c);
        // if you've gotten to the end of the line (received a newline
        // character) and the line is blank, the http request has ended,
        // so you can send a reply
        if (c == '\n' ) 
        {
          bool pageServed = false ;
          Serial.print(MyInputString); 
          int fPOS = MyInputString.indexOf("filename=");
          Serial.println("  Position of file was:" + String(fPOS));
          if (fPOS > 0)
          {
            flickerPage(MyInputString, MyInputString.equals(MyOldInputString)); // serve_dummy() ;
            pageServed = true ;
          }
          fPOS = MyInputString.indexOf("dir=");
          Serial.println("  Position of dir was:" + String(fPOS));
          if (fPOS > 0)
          {
            serve_dir() ;
            pageServed = true ;
          }          
          fPOS = MyInputString.indexOf("QQQ");
          Serial.println("  Position of file was:" + String(fPOS));
          if (fPOS > 0)
          {
            serve_dummy() ;
            pageServed = true ;
          }
          if (!pageServed)
          {
            run_graph() ;
          }
          MyOldInputString = MyInputString ;
          MyInputString = "";
          break ;
        }


        if (c == '\n') 
        {
          // you're starting a new line
          // this is never called
          MyInputString = "";

        } 
        else if (c != '\r') {
          // you've gotten a character on the current line
        }
      }
    }
    // give the web browser time to receive the data
    delay(1);
    // close the connection:
    client.stop();
    //Serial.println("client disonnected: Input now:" + MyInputString + "::::");
  }
} 












