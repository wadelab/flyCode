

//try this http://gammon.com.au/forum/?id=11488&reply=5#reply5 for interrupts
//Digital pin 7 is used as a handshake pin between the WiFi shield and the Arduino, and should not be used
// http://www.arduino.cc/playground/Code/AvailableMemory

// don't use pin 4 or 10-12 either...


//#define __wifisetup__


#define due1
#define USE_DHCP

//#define __USE_SDFAT

//_____________________________________________________

#ifdef mega1
#define MAC_OK 0xDE, 0xAD, 0xBE, 0xEF, 0xFE, 0xED
//biolpc2793 [in use in lab with Emily and Richard]
#endif

#ifdef due5
#define MAC_OK 0x90, 0xA2, 0xDA, 0x0F, 0x42, 0x02
//biolpc2804

#endif

#ifdef due1
#define MAC_OK 0x90, 0xA2, 0xDA, 0x0E, 0x09, 0xA2
//90-A2-DA-0E-09-A2 biolpc2886 [in use for Sultan, has fiber]
#endif

#ifdef due2
#define MAC_OK 0x90, 0xA2, 0xDA, 0x0F, 0x6F, 0x9E
//90-A2-DA-0E-09-A2 biolpc2898 [used in testing...]
#endif

#ifdef due3
#define MAC_OK 0x90, 0xA2, 0xDA, 0x0F, 0x75, 0x17
//90-A2-DA-0E-09-A2 biolpc2899
#endif

#ifdef due4
#define MAC_OK 0x90, 0xA2, 0xDA, 0x0E, 0x09, 0xA3
//90-A2-DA-0E-09-A3 biolpc2939 144.32.86.171
#endif

#ifdef __wifisetup__
#define MAC_OK
#endif

//#if defined(__AVR_ATmega2560__  __SAM3X8E__
/*

  Prototype : put the grey wire in ground, and purple wire in pin7

  Based on Web Server

  A simple web server that shows the value of the analog input pins.
  using an Arduino Wiznet Ethernet shield.

  Circuit:
   Ethernet shield attached to pins 10, 11, 12, 13
   Analog inputs attached to pins A0 through A5 (optional)

  created 18 Dec 2009
  by David A. Mellis
  modified 9 Apr 2012
  by Tom Igoe

*/
#define SS_SD_CARD   4
#define SS_ETHERNET 10
// is 10 on normal uno

#include <SPI.h>

#ifndef __wifisetup__


#include <Ethernet.h>

#else

#include <WiFi.h>

#endif

#ifdef __USE_SDFAT
#include <SdFat.h>
#else
#include <SD.h>
#endif

// include fft
#include <Radix4.h>
//#include <FixFFT.h>

const short max_graph_data = 32 ;
int * myGraphData ;  // will share erg_in space, see below
short iIndex = 0 ;

#ifdef __USE_SDFAT
SdFat sd;
#endif
//
byte usedLED  = 0;
const byte fiberLED = 8 ;
const byte noContactLED = 2;

// define LED mapping here
const byte bluvioletLED = 8 ;
const byte amberled = 6;
const byte whiteled = 11;
const byte cyaled = 9;
const byte extrawhitepin = 53;

#ifdef due4
const byte redled = 7;
const byte grnled = 3;
const byte bluLED = 5;
#else
#ifdef __SAM3X8E__
// fix the LED order in hardware....
const byte redled = 6;
const byte grnled = 5;
const byte bluLED = 7;
#else
const byte redled = 5;
const byte grnled = 6;
const byte bluLED = 8;
#endif
#endif

const byte analogPin = 0 ;
const byte connectedPin = A1;
byte iGainFactor = 1 ;
bool bIsSine = true ;

byte nRepeats = 0;
const byte maxRepeats = 5;

const byte maxContrasts = 9 ;
const byte F2contrastchange = 4;
const byte F1contrast[] = {
  5, 10, 30, 70, 100,  5, 10, 30, 70
};
const byte F2contrast[] = {
  0, 30
};
byte contrastOrder[ maxContrasts ];
byte iThisContrast = 0 ;

bool bNoInternet = false ;
boolean has_filesystem = true;
bool bFileOK = true ;
#ifndef __USE_SDFAT
Sd2Card card;
SdVolume volume;
SdFile root;
#endif
SdFile file;

boolean bDoFlash = false ;
byte freq1 = 12 ; // flicker of LED Hz
byte freq2 = 15 ; // flicker of LED Hz
// as of 18 June, maxdata of 2048 is too big for the mega....
const short max_data = 1025  ;
const int data_block_size = 8 * max_data ;
unsigned int time_stamp [max_data] ;
int erg_in [max_data];
long sampleCount = 0;        // will store number of A/D samples taken
unsigned long interval = 4;           // interval (5ms) at which to - 2 ms is also ok in this version
unsigned long last_time = 0;
unsigned int start_time = 0;
unsigned long timing_too_fast = 0 ;

uint8_t second, myminute, hour, day, month;
uint16_t year ;

const short MaxInputStr = 130 ;
String MyInputString = String(MaxInputStr + 1);
String MyReferString = String(MaxInputStr + 1);

char cFile [30];
char cInput [MaxInputStr + 2] = "";

// for graphic plotting
int istep = 15;
int plot_limit = max_data - max_data / 6 ;
int iXFactor = 4;
int iYFactor = 25 ;
int iBaseline = 260 ;
int iXDiv = 6 ;

#ifndef MAC_OK
#error please define which arduino you are setting up
#endif

#ifndef __wifisetup__
//

byte mac[] = { MAC_OK } ;
IPAddress myIP, theirIP, dnsIP ;

// Initialize the Ethernet server library
// with the IP address and port you want to use
// (port 80 is default for HTTP):
EthernetServer server(80);
EthernetClient client ;
#include <Dns.h>

#else

WiFiServer server (80);
WiFiClient client (80);

#endif

void setup() {

  // ...
  pinMode(SS_SD_CARD, OUTPUT);
  pinMode(SS_ETHERNET, OUTPUT);

  pinMode(noContactLED, OUTPUT);

  for (int i = extrawhitepin; i > extrawhitepin - 7; i = i - 2)
  {
    pinMode(i, OUTPUT);
  }

  digitalWrite(SS_SD_CARD, HIGH);  // HIGH means SD Card not active
  digitalWrite(SS_ETHERNET, HIGH); // HIGH means Ethernet not active


  // Open serial communications and wait for port to open:
  Serial.begin(115200);
  while (!Serial) {
    ; // wait for serial port to connect. Needed for Leonardo only
  }
  myGraphData = erg_in ;
  for (short i = 0; i < max_graph_data; i++)
  {
    myGraphData[i] = 0;
  }

  // initialize the SD card
  Serial.println F("Setting up SD card...\n");
#ifndef __USE_SDFAT
  if (!card.init(SPI_HALF_SPEED, 4))
  {
    Serial.println F("card failed half speed\n");
    if (!card.init(SPI_QUARTER_SPEED, 4))
    {
      Serial.println F("card failed quarter speed\n");
      has_filesystem = false;
    }
  }

  // initialize a FAT volume
  if (has_filesystem && !volume.init(&card))
  {
    Serial.println F("vol.init failed!\n");
    has_filesystem = false;
  }
  if (has_filesystem && !root.openRoot(&volume))
  {
    Serial.println F("openRoot failed");
    has_filesystem = false;
  }
#else

  if (!sd.begin(4)) {
    sd.initErrorHalt();
  }

#endif

  if (has_filesystem)
  {
    Serial.println F("SD card ok\n");
#ifdef __USE_SDFAT
    Serial.println F("Testing SD Fat");
#else
    Serial.println F("Using old SD card code");
#endif
  }

#ifdef __wifisetup__
  //char ssid[] = "SSID";     //  your network SSID (name)
  //char pass[] = "PASSWD";  // your network password
#include "./secret.h"

  int status = WL_IDLE_STATUS;
  while ( status != WL_CONNECTED)
  {
    Serial.print F("Attempting to connect to Network named: ");
    Serial.println(ssid);                   // print the network name (SSID);

    // Connect to WPA/WPA2 network. Change this line if using open or WEP network:
    status = WiFi.begin(ssid, pass);
    // wait 10 seconds for connection:
    delay(2000); // 2 s seems enough
  }
  server.begin();                           // start the web server on port 80
  printWifiStatus();                        // you're connected now, so print out the status

#else
  digitalWrite(SS_ETHERNET, LOW); // HIGH means Ethernet not active
  Serial.println F("Setting up the Ethernet card...\n");
  // start the Ethernet connection and the server:
#ifdef USE_DHCP
  if (! Ethernet.begin(mac))
  {
    Serial.println F("DHCP failed, trying 172, 16, 1, 10");
#else

#endif

    // Setup for eg an ethernet cable from Macbook to Arduino Ethernet shield
    // other macbooks or mac airs may assign differnt local networks
    //
    Serial.println F("Please set your mac ethernet to Manually and '172.16.1.1'");
    byte ip[] = { 172, 16, 1, 10 };
    Ethernet.begin(mac, ip);
    bNoInternet = true ;
#ifdef USE_DHCP
  };
#endif
  server.begin();
  Serial.print F("server is at ");
  myIP = Ethernet.localIP() ;
  dnsIP = Ethernet.dnsServerIP();
  Serial.println(myIP);
  Serial.print(" using dns server ");
  Serial.println(dnsIP);

#endif


  analogReadResolution(12);
  iGainFactor = 4 ;

  goColour(0, 0, 0, 0, false);

  doShuffle();
}


