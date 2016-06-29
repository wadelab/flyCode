

//try this http://gammon.com.au/forum/?id=11488&reply=5#reply5 for interrupts
//Digital pin 7 is used as a handshake pin between the WiFi shield and the Arduino, and should not be used
// http://www.arduino.cc/playground/Code/AvailableMemory

// Serial.print("Free heap:");
// Serial.println(ESP.getFreeHeap(),DEC);


// don't use pin 4 or 10-12 either...

// known bug on Edison: PWM code does not work // FIX

// if we test file, it will return true if the file is open...
// file append is not honoured, need to seek end...

#ifdef ARDUINO_LINUX
#define __wifisetup__
#endif


#ifdef ESP8266
#define __wifisetup__
// run as standalone access point ??

#define ESP8266AP
#endif

#ifndef __wifisetup__


#define due5
#define USE_DHCP


#ifndef ARDUINO_LINUX
#define EthernetShield Ethernet
#define IPAddressShield IPAddress
#define EthernetServerShield EthernetServer
#define EthernetClientShield EthernetClient
#endif
#endif



//_____________________________________________________

#ifdef due6
#define MAC_OK 0xDE, 0xAD, 0xBE, 0xEF, 0xFE, 0xED
//biolpc2793 [in use in lab with Emily and Richard]
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

#ifdef due5
#define MAC_OK 0x90, 0xA2, 0xDA, 0x0F, 0x42, 0x02
//biolpc2804
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
// ethernet...
#ifndef ARDUINO_LINUX
#include <Ethernet.h>
#else
#include <EthernetShield.h>
#endif

#else
//wifi of some sort...

#ifdef ESP8266
extern "C" {
#include "user_interface.h"
}
#include <ESP8266WiFi.h>
#include <ESP8266mDNS.h>
#else
#include <WiFi.h>
#endif
#endif
// end of if wifi or ethernet

#ifdef ESP8266
#include <FS.h>
#else
#include <SD.h>
#endif

//#include "mydata.h"
// include fft
#include <Radix4.h>
//#include <FixFFT.h>


const char * cDays  = "Sun,Mon,Tue,Wed,Thu,Fri,Sat,Sun";
const char * cMonths  = "Jan,Feb,Mar,Apr,May,Jun,Jul,Aug,Sep,Oct,Nov,Dec,";
const short max_graph_data = 32 ;
int * myGraphData ;  // will share erg_in space, see below
short iIndex = 0 ;

//
volatile byte usedLED  = 0;
const byte fiberLED = 8 ;
const byte noContactLED = 2;

// define LED mapping here
const byte bluvioletLED = 8 ;
const byte amberled = 6;
const byte whiteled = 11;
const byte cyaled = 9;
const byte extrawhitepin = 53;

#ifdef ARDUINO_LINUX
const byte redled = 3;
const byte grnled = 5;
const byte bluLED = 6;
#endif

#ifdef due3
const byte redled = 7;
const byte grnled = 3;
const byte bluLED = 5;
#endif

#ifdef due4
const byte redled = 7;
const byte grnled = 3;
const byte bluLED = 5;
#endif

#ifdef due5
const byte redled = 7;
const byte grnled = 3;
const byte bluLED = 5;
#endif

#ifdef due6
const byte redled = 6;
const byte grnled = 5;
const byte bluLED = 7;
#endif

#ifdef ESP8266
const byte redled = 4;
const byte grnled = 0;
const byte bluLED = 5;
#endif

const byte analogPin = 0 ;
const byte connectedPin = 1;
byte iGainFactor = 1 ;
bool bIsSine = true ;

byte nRepeats = 0;
const byte maxRepeats = 5;
//byte nWaits = 1;
//byte nMaxWaits = 1 ;
byte nWaits = 15;
byte nMaxWaits = 15 ;

byte brightness = 255 ;
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
bool bFileOK = true ;
bool has_filesystem = true ;
File file, wfile;

boolean bDoFlash = false ;
byte freq1 = 12 ; // flicker of LED Hz
byte freq2 = 15 ; // flicker of LED Hz
// as of 18 June, maxdata of 2048 is too big for the mega....
#define max_data 1025
#define presamples 102

const int data_block_size = 8 * max_data ;
volatile unsigned int time_stamp [max_data] ;
volatile int erg_in [max_data];
volatile int stimvalue [max_data + presamples] ;


volatile long mean = 0;

volatile long sampleCount = max_data + 2;        // will store number of A/D samples taken
volatile long mStart ;
int pSummary [maxRepeats * maxContrasts * 10];
unsigned long interval = 4;           // interval (5ms) at which to - 2 ms is also ok in this version
unsigned long last_time = 0;
unsigned int start_time = 0;
unsigned long timing_too_fast = 0 ;

uint8_t second, myminute, hour, day, month;
uint16_t year ;

const short MaxInputStr = 130 ;
String MyInputString = String(MaxInputStr + 1);
//String MyReferString = String(MaxInputStr + 1);

char cFile [30];
char cInput [MaxInputStr + 2] = "";
char cLastInput [MaxInputStr + 2] = "oldInput";

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

IPAddressShield myIP, theirIP, dnsIP ;
byte mac[] = { MAC_OK } ;


// Initialize the Ethernet server library
// with the IP address and port you want to use
// (port 80 is default for HTTP):
EthernetServerShield server(80);
EthernetClientShield client ;
// FIX#include <Dns.h>

#else
IPAddress myIP, theirIP, dnsIP ;
WiFiServer server (80);

#ifdef ESP8266
volatile os_timer_t myTimer;
WiFiClient client ;
#else
WiFiClient client (80);
#endif
#endif

#ifdef ESP8266
void setupESPWiFi();
void printWifiStatus();
void doShuffle();
void sendHeader (const String & sTitle, const String & sINBody = "", bool isHTML = true, char * pDate = NULL);
void sendFooter();
void sendError (const String & sError);
void send_GoBack_to_Stim_page ();

void updateColour (const bool boolUpdatePage);
void goColour(const byte r, const byte g, const byte b, const byte a, const byte w, const byte l, const byte c,  const bool boolUpdatePage);
void goColour(const byte r, const bool boolUpdatePage);
void goColour(const byte r, const byte g, const byte b, const byte f, const bool boolUpdatePage);
void serve_dir ();
void run_graph();
void printTwoDigits(char * p, uint8_t v);
void printDirectory(String s);
void webTime ();
void addSummary ();
void doplotFile ();
void doFFTFile (const char * c, bool bNeedHeadFooter);
void doreadFile (const char * c);
void doreadSummaryFile (const char * c);
void flickerPage();
void AppendFlashReport();
void AppendSSVEPReport();
void getData ();
void plotInColour (int iStart, const String & str_col);
void TC3_Handler(void *pArg);
void tidyUp_Collection() ;
void sendGraphic(bool plot_stimulus);
void sendGraphic();
void sendReply ();
//void go4Colour(const byte r, const byte g, const byte b, const byte a, const byte w, const byte l, const byte c,  const bool boolUpdatePage);
//void go4Colour(const byte r, const byte g, const byte b, const byte a, const byte w, const byte l, const byte c,  const bool boolUpdatePage);
//void go4Colour(const byte r, const byte g, const byte b, const byte a, const byte w, const byte l, const byte c,  const bool boolUpdatePage);
void loop();
void do_fft();
int br_Now(double t);
int Get_br_Now(double t, const double F1contrast, const double F2contrast);
int fERG_Now (unsigned int t);
int DayOfWeek (int d, int m, int y);

bool writeFile(char * c);
bool fileExists( char * c);

bool collect_Data ();
void AppendWaitReport ();
double sgn (double x);

void analogReadResolution(int i)
{
  // do nothing
}

uint myReadADC (int i)
{
  // see http://www.esp8266.com/viewtopic.php?f=28&t=3223&start=36 comemnt by bernd331
  // see also http://41j.com/blog/2015/01/esp8266-analogue-input/
  return system_adc_read();
}
#else
// not an ESP
int myReadADC (int i)
{
  return analogRead (i);
}
#endif