#ifndef __wifisetup__

//bool readMAC()
//{
//  // read a byte from the current address of the EEPROM
//  // start at 0
//  int address = 0;
//  byte value;
//  char cMac [4];
//  cMac[3] = '\0' ;
//  while (address < 20)
//  {
//    value = EEPROM.read(address);
//    char * c = " ";
//    *c = value ;
//    if (address < 3)
//    {
//      cMac [address] = (char)value  ;
//    }
//    else
//    {
//      if (address < 9)
//      {
//        mac [address - 3] = value ;
//      }
//    }
//
//    //
//    //    Serial.print(address);
//    //    Serial.print("\t");
//    //    Serial.print (c);
//    //    Serial.print("\t");
//    //    Serial.print(value, DEC);
//    //    Serial.print("\t");
//    //    Serial.print(value, HEX);
//    //    Serial.println();
//
//    // advance to the next address of the EEPROM
//    address = address + 1;
//  }
//  int iComp = strncmp (cMac, "MAC", 3);
//
//  //  Serial.print ("Comparing :") ;
//  //  Serial.print (cMac);
//  //  Serial.print (" with MAC gives ");
//  //  Serial.println (iComp);
//
//  return ( 0 == iComp) ;
//
//}

#else
//ifdef __wifisetup__

void printWifiStatus() {
  // print the SSID of the network you're attached to:
  Serial.print F("SSID: ");
  Serial.println(WiFi.SSID());

  // print your WiFi shield's IP address:
  myIP = WiFi.localIP();
  Serial.print F("IP Address: ");
  Serial.println(ip);

  // print the received signal strength:
  long rssi = WiFi.RSSI();
  Serial.print F("signal strength (RSSI):");
  Serial.print (rssi);
  Serial.println F(" dBm");
  // print where to go in a browser:
  Serial.print F("To see this page in action, open a browser to http://");
  Serial.println (ip);
}

#endif


void doShuffle()
{
  for (int i = 0; i < maxContrasts; i++)
  {
    contrastOrder[i] = i ;
  }
  ///Knuth-Fisher-Yates shuffle algorithm.
  randomSeed(analogRead(analogPin));
  int randomnumber = random(maxContrasts);
  int tmp ;

  for (int i = maxContrasts - 1; i > 0; i--)
  {
    int n = random(i + 1);
    //Swap(contrastOrder[i], contrastOrder[n]);
    tmp = contrastOrder[n];
    contrastOrder[n] = contrastOrder[i];
    contrastOrder[i] = tmp ;
  }
}





void sendHeader (const String & sTitle, const String & sINBody = "", bool isHTML = true, char * pDate = NULL)
{
  // send a standard http response header
  client.println F("HTTP/1.1 200 OK");
  if (isHTML)
  {
    client.println F("Content-Type: text/html");
  }
  else
  {
    client.println F("Content-Type: text/plain");
  }
  if (pDate)
  {
    client.print F("Last-Modified: ");
    client.println (pDate);
  }
  client.println F("Connection: close");  // the connection will be closed after completion of the response
  client.println();
  if (isHTML)
  {
    client.println F("<!DOCTYPE HTML><html><title>");
    client.println (sTitle);
    client.println F("</title><body ");
    client.println (sINBody);
    client.println F(">");
  }
}

void sendFooter()
{
  client.println F("</body></html>");
}


void send_GoBack_to_Stim_page ()
{
  client.println F("<A HREF=\"") ;
  if (MyReferString != String("131"))
  {

    //    client.println F(" <script>");
    //    client.println F("function goBack() ");
    //    client.println F("{ window.history.back() }");
    //    client.println F("</script>");

    client.println (MyReferString) ;
    client.println F("\"" );
  }
  //    Serial.print("My reference is :");
  //    Serial.println (MyReferString) ;
  else
  {
    // i think this migth work everywhere with firefox > 31 - seems to work in Safari too
    client.print F("javascript:void(0)\" onclick=\"history.back(); ") ;
  }
  client.println F("\">the stimulus selection form</A>  <BR>");
}

void updateColour (const bool boolUpdatePage)
{
  if (boolUpdatePage)
  {
    sendHeader ("Lit up ?", "onload=\"goBack()\" ");
    client.println F("Click to reload");
    send_GoBack_to_Stim_page ();

    sendFooter();
  }
}

void goColour(const byte r, const byte g, const byte b, const byte a, const byte w, const byte l, const byte c,  const bool boolUpdatePage)
{
  analogWrite( redled, r );
  analogWrite( grnled, g );
  analogWrite( bluLED, b );
#ifdef due4
  analogWrite( amberled, a );
  analogWrite( whiteled, w );
  analogWrite( bluvioletLED, l );
  analogWrite( cyaled, c );
#endif
#ifdef due1
  analogWrite( fiberLED, a );
#endif
  updateColour( boolUpdatePage);

  for (int i = extrawhitepin; i > extrawhitepin - 7; i = i - 2)

  {
    digitalWrite (i, 0);
  }
}

void goColour(const byte r, const bool boolUpdatePage)
{
  goColour (r, r, r, 0, r, 0, 0, boolUpdatePage);
  for (int i = extrawhitepin; i > extrawhitepin - 7; i = i - 2)

  {
    digitalWrite (i, r);
  }
}

void goColour(const byte r, const byte g, const byte b, const byte f, const bool boolUpdatePage)
{
  goColour (r, g, b, f, 0, 0, 0, boolUpdatePage);
}

void serve_dir ()
{
  sendHeader("Directory listing");
  printDirectory(0) ; //LS_SIZE);
  sendFooter();
}

void run_graph()
{
  // turn off any LEDs, always do flash with blue
  goColour(255, false);

  // read the value of  analog input pin and turn light on if in mid-stimulus...
  short sensorReading = analogRead(connectedPin);
  //  Serial.print(" sweep is : ");
  //  Serial.println(sensorReading);

  if (sensorReading < 2 || sensorReading > 4090)
  {
    //probably no contact
    digitalWrite (noContactLED, HIGH);
    //    Serial.print("on");
  }
  else
  {
    digitalWrite (noContactLED, LOW);
  }

  sensorReading = analogRead(analogPin);
  myGraphData[iIndex] = sensorReading / iGainFactor ;
  iIndex ++ ;
  //  if (iIndex > max_graph_data / 10 && iIndex < max_graph_data / 2)
  //  {
  //    analogWrite(bluLED, 255);
  //  }
  //  else
  //  {
  //    analogWrite(bluLED, 0);
  //  }

  sendHeader ("Graph of last sweep") ;
  client.println F("<script>");

  // script to reload ...
  client.println F("var myVar = setInterval(function(){myTimer()}, 1000);"); //mu sec
  client.println F("function myTimer() {");
  client.println F("location.reload(true);");
  client.println F("};");

  client.println F("function myStopFunction() {");
  client.println F("clearInterval(myVar); }");
  client.println F("");
  client.println F("</script>");
  // now do the graph...
  client.println F("<canvas id=\"myCanvas\" width=\"640\" height=\"520\" style=\"border:1px solid #d3d3d3;\">");
  client.println F("Your browser does not support the HTML5 canvas tag.</canvas>");

  client.println F("<script>");
  client.println F("var c = document.getElementById(\"myCanvas\");");
  client.println F("var ctx = c.getContext(\"2d\");");

  if (iIndex >= max_graph_data) iIndex = 0;
  for (int i = 0; i < max_graph_data - 2; i++)
  {
    if (i < iIndex - 1 || i > iIndex + 1)
    {
      client.print F("ctx.moveTo(");
      client.print (i * 20);
      client.print F(",");
      client.print (myGraphData[i] / 2);
      client.println F(");");
      client.print F("ctx.lineTo(");
      client.print ((i + 1) * 20);
      client.print F(",");
      client.print(myGraphData[i + 1] / 2);
      client.println F(");");
      client.println F("ctx.strokeStyle=\"blue\";");
      client.println F("ctx.stroke();");
    }
  }
  //draw stimulus...
  client.print F("ctx.moveTo(");
  client.print ((max_graph_data / 10) * 20);
  client.print F(",30);");

  client.print F("ctx.lineTo(");
  client.print (max_graph_data / 2 * 20);
  client.print F(",30);");

  client.println F("ctx.strokeStyle=\"blue\";");
  //              client.println("ctx.lineWidth=5;");
  client.println F("ctx.stroke();");

  client.println F("</script>");
  client.println F("<BR><BR><button onclick=\"myStopFunction()\">Stop display</button>");

  client.println F("To run a test please stop and then load ") ;

  send_GoBack_to_Stim_page ();

  sendFooter();

}


void printTwoDigits(char * p, uint8_t v)
{

  *p   = '0' + v / 10;
  *(p + 1) = '0' + v % 10;
  *(p + 2) = 0;

}

//code to print date...
void myPrintFatDateTime(const dir_t & pFile)
{
  // write this as a string to erg_in
  char * pErg_in = (char * ) erg_in ;
  erg_in [0] = 0;

  strcat_P(pErg_in, PSTR("  "));
  itoa( FAT_YEAR(pFile.lastWriteDate), pErg_in + 1, 10);
  strcat_P(pErg_in, PSTR("-"));
  printTwoDigits(pErg_in + strlen(pErg_in) , FAT_MONTH(pFile.lastWriteDate));
  strcat_P(pErg_in, PSTR("-"));
  printTwoDigits(pErg_in + strlen(pErg_in) , FAT_DAY(pFile.lastWriteDate));
  strcat_P(pErg_in, PSTR(" "));
  printTwoDigits(pErg_in + strlen(pErg_in) , FAT_HOUR(pFile.lastWriteTime));
  strcat_P(pErg_in, PSTR(":"));
  printTwoDigits(pErg_in + strlen(pErg_in) , FAT_MINUTE(pFile.lastWriteTime));
  strcat_P(pErg_in, PSTR(":"));
  printTwoDigits(pErg_in + strlen(pErg_in) , FAT_SECOND(pFile.lastWriteTime));
  strcat_P(pErg_in, PSTR(" "));
  client.print(pErg_in);
}



void printDirectory(uint8_t flags) {
  // This code is just copied from SdFile.cpp in the SDFat library
  // and tweaked to print to the client output in html!
  dir_t pAll[512];
  dir_t p ;
  int iFiles = 0 ;
#ifdef __USE_SDFAT
  sd.vwd()->rewind();
  while (sd.vwd()->readDir(&p) > 0)
#else
  root.rewind();
  while (root.readDir(p) > 0)
#endif
  {
    // done if past last used entry
    if (p.name[0] == DIR_NAME_FREE) break;

    // skip deleted entry and entries for . and  ..
    if (p.name[0] == DIR_NAME_DELETED || p.name[0] == '.') continue;

    // only list subdirectories and files
    if (!DIR_IS_FILE_OR_SUBDIR(&p)) continue;
    memcpy (&pAll[iFiles], &p, sizeof(dir_t));
    iFiles ++ ;
  }
  //iFiles -- ; // allow for last increment...

  client.print (iFiles);
  client.print F(" files found on disk  ");
#ifdef __USE_SDFAT
  // Free KB on SD.
  uint32_t freeKB = sd.vol()->freeClusterCount() * sd.vol()->blocksPerCluster() / 2;
  uint32_t diskKB = sd.vol()->clusterCount()    *  sd.vol()->blocksPerCluster() / 2;
  client.print F(" (free space ");
  client.print (freeKB / 1024);
  client.print F(" of ");
  client.print (diskKB / 1024);
  client.print F(" MBytes)");
#endif
  client.println ();
  client.println F("<ul>");

  for (int i = iFiles; i--; i >= 0)
  {
    // now print them out in reverse order
    memcpy (&p, &pAll[i], sizeof(p));
    // print any indent spaces
    client.print F("<li><a href=\"");
    for (uint8_t i = 0; i < 11; i++)
    {
      if (p.name[i] == ' ') continue;
      if (i == 8) {
        client.print('.');
      }
      client.print(char(p.name[i]));
    }
    client.print F("\">");

    // print file name with possible blank fill
    for (uint8_t i = 0; i < 11; i++)
    {
      if (p.name[i] == ' ') continue;
      if (i == 8) {
        client.print('.');
      }
      client.print(char(p.name[i]));
    }
    client.print F("</a> ");
    /////////////////////////////// now put in a link for a picture
    if (char(p.name[10]) == 'G')
    {
      // print any indent spaces
      client.print F(" <a href=\"");
      for (uint8_t i = 0; i < 10; i++)
      {
        if (p.name[i] == ' ') continue;
        if (i == 8) {
          client.print('.');
        }
        client.print(char(p.name[i]));
      }
      client.print F("P\"> (picture)</a>");
      ///////////////////////////////
    }
    if (char(p.name[10]) == 'P')
    {
      // print any indent spaces
      client.print F(" <a href=\"");
      for (uint8_t i = 0; i < 10; i++)
      {
        if (p.name[i] == ' ') continue;
        if (i == 8) {
          client.print('.');
        }
        client.print(char(p.name[i]));
      }
      client.print F("V\"> (fft (30,30))</a>");
      ///////////////////////////////
    }


    ////////////////////////////////////////

    if (DIR_IS_SUBDIR(&p))
    {
      client.print('/');
    }
    else
      // print size
    {
      myPrintFatDateTime(p);
      client.print F(" size: ");
      client.print(p.fileSize);

    }
    client.println F("</li>");
  }
  client.println F("</ul>");



}

double sgn (double x)
{
  if (x > 0) return 1;
  if (x < 0) return -1;
  return 0;
}

int br_Now(double t)
{
  int randomnumber = contrastOrder[iThisContrast];
  int F2index = 0 ;
  if (randomnumber > F2contrastchange) F2index = 1;
  return Get_br_Now( t,  F1contrast[randomnumber],  F2contrast[F2index]) ;
}

int Get_br_Now(double t, const double F1contrast, const double F2contrast)
{
  double s1 = sin((t / 1000.0) * PI * 2.0 * double(freq1));
  double s2 = sin((t / 1000.0) * PI * 2.0 * double(freq2));
  if (!bIsSine)
  {
    s1 = sgn(s1);
    s2 = sgn(s2);
  }
  return int(s1 * 1.270 * F1contrast + s2 * 1.270 * F2contrast + 127.0);
}


int fERG_Now (unsigned int t)
{
  // 2ms per sample
  if (t < (2 * max_data) / 3) return 0;
  if (t > (4 * max_data) / 3) return 0;
  return 255;
}