void setup() {

  // ...
  pinMode(SS_SD_CARD, OUTPUT);
  pinMode(SS_ETHERNET, OUTPUT);

  pinMode(noContactLED, OUTPUT);
  pinMode( redled, OUTPUT);
  pinMode( grnled, OUTPUT);
  pinMode( bluLED, OUTPUT);

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
  myGraphData = (int *)erg_in ;
  for (short i = 0; i < max_graph_data; i++)
  {
    myGraphData[i] = 0;
  }

#ifdef ESP8266
  // initialise Flash disk
  Serial.println ("Now trying flash drive card ...\n");
  if (SPIFFS.begin())
  {
    Serial.println ("Setting up flash drive  succeded OK...\n");
  }
  else
  {
    Serial.println ("Setting up flash drive failed...\n");
    if (SPIFFS.format()) // we may only need to use this once ??
    {
      Serial.println ("Formatting flash drive ok...\n");
    }
    else
    {
      Serial.println ("Formatting flash drive failed...\n");
      has_filesystem = false ;
    }
  }
#define SD SPIFFS
#define MyDir Dir
#define FILE_READ "r"
#define FILE_WRITE "a"

  if (has_filesystem)
  {
    FSInfo fs_info;
    SPIFFS.info(fs_info);
    Serial.print ("Disk size ");
    Serial.println (fs_info.totalBytes);
    Serial.print ("used Bytes " );
    Serial.println( fs_info.usedBytes);
    size_t fBytes = fs_info.totalBytes - fs_info.usedBytes ;
    Serial.print ("Free Bytes " );
    Serial.println( fBytes);
    if (fBytes < 41500)
    {
      // for now reformat the disk if there is no space !
      // fix this - ask before formatting
      SPIFFS.format();
      Serial.println( "disk reformatted" );
    }
  }

#else
  // initialize the SD card
  Serial.println ("Setting up SD card...\n");

  if (SD.begin(4))
  {
    Serial.println ("SD card ok\n");
  }
  else
  {
    Serial.println ("SD card failed\n");
    has_filesystem = false ;
  }
#define MyDir File
#define openDir open
#endif


#ifdef __wifisetup__

#ifdef ESP8266AP
  setupESPWiFi();                            // start the web server on port 80
#else
  //char ssid[] = "SSID";     //  your network SSID (name)
  //char pass[] = "PASSWD";  // your network password
#include "./secret.h"

  int status = WL_IDLE_STATUS;
  while ( status != WL_CONNECTED)
  {
    Serial.print ("Attempting to connect to Network named: ");
    Serial.println(ssid);                   // print the network name (SSID);

    // Connect to WPA/WPA2 network. Change this line if using open or WEP network:
    status = WiFi.begin(ssid, pass);
    // wait 10 seconds for connection:
    delay(10000); // 2 s seems enough
    myIP = WiFi.localIP();
  }
#endif
  Serial.print ("Connected ...");
  printWifiStatus();                        // you're connected now, so print out the status

  server.begin();                           // start the web server on port 80

#else
  digitalWrite(SS_ETHERNET, LOW); // HIGH means Ethernet not active
  Serial.println ("Setting up the Ethernet card...\n");
  // start the Ethernet connection and the server:
#ifdef USE_DHCP
  if (! EthernetShield.begin(mac))
  {
    Serial.println ("DHCP failed, trying 172, 16, 1, 10");
#endif

    // Setup for eg an ethernet cable from Macbook to Arduino Ethernet shield
    // other macbooks or mac airs may assign differnt local networks
    //
    Serial.println ("Please set your mac ethernet to Manually and '172.16.1.1'");
    byte ip[] = { 172, 16, 1, 10 };
    EthernetShield.begin(mac, ip);
    bNoInternet = true ;
#ifdef USE_DHCP
  };
#endif
  server.begin();
  Serial.print ("server is at ");
  myIP = EthernetShield.localIP() ;
  dnsIP = EthernetShield.dnsServerIP();
  Serial.println(myIP);
  Serial.print(" using dns server ");
  Serial.println(dnsIP);

#endif

  analogReadResolution(12);
  iGainFactor = 4 ;
#ifdef ARDUINO_LINUX
  pinMode( redled, OUTPUT);
  pinMode( grnled, OUTPUT);
  pinMode( bluLED, OUTPUT);
#endif

  goColour(0, 0, 0, 0, false);

  doShuffle();
#ifdef ESP8266
  // only call this once
  os_timer_setfn((ETSTimer *) &myTimer, TC3_Handler, NULL);
#endif
}



#ifdef __wifisetup__

#ifdef ESP8266
const char WiFiAPPSK[] = "sparkfun";

void setupESPWiFi()
{
  WiFi.mode(WIFI_AP);

  // Do a little work to get a unique-ish name. Append the
  // last two bytes of the MAC (HEX'd) to "ThingDev-":
  uint8_t mac[WL_MAC_ADDR_LENGTH];
  WiFi.softAPmacAddress(mac);
  String macID = String(mac[WL_MAC_ADDR_LENGTH - 2], HEX) +
                 String(mac[WL_MAC_ADDR_LENGTH - 1], HEX);
  macID.toUpperCase();
  String AP_NameString = "ThingDev-" + macID;

  char AP_NameChar[AP_NameString.length() + 1];
  memset(AP_NameChar, 0, AP_NameString.length() + 1);

  for (int i = 0; i < AP_NameString.length(); i++)
    AP_NameChar[i] = AP_NameString.charAt(i);
  Serial.print("Setting up access point 8266");
  Serial.println (AP_NameString);
  WiFi.softAP(AP_NameChar, WiFiAPPSK);
  myIP = WiFi.softAPIP() ;
  Serial.print("ESP accesspoint :");
  Serial.print (myIP) ;
}
#endif

void printWifiStatus() {
  // print the SSID of the network you're attached to:
  Serial.print ("SSID: ");
  Serial.println(WiFi.SSID());

  // print your WiFi shield's IP address:

  Serial.print ("IP Address: ");
  Serial.println(myIP);

  // print the received signal strength:
  long rssi = WiFi.RSSI();
  Serial.print ("signal strength (RSSI):");
  Serial.print (rssi);
  Serial.println (" dBm");
  // print where to go in a browser:
  Serial.print ("To see this page in action, open a browser to http://");
  Serial.println (myIP);
}

#endif


void doShuffle()
{
  for (int i = 0; i < maxContrasts; i++)
  {
    contrastOrder[i] = i ;
  }
  ///Knuth-Fisher-Yates shuffle algorithm.
  randomSeed(myReadADC(analogPin));
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




#ifdef ESP8266
void sendHeader (const String & sTitle, const String & sINBody , bool isHTML , char * pDate)
#else
void sendHeader (const String & sTitle, const String & sINBody = "", bool isHTML = true, char * pDate = NULL)
#endif
{
  // send a standard http response header
  client.println ("HTTP/1.1 200 OK");
  if (isHTML)
  {
    client.println ("Content-Type: text/html");
  }
  else
  {
    client.println ("Content-Type: text/plain");
  }
  //  if (pDate) Serial.print (pDate);
  //  else Serial.print("boo");
  if (pDate)
  {
    client.print ("Last-Modified: ");
    client.println (pDate);
  }
  client.println ("Connection: close");  // the connection will be closed after completion of the response
  client.println();
  if (isHTML)
  {
    client.println ("<!DOCTYPE HTML><html><title>");
    client.println (sTitle);
    client.println ("</title><body ");
    client.println (sINBody);
    client.println (">");
  }
}

void sendFooter()
{
  client.println ("</body></html>");
}

void sendError (const String & sError)
{
  sendHeader (String("Arduino System Error"));
  client.print ("Error in system, Please check for update <BR>");
  client.println (sError) ;
  sendFooter();
}
void send_GoBack_to_Stim_page ()
{
  client.println ("<A HREF=\"") ;
  //  if (MyReferString != String("131"))
  //  {
  //
  //    //    client.println (" <script>");
  //    //    client.println ("function goBack() ");
  //    //    client.println ("{ window.history.back() }");
  //    //    client.println ("</script>");
  //
  //    client.println (MyReferString) ;
  //    client.println ("\"" );
  //  }
  //  //    Serial.print("My reference is :");
  //  //    Serial.println (MyReferString) ;
  //  else
  //  {
  // i think this migth work everywhere with firefox > 31 - seems to work in Safari too
  client.print ("javascript:void(0)\" onclick=\"history.back(); ") ;
  //  }
  client.println ("\">the stimulus selection form</A>  <BR>");
}

void updateColour (const bool boolUpdatePage)
{
  if (boolUpdatePage)
  {
    sendHeader ("Lit up ?", "onload=\"goBack()\" ");
    client.println ("Click to reload");
    send_GoBack_to_Stim_page ();

    sendFooter();
  }
}

void goColour(const byte r, const byte g, const byte b, const byte a, const byte w, const byte l, const byte c,  const bool boolUpdatePage)
{
  //Serial.println("colouring 1");
#ifdef ESP8266
  //0/1023 with high values giving least light
  analogWrite( redled, 1023 - 4 * r );
  analogWrite( grnled, 1023 - 4 * g );
  analogWrite( bluLED, 1023 - 4 * b );
#else
  analogWrite( redled, r );
  analogWrite( grnled, g );
  analogWrite( bluLED, b );
#endif

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
    digitalWrite (i, w);
  }

  //Serial.println("colouring 3");
}

void goColour(const byte r, const bool boolUpdatePage)
{
  goColour (r, r, r, 0, r, 0, 0, boolUpdatePage); // should this be all of them ?

}

void goColour(const byte r, const byte g, const byte b, const byte f, const bool boolUpdatePage)
{
  goColour (r, g, b, f, 0, 0, 0, boolUpdatePage);
}

void serve_dir (String s)
{
  sendHeader("Directory listing");
  printDirectory (s);
  sendFooter();
}