void webTime ()
{
#ifdef __wifisetup__
  WiFiClient timeclient;
#else
  EthernetClient timeclient;
#endif
  // default values ...
  //year = 2015;
  second = myminute = hour = day = month = 1;

  // Just choose any reasonably busy web server, the load is really low
  if (timeclient.connect ("www.york.ac.uk", 80))
  {
    // Make an HTTP 1.1 request which is missing a Host: header
    // compliant servers are required to answer with an error that includes
    // a Date: header.
    timeclient.print(F("GET / HTTP/1.1 \r\n\r\n"));
    delay (10);

    char buf[5];			// temporary buffer for characters
    timeclient.setTimeout(8000);
    if (timeclient.find((char *)"\r\nDate: ") // look for Date: header
        && timeclient.readBytes(buf, 5) == 5) // discard
    {
      day = timeclient.parseInt();	   // day
      timeclient.readBytes(buf, 1);	   // discard
      timeclient.readBytes(buf, 3);	   // month
      year = timeclient.parseInt();	   // year
      hour = timeclient.parseInt();   // hour
      myminute = timeclient.parseInt(); // minute
      second = timeclient.parseInt(); // second


      switch (buf[0])
      {
        case 'F': month = 2 ; break; // Feb
        case 'S': month = 9; break; // Sep
        case 'O': month = 10; break; // Oct
        case 'N': month = 11; break; // Nov
        case 'D': month = 12; break; // Dec
        default:
          if (buf[0] == 'J' && buf[1] == 'a')
            month = 1;		// Jan
          else if (buf[0] == 'A' && buf[1] == 'p')
            month = 4;		// Apr
          else switch (buf[2])
            {
              case 'r': month =  3; break; // Mar
              case 'y': month = 5; break; // May
              case 'n': month = 6; break; // Jun
              case 'l': month = 7; break; // Jul
              default: // add a default label here to avoid compiler warning
              case 'g': month = 8; break; // Aug
            }
      } // months sorted
      //month -- ; // zero based, I guess

    }
    Serial.print("webtime:");
    Serial.println (buf);
  }
  delay(10);
  timeclient.flush();
  timeclient.stop();

  return ;
}

void file__time ()
{
  year = 2018;
  second = myminute = hour = day = month = 1;

  //GET /?GAL4=JoB&UAS=w&Age=-1&Antn=Ok&sex=male&org=fly&col=blue&F1=12&F2=15&stim=fERG&filename=7_04_14h35m44 HTTP/1.1
  Serial.print ("INPUT is " );
  Serial.flush();
  //Serial.println (String(cInput));
  const int calcTimemax = 17 ;
  char calcTime [calcTimemax] ; //= "0000000000000" ;
  for (int i = 0; i < calcTimemax - 1; i++)
  {
    calcTime[i] = '0';
  }
  calcTime[calcTimemax] = 0;
  char * fPOS = strstr (cInput, "filename=");
  if (fPOS)
  {
    Serial.print ("fpos is " );
    Serial.println (*fPOS);
    Serial.flush();
    fPOS = fPOS + 9;
    Serial.print ("fpos is now" );
    Serial.println (*fPOS);
    Serial.flush();

    //Serial.println ("time is" + String(fPOS));
    char * cU = (strstr(fPOS, "_")) ;
    int iUnderline = cU - fPOS ;
    Serial.print ("underline is at" );
    Serial.println (iUnderline);
    Serial.flush();
    if (cU && (iUnderline) < 2)
    {
      strcpy (calcTime + 1, fPOS);
    }
    else
    {
      strcpy (calcTime, fPOS);
    }
    Serial.print ("time is:");
    for (int i = 0; i < calcTimemax - 1; i++)
    {
      Serial.print( calcTime[i] );
      Serial.flush();
    }
    Serial.println();
    // 12_10_10h26m55

    day = atoi(calcTime);
    month = atoi(calcTime + 3);
    hour = atoi(calcTime + 6);
    myminute = atoi(calcTime + 9);
    second = atoi(calcTime + 12) ;
  }
  else // filname= not found
  {
    Serial.print("No filename code");
  }
}

bool writeFile(const char * c)
{
  // file format
  //    MyInputString viz. char cInput [MaxInputStr+2];
  //    int contrastOrder[ maxContrasts ];
  //    unsigned int time_stamp [max_data] ;
  //    int erg_in [max_data];

  int16_t iBytesWritten ;
  year = 2014 ;
  webTime ();
  if (year == 2014)
  {
    file__time();
  }

  /*
    Serial.println F ("Filetime determined..");

    Serial.println( year );
    Serial.println( month );
    Serial.flush();
    Serial.println( day );
    Serial.flush();
    Serial.println( hour );
    Serial.flush();
    Serial.println( myminute );
    Serial.flush();
    Serial.println( second );
    Serial.flush();
  */
#ifdef __USE_SDFAT
#define root sd.vwd()
#endif

  if (!fileExists(c))
  {

    if ( !file.open(root, c /*myName*/,   O_CREAT | O_APPEND | O_WRITE))
    {
      Serial.println F ("Error in opening file");
      Serial.println (c);
      Serial.flush();
      return false;
    }

    if (!file.timestamp(T_CREATE | T_ACCESS | T_WRITE, year, month, day, hour, myminute, second)) {
      Serial.println F ("Error in timestamping file");
      Serial.println (c);
      Serial.flush();
      return false ;
    }
    iBytesWritten = file.write(cInput, MaxInputStr + 2);
    if (iBytesWritten <= 0)
    {
      Serial.println F ("Error in writing header to file");
      file.close();
      return false ;
    }

  }
  else // file exists, so just append...
  {
    if ( !file.open(root, c /*myName*/,  O_APPEND | O_WRITE))
    {
      Serial.println F ("Error in reopening file");
      Serial.println (c);
      return false;
    }

  }


  // always write the erg and time data, and on last line contrast data
  iBytesWritten = file.write(erg_in, max_data * sizeof(int));
  if (iBytesWritten <= 0)
  {
    Serial.println F ("Error in writing erg data to file");
    file.close();
    return false;
  }

  // Serial.println("File success: written bytes " + String(iBytesWritten));
  iBytesWritten = file.write(time_stamp, max_data * sizeof(unsigned int));
  if (iBytesWritten <= 0)
  {
    Serial.println F ("Error in writing timing data to file");
    return false ;
  }
  Serial.print F(" More bytes writen to file.........");
  Serial.print  (c);
  Serial.print F(" size now ");
  Serial.println (file.fileSize());
  file.sync();
  return true ;
}

bool fileExists(const char * c)
{
  if (file.isOpen()) file.close();
  bool bExixsts = file.open(root, c, O_READ);
  if (bExixsts) file.close();
  return bExixsts ;
}

// find day of week http://stackoverflow.com/questions/6054016/c-program-to-find-day-of-week-given-date
int DayOfWeek (int d, int m, int y)
{
  return (d += m < 3 ? y-- : y - 2, 23 * m / 9 + d + 4 + y / 4 - y / 100 + y / 400) % 7   ;
}

void gmdate ( const dir_t & pFile)
{
  // Last-Modified: Tue, 15 Nov 1994 12:45:26 GMT
  const char * cDays PROGMEM = "Sun,Mon,Tue,Wed,Thu,Fri,Sat,Sun";
  const char * cMonths PROGMEM = "Jan,Feb,Mar,Apr,May,Jun,Jul,Aug,Sep,Oct,Nov,Dec,";
  char * c  = (char *) erg_in ;
  erg_in [0] = 0;
  int iTmp ;
  int d = FAT_DAY(pFile.lastWriteDate) ;
  int m = FAT_MONTH(pFile.lastWriteDate) ;
  int y = FAT_YEAR(pFile.lastWriteDate) ;

  iTmp = DayOfWeek (d, m, y) ;
  if (iTmp > 6) iTmp = 0;
  strncpy(c, cDays + iTmp * 4, 3); // tue
  c[3] = 0;
  strcat_P(c, PSTR(", "));
  //Serial.println (c);

  printTwoDigits(c + strlen(c) , FAT_DAY(pFile.lastWriteDate));
  strcat_P (c, PSTR(" "));

  int iLen = strlen(c);
  iTmp = m - 1;
  if (iTmp > 11) iTmp = 0;
  strncpy(c + iLen, cMonths + iTmp * 4, 3); //nov
  c[iLen + 3] = 0;
  //Serial.println (c);

  strcat_P (c, PSTR(" "));
  itoa( y, c + strlen(c), 10);
  strcat_P (c, PSTR(" "));
  printTwoDigits(c + strlen(c) , FAT_HOUR(pFile.lastWriteTime));
  strcat_P (c, PSTR(":"));
  printTwoDigits(c + strlen(c) , FAT_MINUTE(pFile.lastWriteTime));
  strcat_P (c, PSTR(":"));
  printTwoDigits(c + strlen(c) , FAT_SECOND(pFile.lastWriteTime));
  strcat_P (c, PSTR(" GMT"));

  //Serial.println( c );
}


void doplotFile (const char * c)
{
  String Sc = (c);
  Sc = String (F("Plotting ")) + Sc ;
  sendHeader (Sc);
  //based on doReadFile...

  //String dataString ;
  char * cPtr;
  cPtr = (char *) erg_in ;
  int iOldContrast ;

  //Serial.print F("trying to open:");
  //Serial.println (c);
  if (file.isOpen()) file.close();
  file.open(root, c, O_READ);

  int iBytesRequested, iBytesRead;
  // note this overwrites any data already in memeory...
  //first read the header string ...
  iBytesRequested = MaxInputStr + 2;
  iBytesRead = file.read(cPtr, iBytesRequested);
  if (iBytesRead < iBytesRequested)
  {
    client.println F("Error reading header data in file ");
    client.println(c);
    return ;
  }

  // write out the string ....
  client.println(cPtr);
  client.println("<BR>");
  // test if its an ERG
  //boolean bERG = ( NULL != strstr ( cPtr, "stim=fERG&") ) ;
  client.print("Download file <a HREF=\"");
  client.print(c);
  client.print("\">");
  client.print(c);
  client.println("</a><BR>");

  // now on to the data
  int nBlocks = 0;
  unsigned int time_stamp2 [max_data];
  int erg_in2 [max_data] ;

  for (int i = 0; i < max_data; i++)
  {
    erg_in[i] = 0;
    time_stamp[i] = 0;
  }

  iBytesRequested = max_data * sizeof(int);
  iBytesRead = file.read(erg_in2, iBytesRequested);


  while (iBytesRead == iBytesRequested)
  {
    iBytesRequested = max_data * sizeof(unsigned int);
    iBytesRead = file.read (time_stamp2, iBytesRequested );
    nBlocks ++;

    for (int i = 0; i < max_data; i++)
    {
      erg_in[i] = erg_in[i] + erg_in2[i];
      time_stamp[i] = time_stamp[i] + time_stamp2[i];
    }

    //read next block
    iBytesRequested = max_data * sizeof(int);
    iBytesRead = file.read(erg_in2, iBytesRequested);

  } // end of while

  file.close();

  for (int i = 0; i < max_data; i++)
  {
    erg_in[i] = erg_in [i] / nBlocks;
    time_stamp[i] = time_stamp [i] / nBlocks;
  }
  sendGraphic ();
  sendFooter();

}

void doFFTFile (const char * c, bool bNeedHeadFooter)
{
  String Sc = (c);
  Sc = String (F("FFT of ")) + Sc ;
  if (bNeedHeadFooter) sendHeader (Sc);

  //String dataString ;
  char * cPtr;
  cPtr = (char *) erg_in ;
  int iOldContrast ;
  int erg_in2 [max_data] ;
  memset (erg_in2, 0, sizeof(int) * max_data);

  Serial.print F("trying to open:");
  Serial.println (c);
  if (file.isOpen()) file.close();
  file.open(root, c, O_READ);

  // Content-Length: 1000000 [size in bytes
  // Last-Modified: Sat, 28 Nov 2009 03:50:37 GMT
  // make erg_in buffer do the dirty work of getting the date...
  dir_t  dE;
  if (file.dirEntry (&dE))
  {
    Serial.println F("file date recovered") ;
  }
  else
  {
    Serial.println F("file date not recovered") ;
  }
  gmdate ( dE );
  Serial.print F("Last modified is:");
  Serial.println( cPtr ) ;
  //sendHeader(String(c), "", false, cPtr);

  int iBytesRequested, iBytesRead;
  // note this overwrites any data already in memeory...
  //first read the header string ...
  iBytesRequested = MaxInputStr + 2;
  iBytesRead = file.read(cPtr, iBytesRequested);
  if (iBytesRead < iBytesRequested)
  {
    client.println F("Error reading header data in file ");
    client.println(c);
    return ;
  }

  // write out the string ....
  client.print(cPtr);
  client.println("<BR>");

  // now on to the data
  iBytesRequested = max_data * sizeof(int);
  iBytesRead = file.read(erg_in, iBytesRequested);

  int nBlocks = 0;
  while (iBytesRead == iBytesRequested)
  {
    iBytesRequested = max_data * sizeof(unsigned int);
    iBytesRead = file.read (time_stamp, iBytesRequested );
    nBlocks ++;
    // stop when mask and probe are both 30%
    Serial.print("time ");
    Serial.print(time_stamp[max_data - 1]);
    Serial.print(" erg ");
    Serial.println(erg_in[max_data - 1]);
    if ( time_stamp[max_data - 1] == 30 && erg_in[max_data - 1] == 30 )
    {
      Serial.print F("about to do FFT ");
      do_fft();
      for (int ii = 0; ii < max_data; ii++)
      {
        erg_in2[ii] = erg_in2[ii] + erg_in[ii];
      }
      Serial.print (erg_in[48]);
      Serial.println F(" done FFT");
    }

    //read next block
    iBytesRequested = max_data * sizeof(int);
    iBytesRead = file.read(erg_in, iBytesRequested);

  } // end of while

  file.close();
  for (int ii = 0; ii < max_data; ii++)
  {
    erg_in[ii] = erg_in2[ii] / maxRepeats;
  }
  Serial.print (erg_in[48]);
  // now plot data in erg_in
  sendGraphic(false);
  Serial.println F(" plotted FFT");
  if (bNeedHeadFooter) sendFooter ();

}


void doreadFile (const char * c)
{
  //String dataString ;
  char * cPtr;
  cPtr = (char *) erg_in ;
  int iOldContrast ;

  //Serial.print F("trying to open:");
  //Serial.println (c);
  if (file.isOpen()) file.close();
  file.open(root, c, O_READ);

  // Content-Length: 1000000 [size in bytes
  // Last-Modified: Sat, 28 Nov 2009 03:50:37 GMT
  // make erg_in buffer do the dirty work of getting the date...
  dir_t  dE;
  if (file.dirEntry (&dE))
  {
    Serial.println F("file date recovered") ;
  }
  else
  {
    Serial.println F("file date not recovered") ;
  }
  gmdate ( dE );
  Serial.print F("Last modified is:");
  Serial.println( cPtr ) ;
  sendHeader(String(c), "", false, cPtr);

  int iBytesRequested, iBytesRead;
  // note this overwrites any data already in memeory...
  //first read the header string ...
  iBytesRequested = MaxInputStr + 2;
  iBytesRead = file.read(cPtr, iBytesRequested);
  if (iBytesRead < iBytesRequested)
  {
    client.println F("Error reading header data in file ");
    client.println(c);
    return ;
  }

  // write out the string ....
  client.print(cPtr);
  client.println();
  // test if its an ERG
  boolean bERG = ( NULL != strstr ( cPtr, "stim=fERG&") ) ;
  bIsSine = ( NULL == strstr ( cPtr, "stm=SQ") ) ;

  // now on to the data
  iBytesRequested = max_data * sizeof(int);
  iBytesRead = file.read(erg_in, iBytesRequested);

  int nBlocks = 0;
  while (iBytesRead == iBytesRequested)
  {
    iBytesRequested = max_data * sizeof(unsigned int);
    iBytesRead = file.read (time_stamp, iBytesRequested );
    nBlocks ++;

    for (int i = 0; i < max_data - 1; i++)
    {
      // make a string for assembling the data to log:
      client.print(time_stamp[i]);
      client.print F( ", ");
      if (bERG)
      {
        client.print( fERG_Now (time_stamp[i] - time_stamp[0] ) );
      }
      else
      {
        client.print(Get_br_Now(time_stamp[i],  time_stamp [max_data - 1], erg_in [max_data - 1]));
      }
      client.print F(", ");

      client.print(erg_in[i]);
      client.println();
    } //for

    // write out contrast

    client.print F( "-99, " );

    client.print(time_stamp[max_data - 1]);
    client.print ( ", " );

    client.print(erg_in[max_data - 1]);
    client.println();

    //read next block
    iBytesRequested = max_data * sizeof(int);
    iBytesRead = file.read(erg_in, iBytesRequested);

  } // end of while

  file.close();

}