void run_graph()
{
  // turn off any LEDs, always do flash with blue
  goColour(255, false);
  // reset the wait count
  nWaits = nMaxWaits;

  // read the value of  analog input pin and turn light on if in mid-stimulus...
  short sensorReading = myReadADC(connectedPin);
  //  Serial.print(" dc is : ");
  //  Serial.print(sensorReading);
  //// seems to be about 50

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

  //  int sensorReadinga = myReadADC(analogPin);
  //  Serial.print(" ac is : ");
  //  Serial.println(sensorReadinga);

  myGraphData[iIndex] = sensorReading * 5 ;
  iIndex ++ ;
  //  if (iIndex > max_graph_data / 10 && iIndex < max_graph_data / 2)
  //  {
  //    analogWrite(bluLED, 255);
  //  }
  //  else
  //  {
  //    analogWrite(bluLED, 0);
  //  }

  sendHeader ("Graph of last sweep", "onload=\"init()\"") ;
  client.println ("<script>");

  // script to reload ...
  client.println ("var myVar = setInterval(function(){myTimer()}, 1000);"); //mu sec
  client.println ("function myTimer() {");
  client.println ("location.reload(true);");
  client.println ("};");

  client.println ("function myStopFunction() {");
  client.println ("clearInterval(myVar); }");
  client.println ("");
  client.println ("</script>");
  // now do the graph...
  client.println ("<canvas id=\"myCanvas\" width=\"640\" height=\"520\" style=\"border:1px solid #d3d3d3;\">");
  client.println ("Your browser does not support the HTML5 canvas tag.</canvas>");

  client.println ("<script>");
  client.println ("var can;");
  client.println ("var ctx;");
  client.println ("var i = 20; ");

  client.println ("function l(v){");
  client.println ("ctx.lineTo(i,v);");
  client.println ("i = i + 20;");
  client.println ("};");
  client.println ("function m(v){");
  client.println ("ctx.moveTo(i,v);");
  client.println ("i = i + 20;");
  client.println ("};");

  client.println ("function init() {");
  client.println (" can = document.getElementById(\"myCanvas\");");
  client.println (" ctx = can.getContext(\"2d\");");

  if (iIndex >= max_graph_data) iIndex = 0;
  for (int i = 0; i < max_graph_data - 2; i++)
  {
    if (i < iIndex - 1 || i > iIndex + 1)
    {
      client.print ("l(");
      client.print(myGraphData[i + 1] );
      client.print (");");
    }
    else
    {
      client.print ("m(");
      client.print (myGraphData[i] );
      client.print (");");
    }
  }
  client.print ("ctx.strokeStyle=\"blue\";");
  client.println ("ctx.stroke();");

  //  //draw stimulus...
  //  client.print ("ctx.moveTo(");
  //  client.print ((max_graph_data / 10) * 20);
  //  client.print (",30);");
  //
  //  client.print ("ctx.lineTo(");
  //  client.print (max_graph_data / 2 * 20);
  //  client.print (",30);");
  //
  //  client.println ("ctx.strokeStyle=\"blue\";");
  //  //              client.println("ctx.lineWidth=5;");
  //  client.println ("ctx.stroke();");
  client.println ("}");

  client.println ("</script>");
  client.println ("<BR><BR><button onclick=\"myStopFunction()\">Stop display</button>");

  client.println ("To run a test please stop and then load ") ;

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
//void myPrintFatDateTime(const dir_t & pFile)
//{
//  // write this as a string to erg_in
//  char * pErg_in = (char * ) erg_in ;
//  erg_in [0] = 0;
//
//  strcat_P(pErg_in, PSTR("  "));
//  itoa( FAT_YEAR(pFile.lastWriteDate), pErg_in + 1, 10);
//  strcat_P(pErg_in, PSTR("-"));
//  printTwoDigits(pErg_in + strlen(pErg_in) , FAT_MONTH(pFile.lastWriteDate));
//  strcat_P(pErg_in, PSTR("-"));
//  printTwoDigits(pErg_in + strlen(pErg_in) , FAT_DAY(pFile.lastWriteDate));
//  strcat_P(pErg_in, PSTR(" "));
//  printTwoDigits(pErg_in + strlen(pErg_in) , FAT_HOUR(pFile.lastWriteTime));
//  strcat_P(pErg_in, PSTR(":"));
//  printTwoDigits(pErg_in + strlen(pErg_in) , FAT_MINUTE(pFile.lastWriteTime));
//  strcat_P(pErg_in, PSTR(":"));
//  printTwoDigits(pErg_in + strlen(pErg_in) , FAT_SECOND(pFile.lastWriteTime));
//  strcat_P(pErg_in, PSTR(" "));
//  client.print(pErg_in);
//}


void printDirectory(String s)
{
  String s2 = s + String("/");
  int iLength = s.length();
  char cTmp  [iLength + 2];
  s.toCharArray(cTmp, iLength);
  //Serial.println ("Now reading directry:" + s2 + String("!!"));
  MyDir dir = SD.openDir(cTmp) ;
  // if (!dir) return ; FIX

  char sArray [512 * 15];
  long lArray [512] ;
#ifdef ESP8266
  bool bNext ;

  //dir.rewindDirectory();
  int iFiles = 0 ;
  bNext =  dir.next();
  while (bNext)
  {
    //    if (!entry.isDirectory())
    //    {
    File entry = dir.openFile("r");
    Serial.println(entry.name());
    strncpy (sArray + (iFiles * 15) , entry.name(), sizeof (entry)) ;
    lArray [iFiles] = entry.size();
    //Serial.println((char*)sArray + (iFiles * 15));
    iFiles ++ ;
    //    }
    entry.close();
    bNext =  dir.next();
  }
#else
  File entry ;
  dir.rewindDirectory();
  int iFiles = 0 ;
  entry =  dir.openNextFile();
  while (entry)
  {
    if (!entry.isDirectory() && entry.name() [0] != '~')
    {
      //Serial.println(entry.name());
      strncpy (sArray + (iFiles * 15) , entry.name(), sizeof (entry)) ;
      lArray [iFiles] = entry.size();
      //Serial.println((char*)sArray + (iFiles * 15));
      iFiles ++ ;
    }
    entry.close();
    entry =  dir.openNextFile();
  }
#endif

  client.print (iFiles);
  client.print (" files found on disk  ");
  iFiles -- ; // allow for last increment...

  client.println ();
  client.println ("<ul>");
  while (iFiles >= 0)
  {
    client.print ("<li><a href=\"");
    client.print ((char*)sArray + (iFiles * 15));
    client.print ("\">");
    client.print ((char*)sArray + (iFiles * 15));
    client.print ("</a> ");
    client.print ("   ");
    client.print (lArray [iFiles]);

    // if its an SVP allow us to have alink to the picture...
    if ('P' == * (sArray + (iFiles * 15) + 11 ))
    {
      * (sArray + (iFiles * 15) + 11) = 'V';
      client.print ("      <a href=\"");
      client.print ((char*)sArray + (iFiles * 15));
      client.print ("\">");
      client.print ("(fft (30,30))");
      client.print ("</a> ");
    }

    // if its an ERG allow us to have alink to the picture...
    if ('G' == * (sArray + (iFiles * 15) + 11 ))
    {
      * (sArray + (iFiles * 15) + 11) = 'P';
      client.print ("      <a href=\"");
      client.print ((char*)sArray + (iFiles * 15));
      client.print ("\">");
      client.print ((char*)sArray + (iFiles * 15));
      client.print ("</a> ");
    }


    client.println ("</li>");
    iFiles -- ;
  }



  //  client.println ();
  //  client.println ("<ul>");
  //
  //  Serial.println("dir done, s is :" + s);
  //
  //
  //  s = String("/") + s + String("/") ;
  //  s.replace ("//", "/");
  //  s.replace ("//", "/");
  //  Serial.println("string replace done, s is :" + s);
  //
  //  for (int iff = iFiles; iff--; iff >= 0)
  //  {
  //    // now print them out in reverse order
  //
  //    char * p_name = pAll[iff].c;
  //    Serial.println(p_name);
  //
  //    // print any indent spaces
  //    client.print ("<li><a href=\"");
  //    if (s.length() > 1) client.print (s);
  //    client.print ("/");
  //    client.print(p_name);
  //    client.print ("\">");
  //    client.print(p_name);
  //    client.print ("</a> ");
  //
  //
  //    /////////////////////////////// now put in a link for a picture
  //    if (strlen (p_name) == 12)
  //    {
  //      if (char(p_name[11]) == 'G')
  //      {
  //        // print any indent spaces
  //        client.print (" <a href=\"");
  //        if (s.length() > 1) client.print (s);
  //        for (uint8_t i = 0; i < 11; i++)
  //        {
  //          client.print(char(p_name[i]));
  //        }
  //        client.print ("P\"> (picture)</a>");
  //        ///////////////////////////////
  //      }
  //      if (char(p_name[11]) == 'P')
  //      {
  //        // print any indent spaces
  //        client.print (" <a href=\"");
  //        if (s.length() > 1) client.print (s);
  //        client.print ("/");
  //        for (uint8_t i = 0; i < 11; i++)
  //        {
  //          client.print(char(p_name[i]));
  //        }
  //        client.print ("V\"> (fft (30,30))</a>");
  //        ///////////////////////////////
  //      }
  //    }
  //
  //    ////////////////////////////////////////
  //
  //    if (pAll[iff].i == 0)
  //    {
  //      client.print('/');
  //    }
  //    else
  //      // print size
  //    {
  //      //myPrintFatDateTime(p); FIX
  //      client.print (" size: ");
  //      client.print(pAll[iff].i);
  //
  //    }
  //    client.println ("</li>");
  //  }
  client.println ("</ul>");



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
  if (t < (max_data) / 3) return 0;
  if (t > (2 * max_data) / 3) return 0;
  return brightness;
}

void webTime ()
{
#ifdef __wifisetup__
  WiFiClient timeclient;
#else
  EthernetClientShield timeclient;
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
    timeclient.print(("GET / HTTP/1.1 \r\n\r\n"));
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


bool file_time (char * cIn)
{
  year = 2016;
  second = myminute = hour = day = month = 1;
  Serial.print("Doing filetime with:");
  Serial.println(cIn);
  //GET /?GAL4=JoB&UAS=w&Age=-1&Antn=Ok&sex=male&org=fly&col=blue&F1=12&F2=15&stim=fERG&filename=2016_31_01_15h02m25 HTTP/1.1

  const int calcTimemax = 21;
  char calcTime [calcTimemax] ; //= "0000000000000" ;
  for (int i = 0; i < calcTimemax ; i++)
  {
    calcTime[i] = 0;
  }

  char * fPOS = strstr (cIn, "filename=");
  if (!fPOS)
  {
    sendError (("No filename= in request to serve page"));
    return false;
  }
  //char * gPOS = strstr (fPOS, "HTTP/1.1"); - if we have too long a URL, we lose the end...
  char * gPOS = strstr (fPOS, "HTT");
  if (!gPOS)
  {
    sendError (("No HHTP in request to serve page"));
    return false;
  }
  *gPOS = 0;


  Serial.print ("fpos is " );
  Serial.println (fPOS);
  Serial.flush();
  fPOS = fPOS + 9;
  Serial.print ("fpos is now" );
  Serial.println (fPOS);
  Serial.flush();

  if (strlen(fPOS) < 20)
  {
    sendError ("Wrong length of date in request to serve page");
    return false;
  }

  strcpy (calcTime, fPOS);

  Serial.print ("time is:");
  for (int i = 0; i < calcTimemax - 1; i++)
  {
    Serial.print( calcTime[i] );
    Serial.flush();
  }
  Serial.println();
  // 2016_31_01_15h02m25
  year = atoi(calcTime);
  month = atoi(calcTime + 5);
  day = atoi(calcTime + 8);
  hour = atoi(calcTime + 11);
  myminute = atoi(calcTime + 14);
  second = atoi(calcTime + 17) ;
  Serial.print ("year is (if zero, atoi error):");
  Serial.println (year) ;
  return (year != 0) ;
}

void addSummary ()
{
  //  Serial.print ("summarising  C:R ");
  //  Serial.print (iThisContrast);
  //  Serial.print (":");
  //  Serial.println (nRepeats);
  int iOffset = 0;
  int kk = 0 ;
  if (bDoFlash)
  {
    iOffset = (nRepeats - 1) * 14 ;
    // "start,10,20,30,40,50,60,70,80,90%,max1,min1,max2,min2");

    pSummary[iOffset + kk] = erg_in[1] ;
    //    Serial.println(pSummary[iOffset + kk]);


    for (int ii = max_data / 10; ii < max_data - 1; ii = ii + max_data / 10)
    {
      pSummary [iOffset + kk] = erg_in[ii] ;
      kk ++ ;
    }
    int myminsofar = erg_in[0];
    int mymaxsofar = erg_in[0];
    for (int ii = 1; ii < (max_data - 1) / 2; ii++)
    {
      if (erg_in[ii] < myminsofar) myminsofar = erg_in[ii] ;
      if (erg_in[ii] > mymaxsofar) mymaxsofar = erg_in[ii] ;
    }
    pSummary [iOffset + kk] = mymaxsofar ;
    kk ++ ;
    pSummary [iOffset + kk] = myminsofar ;
    kk ++;
    myminsofar = erg_in[(max_data - 1) / 2];
    mymaxsofar = erg_in[(max_data - 1) / 2];
    for (int ii = (max_data - 1) / 2; ii < max_data - 1; ii++)
    {
      if (erg_in[ii] < myminsofar) myminsofar = erg_in[ii] ;
      if (erg_in[ii] > mymaxsofar) mymaxsofar = erg_in[ii] ;
    }
    pSummary [iOffset + kk] = mymaxsofar ;
    kk ++ ;
    pSummary [iOffset + kk] = myminsofar ;
    kk ++;
  }
  else
  {
    // fft
    iOffset = ((nRepeats * maxContrasts) + iThisContrast ) * 10 - 10;
    //    Serial.print("Offset ");
    //    Serial.println( iOffset );

    pSummary[iOffset + kk] = time_stamp[max_data - 1] ;
    kk ++ ;
    pSummary[iOffset + kk] = erg_in[max_data - 1] ;
    kk ++ ;
    pSummary[iOffset + kk] = nRepeats ;
    kk ++ ;

    // save erg as we do an in place FFT
    int erg_tmp [ max_data];
    for (int iERG = 0; iERG < max_data; iERG++) erg_tmp[iERG] = erg_in[iERG];
    do_fft() ;

    // F2-F1
    pSummary[iOffset + kk] = erg_in[12] ;
    kk ++ ;
    pSummary[iOffset + kk] = erg_in[49] ;
    kk ++ ;
    pSummary[iOffset + kk] = erg_in[61] ;
    kk ++ ;
    pSummary[iOffset + kk] = erg_in[98] ;
    kk ++ ;
    pSummary[iOffset + kk] = erg_in[111] ;
    kk ++ ;
    pSummary[iOffset + kk] = erg_in[221] ;
    kk ++ ;
    pSummary[iOffset + kk] = erg_in[205] ; // 50Hz

    // restore erg
    for (int iERG = 0; iERG < max_data; iERG++) erg_in[iERG] = erg_tmp[iERG];
  }

  //  for (int ii = 0; ii < 14; ii ++ )
  //  {
  //    Serial.print (pSummary[ii]);
  //    Serial.print (",");
  //  }
  //  Serial.println();
}

bool writeSummaryFile(const char * cMain)
{
  int iCharMaxHere = 100 ;
  char c [iCharMaxHere]; // will hold filename
  char cTmp [iCharMaxHere]; // to hold text to write
  char * pDot = strchr ((char *)cMain, '.');

  Serial.print ("Summarising filename ");
  Serial.println (cMain);
  Serial.flush();
  if (!pDot)
  {
    Serial.print ("Error in filename");
    Serial.println (c);
    Serial.flush();
    return false ;
  }
  Serial.print ("filename extension:");
  Serial.println (pDot);
  Serial.flush();
  int iBytes = pDot - cMain ;

  Serial.print ("length of string:");
  Serial.println (iBytes);
  Serial.flush();

  strncpy (c, cMain , iBytes);
  c[iBytes] = 0;
  strcat (c, ".CSV");

  Serial.print ("now writing summary: ");
  Serial.println (c);
  Serial.flush();

  int16_t iBytesWritten ;

  if (fileExists(c))
  {
    Serial.println ("Error in opening file");
    Serial.println (c);
    Serial.flush();
    return false; // FIX - send error to usrrs
  }
  file = SD.open(c, FILE_WRITE);
  if ( !file )
  {
    Serial.println ("Error in opening file");
    Serial.println (c);
    Serial.flush();
    return false;
  }
  //
  //    getRealTime();
  //
  //    if (!file.timestamp(T_CREATE | T_ACCESS | T_WRITE, year, month, day, hour, myminute, second)) {
  //      Serial.println F("Error in timestamping file");
  //      Serial.println (c);
  //      Serial.flush();
  //      file.close();
  //      return false ;
  //    }
  iBytesWritten = file.write((uint8_t *)cInput, MaxInputStr + 2);
  if (iBytesWritten <= 0)
  {
    Serial.println ("Error in writing header to file");
    file.close();
    return false ;
  }
  if (bDoFlash)
  {
    strcpy (cTmp, "start,10,20,30,40,50,60,70,80,90%,max1,min1,max2,min2\n");
  }
  else
  {
    strcpy (cTmp, "probe contrast, mask, repeat, F2-F1, 1F1, 2F1, 2F2, 1F1+1F2, 2F1+2F2, 50 Hz\n");
  }
  iBytesWritten = file.write((uint8_t *)cTmp, strlen(cTmp)) ;
  if (iBytesWritten <= 0)
  {
    Serial.println ("Error in writing header to file");
    file.close();
    return false ;
  }

  // for nor bFlash
  int iOfssfet  = 10;
  int mm = maxRepeats * maxContrasts ;
  if (bDoFlash)
  {
    iOfssfet = 14;
    mm = maxRepeats ;
  }

  for ( int ii = 0; ii < mm ; ii++)
  {
    for (int jj = 0; jj < iOfssfet; jj++)
    {
      iBytesWritten = iBytesWritten + file.print (pSummary[ii * iOfssfet + jj]);
      iBytesWritten = iBytesWritten + file.print (", ");
    }
    iBytesWritten = iBytesWritten + file.print ("\n");
  }

  if (iBytesWritten <= 0)
  {
    Serial.println ("Error in writing erg data to file");
    file.close();
    return false;
  }

  // Serial.println F("File success: written bytes " + String(iBytesWritten));

  Serial.print (" More bytes writen to file.........");
  Serial.print  (c);
  Serial.print F(" size now ");
  Serial.println (file.size());
  file.close();
  return true ;
}



bool writeFile(char * c)
{
  // file format
  //    MyInputString viz. char cInput [MaxInputStr+2];
  //    int contrastOrder[ maxContrasts ];
  //    unsigned int time_stamp [max_data] ;
  //    int erg_in [max_data];

  int16_t iBytesWritten ;
  year = 2014 ;
  // Fix the time ?
  //  webTime ();
  //  if (year == 2014)
  //  {
  //    file__time();
  //  }

  if (!SD.exists(c))
  {
    wfile = SD.open( c /*myName*/,  FILE_WRITE) ;
    if ( !wfile)
    {
      Serial.println F ("Error in opening file");
      Serial.println (c);
      Serial.flush();
      return false;
    }

    //    if (!file.timestamp(T_CREATE | T_ACCESS | T_WRITE, year, month, day, hour, myminute, second)) { FIX
    //      Serial.println F ("Error in timestamping file");
    //      Serial.println (c);
    //      Serial.flush();
    //      return false ;
    //    }
    iBytesWritten = wfile.write((uint8_t *)cInput, MaxInputStr + 2);
    if (iBytesWritten <= 0)
    {
      Serial.println F ("Error in writing header to file");
      wfile.close();
      return false ;
    }

  }
  else // file exists, so just append...
  {
    //  file = SD.open( c /*myName*/,  FILE_WRITE /*O_APPEND | O_WRITE*/) ; // on the Due we have to keep the file open...
    if ( !wfile )
    {
      Serial.println F ("Error in reopening file");
      Serial.println (c);
      return false;
    }
#ifndef ESP8266
    //FIXED - append - go to end of file
    unsigned long l = wfile.size() ;
    if (wfile.seek(l))
    {
      Serial.println F ("File length :");
      Serial.println (l);
    }
    else
    {
      Serial.println F ("Error in seeking on file");
      Serial.println (c);

    }
#endif
  }


  // always write the erg and time data, and on last line contrast data
  char * cData = (char *) erg_in ;
  iBytesWritten = wfile.write((uint8_t *) cData, (size_t)(max_data * sizeof (int)));
  if (iBytesWritten <= 0)
  {
    Serial.println F ("Error in writing erg data to file");
    wfile.close();
    return false;
  }

  // Serial.println("File success: written bytes " + String(iBytesWritten));
  cData = (char *) time_stamp;
  iBytesWritten = wfile.write((uint8_t *)cData, max_data * sizeof (unsigned int));
  if (iBytesWritten <= 0)
  {
    Serial.println F ("Error in writing timing data to file");
    return false ;
  }
  Serial.print (" More bytes writen to file.........");
  Serial.print  (c);
  Serial.print (" size now ");
  Serial.println (wfile.size());
  wfile.flush();
  return true ;
}

bool fileExists( char * c)
{
  return SD.exists(c);
}

// find day of week http://stackoverflow.com/questions/6054016/c-program-to-find-day-of-week-given-date
int DayOfWeek (int d, int m, int y)
{
  return (d += m < 3 ? y-- : y - 2, 23 * m / 9 + d + 4 + y / 4 - y / 100 + y / 400) % 7   ;
}

////
//void gmdate ( const dir_t & pFile)
//{
//  // Last-Modified: Tue, 15 Nov 1994 12:45:26 GMT
//  const char * cDays PROGMEM = "Sun,Mon,Tue,Wed,Thu,Fri,Sat,Sun";
//  const char * cMonths PROGMEM = "Jan,Feb,Mar,Apr,May,Jun,Jul,Aug,Sep,Oct,Nov,Dec,";
//  char * c  = (char *) erg_in ;
//  erg_in [0] = 0;
//  int iTmp ;
//  int d = FAT_DAY(pFile.lastWriteDate) ;
//  int m = FAT_MONTH(pFile.lastWriteDate) ;
//  int y = FAT_YEAR(pFile.lastWriteDate) ;
//
//  iTmp = DayOfWeek (d, m, y) ;
//  if (iTmp > 6) iTmp = 0;
//  strncpy(c, cDays + iTmp * 4, 3); // tue
//  c[3] = 0;
//  strcat_P(c, PSTR(", "));
//  //Serial.println (c);
//
//  printTwoDigits(c + strlen(c) , FAT_DAY(pFile.lastWriteDate));
//  strcat_P (c, PSTR(" "));
//
//  int iLen = strlen(c);
//  iTmp = m - 1;
//  if (iTmp > 11) iTmp = 0;
//  strncpy(c + iLen, cMonths + iTmp * 4, 3); //nov
//  c[iLen + 3] = 0;
//  //Serial.println (c);
//
//  strcat_P (c, PSTR(" "));
//  itoa( y, c + strlen(c), 10);
//  strcat_P (c, PSTR(" "));
//  printTwoDigits(c + strlen(c) , FAT_HOUR(pFile.lastWriteTime));
//  strcat_P (c, PSTR(":"));
//  printTwoDigits(c + strlen(c) , FAT_MINUTE(pFile.lastWriteTime));
//  strcat_P (c, PSTR(":"));
//  printTwoDigits(c + strlen(c) , FAT_SECOND(pFile.lastWriteTime));
//  strcat_P (c, PSTR(" GMT"));
//
//  //Serial.println( c );
//}


void doplotFile ()
{

  String Sc ; //= (c);
  Sc = String (("Plotting ")) + Sc ;
  sendHeader ("plotting", "onload=\"init()\"") ;
  //based on doReadFile...

  //String dataString ;
  unsigned char * cPtr;
  cPtr = (unsigned char *) erg_in ;

  Serial.print ("trying to open:");
  Serial.println (cFile);
  if (file) file.close();
  file = SD.open( cFile, FILE_READ);
  if (!file)
  {
    client.println ("Error opening file ");
    client.println(cFile);
    sendFooter();
    return ;
  }

  int iBytesRequested, iBytesRead;
  // note this overwrites any data already in memeory...
  //first read the header string ...
  iBytesRequested = MaxInputStr + 2;
  iBytesRead = file.read(cPtr, iBytesRequested);
  if (iBytesRead < iBytesRequested)
  {
    client.println ("Error reading header data in file ");
    client.println(cFile);
    sendFooter();
    return ;
  }

  // write out the string ....
  client.println((char *)cPtr);
  client.println("<BR>");
  // test if its an ERG
  //boolean bERG = ( NULL != strstr ( cPtr, "stim=fERG&") ) ;
  client.print("Download file <a HREF=\"");
  client.print(cFile);
  client.print("\">");
  client.print(cFile);
  client.println("</a><BR>");

  // now on to the data
  int nBlocks = 0;

  // make this static otherwise the ESP overflows the tiny little stack
  static int erg_in2 [max_data] ;

  for (int i = 0; i < max_data; i++)
  {
    erg_in[i] = 0;
    time_stamp[i] = 0;
  }

  iBytesRequested = max_data * sizeof (int);
  iBytesRead = file.read((unsigned char *)erg_in2, iBytesRequested);


  while (iBytesRead == iBytesRequested)
  {
    iBytesRequested = max_data * sizeof (unsigned int);
    iBytesRead = file.read ((unsigned char *)time_stamp, iBytesRequested );
    nBlocks ++;

    for (int i = 0; i < max_data; i++)
    {
      erg_in[i] = erg_in[i] + erg_in2[i];
    }

    //read next block
    iBytesRequested = max_data * sizeof (int);
    iBytesRead = file.read((unsigned char *)erg_in2, iBytesRequested);

  } // end of while

  file.close();

  for (int i = 0; i < max_data; i++)
  {
    erg_in[i] = erg_in [i] / nBlocks;
  }
  sendGraphic ();
  sendFooter();

}

void doFFTFile (const char * c, bool bNeedHeadFooter)
{
  String Sc = (c);
  Sc = String (("FFT of ")) + Sc ;

  //String dataString ;
  unsigned char * cPtr;
  cPtr = (unsigned char *) erg_in ;
  int iOldContrast ;
  static int erg_in2 [max_data] ;
  memset (erg_in2, 0, sizeof (int) * max_data);

  Serial.print ("trying to open:");
  Serial.println (c);
  if (file) file.close();
  file = SD.open( c, FILE_READ);

  if (bNeedHeadFooter) sendHeader(Sc, "onload=\"init()\"", true /*, cPtr*/ ); //FIX - get date out of file header

  int iBytesRequested, iBytesRead;
  // note this overwrites any data already in memeory...
  //first read the header string ...
  iBytesRequested = MaxInputStr + 2;
  iBytesRead = file.read(cPtr, iBytesRequested);
  if (iBytesRead < iBytesRequested)
  {
    client.println ("Error reading header data in file ");
    client.println(c);
    return ;
  }

  // write out the string ....
  client.print((char *)cPtr);
  client.println("<BR>");

  // now on to the data
  iBytesRequested = max_data * sizeof (int);
  iBytesRead = file.read((unsigned char *)erg_in, iBytesRequested);

  int nBlocks = 0;
  while (iBytesRead == iBytesRequested)
  {
    iBytesRequested = max_data * sizeof (unsigned int);
    iBytesRead = file.read ((unsigned char *)time_stamp, iBytesRequested );
    nBlocks ++;
    // stop when mask and probe are both 30%
    Serial.print("time ");
    Serial.print(time_stamp[max_data - 1]);
    Serial.print(" erg ");
    Serial.println(erg_in[max_data - 1]);
    if ( time_stamp[max_data - 1] == 30 && erg_in[max_data - 1] == 30 )
    {
      Serial.print ("about to do FFT ");
      int m = millis();
      do_fft();
      // add to the average
      for (int ii = 0; ii < max_data; ii++)
      {
        erg_in2[ii] = erg_in2[ii] + erg_in[ii];
      }
      Serial.print (erg_in[48]);
      Serial.print (" done FFT in");
      Serial.print(millis() - m);
      Serial.println (" milliseconds");
    }

    //read next block
    iBytesRequested = max_data * sizeof (int);
    iBytesRead = file.read((unsigned char *)erg_in, iBytesRequested);

  } // end of while

  file.close();
  for (int ii = 0; ii < max_data; ii++)
  {
    erg_in[ii] = erg_in2[ii] / maxRepeats;
  }
  Serial.print (erg_in[48]);
  // now plot data in erg_in
  sendGraphic(false);
  Serial.println (" plotted FFT");
  if (bNeedHeadFooter) sendFooter ();

}

void sendLastModified(char * cPtr, char * c, bool bIsHTML)
{
  //  // Content-Length: 1000000 [size in bytes FIX
  //  // Last-Modified: Sat, 28 Nov 2009 03:50:37 GMT
  if (file_time (cPtr))
  {
    //  const char * cDays PROGMEM = "Sun,Mon,Tue,Wed,Thu,Fri,Sat,Sun";
    //  const char * cMonths PROGMEM = "Jan,Feb,Mar,Apr,May,Jun,Jul,Aug,Sep,Oct,Nov,Dec,";
    char dateString [31] ;
    memset (dateString, 0, 31);

    int iTmp = DayOfWeek (day, month, year) ;
    if (iTmp > 6) iTmp = 0;
    strncpy(dateString, cDays + iTmp * 4, 3); // tue
    strcat(dateString, ", ");

    iTmp = strlen (dateString);
    printTwoDigits (dateString + iTmp, day);
    strcat (dateString, " ");

    int iLen = strlen(dateString);
    iTmp = month - 1;
    if (iTmp > 11) iTmp = 0;
    strncpy(dateString + iLen, cMonths + iTmp * 4, 3); //nov
    dateString[iLen + 3] = 0;

    iTmp = strlen (dateString);
    sprintf (dateString + iTmp, " %d ", year);

    iTmp = strlen (dateString);
    printTwoDigits (dateString + iTmp, hour);
    strcat (dateString, ":");

    iTmp = strlen (dateString);
    printTwoDigits (dateString + iTmp, myminute);
    strcat (dateString, ":");

    iTmp = strlen (dateString);
    printTwoDigits (dateString + iTmp, second);
    strcat (dateString, " GMT");

    Serial.print("Last modified Date is");
    Serial.println (dateString);

    sendHeader(String(c), "", bIsHTML , dateString );
  }
  else
  {
    Serial.println("Last modified date is unknown");
    sendHeader(String(c), "", bIsHTML );
  }
}

void doreadFile ( char * c)
{
  //String dataString ;
  unsigned char * cPtr;
  cPtr = (unsigned char *) erg_in ;
  int iOldContrast ;

  //Serial.print ("trying to open:");
  //Serial.println (c);
  //if (file.isOpen()) file.close(); FIX
  file = SD.open( c, FILE_READ);

  int iBytesRequested, iBytesRead;
  // note this overwrites any data already in memeory...
  //first read the header string ...
  iBytesRequested = MaxInputStr + 2;
  iBytesRead = file.read(cPtr, iBytesRequested);
  if (iBytesRead < iBytesRequested)
  {
    client.println ("Error reading header data in file ");
    client.println(c);
    return ;
  }

  sendLastModified((char *)cPtr, c, false);

  // write out the string ....
  client.print((char *)cPtr);
  client.println();
  // test if its an ERG
  boolean bERG = ( NULL != strstr ( (char *) cPtr, "stim=fERG&") ) ;
  bIsSine = ( NULL == strstr ((char *) cPtr, "stm=SQ") ) ;

  // now on to the data
  iBytesRequested = max_data * sizeof (int);
  iBytesRead = file.read((unsigned char *)erg_in, iBytesRequested);

  int nBlocks = 0;
  while (iBytesRead == iBytesRequested)
  {
    iBytesRequested = max_data * sizeof (unsigned int);
    iBytesRead = file.read ((unsigned char *)time_stamp, iBytesRequested );
    nBlocks ++;

    for (int i = 0; i < max_data - 1; i++)
    {
      // make a string for assembling the data to log:
      client.print(time_stamp[i]);
      client.print ( ", ");
      if (bERG)
      {
        client.print( fERG_Now (time_stamp[i] - time_stamp[0] ) );
      }
      else
      {
        client.print(Get_br_Now(time_stamp[i],  time_stamp [max_data - 1], erg_in [max_data - 1]));
      }
      client.print (", ");

      client.print(erg_in[i]);
      client.println();
    } //for

    // write out contrast

    client.print ( "-99, " );

    client.print(time_stamp[max_data - 1]);
    client.print ( ", " );

    client.print(erg_in[max_data - 1]);
    client.println();

    //read next block
    iBytesRequested = max_data * sizeof (int);
    iBytesRead = file.read((unsigned char *)erg_in, iBytesRequested);

  } // end of while

  file.close();

}


void doreadSummaryFile (const char * c)
{
  //String dataString ;
  unsigned char * cPtr = NULL;
  cPtr = (unsigned char *) erg_in ;

  Serial.print F("trying to open summary file:");
  Serial.println (c);
  if (file) file.close();
  file = SD.open( c, FILE_READ);

  int iBytesRequested, iBytesRead;
  // note this overwrites any data already in memeory...
  //first read the header string ...
  iBytesRequested = MaxInputStr + 2;
  iBytesRead = file.read(cPtr, iBytesRequested);
  if (iBytesRead < iBytesRequested)
  {
    client.println F("Error reading header data in file ");
    client.println(c);
    file.close();
    return ;
  }
  sendLastModified((char *)cPtr, (char *) c, true); // make this HTML so we can display it...
  // write out the string ....
  client.print((char *)cPtr);
  client.println("<BR>");

  // inefficiently read the file a byte at a time, and send it to the client
  // replace \n with <BR>
  memset (cPtr, 0, 20 );
  bool b = file.read(cPtr, 1);
  while (b)
  {
    if (*cPtr == '\n')
    {
      client.println("<BR>");
    }
    else
    {
      client.print ((char *)cPtr);
    }
    b = file.read(cPtr, 1);
  }


  file.close();
  sendFooter();
}

#ifdef ESP8266
void startTimer (uint32_t frequency)
{
  //os_timer_setfn((ETSTimer *) &myTimer, TC3_Handler, NULL);
  os_timer_arm((ETSTimer *) &myTimer, 1000 / frequency, true); // 1000/frequency
}


void stopTimer()
{
  os_timer_disarm((ETSTimer *) &myTimer);
}
#else


// due

//////////// based on http://forum.arduino.cc/index.php?topic=130423.0

//void startTimer ()
//{
//  startTimer(TC1, 0, TC3_IRQn, 500); // fixed 0.5 kHz
//}

void startTimer (uint32_t frequency)
{
  startTimer(TC1, 0, TC3_IRQn, frequency); // fixed 0.5 kHz
}

void startTimer(Tc *tc, uint32_t channel, IRQn_Type irq, uint32_t frequency) {
  pmc_set_writeprotect(false);
  pmc_enable_periph_clk((uint32_t)irq);
  TC_Configure(tc, channel, TC_CMR_WAVE | TC_CMR_WAVSEL_UP_RC | TC_CMR_TCCLKS_TIMER_CLOCK4);
  uint32_t rc = VARIANT_MCK / 128 / frequency; //128 because we selected TIMER_CLOCK4 above
  TC_SetRA(tc, channel, rc / 2); //50% high, 50% low
  TC_SetRC(tc, channel, rc);
  TC_Start(tc, channel);
  tc->TC_CHANNEL[channel].TC_IER = TC_IER_CPCS;
  tc->TC_CHANNEL[channel].TC_IDR = ~TC_IER_CPCS;
  NVIC_EnableIRQ(irq);
}

void stopTimer()
{
  stopTimer(TC1, 0, TC3_IRQn);
}

void stopTimer(Tc *tc, uint32_t channel, IRQn_Type irq)
{
  TC_Stop(tc, channel);
  NVIC_DisableIRQ(irq);
}
#endif


#ifdef ESP8266
void TC3_Handler(void * pArg)
{
#else
void TC3_Handler()
{
  // acknowledge interrupt
  TC_GetStatus(TC1, 0);
#endif

  if (sampleCount >= max_data - 1)
  {
    stopTimer();
    Serial.println("Timer done");
    tidyUp_Collection();
    return ;
  }

  if (sampleCount == 0)
  {
    mean = mean / presamples ;
  }
  if (sampleCount >= 0)
  {
    // read  sensor
    erg_in[sampleCount] = myReadADC(analogPin) - mean ;
  }
  else
  {
    mean = mean + long(myReadADC(analogPin));
  }
  int intensity = stimvalue [sampleCount + presamples] ;
  analogWrite(usedLED, intensity);
  sampleCount ++ ;

  if (sampleCount >= max_data - 1)
  {
    stopTimer();
    Serial.println("Timer done");
    tidyUp_Collection();
    return ;
  }

}

void StartTo_collect_Data ()
{
  mStart = millis();
  sampleCount = -presamples ;
  if (bDoFlash)
  {
    iThisContrast = maxContrasts;
    nRepeats ++;
    for (int i = 0; i < max_data + presamples; i++)
    {
      stimvalue[i] = fERG_Now (i - presamples);
    }
    startTimer(500);
  }
  else
  {
    // SSVEP
    for (int i = 0; i < max_data + presamples; i++)
    {
      stimvalue[i] = br_Now (i * 4);
    }
    startTimer(250);
  }
  //  while (sampleCount < max_data)
  //  {
  //    Serial.print (sampleCount);
  //    Serial.print (" ");
  //    Serial.println (stimvalue[sampleCount + presamples]);
  //    delay(500) ;
  //  }
}



void tidyUp_Collection()
{
  sampleCount ++ ;
  if (bDoFlash)
  {
    analogWrite(usedLED, 0);
    iThisContrast = maxContrasts ; //++;
    for (int i = 0; i < max_data; i++)
    {
      time_stamp[i] = i * 2 ; // fixed 2 ms per sample
    }
  }
  else
  {
    // SSVEP
    // now done with sampling....
    for (int i = 0; i < max_data; i++)
    {
      time_stamp[i] = i * 4 ; // fixed 4 ms per sample
    }
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
  }
  bool bResult = writeFile(cFile);
  if (bResult)
  {
    addSummary() ;
  }
  else
  {
    Serial.print("File not written :");
    Serial.println(cFile);
  }
  long mEnd = millis();
  Serial.print("took AD ");
  Serial.println (mEnd - mStart); // fERG: with timer driven this was exactly 2253 ms ( should be ~2248 )

}


void flickerPage()
{
  //  Serial.print ("Sampling at :");
  //  Serial.println (String(sampleCount));

  sendHeader ("Sampling", "onload=\"init()\"") ;

  // script to reload ...
  client.println ("<script>");
  client.println ("var myVar = setInterval(function(){myTimer()}, 8500);"); //mu sec
  client.println ("function myTimer() {");
  client.println ("location.reload(true);");
  client.println ("};");

  client.println ("function myStopFunction() {");
  client.println ("var b = confirm(\"Really Stop Data Acqusition ?\"); \n if ( b == true )  ");
  client.print ("{ \n clearInterval(myVar); ");
  client.print ("\n history.back();");
  client.print (" } }");
  client.println ("");
  client.println ("</script>");


  if (bDoFlash)
  {
    if (nWaits > 0)
    {
      AppendWaitReport ();
    }
    else
    {
      AppendFlashReport ();
    }
  }
  else
  {
    AppendSSVEPReport();
  }
  sendFooter ();
}

void AppendWaitReport()
{
  client.print ("waiting ") ;
  client.print ( nWaits );
  client.print (" of ");
  client.print (nMaxWaits);
  client.println (" time so far " );
  client.println ("<button onclick=\"myStopFunction()\">Stop Data Acquisition</button><BR>");
  client.println (cInput);
  client.println ( "<BR> ");
  nWaits -- ;
}

void AppendFlashReport()
{
  client.print ("Acquired ") ;
  client.print ( nRepeats );
  client.print (" of ");
  client.print (maxRepeats);
  client.println (" data blocks so far " );
  client.println ("<button onclick=\"myStopFunction()\">Stop Data Acquisition</button><BR>");
  client.println (cInput);
  client.println ( "<BR> ");


  if (nRepeats > 0)
  {
    sendGraphic();
  }
}

void AppendSSVEPReport()
{
  client.print ("Acquired ") ;
  int iTmp = nRepeats * maxContrasts ; //- maxContrasts ;
  Serial.print ("Acquired ");
  Serial.print (iTmp);
  iTmp = iTmp + iThisContrast ;
  Serial.print (" really ");
  Serial.println (iTmp);

  client.print (iTmp);
  client.print (" of ");
  client.print (maxRepeats * maxContrasts);
  client.println (" data blocks so far " );
  client.println ("<button onclick=\"myStopFunction()\">Stop Data Acquisition</button><BR>");
  client.println (cInput);
  client.println ( "<BR> ");


  if (iThisContrast < maxContrasts)
  {
    int randomnumber = contrastOrder[iThisContrast];
    int F2index = 0 ;
    if (randomnumber > F2contrastchange) F2index = 1;
    client.print ("Data will flicker at "); +
    client.print (freq1) ;
    client.print ( " Hz with contrast ");
    client.print (F1contrast[randomnumber] );
    client.print (" and "); +
    client.print (freq2) ;
    client.print (" Hz with contrast ") ;
    client.print ( F2contrast[F2index] );
    client.print (" % <BR> " );
    client.println ();

    client.println ("please wait....<BR>");
    if (iThisContrast > 0)
    {
      iThisContrast -- ;
      client.println ("<canvas id=\"myCanvas\" width=\"620\" height=\"450\" style=\"border:1px solid #d3d3d3;\">");
      client.println ("Your browser does not support the HTML5 canvas tag.</canvas>");

      client.println ("<script>");
      client.println ("var can;");
      client.println ("var ctx;");
      client.println ("var i = 8; ");

      client.println ("function l(v){");
      client.println ("ctx.lineTo(i,v);");
      client.println ("i = i + 8;");  // iStep ??
      client.println ("};");
      client.println ("function m(v){");
      client.println ("ctx.moveTo(0,v);");
      client.println ("i = 8;");
      client.println ("};");

      client.println ("function init() {");
      client.println (" can = document.getElementById(\"myCanvas\");");
      client.println (" ctx = can.getContext(\"2d\");");

      int iStep = 2;
      client.print ("m(");
      client.print(myGraphData[0] / 4 + 350);
      client.print (");");
      for (int i = 1; i < 5 * max_graph_data - 2; i = i + iStep)
      {
        client.print ("l(");
        client.print(myGraphData[i + iStep] / 4 + 350);
        client.println (");");
      }
      client.println ("ctx.stroke();");
      client.print ("m(");
      client.print(br_Now(time_stamp[0]) );
      client.println (");");
      for (int i = 1; i < 5 * max_graph_data - 2; i = i + iStep)
      {
        client.print ("l(");
        client.print(br_Now(time_stamp[i + iStep]));
        client.println (");");
      }
      client.println ("ctx.stroke(); }");

      client.println ("</script>");
      iThisContrast ++ ;
    }


    for (int i = iThisContrast - 1; i > -1 ; i--)
    {
      int randomnumber = contrastOrder[i];
      int F2index = 0 ;
      if (randomnumber > F2contrastchange) F2index = 1;

      client.print ("<BR>Data has been flickered at "); +
      client.print (freq1) ;
      client.print ( " Hz with contrast ");
      client.print (F1contrast[randomnumber] );
      client.print (" and "); +
      client.print (freq2) ;
      client.print (" Hz with contrast ") ;
      client.print (F2contrast[F2index] );
      client.print (" % " );
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
      if (nWaits > 0) return ;
    }
    StartTo_collect_Data ();

  }

}

void plotInColour (int iStart, const String & str_col)
{
  // 12 Hz in blue ?
  // 4 ms per point 0.25 Hz per point, so 12 Hz expected at 48
  client.println ("ctx.beginPath();");
  client.print ("ctx.moveTo(");
  client.print((iXFactor * iStart) / iXDiv );
  client.print (",");
  client.print(iBaseline - (10 * myGraphData[iStart]) / iYFactor);
  client.println (");");
  for (int i = iStart + istep; i < iStart + 5; i = i + istep)
  {
    client.print ("ctx.lineTo(");
    client.print((iXFactor * i) / iXDiv );
    client.print (",");
    client.print(iBaseline - (10 * myGraphData[i]) / iYFactor);
    client.println (");");
  }
  client.print ("ctx.strokeStyle = '");
  client.print (str_col);
  client.println ("';");
  client.println ("ctx.closePath();");
  client.print ("ctx.fillStyle='");
  client.print (str_col);
  client.println ("';");
  client.println ("ctx.fill();");
  client.println ("ctx.stroke();");
}
void sendGraphic()
{
  sendGraphic(true);
}

void sendGraphic(bool plot_stimulus)
{

  istep = 15;
  plot_limit = max_data - max_data / 6 ;
  iXFactor = 4;
  iYFactor = 50 ;
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

  client.println ("<canvas id=\"myCanvas\" width=\"640\" height=\"520\" style=\"border:1px solid #d3d3d3;\">");
  client.println ("Your browser does not support the HTML5 canvas tag.</canvas>");

  client.println ("<script>");
  client.println ("var can;");
  client.println ("var ctx;");
  client.print   ("var i = ");
  client.print   ((iXFactor * istep) / iXDiv );
  client.println ("; ");

  client.println ("function l(v){");
  client.println ("ctx.lineTo(i,v);");
  client.println ("i = i +  ");
  client.print   ((iXFactor * istep) / iXDiv );
  client.println ("; ");  // iStep ??
  client.println ("};");
  client.println ("function m(v){");
  client.println ("ctx.moveTo(0,v);");
  client.print   ("i = ");
  client.print   ((iXFactor * istep) / iXDiv );
  client.println ("; ");
  client.println ("};");

  client.println ("function init() {");
  client.println (" can = document.getElementById(\"myCanvas\");");
  client.println (" ctx = can.getContext(\"2d\");");


  // move to start of line
  client.println ("ctx.beginPath();");
  client.print ("m(");
  client.print(iBaseline - (10 * myGraphData[istep]) / iYFactor);
  client.println (");");

  //now join up the line
  for (int i = 2 * istep; i < plot_limit; i = i + istep)
  {
    client.print ("l(");
    client.print(iBaseline - (10 * myGraphData[i]) / iYFactor);
    client.println (");");
  }
  client.println ("ctx.stroke();");

  if (plot_stimulus)
  {
    client.println ("ctx.beginPath();");
    client.print ("m(");
    client.print(10 + (10 * fERG_Now(time_stamp[1] - time_stamp[0])) / iYFactor);
    client.println (");");

    for (int i = 2 * istep; i < plot_limit; i = i + istep)
    {
      client.print ("l(");
      client.print(10 + (10 * fERG_Now(time_stamp[i / 2] - time_stamp[0]) ) / iYFactor);
      client.println (");");
    }
    client.println ("ctx.stroke();");
  }
  else
  {
    plotInColour (4 * 12, String ("#0000FF"));
    plotInColour (4 * 15, String ("#0088FF"));
    plotInColour (4 * 12 * 2, String ("#8A2BE2"));
    plotInColour (4 * 27, String ("#FF8C00"));
    // 1024 rather than 1000
    plotInColour (4 * 51, String ("#FF0000"));
  }

  client.println ("} </script>");
}


void sendReply ()
{
  int exp_size = MaxInputStr + 2 ;
  Serial.println(MyInputString);
  if (!has_filesystem)
  {
    sendHeader ("Card not working");
    client.println ("SD Card failed");
    sendFooter();
    return ;
  }
  if (!bFileOK)
  {
    sendHeader ("File not written");
    client.print ("File write failed on SD Card : ");
    client.print (cFile);
    client.println ("<BR>Disk full (512 files?) <BR>File already exists?<BR>To setup for another test please ");

    send_GoBack_to_Stim_page ();
    sendFooter();

    bFileOK = true ;
    return ;
  }

  int fPOS = MyInputString.indexOf ("filename=");
  // asking for new sample
  if (fPOS > 0)
  {
    bool bNewCommand = false ;

    // save the commandline....
    MyInputString.toCharArray(cInput, MaxInputStr + 2);
    if (0 != strcmp(cLastInput, cInput))
    {
      bNewCommand = true ;
      strcpy (cLastInput, cInput);
      memset (pSummary, 0, maxRepeats * maxContrasts * 10 * sizeof (int));
    }
    strncpy(cLastInput, cInput, MaxInputStr);
    char * cP = strstr(cInput, "HTTP/");
    if (cP) cP = '\0';
    // now choose the colour
    int oldLED = usedLED ;
    if (MyInputString.indexOf ("col=blue&") > 0 ) usedLED  = bluLED ; //
    if (MyInputString.indexOf ("col=green&") > 0 ) usedLED  = grnled ; //
    if (MyInputString.indexOf ("col=red&") > 0 ) usedLED  = redled ; //
    if (MyInputString.indexOf ("col=fiber") > 0 ) usedLED  = fiberLED ; //
    //due4 is special
    if (MyInputString.indexOf ("col=amber&") > 0 ) usedLED  = amberled ; //
    if (MyInputString.indexOf ("col=cyan&") > 0 ) usedLED  = cyaled ; //
    if (MyInputString.indexOf ("col=bvio&") > 0 ) usedLED  = bluvioletLED ; //

    //flash ERG or SSVEP?
    bDoFlash = MyInputString.indexOf ("stim=fERG") > 0  ;
    bIsSine = MyInputString.indexOf ("_SQ&") < 0  ; // -1 if not found

    int ibrPos  = MyInputString.indexOf ("bri=") + 4;
    brightness = atoi(cInput + ibrPos);

    // find filename
    String sFile = MyInputString.substring(fPOS + 9); // ignore the leading / should be 9
    // first check for overlong URLs
    if (sFile.indexOf("HTT") < 1)
    {
      sendHeader ("Request too long");
      client.print ("URL is too long : ");
      client.print (MyInputString);

      send_GoBack_to_Stim_page ();
      sendFooter();
      return ;
    }
    //Serial.println("  Position of filename= was:" + String(fPOS));
    //Serial.println(" Proposed saving filename " + sFile );
    fPOS = sFile.indexOf (" ");  // or  & id filename is not the last paramtere
    //Serial.println("  Position of blankwas:" + String(fPOS));
    sFile = sFile.substring(0, fPOS);
    while (sFile.length() > 8)
    {
      sFile = sFile.substring(1);
      //Serial.println(" Proposed saving filename " + sFile );
    }
    if (bDoFlash)
    {
      sFile = sFile + (".ERG");
      exp_size = exp_size + (maxRepeats * data_block_size) ;
    }
    else
    {
      sFile = sFile + (".SVP");
      exp_size = exp_size + (maxRepeats * maxContrasts * data_block_size) ;
    }

    //Serial.println(" Proposed filename now" + sFile + ";");

    sFile.toCharArray(cFile, 29); // adds terminating null

    if (bNewCommand)
    {
      //if file exists... ????
      if (fileExists(cFile))
      {
        sendHeader ("File exists");
        client.print ("File already exists on disk ( ");
        client.print (cFile);
        client.print (" ) <BR> Click here to go back to the ");

        send_GoBack_to_Stim_page ();
        sendFooter();
        return ;
      }
      // new file
      nRepeats = iThisContrast = 0 ;
      //turn off any lights we have on...
      goColour(0, false);
    }
    //Serial.print("repeats now ");
    //Serial.println(nRepeats);
#ifdef ESP8266
    if (nRepeats >= maxRepeats)
#else
    if (wfile && wfile.size() >= exp_size ) //nRepeats >= maxRepeats)
#endif
    {
      // done so tidy up
      Serial.println("done and tidy up time");
      //turn off any lights we have on...
      nRepeats = iThisContrast = 0 ; // ready to start again
      nWaits = nMaxWaits ;
      //file.timestamp(T_ACCESS, 2009, 11, 12, 7, 8, 9) ;
      sendHeader ("Sampling Complete!", "onload=\"init()\"") ;
      client.print( "Sampling Now Complete <BR><BR>");
      client.print( "<A HREF= \"" + sFile + "\" >" + sFile + "</A>" + " size: ");
      client.print(wfile.size());
      client.print(" bytes; expected size ");
      client.print(exp_size);
      wfile.close() ;
      writeSummaryFile(cFile);
      if (bDoFlash)
      {
        String sPicture = sFile;
        sPicture.replace ("ERG", "ERP" );
        client.print("<A HREF= \"" + sPicture + "\" > (averaged picture) </A>" );
      }
      client.println("<BR><BR>");
      client.println ("To setup for another test please ") ;
      send_GoBack_to_Stim_page ();
      client.println ("<BR><A HREF= \"dir=\"  > Full directory</A> <BR><BR>");
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
  fPOS = MyInputString.indexOf ("dir=");
  Serial.println("  Position of dir was:" + String(fPOS));
  if (fPOS > 0)
  {
    serve_dir("/") ;
    return ;
  }

  //light up
  fPOS = MyInputString.indexOf ("white/");
  if (fPOS > 0)
  {
    goColour(255, true) ;
    return ;
  }

  fPOS = MyInputString.indexOf ("amber/");
  if (fPOS > 0)
  {
    //void go4Colour(const byte r, const byte g, const byte b, const byte a, const byte w, const byte l, const byte c,  const bool boolUpdatePage)
    goColour(0, 0, 0, 255, 0, 0, 0, true) ;
    return ;
  }
  fPOS = MyInputString.indexOf ("cyan/");
  if (fPOS > 0)
  {
    //void go4Colour(const byte r, const byte g, const byte b, const byte a, const byte w, const byte l, const byte c,  const bool boolUpdatePage)
    goColour(0, 0, 0, 0, 0, 0, 255, true) ;
    return ;
  }
  fPOS = MyInputString.indexOf ("blueviolet/");
  if (fPOS > 0)
  {
    //void go4Colour(const byte r, const byte g, const byte b, const byte a, const byte w, const byte l, const byte c,  const bool boolUpdatePage)
    goColour(0, 0, 0, 0, 0, 255, 0, true) ;
    return ;
  }

  fPOS = MyInputString.indexOf ("red/");
  if (fPOS > 0)
  {
    goColour(255, 0, 0, 0, true) ;
    return ;
  }
  fPOS = MyInputString.indexOf ("blue/");
  if (fPOS > 0)
  {
    goColour(0, 0, 255, 0, true) ;

    return ;
  }
  fPOS = MyInputString.indexOf ("green/");
  if (fPOS > 0)
  {
    goColour(0, 255, 0, 0, true) ;
    return ;
  }
  fPOS = MyInputString.indexOf ("black/");
  if (fPOS > 0)
  {
    //    Serial.println ("off");
    goColour(0, true) ;
    return ;
  }
  fPOS = MyInputString.indexOf ("fiber/");
  if (fPOS > 0)
  {
    goColour(0, 0, 0, 255, true) ;
    return ;
  }

  // a file is requested...
  fPOS = MyInputString.indexOf (".SVP");
  if (fPOS == -1)
  {
    fPOS = MyInputString.indexOf (".SVV");
  }
  if (fPOS == -1)
  {
    fPOS = MyInputString.indexOf (".ERG");
  }
  if (fPOS == -1)
  {
    fPOS = MyInputString.indexOf (".ERP");
  }
  if (fPOS == -1)
  {
    fPOS = MyInputString.indexOf (".CSV");
  }
  if (fPOS == -1)
  {
    fPOS = MyInputString.indexOf ("/");
  }
  //Serial.println("  Position of .SVP was:" + String(fPOS));
  if (fPOS > 0)
  {

#ifdef ESP8266
    delay(1);
#endif

    // requested a file...
    fPOS = MyInputString.indexOf ("/");
    String sFile = MyInputString.substring(fPOS + 1); // ignore the leading /
    Serial.println(" Proposed filename " + sFile );
    fPOS = sFile.indexOf (" HTTP/");
    sFile = sFile.substring(0, fPOS);
    Serial.println(" Proposed filename now" + sFile + ";");

    if (MyInputString.indexOf (".ERP") > 0)
    {
      sFile.replace((".ERP"), (".ERG"));
      sFile.toCharArray(cFile, 29); // adds terminating null
      Serial.print (sFile);
      doplotFile() ;
      return ;
    }
    if (MyInputString.indexOf (".SVV") > 0)
    {
      sFile.replace((".SVV"), (".SVP"));
      sFile.toCharArray(cFile, 29); // adds terminating null
      doFFTFile(cFile, true) ;
      return;
    }
    if ((MyInputString.indexOf (".csv") > 0) || (MyInputString.indexOf (".CSV") > 0))
    {
      Serial.println("csv found");
      sFile.toCharArray(cFile, 29); // adds terminating null
      doreadSummaryFile(cFile) ;
      return ;
    }
    if ((MyInputString.indexOf (".ERG") > 0) || (MyInputString.indexOf (".SVP") > 0))
    {
      sFile.toCharArray(cFile, 29); // adds terminating null
      doreadFile(cFile) ;
      return;

    }
    // robots.txt
    if (MyInputString.indexOf ("robots.txt") > 0)
    {
      client.println("welcome to robots!");
      return ;
    }
    //
    //    // otherwise we'll assume its a directory...
    //    sFile = sFile + ("/");
    //    serve_dir(sFile);
    //    return ;
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
  // delay till we are sure data acq is done ??
  // SSVEP ERG is 250 Hz so 4 ms per sample...
  delay(max_data + presamples * 10);
#ifdef ESP8266
  delay(1);
#endif
  boolean currentLineIsBlank = true;
  // listen for incoming clients

  client = server.available();
  if (client) {
    Serial.println ("new client");
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
          if (sTmp.indexOf ("GET") >= 0)
          {
            MyInputString = sTmp;
          }
          int iTmp = sTmp.indexOf ("Referer:") ;
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

static int         f_r[FFT_SIZE]   = { 0};
static   int         f_i[FFT_SIZE]   = { 0};
static   int         out[FFT_SIZE / 2]     = { 0};     // Magnitudes

  Radix4     radix;
  for ( uint16_t i = 0, k = (NWAVE / FFT_SIZE); i < FFT_SIZE; i++ )
  {
    f_r[i] = erg_in[i];
  }
  memset( f_i, 0, sizeof (f_i));                   // Image -zero.
  radix.rev_bin( f_r, FFT_SIZE);
  radix.fft_radix4_I( f_r, f_i, LOG2_FFT);
  radix.gain_Reset( f_r, LOG2_FFT - 1);
  radix.gain_Reset( f_i, LOG2_FFT - 1);
  radix.get_Magnit( f_r, f_i, (int *) erg_in);

}