bool collectSSVEPData ()
{
  const long presamples = 102;
  long mean = 0;
  unsigned int iTime ;
  if (iThisContrast == 0 && file.isOpen()) file.close();

  //
  //
  //  Serial.print F("collecting data with ");
  //  Serial.print (nRepeats);
  //  Serial.print F("r : c");
  //  Serial.println (iThisContrast);
  //
  //  Serial.print F("update collecting data with ");
  //  Serial.print (nRepeats);
  //  Serial.print F("r : c");
  //  Serial.println (iThisContrast);

  sampleCount = -presamples ;
  last_time = millis();
  start_time = last_time;
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
      last_time = last_time + interval ;
      iTime = now_time - start_time ;
      if (sampleCount == 0)
      {
        mean = mean / presamples ;
      }
      if (sampleCount >= 0)
      {
        // read  sensor
        erg_in[sampleCount] = analogRead(analogPin) - mean ; // subtract 512 so we get it in the range...
        time_stamp[sampleCount] = iTime ;
      }
      else
      {
        mean = mean + long(analogRead(analogPin));
      }
      int intensity = br_Now(iTime) ;
      analogWrite(usedLED, intensity);
      sampleCount ++ ;
    }
  }

  // now done with sampling....
  //save contrasts we've used...
  int randomnumber = contrastOrder[iThisContrast];
  int F2index = 0 ;
  if (randomnumber > F2contrastchange) F2index = 1;
  time_stamp [max_data - 1] = F1contrast[randomnumber];
  erg_in [max_data - 1] = F2contrast[F2index] ;

  sampleCount ++ ;
  analogWrite(usedLED, 127);
  iThisContrast ++;
  if (iThisContrast >= maxContrasts)
  {
    iThisContrast = 0;
    nRepeats ++;
    doShuffle ();
  }

  return writeFile(cFile);


}


bool collect_fERG_Data ()
{
  const long presamples = 102;
  long mean = 0;
  unsigned int iTime ;
  if (iThisContrast == 0 && file.isOpen()) file.close();

  iThisContrast = maxContrasts;
  nRepeats ++;
  //  Serial.print F("collecting fERG data with ");
  //  Serial.print (nRepeats);
  //  Serial.print F("r : c");
  //  Serial.println (iThisContrast);

  sampleCount = -presamples ;
  last_time = millis();
  start_time = last_time;
  while (sampleCount < max_data)
  {
    unsigned long now_time = millis();
    if (now_time < last_time + interval / 2)
    {
      timing_too_fast ++ ;
    }
    else
    {
      // Initial test showed it could write this to the card at 12 ms intervals
      last_time = last_time + interval / 2 ;
      iTime = now_time - start_time ;
      if (sampleCount == 0)
      {
        mean = mean / presamples ;
      }
      if (sampleCount >= 0)
      {
        // read  sensor
        erg_in[sampleCount] = analogRead(analogPin) - mean ; // subtract 512 so we get it in the range...
        time_stamp[sampleCount] = iTime ;
      }
      else
      {
        mean = mean + long(analogRead(analogPin));
      }
      int intensity = fERG_Now(iTime - time_stamp[0]) ;
      analogWrite(usedLED, intensity);
      sampleCount ++ ;
    }
  }

  sampleCount ++ ;
  analogWrite(usedLED, 0);
  iThisContrast = maxContrasts ; //++;

  return writeFile(cFile);


}

void flickerPage()
{
  //  Serial.print F("Sampling at :");
  //  Serial.println (String(sampleCount));

  sendHeader F("Sampling");

  // script to reload ...
  client.println F("<script>");
  client.println F("var myVar = setInterval(function(){myTimer()}, 8500);"); //mu sec
  client.println F("function myTimer() {");
  client.println F("location.reload(true);");
  client.println F("};");

  client.println F("function myStopFunction() {");
  client.println F("var b = confirm(\"Really Stop Data Acqusition ?\"); \n if ( b == true )  ");
  client.print F("{ \n clearInterval(myVar); ");
  if (MyReferString != String("131") )
  {
    client.print F("\n location.assign(\"");
    client.print (MyReferString);
    client.print F("\") ") ;
  }
  else
  {
    client.print F("\n history.back();");
  }
  client.print F(" } }");
  //client.println F("location.assign(\"stop/\");");
  client.println F("");
  client.println F("</script>");

  if (bDoFlash)
  {
    AppendFlashReport ();
  }
  else
  {
    AppendSSVEPReport();
  }
  sendFooter ();
}

void AppendFlashReport()
{
  client.print F("Acquired ") ;
  client.print ( nRepeats );
  client.print F(" of ");
  client.print (maxRepeats);
  client.println F(" data blocks so far " );
  client.println F("<button onclick=\"myStopFunction()\">Stop Data Acquisition</button><BR>");
  client.println (cInput);
  client.println F( "<BR> ");


  if (nRepeats > 0)
  {
    sendGraphic();
  }
}

void AppendSSVEPReport()
{
  client.print F("Acquired ") ;
  int iTmp = nRepeats * maxContrasts ; //- maxContrasts ;
  Serial.print F("Acquired ");
  Serial.print (iTmp);
  iTmp = iTmp + iThisContrast ;
  Serial.print F(" really ");
  Serial.println (iTmp);

  client.print (iTmp);
  client.print F(" of ");
  client.print (maxRepeats * maxContrasts);
  client.println F(" data blocks so far " );
  client.println F("<button onclick=\"myStopFunction()\">Stop Data Acquisition</button><BR>");
  client.println (cInput);
  client.println F( "<BR> ");


  if (iThisContrast < maxContrasts)
  {
    int randomnumber = contrastOrder[iThisContrast];
    int F2index = 0 ;
    if (randomnumber > F2contrastchange) F2index = 1;
    client.print F("Data will flicker at "); +
    client.print (freq1) ;
    client.print F( " Hz with contrast ");
    client.print (F1contrast[randomnumber] );
    client.print F(" and "); +
    client.print (freq2) ;
    client.print F(" Hz with contrast ") ;
    client.print ( F2contrast[F2index] );
    client.print F(" % <BR> " );
    client.println ();

    client.println F("please wait....<BR>");
    if (iThisContrast > 0)
    {
      iThisContrast -- ;
      client.println F("<canvas id=\"myCanvas\" width=\"640\" height=\"450\" style=\"border:1px solid #d3d3d3;\">");
      client.println F("Your browser does not support the HTML5 canvas tag.</canvas>");

      client.println F("<script>");
      client.println F("var c = document.getElementById(\"myCanvas\");");
      client.println F("var ctx = c.getContext(\"2d\");");

      int iStep = 2;
      for (int i = 0; i < 5 * max_graph_data - 2; i = i + iStep)
      {
        client.print F("ctx.moveTo(");
        client.print(i * 4);
        client.print F(",");
        client.print(myGraphData[i] / 4 + 350);
        client.println F(");");
        client.print F("ctx.lineTo(");
        client.print((i + iStep) * 4);
        client.print F(",");
        client.print(myGraphData[i + iStep] / 4 + 350);
        client.println F(");");
      }
      client.println F("ctx.stroke();");

      for (int i = 0; i < 5 * max_graph_data - 2; i = i + iStep)
      {
        client.print F("ctx.moveTo(");
        client.print(i * 4);
        client.print F(",");
        client.print(br_Now(time_stamp[i]) );
        client.println F(");");
        client.print F("ctx.lineTo(");
        client.print((i + iStep) * 4);
        client.print F(",");
        client.print(br_Now(time_stamp[i + iStep]));
        client.println F(");");
      }
      client.println F("ctx.stroke();");

      client.println F("</script>");
      iThisContrast ++ ;
    }


    for (int i = iThisContrast - 1; i > -1 ; i--)
    {
      int randomnumber = contrastOrder[i];
      int F2index = 0 ;
      if (randomnumber > F2contrastchange) F2index = 1;

      client.print F("<BR>Data has been flickered at "); +
      client.print (freq1) ;
      client.print F( " Hz with contrast ");
      client.print (F1contrast[randomnumber] );
      client.print F(" and "); +
      client.print (freq2) ;
      client.print F(" Hz with contrast ") ;
      client.print (F2contrast[F2index] );
      client.print F(" % " );
      client.println ();
    }
  }

}


void getData ()
{
  if (sampleCount < 0)
  {
    if (bDoFlash)
    {
      bFileOK = collect_fERG_Data ();
    }
    else
    {
      bFileOK = collectSSVEPData ();
    }
  }

}
void plotInColour (int iStart, const String & str_col)
{
  // 12 Hz in blue ?
  // 4 ms per point 0.25 Hz per point, so 12 Hz expected at 48
  client.println F("ctx.beginPath();");
  client.print F("ctx.moveTo(");
  client.print((iXFactor * iStart) / iXDiv );
  client.print F(",");
  client.print(iBaseline - (10 * myGraphData[iStart]) / iYFactor);
  client.println F(");");
  for (int i = iStart + istep; i < iStart + 5; i = i + istep)
  {
    client.print F("ctx.lineTo(");
    client.print((iXFactor * i) / iXDiv );
    client.print F(",");
    client.print(iBaseline - (10 * myGraphData[i]) / iYFactor);
    client.println F(");");
  }
  client.print F("ctx.strokeStyle = '");
  client.print (str_col);
  client.println F("';");
  client.println F("ctx.closePath();");
  client.print F("ctx.fillStyle='");
  client.print (str_col);
  client.println F("';");
  client.println F("ctx.fill();");
  client.println F("ctx.stroke();");
}
void sendGraphic()
{
  sendGraphic(true);
}

void sendGraphic(bool plot_stimulus)
{
  client.println F("<canvas id=\"myCanvas\" width=\"640\" height=\"520\" style=\"border:1px solid #d3d3d3;\">");
  client.println F("Your browser does not support the HTML5 canvas tag.</canvas>");

  client.println F("<script>");
  client.println F("var c = document.getElementById(\"myCanvas\");");
  client.println F("var ctx = c.getContext(\"2d\");");

  istep = 15;
  plot_limit = max_data - max_data / 6 ;
  iXFactor = 4;
  iYFactor = 25 ;
  iBaseline = 260 ;
  iXDiv = 6 ;
  if (!plot_stimulus)
  {
    istep = 1;
    plot_limit = plot_limit / 2;
    iXFactor = 10 ;
    iYFactor = 5;
    iBaseline = 420 ;
    iXDiv = 5 ;
  }
  // move to start of line
  client.println F("ctx.beginPath();");
  client.print F("ctx.moveTo(");
  client.print((iXFactor * istep) / iXDiv );
  client.print F(",");
  client.print(iBaseline - (10 * myGraphData[istep]) / iYFactor);
  client.println F(");");

  //now join up the line
  for (int i = 2 * istep; i < plot_limit; i = i + istep)
  {
    client.print F("ctx.lineTo(");
    client.print((iXFactor * i) / iXDiv );
    client.print F(",");
    client.print(iBaseline - (10 * myGraphData[i]) / iYFactor);
    client.println F(");");
  }
  client.println F("ctx.stroke();");

  if (plot_stimulus)
  {
    client.println F("ctx.beginPath();");
    client.print F("ctx.moveTo(");
    client.print((iXFactor * 1) / iXDiv );
    client.print F(",");
    client.print(10 + (4 * fERG_Now(time_stamp[1] - time_stamp[0])) / iYFactor);
    client.println F(");");

    for (int i = 2 * istep; i < plot_limit; i = i + istep)
    {
      client.print F("ctx.lineTo(");
      client.print((iXFactor * (i)) / iXDiv );
      client.print F(",");
      client.print(10 + (4 * fERG_Now(time_stamp[i] - time_stamp[0]) ) / iYFactor);
      client.println F(");");
    }
    client.println F("ctx.stroke();");
  }
  else
  {
    plotInColour (4 * 12, String F("#0000FF"));
    plotInColour (4 * 12 * 2, String F("#8A2BE2"));
    plotInColour (4 * 27, String F("#FF8C00"));
    // 1024 rather than 1000
    plotInColour (4 * 51, String F("#FF0000"));
  }

  client.println F("</script>");
}


void sendReply ()
{
  int exp_size = MaxInputStr + 2 ;
  Serial.println(MyInputString);
  if (!has_filesystem)
  {
    sendHeader F("Card not working");
    client.println F("SD Card failed");
    sendFooter();
    return ;
  }
  if (!bFileOK)
  {
    sendHeader F("Card not working");
    client.print F("File write failed on SD Card : ");
    client.print (cFile);
    client.println F("<BR><BR>To setup for another test please ");

    send_GoBack_to_Stim_page ();
    sendFooter();

    bFileOK = true ;
    return ;
  }

  int fPOS = MyInputString.indexOf F("filename=");
  // asking for new sample
  if (fPOS > 0)
  {
    // save the commandline....
    MyInputString.toCharArray(cInput, MaxInputStr + 2);
    char * cP = strstr(cInput, "HTTP/");
    if (cP) cP = '\0';
    // now choose the colour
    int oldLED = usedLED ;
    if (MyInputString.indexOf F("col=blue&") > 0 ) usedLED  = bluLED ; //
    if (MyInputString.indexOf F("col=green&") > 0 ) usedLED  = grnled ; //
    if (MyInputString.indexOf F("col=red&") > 0 ) usedLED  = redled ; //
    if (MyInputString.indexOf F("col=fiber") > 0 ) usedLED  = fiberLED ; //
    //due4 is special
    if (MyInputString.indexOf F("col=amber&") > 0 ) usedLED  = amberled ; //
    if (MyInputString.indexOf F("col=cyan&") > 0 ) usedLED  = cyaled ; //
    if (MyInputString.indexOf F("col=blueviolet&") > 0 ) usedLED  = bluvioletLED ; //

    //flash ERG or SSVEP?
    bDoFlash = MyInputString.indexOf F("stim=fERG&") > 0  ;
    bIsSine = MyInputString.indexOf F("stm=SQ&") < 0  ; // -1 if not found

    // find filename
    String sFile = MyInputString.substring(fPOS + 9); // ignore the leading / should be 9
    //Serial.println("  Position of filename= was:" + String(fPOS));
    //Serial.println(" Proposed saving filename " + sFile );
    fPOS = sFile.indexOf F(" ");  // or  & id filename is not the last paramtere
    //Serial.println("  Position of blankwas:" + String(fPOS));
    sFile = sFile.substring(0, fPOS);
    while (sFile.length() > 8)
    {
      sFile = sFile.substring(1);
      //Serial.println(" Proposed saving filename " + sFile );
    }
    if (bDoFlash)
    {
      sFile = sFile + F(".ERG");
      exp_size = exp_size + (maxRepeats * data_block_size) ;
    }
    else
    {
      sFile = sFile + F(".SVP");
      exp_size = exp_size + (maxRepeats * maxContrasts * data_block_size) ;
    }

    //Serial.println(" Proposed filename now" + sFile + ";");
    //if file exists... ????
    sFile.toCharArray(cFile, 29); // adds terminating null
    if (!fileExists(cFile))
    {
      // new file
      nRepeats = iThisContrast = 0 ;
      //turn off any lights we have on...
      goColour(0, false);
    }
    //Serial.print("repeats now ");
    //Serial.println(nRepeats);
    if (fileExists(cFile) && file.fileSize() >= exp_size ) //nRepeats >= maxRepeats)
    {
      // done so tidy up
      nRepeats = iThisContrast = 0 ; // ready to start again
      //file.timestamp(T_ACCESS, 2009, 11, 12, 7, 8, 9) ;
      file.close();

      sendHeader F("Sampling Complete!");
      client.print( "Sampling Now Complete <BR><BR>");
      client.print( "<A HREF= \"" + sFile + "\" >" + sFile + "</A>" + " size: ");
      client.print(file.fileSize());
      client.print(" bytes; expected size ");
      client.print(exp_size);

      if (bDoFlash)
      {
        String sPicture = sFile;
        sPicture.replace ("ERG", "ERP" );
        client.print("<A HREF= \"" + sPicture + "\" > (averaged picture) </A>" );
      }
      client.println("<BR><BR>");

      client.println F("To setup for another test please ") ;
      send_GoBack_to_Stim_page ();
      client.println F("<BR><A HREF= \"dir=\"  > Full directory</A> <BR><BR>");
      
      if (bDoFlash)
      {
        sendGraphic();
      }
      else
      {
        doFFTFile (cFile, false) ;
      }
      sendFooter ();
      return ;
    }

    flickerPage();
    sampleCount = -102 ; //implies collectData();
    return ;
  }

  // show directory
  fPOS = MyInputString.indexOf F("dir=");
  //Serial.println("  Position of dir was:" + String(fPOS));
  if (fPOS > 0)
  {
    serve_dir() ;
    return ;
  }

  //light up
  fPOS = MyInputString.indexOf F("white/");
  if (fPOS > 0)
  {
    goColour(255, true) ;
    return ;
  }

  fPOS = MyInputString.indexOf F("amber/");
  if (fPOS > 0)
  {
    //void go4Colour(const byte r, const byte g, const byte b, const byte a, const byte w, const byte l, const byte c,  const bool boolUpdatePage)
    goColour(0, 0, 0, 255, 0, 0, 0, true) ;
    return ;
  }
  fPOS = MyInputString.indexOf F("cyan/");
  if (fPOS > 0)
  {
    //void go4Colour(const byte r, const byte g, const byte b, const byte a, const byte w, const byte l, const byte c,  const bool boolUpdatePage)
    goColour(0, 0, 0, 0, 0, 0, 255, true) ;
    return ;
  }
  fPOS = MyInputString.indexOf F("blueviolet/");
  if (fPOS > 0)
  {
    //void go4Colour(const byte r, const byte g, const byte b, const byte a, const byte w, const byte l, const byte c,  const bool boolUpdatePage)
    goColour(0, 0, 0, 0, 0, 255, 0, true) ;
    return ;
  }

  fPOS = MyInputString.indexOf F("red/");
  if (fPOS > 0)
  {
    goColour(255, 0, 0, 0, true) ;
    return ;
  }
  fPOS = MyInputString.indexOf F("blue/");
  if (fPOS > 0)
  {
    goColour(0, 0, 255, 0, true) ;
    return ;
  }
  fPOS = MyInputString.indexOf F("green/");
  if (fPOS > 0)
  {
    goColour(0, 255, 0, 0, true) ;
    return ;
  }
  fPOS = MyInputString.indexOf F("black/");
  if (fPOS > 0)
  {
    goColour(0, true) ;
    return ;
  }
  fPOS = MyInputString.indexOf F("fiber/");
  if (fPOS > 0)
  {
    goColour(0, 0, 0, 255, true) ;
    return ;
  }

  // a file is requested...
  fPOS = MyInputString.indexOf F(".SVP");
  if (fPOS == -1)
  {
    fPOS = MyInputString.indexOf F(".SVV");
  }
  if (fPOS == -1)
  {
    fPOS = MyInputString.indexOf F(".ERG");
  }
  if (fPOS == -1)
  {
    fPOS = MyInputString.indexOf F(".ERP");
  }
  //Serial.println("  Position of .SVP was:" + String(fPOS));
  if (fPOS > 0)
  {
    // requested a file...
    fPOS = MyInputString.indexOf F("/");
    String sFile = MyInputString.substring(fPOS + 1); // ignore the leading /
    //Serial.println(" Proposed filename " + sFile );
    fPOS = sFile.indexOf(" HTTP/");
    sFile = sFile.substring(0, fPOS);
    //Serial.println(" Proposed filename now" + sFile + ";");

    if (MyInputString.indexOf F(".ERP") > 0)
    {
      sFile.replace(F(".ERP"), F(".ERG"));
      sFile.toCharArray(cFile, 29); // adds terminating null
      doplotFile(cFile) ;
    }
    else
    {

      if (MyInputString.indexOf F(".SVV") > 0)
      {
        sFile.replace(F(".SVV"), F(".SVP"));
        sFile.toCharArray(cFile, 29); // adds terminating null
        doFFTFile(cFile, true) ;
      }
      else
      {
        sFile.toCharArray(cFile, 29); // adds terminating null
        doreadFile(cFile) ;
      }
    }
    return ;

  }

  // default - any other url
  run_graph() ;
  MyInputString = "";
}

void loop()
{

  String sTmp = "";
  MyInputString = "";
  getData ();
  boolean currentLineIsBlank = true;
  // listen for incoming clients

  client = server.available();
  if (client) {
    Serial.println F("new client");
    MyInputString = "";
    // an http request ends with a blank line
    while (client.connected()) {
      if (client.available()) {            // if there's bytes to read from the client,
        char c = client.read();

        // if you've gotten to the end of the line (received a newline
        // character) and the line is blank, the http request has ended,
        // so you can send a reply
        if (c == '\n' && currentLineIsBlank)
        {
          sendReply ()  ;
          break ;
        }

        if (c == '\n')
        {
          //Serial.print("Input string now " );
          //Serial.println (sTmp);

          // you're starting a new line
          // see if we need to save the old one
          if (sTmp.indexOf F("GET") >= 0)
          {
            MyInputString = sTmp;
          }
          int iTmp = sTmp.indexOf F("Referer:") ;
          if (iTmp >= 0)
          {
            String sHost = sTmp.substring(16);
            //Serial.println (sHost) ;
            int iSlash = sHost.indexOf ("/");
            sHost = sHost.substring(0, iSlash);
            //Serial.println (sHost) ;
            DNSClient dc;
            dc.begin(dnsIP);
            dc.getHostByName(sHost.c_str(), theirIP);
            //S//erial.print F("Their IP is ");
            //Serial.println (theirIP) ;
            if (myIP != theirIP)
            {
              //Serial.println F("this does not appear to be my ip");
              MyReferString = sTmp.substring(iTmp + 9);
              //Serial.print F("Ref string now :" );
              //Serial.println (MyReferString);
            }
            //            else
            //            {
            //              Serial.println F("this appears to be my ip");
            //              Serial.print F("Ref string unchanged at :" );
            //              Serial.println (MyReferString);
            //            }


          }
          sTmp = "";

          currentLineIsBlank = true;
        }
        else if (c != '\r')
        {
          // you've gotten a character on the current line
          currentLineIsBlank = false;
          if (sTmp.length() < MaxInputStr)
          {
            sTmp.concat(c);
            //Serial.println(sTmp);
          }
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


void do_fft()
{

  //  read it  in erg_in, transfer it to f_ and then put the fft back in erg_in


  // FFT_SIZE IS DEFINED in Header file Radix4.h
  // #define   FFT_SIZE           1024

  int         f_r[FFT_SIZE]   = { 0};
  int         f_i[FFT_SIZE]   = { 0};
  int         out[FFT_SIZE / 2]     = { 0};     // Magnitudes

  Radix4     radix;
  for ( uint16_t i = 0, k = (NWAVE / FFT_SIZE); i < FFT_SIZE; i++ )
  {
    f_r[i] = erg_in[i];
  }
  memset( f_i, 0, sizeof(f_i));                   // Image -zero.



  radix.rev_bin( f_r, FFT_SIZE);
  radix.fft_radix4_I( f_r, f_i, LOG2_FFT);
  radix.gain_Reset( f_r, LOG2_FFT - 1);
  radix.gain_Reset( f_i, LOG2_FFT - 1);
  radix.get_Magnit( f_r, f_i, erg_in);

}

