
//try this http://gammon.com.au/forum/?id=11488&reply=5#reply5 for interrupts
//Digital pin 7 is used as a handshake pin between the WiFi shield and the Arduino, and should not be used
// http://www.arduino.cc/playground/Code/AvailableMemory

// Serial.println F("Free heap:");
// Serial.println (ESP.getFreeHeap(),DEC);

// don't use pin 4 or 10-12 either...

// if we test file, it will return true if the file is open...
// file append is not honoured, need to seek end...

// This version of the code uses a domain name wadelab.github.io/flyCode/collectData/fly_arduino/sitran/ not a hard-coded IP address.



#define USE_DHCP

// define the due in an external file so we don't keep fighting with git, like this:

#include "./due.h"

// Classroom allocation 2020

#ifdef due11
#define MAC_OK 0xA8, 0x61, 0x0A, 0xAE, 0x0B, 0xD0
//biolpc3462
#endif


#ifdef due12
#define MAC_OK 0xA8, 0x61, 0x0A, 0xAE, 0x05, 0xC1
//biolpc3463
#endif


#ifdef due13
#define MAC_OK 0xA8, 0x61, 0x0A, 0xAE, 0x0B, 0xD6
//biolpc3464
#endif


#ifdef due14
#define MAC_OK 0xA8, 0x61, 0x0A, 0xAE, 0x05, 0x99
//biolpc3465
#endif


#ifdef due15
#define MAC_OK 0xA8, 0x61, 0x0A, 0xAE, 0x05, 0x0F
//biolpc3466
#endif


#ifdef due16
#define MAC_OK 0xA8, 0x61, 0x0A, 0xAE, 0x5E, 0xDF
//biolpc3467 - Sheffield Rig 3 - Last target! 23/10/24
#endif


#ifdef due17
#define MAC_OK 0xA8, 0x61, 0x0A, 0xAE, 0x5E, 0xFD
//biolpc3468 This is the one in Sheffield that has an IP address. 143.167.150.56
#endif


#ifdef due18
#define MAC_OK 0xA8, 0x61, 0x0A, 0xAE, 0x4B, 0x55
//biolpc3469
#endif


#ifdef due19
#define MAC_OK 0xA8, 0x61, 0x0A, 0xAE, 0x5E, 0xE6
//biolpc3470
#endif


#ifdef due20
#define MAC_OK 0xA8, 0x61, 0x0A, 0xAE, 0x5E, 0xE0
//biolpc3471
#endif


#ifdef due21
#define MAC_OK 0xA8, 0x61, 0x0A, 0xAE, 0x5E, 0xA1
//biolpc3472
#endif


#ifdef due22
#define MAC_OK 0xA8, 0x61, 0x0A, 0xAE, 0x5D, 0x36
//biolpc3473. This is the one in Sheffield ARW took down on 19/10/22023 IP : 143.167.151.4
#endif


#ifdef due23
#define MAC_OK 0x90, 0xA2, 0xDA, 0x0F, 0x4C, 0x02
//biolpc3474
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
//90-A2-DA-0F-6F-9E biolpc2898 [used in testing...]
#endif

#ifdef due3
#define MAC_OK 0x90, 0xA2, 0xDA, 0x0F, 0x75, 0x17
// biolpc2899 144.32.87.178
#endif

#ifdef due4
#define MAC_OK 0x90, 0xA2, 0xDA, 0x0E, 0x09, 0xA3
//90-A2-DA-0E-09-A3 biolpc2939 144.32.86.171
#endif

#ifdef due5
#define MAC_OK 0x90, 0xA2, 0xDA, 0x0F, 0x42, 0x02
//biolpc2804 //144.32.86.146
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
#define SS_SD_CARD 4
#define SS_ETHERNET 10
// is 10 on normal uno

#include <SPI.h>



#include <Ethernet.h>
#include <SD.h>

//#include "mydata.h"
// include fft
#include <Radix4.h>
//#include <FixFFT.h>


const char *cDays = "Sun,Mon,Tue,Wed,Thu,Fri,Sat,Sun";
const char *cMonths = "Jan,Feb,Mar,Apr,May,Jun,Jul,Aug,Sep,Oct,Nov,Dec,";
const short max_graph_data = 32;
int *myGraphData;  // will share erg_in space, see below
short iIndex = 0;

//
volatile byte usedLED = 0;
const byte fiberLED = 8;
const byte noContactLED = 2;

// define LED mapping here
const byte bluLED = 11;
const byte extrawhitepin = 53;
const byte whiteled = 13;


volatile byte analogPin = 0;
const byte connectedPin = 1;
byte iGainFactor = 1;
bool bIsSine = true;
bool bTestFlash = true;

byte nRepeats = 0;
const byte maxRepeats = 5;
//byte nWaits = 1;
byte nMaxWaits = 1;
byte nWaits = 15;
//byte nMaxWaits = 15 ;

#define maxbrightness 255
byte brightness = maxbrightness;

const byte maxContrasts = 9;
const int maxsummaryentries = 16;
int pSummary[maxRepeats * maxContrasts * maxsummaryentries];
const byte F2contrastchange = 4;
const byte F1contrast[] = {
  5, 10, 30, 70, 100, 5, 10, 30, 70
};
const byte F2contrast[] = {
  0, 30
};
byte contrastOrder[maxContrasts];
byte iThisContrast = 0;

#define maxDirSize 513
bool bNoInternet = false;
bool bFileOK = true;
bool has_filesystem = true;
File file, wfile;


byte freq1 = 12;  // flicker of LED Hz
byte freq2 = 15;  // flicker of LED Hz
// as of 18 June, maxdata of 2048 is too big for the mega....
#define max_data 1025
#define presamples 102

#define data_block_size 8 * max_data
volatile unsigned int time_stamp[max_data + presamples];
volatile int erg_in[max_data];
int f_i[FFT_SIZE];
volatile int *stimvalue = (int *)time_stamp;  // save memory by sharing time_stamp...


volatile long mean = 0;

volatile long sampleCount = 0;  //max_data + 2;        // will store number of A/D samples taken
volatile long mStart;
unsigned long interval = 4;  // interval (5ms) at which to - 2 ms is also ok in this version
unsigned long last_time = 0;
unsigned int start_time = 0;
unsigned long timing_too_fast = 0;

uint8_t second, myminute, hour, day, month;
uint16_t year;

const short MaxInputStr = 130;
String MyInputString = String(MaxInputStr + 1);
//String MyReferString = String(MaxInputStr + 1);

char cFile[30];
char cInput[MaxInputStr + 2] = "";
unsigned int iLastCRC = 0;

// for graphic plotting
int istep = 15;
int plot_limit = max_data - max_data / 6;
int iXFactor = 4;
int iYFactor = 25;
int iBaseline = 260;
int iXDiv = 6;

#ifndef MAC_OK
#error please define which arduino you are setting up
#endif


IPAddress myIP, theirIP, dnsIP;
byte mac[] = { MAC_OK };


// Initialize the Ethernet server library
// with the IP address and port you want to use
// (port 80 is default for HTTP):
EthernetServer server(80);
EthernetClient client;
// FIX#include <Dns.h>

int myReadADC(int i) {
  return analogRead(i);
}

typedef enum StimTypes { flash,
                         SSVEP };  //, zap};
StimTypes eDoFlash = flash;

/////////////////////////// prototypes for dues
bool fileExists(char *c);
void sendGraphic(StimTypes plot_stimulus);
int light_NOW(int i, StimTypes bErg);
int GetStimType(unsigned char *c);


///////////////////////////////////////////////////////////

void setup() {


  pinMode(noContactLED, OUTPUT);
  pinMode(bluLED, OUTPUT);
  pinMode(whiteled, OUTPUT);
  // ...
  pinMode(SS_SD_CARD, OUTPUT);
  pinMode(SS_ETHERNET, OUTPUT);

  digitalWrite(SS_SD_CARD, HIGH);   // HIGH means SD Card not active
  digitalWrite(SS_ETHERNET, HIGH);  // HIGH means Ethernet not active

  for (int i = extrawhitepin; i > extrawhitepin - 7; i = i - 2) {
    pinMode(i, OUTPUT);
  }


  // Open serial communications and wait for port to open:
  Serial.begin(115200);
  while (!Serial) {
    ;  // wait for serial port to connect. Needed for Leonardo only
  }
  myGraphData = (int *)erg_in;
  for (short i = 0; i < max_graph_data; i++) {
    myGraphData[i] = 0;
  }

  ////////////////////////////////// Setup Disk first

  // initialize the SD card
  Serial.println F("Setting up SD card...\n");

  if (SD.begin(4)) {
    Serial.println F("SD card ok\n");
  } else {
    Serial.println F("SD card failed\n");
    has_filesystem = false;
  }
#define MyDir File
#define openDir open

  /////////////////////////// Now setup network...................
  setupEthernet();

  //  //////////////////////////////////////// basic settings for all

  analogReadResolution(12);
  iGainFactor = 4;
  goColour(0, 0, 0, 0, false);
  doShuffle();
}


void setupEthernet() {
  digitalWrite(SS_ETHERNET, LOW);  // HIGH means Ethernet not active
  Serial.println F("Setting up the Ethernet card...\n");
  // start the Ethernet connection and the server:
  for (int i = 0; i < 6; i++) {
    Serial.print(mac[i], HEX);
    Serial.print(" ");
  }
  Serial.println();
#ifdef USE_DHCP
  if (!Ethernet.begin(mac)) {
    Serial.println F("DHCP failed, trying 172, 16, 1, 10");
#endif

    // Setup for eg an ethernet cable from Macbook to Arduino Ethernet shield
    // other macbooks or mac airs may assign differnt local networks
    //
    Serial.println F("Please set your mac ethernet to Manually and '172.16.1.1'");
    byte ip[] = { 172, 16, 1, 10 };
    Ethernet.begin(mac, ip);
    bNoInternet = true;
#ifdef USE_DHCP
  };
#endif
  server.begin();
  Serial.print F("server is at ");
  myIP = Ethernet.localIP();
  dnsIP = Ethernet.dnsServerIP();
  Serial.print(myIP);
  Serial.print F(" using dns server ");
  Serial.println(dnsIP);
}

void doShuffle() {
  for (int i = 0; i < maxContrasts; i++) {
    contrastOrder[i] = i;
  }
  ///Knuth-Fisher-Yates shuffle algorithm.
  randomSeed(myReadADC(analogPin));
  int randomnumber = random(maxContrasts);
  int tmp;

  for (int i = maxContrasts - 1; i > 0; i--) {
    int n = random(i + 1);
    //Swap(contrastOrder[i], contrastOrder[n]);
    tmp = contrastOrder[n];
    contrastOrder[n] = contrastOrder[i];
    contrastOrder[i] = tmp;
  }
}

// ----------------------------- crc32b --------------------------------

// http://www.hackersdelight.org/hdcodetxt/crc.c.txt

/* This is the basic CRC-32 calculation with some optimization but no
  table lookup. The the byte reversal is avoided by shifting the crc reg
  right instead of left and by using a reversed 32-bit word to represent
  the polynomial.
   When compiled to Cyclops with GCC, this function executes in 8 + 72n
  instructions, where n is the number of bytes in the input message. It
  should be doable in 4 + 61n instructions.
   If the inner loop is strung out (approx. 5*8 = 40 instructions),
  it would take about 6 + 46n instructions. */

unsigned int crc32b(unsigned char *message) {
  int i, j;
  unsigned int byte, crc, mask;

  i = 0;
  crc = 0xFFFFFFFF;
  while (message[i] != 0) {
    byte = message[i];  // Get next byte.
    crc = crc ^ byte;
    for (j = 7; j >= 0; j--) {  // Do eight times.
      mask = -(crc & 1);
      crc = (crc >> 1) ^ (0xEDB88320 & mask);
    }
    i = i + 1;
  }
  return ~crc;
}


void sendHeader(const String &sTitle, const String &sINBody = "", bool isHTML = true, char *pDate = NULL) {
  // send a standard http response header
  client.println F("HTTP/1.1 200 OK");
  if (isHTML) {
    client.println F("Content-Type: text/html");
  } else {
    client.println F("Content-Type: text/plain");
  }
  //  if (pDate) Serial.print (pDate);
  //  else Serial.println F("boo");
  if (pDate) {
    client.print F("Last-Modified: ");
    client.println(pDate);
  }
  client.println F("Connection: close");  // the connection will be closed after completion of the response
  client.println();
  if (isHTML) {
    client.println F("<!DOCTYPE HTML><head><html><title>");
    client.println(sTitle);
    client.println F("</title><a href=\'https://wadelab.github.io/flyCode/collectData/fly_arduino/pages/sitran/'>This is the git server</a></head><body ");
    client.println(sINBody);
    client.println F(">");
  } 
}

void sendFooter() {
  client.println F("</body></html>");
}

void sendError(const String &sError) {
  sendHeader(String("Arduino System Error"));
  client.print F("Error in system, Please check for update <BR>");
  client.println(sError);
  sendFooter();
}
void send_GoBack_to_Stim_page() {
  client.println F("<A HREF=\"");
  // i think this migth work everywhere with firefox > 31 - seems to work in Safari too
  client.print F("javascript:void(0)\" onclick=\"history.back(); ");
  client.println F("\">the stimulus selection form</A>  <BR>");
}

void updateColour(const bool boolUpdatePage) {
  if (boolUpdatePage) {
    sendHeader("Lit up ?", "onload=\"goBack()\" ");
    client.println F("Click to reload");
    send_GoBack_to_Stim_page();

    sendFooter();
  }
}

void goColour(const byte r, const byte g, const byte b, const byte a, const byte w, const byte l, const byte c, const bool boolUpdatePage) {
  //Serial.println F("colouring 1");
  analogWrite(bluLED, b);
  analogWrite(whiteled, w);

  updateColour(boolUpdatePage);

  for (int i = extrawhitepin; i > extrawhitepin - 7; i = i - 2) {
    digitalWrite(i, w);
  }

  //Serial.println F("colouring 3");
}

void goColour(const byte r, const bool boolUpdatePage) {
  //goColour (r, r, r, 0, r, 0, 0, boolUpdatePage); // should this be all of them ?
  goColour(0, 0, 0, 0, r, 0, 0, boolUpdatePage);
}

void goColour(const byte r, const byte g, const byte b, const byte f, const bool boolUpdatePage) {
  goColour(r, g, b, f, 0, 0, 0, boolUpdatePage);
}

void serve_dir(String s) {
  sendHeader("Directory listing");
  printDirectory(s);
  sendFooter();
}




void printTwoDigits(char *p, uint8_t v) {

  *p = '0' + v / 10;
  *(p + 1) = '0' + v % 10;
  *(p + 2) = 0;
}



size_t GetFreeSpace(EthernetClient *client) {
  return (size_t)-1;
}

void printDirectory(String s) {
  //String s2 = s + String("/");
  int iLength = s.length();
  char cTmp[iLength + 2];
  s.toCharArray(cTmp, iLength);
  //Serial.println F("Now reading directry:" + s2 + String("!!"));
  MyDir dir = SD.openDir(cTmp);
  // if (!dir) return ; FIX

  char sArray[maxDirSize * 15];
  long lArray[maxDirSize];

  File entry;
  dir.rewindDirectory();
  int iFiles = 0;
  entry = dir.openNextFile();
  while (entry) {
    if (!entry.isDirectory() && entry.name()[0] != '~') {
      //Serial.println (entry.name());
      strncpy(sArray + (iFiles * 15), entry.name(), sizeof(entry));
      lArray[iFiles] = entry.size();
      //Serial.println ((char*)sArray + (iFiles * 15));
      iFiles++;
    }
    entry.close();
    entry = dir.openNextFile();
  }

  GetFreeSpace(&client);

  client.print(iFiles);
  client.print F(" files found on disk  ");
  iFiles--;  // allow for last increment...

  client.println();
  client.println F("<ul>");
  while (iFiles >= 0) {
    client.print F("<li><a href=\"");
    client.print((char *)sArray + (iFiles * 15));
    client.print F("\">");
    client.print((char *)sArray + (iFiles * 15));
    client.print F("</a> ");
    client.print F("   ");
    client.print(lArray[iFiles]);

    // if its an SVP allow us to have alink to the picture...
    if ('P' == *(sArray + (iFiles * 15) + 11)) {
      *(sArray + (iFiles * 15) + 11) = 'V';
      client.print F("  <a href=\"");
      client.print((char *)sArray + (iFiles * 15));
      client.print F("\">(fft (30,30))</a> ");
    }

    // if its an ERG allow us to have alink to the picture...
    if ('G' == *(sArray + (iFiles * 15) + 11)) {
      *(sArray + (iFiles * 15) + 11) = 'P';
      client.print F("  <a href=\"");
      client.print((char *)sArray + (iFiles * 15));
      client.print F("\">");
      client.print((char *)sArray + (iFiles * 15));
      client.print F("</a> ");
    }

    client.print F("</li>\n");
    iFiles--;
  }

  client.print F("</ul>\n");
}

double sgn(double x) {
  if (x > 0) return 1;
  if (x < 0) return -1;
  return 0;
}

int br_Now(double t) {
  int randomnumber = contrastOrder[iThisContrast];
  int F2index = 0;
  if (randomnumber > F2contrastchange) F2index = 1;
  return Get_br_Now(t, F1contrast[randomnumber], F2contrast[F2index]);
}

int Get_br_Now(double t, const double F1contrast, const double F2contrast) {
  double s1 = sin((t / 1000.0) * PI * 2.0 * double(freq1));
  double s2 = sin((t / 1000.0) * PI * 2.0 * double(freq2));
  if (!bIsSine) {
    s1 = sgn(s1);
    s2 = sgn(s2);
  }
  return int(s1 * 1.270 * F1contrast + s2 * 1.270 * F2contrast + 127.0);
}


int fERG_Now(unsigned int t) {
  // 2ms per sample
  if (t < (max_data) / 3) return 0;
  if (t > (2 * max_data) / 3) return 0;
  return brightness;
}

/* int zap_Now (unsigned int t)
{
  // 2ms per sample ???
  if (t < 10) return 0;
  if (0 == (t % 100) ) return 255 ;
  return 0;
} */



//void webTime ()
//{
//  EthernetClientShield timeclient;
//  // default values ...
//  //year = 2015;
//  second = myminute = hour = day = month = 1;
//
//  // Just choose any reasonably busy web server, the load is really low
//  if (timeclient.connect ("www.york.ac.uk", 80))
//  {
//    // Make an HTTP 1.1 request which is missing a Host: header
//    // compliant servers are required to answer with an error that includes
//    // a Date: header.
//    timeclient.print (("GET / HTTP/1.1 \r\n\r\n"));
//    delay (10);
//
//    char buf[5];			// temporary buffer for characters
//    timeclient.setTimeout(8000);
//    if (timeclient.find((char *)"\r\nDate: ") // look for Date: header
//        && timeclient.readBytes(buf, 5) == 5) // discard
//    {
//      day = timeclient.parseInt();	   // day
//      timeclient.readBytes(buf, 1);	   // discard
//      timeclient.readBytes(buf, 3);	   // month
//      year = timeclient.parseInt();	   // year
//      hour = timeclient.parseInt();   // hour
//      myminute = timeclient.parseInt(); // minute
//      second = timeclient.parseInt(); // second
//
//
//      switch (buf[0])
//      {
//        case 'F': month = 2 ; break; // Feb
//        case 'S': month = 9; break; // Sep
//        case 'O': month = 10; break; // Oct
//        case 'N': month = 11; break; // Nov
//        case 'D': month = 12; break; // Dec
//        default:
//          if (buf[0] == 'J' && buf[1] == 'a')
//            month = 1;		// Jan
//          else if (buf[0] == 'A' && buf[1] == 'p')
//            month = 4;		// Apr
//          else switch (buf[2])
//            {
//              case 'r': month =  3; break; // Mar
//              case 'y': month = 5; break; // May
//              case 'n': month = 6; break; // Jun
//              case 'l': month = 7; break; // Jul
//              default: // add a default label here to avoid compiler warning
//              case 'g': month = 8; break; // Aug
//            }
//      } // months sorted
//      //month -- ; // zero based, I guess
//
//    }
//    Serial.println F("webtime:");
//    Serial.println (buf);
//  }
//  delay(10);
//  timeclient.flush();
//  timeclient.stop();
//
//  return ;
//}


bool file_time(char *cIn) {
  year = 2016;
  second = myminute = hour = day = month = 1;
  Serial.println F("Doing filetime with:");
  Serial.println(cIn);
  //GET /?GAL4=JoB&UAS=w&Age=-1&Antn=Ok&sex=male&org=fly&col=blue&F1=12&F2=15&stim=fERG&filename=2016_31_01_15h02m25 HTTP/1.1

  const int calcTimemax = 21;
  char calcTime[calcTimemax];  //= "0000000000000" ;
  for (int i = 0; i < calcTimemax; i++) {
    calcTime[i] = 0;
  }

  char *fPOS = strstr(cIn, "filename=");
  if (!fPOS) {
    sendError(("No filename= in request to serve page"));
    return false;
  }
  //char * gPOS = strstr (fPOS, "HTTP/1.1"); - if we have too long a URL, we lose the end...
  char *gPOS = strstr(fPOS, "HTT");
  if (!gPOS) {
    sendError(("No HHTP in request to serve page"));
    return false;
  }
  *gPOS = 0;


  Serial.println F("fpos is ");
  Serial.println(fPOS);
  Serial.flush();
  fPOS = fPOS + 9;
  Serial.println F("fpos is now");
  Serial.println(fPOS);
  Serial.flush();

  if (strlen(fPOS) < 20) {
    sendError("Wrong length of date in request to serve page");
    return false;
  }

  strcpy(calcTime, fPOS);

  Serial.println F("time is:");
  for (int i = 0; i < calcTimemax - 1; i++) {
    Serial.print(calcTime[i]);
    Serial.flush();
  }
  Serial.println();
  // 2016_31_01_15h02m25
  year = atoi(calcTime);
  month = atoi(calcTime + 5);
  day = atoi(calcTime + 8);
  hour = atoi(calcTime + 11);
  myminute = atoi(calcTime + 14);
  second = atoi(calcTime + 17);
  Serial.print F("year is (if zero, atoi error):");
  Serial.println(year);
  return (year != 0);
}

void do_fft();


bool writeFile(char *c) {
  // file format
  //    MyInputString viz. char cInput [MaxInputStr+2];
  //    int contrastOrder[ maxContrasts ];
  //    unsigned int time_stamp [max_data] ;
  //    int erg_in [max_data];

  int16_t iBytesWritten;
  year = 2014;
  // Fix the time ?
  //  webTime ();
  //  if (year == 2014)
  //  {
  //    file__time();
  //  }

  if (!SD.exists(c)) {
    wfile = SD.open(c /*myName*/, FILE_WRITE);
    if (!wfile) {
      Serial.println F("Error in opening file");
      Serial.println(c);
      Serial.flush();
      return false;
    }

    iBytesWritten = wfile.write((uint8_t *)cInput, MaxInputStr + 2);
    if (iBytesWritten <= 0) {
      Serial.println F("Error in writing header to file");
      wfile.close();
      return false;
    }

  } else  // file exists, so just append...
  {
    if (!wfile) {
      Serial.println F("Error in reopening file");
      Serial.println(c);
      return false;
    }
    //FIXED - append - go to end of file
    unsigned long l = wfile.size();
    if (wfile.seek(l)) {
      Serial.print F("File length :");
      Serial.println(l);
    } else {
      Serial.print F("Error in seeking on file");
      Serial.println(c);
    }
  }


  // always write the erg and time data, and on last line contrast data
  char *cData = (char *)erg_in;
  iBytesWritten = wfile.write((uint8_t *)cData, (size_t)(max_data * sizeof(int)));
  if (iBytesWritten <= 0) {
    Serial.println F("Error in writing erg data to file");
    wfile.close();
    return false;
  }

  // Serial.println F("File success: written bytes " + String(iBytesWritten));
  cData = (char *)time_stamp;
  iBytesWritten = wfile.write((uint8_t *)cData, max_data * sizeof(unsigned int));
  if (iBytesWritten <= 0) {
    Serial.println F("Error in writing timing data to file");
    return false;
  }
  Serial.print F(" More bytes writen to file.........");
  Serial.print(c);
  Serial.print F(" size now ");
  Serial.println(wfile.size());
  wfile.flush();
  return true;
}

bool fileExists(char *c) {
  return SD.exists(c);
}

// find day of week http://stackoverflow.com/questions/6054016/c-program-to-find-day-of-week-given-date
int DayOfWeek(int d, int m, int y) {
  return (d += m < 3 ? y-- : y - 2, 23 * m / 9 + d + 4 + y / 4 - y / 100 + y / 400) % 7;
}



void doplotFile() {

  String Sc;  //= (c);
  Sc = String(("Plotting ")) + Sc;
  sendHeader("plotting", "onload=\"init()\"");
  //based on doReadFile...

  //String dataString ;
  unsigned char *cPtr;
  cPtr = (unsigned char *)erg_in;

  Serial.print F("trying to plot:");
  Serial.println(cFile);
  if (file) file.close();
  file = SD.open(cFile, FILE_READ);
  if (!file) {
    client.print F("Error opening file ");
    client.println(cFile);
    sendFooter();
    return;
  }

  int iBytesRequested, iBytesRead;
  // note this overwrites any data already in memeory...
  //first read the header string ...
  iBytesRequested = MaxInputStr + 2;
  iBytesRead = file.read(cPtr, iBytesRequested);
  if (iBytesRead < iBytesRequested) {
    client.print F("Error reading header data in file ");
    client.println(cFile);
    sendFooter();
    return;
  }

  // test if its an ERG
  StimTypes ss = (StimTypes)GetStimType(cPtr);
  // write out the string ....
  client.println((char *)cPtr);
  client.println F("<BR>Download file <a HREF=\"");
  client.print(cFile);
  client.print F("\">");
  client.print(cFile);
  client.println F("</a><BR>");

  if (ss == flash) {
    brightness = atoi(4 + strstr((char *)cPtr, "bri="));
    Serial.print F("brightness decoded as ");
    Serial.println(brightness);
  }

  // now on to the data
  int nBlocks = 0;

  for (int i = 0; i < max_data; i++) {
    erg_in[i] = 0;
  }

  // read ERG into time stamp
  iBytesRequested = max_data * sizeof(int);
  iBytesRead = file.read((unsigned char *)time_stamp, iBytesRequested);


  while (iBytesRead == iBytesRequested) {
    for (int i = 0; i < max_data; i++) {
      erg_in[i] = erg_in[i] + time_stamp[i];
    }
    // read and ignore the time stamp data
    iBytesRequested = max_data * sizeof(unsigned int);
    iBytesRead = file.read((unsigned char *)time_stamp, iBytesRequested);
    nBlocks++;

    //read next ERG block
    iBytesRequested = max_data * sizeof(int);
    iBytesRead = file.read((unsigned char *)time_stamp, iBytesRequested);

  }  // end of while

  file.close();

  for (int i = 0; i < max_data; i++) {
    erg_in[i] = erg_in[i] / nBlocks;
  }
  Serial.println("file read");

  sendGraphic(ss);
  sendFooter();
}

void doFFTFile(const char *c, bool bNeedHeadFooter) {
  String Sc = (c);
  Sc = String(("FFT of ")) + Sc;

  //String dataString ;
  unsigned char *cPtr;
  cPtr = (unsigned char *)erg_in;
  static int erg_in2[max_data];
  memset(erg_in2, 0, sizeof(int) * max_data);

  Serial.println F("trying to open:");
  Serial.println(c);
  if (file) file.close();
  file = SD.open(c, FILE_READ);

  if (bNeedHeadFooter) sendHeader(Sc, "onload=\"init()\"", true /*, cPtr*/);  //FIX - get date out of file header

  int iBytesRequested, iBytesRead;
  // note this overwrites any data already in memeory...
  //first read the header string ...
  iBytesRequested = MaxInputStr + 2;
  iBytesRead = file.read(cPtr, iBytesRequested);
  if (iBytesRead < iBytesRequested) {
    client.println F("Error reading header data in file ");
    client.println(c);
    return;
  }

  // write out the string ....
  client.print((char *)cPtr);
  client.println F("<BR>");

  // now on to the data
  iBytesRequested = max_data * sizeof(int);
  iBytesRead = file.read((unsigned char *)erg_in, iBytesRequested);

  int nBlocks = 0;
  while (iBytesRead == iBytesRequested) {
    iBytesRequested = max_data * sizeof(unsigned int);
    iBytesRead = file.read((unsigned char *)time_stamp, iBytesRequested);
    nBlocks++;
    // stop when mask and probe are both 30%
    //    Serial.println F("time ");
    //    Serial.print (time_stamp[max_data - 1]);
    //    Serial.println F(" erg ");
    //    Serial.println (erg_in[max_data - 1]);
    if (time_stamp[max_data - 1] == 30 && erg_in[max_data - 1] == 30) {
      Serial.print F("about to do FFT ");
      int m = millis();
      do_fft();
      // add to the average
      for (int ii = 0; ii < max_data; ii++) {
        erg_in2[ii] = erg_in2[ii] + erg_in[ii];
      }
      //      Serial.print (erg_in[48]);
      Serial.print F(" done FFT in");
      Serial.print(millis() - m);
      Serial.println F(" msec");
    }

    //read next block
    iBytesRequested = max_data * sizeof(int);
    iBytesRead = file.read((unsigned char *)erg_in, iBytesRequested);

  }  // end of while

  file.close();
  for (int ii = 0; ii < max_data; ii++) {
    erg_in[ii] = erg_in2[ii] / maxRepeats;
  }
  Serial.print(erg_in[48]);
  // now plot data in erg_in
  sendGraphic(SSVEP);
  Serial.println F(" plotted FFT");
  if (bNeedHeadFooter) sendFooter();
}

void sendLastModified(char *cPtr, char *c, bool bIsHTML) {
  //  // Content-Length: 1000000 [size in bytes FIX
  //  // Last-Modified: Sat, 28 Nov 2009 03:50:37 GMT
  if (file_time(cPtr)) {
    //  const char * cDays PROGMEM = "Sun,Mon,Tue,Wed,Thu,Fri,Sat,Sun";
    //  const char * cMonths PROGMEM = "Jan,Feb,Mar,Apr,May,Jun,Jul,Aug,Sep,Oct,Nov,Dec,";
    char dateString[31];
    memset(dateString, 0, 31);

    int iTmp = DayOfWeek(day, month, year);
    if (iTmp > 6) iTmp = 0;
    strncpy(dateString, cDays + iTmp * 4, 3);  // tue
    strcat(dateString, ", ");

    iTmp = strlen(dateString);
    printTwoDigits(dateString + iTmp, day);
    strcat(dateString, " ");

    int iLen = strlen(dateString);
    iTmp = month - 1;
    if (iTmp > 11) iTmp = 0;
    strncpy(dateString + iLen, cMonths + iTmp * 4, 3);  //nov
    dateString[iLen + 3] = 0;

    iTmp = strlen(dateString);
    sprintf(dateString + iTmp, " %d ", year);

    iTmp = strlen(dateString);
    printTwoDigits(dateString + iTmp, hour);
    strcat(dateString, ":");

    iTmp = strlen(dateString);
    printTwoDigits(dateString + iTmp, myminute);
    strcat(dateString, ":");

    iTmp = strlen(dateString);
    printTwoDigits(dateString + iTmp, second);
    strcat(dateString, " GMT");

    Serial.println F("Last modified Date is");
    Serial.println(dateString);

    sendHeader(String(c), "", bIsHTML, dateString);
  } else {
    Serial.println F("Last modified date is unknown");
    sendHeader(String(c), "", bIsHTML);
  }
}


int light_NOW(int i, StimTypes bErg) {
  //Serial.println F("berg=");
  //Serial.println(bErg);
  switch (bErg) {
    case flash:

      return (fERG_Now(i));  // i is related to max data, not the actual time

    case SSVEP:
      return (Get_br_Now(time_stamp[i], time_stamp[max_data - 1], erg_in[max_data - 1]));

      /* case zap :
      return zap_Now (i); */
  }
}


int GetStimType(unsigned char *cPtr) {
  // test if its an ERG
  Serial.print("Hello ");
  Serial.println((char *)cPtr);
  StimTypes bERG = SSVEP;
  if (strstr((char *)cPtr, "stim=fERG&")) {
    bERG = flash;
    Serial.println("flash found");
  }
  return (int)bERG;
}

void doreadFile(char *c) {
  //String dataString ;
  unsigned char *cPtr;
  cPtr = (unsigned char *)erg_in;


  //Serial.println F("trying to open:");
  //Serial.println (c);
  //if (file.isOpen()) file.close(); FIX
  file = SD.open(c, FILE_READ);

  int iBytesRequested, iBytesRead;
  // note this overwrites any data already in memeory...
  //first read the header string ...
  iBytesRequested = MaxInputStr + 2;
  iBytesRead = file.read(cPtr, iBytesRequested);
  if (iBytesRead < iBytesRequested) {
    client.println F("Error reading header data in file ");
    client.println(c);
    return;
  }

  sendLastModified((char *)cPtr, c, false);

  // test if its an ERG
  StimTypes bERG = (StimTypes)GetStimType(cPtr);

  bIsSine = (NULL == strstr((char *)cPtr, "stm=SQ"));
  if (bERG == flash) {
    brightness = atoi(4 + strstr((char *)cPtr, "bri="));
    Serial.print F("brightness decoded as ");
    Serial.println(brightness);
  }
  // write out the string ....
  char *pNext = strchr((char *)cPtr, '&');
  while (pNext) {
    *pNext = ',';
    pNext = strchr((char *)cPtr, '&');
  }

  pNext = strchr((char *)cPtr, '?');
  while (pNext) {
    *pNext = ',';
    pNext = strchr((char *)cPtr, '?');
  }

  client.print((char *)cPtr);
  client.println();

  // now on to the data
  iBytesRequested = max_data * sizeof(int);
  iBytesRead = file.read((unsigned char *)erg_in, iBytesRequested);

  int nBlocks = 0;
  while (iBytesRead == iBytesRequested) {
    iBytesRequested = max_data * sizeof(unsigned int);
    iBytesRead = file.read((unsigned char *)time_stamp, iBytesRequested);
    nBlocks++;

    for (int i = 0; i < max_data - 1; i++) {
      // make a string for assembling the data to log:
      client.print(time_stamp[i]);
      client.print(", ");
      client.print(light_NOW(i, bERG));
      client.print F(", ");
      client.print(erg_in[i]);
      client.println();
    }  //for

    // write out contrast

    client.print("-99, ");
    client.print(time_stamp[max_data - 1]);
    client.print(", ");
    client.print(erg_in[max_data - 1]);
    client.println();

    //read next block
    iBytesRequested = max_data * sizeof(int);
    iBytesRead = file.read((unsigned char *)erg_in, iBytesRequested);

  }  // end of while

  file.close();
}


void doreadSummaryFile(const char *c) {
  //String dataString ;
  unsigned char *cPtr = NULL;
  cPtr = (unsigned char *)erg_in;

  Serial.println F("trying to open summary file:");
  Serial.println(c);
  if (file) file.close();
  file = SD.open(c, FILE_READ);

  int iBytesRequested, iBytesRead;
  // note this overwrites any data already in memeory...
  //first read the header string ...
  iBytesRequested = MaxInputStr + 2;
  iBytesRead = file.read(cPtr, iBytesRequested);
  if (iBytesRead < iBytesRequested) {
    client.println F("Error reading header data in file ");
    client.println(c);
    file.close();
    return;
  }
  sendLastModified((char *)cPtr, (char *)c, false);
  // write out the string .... after replacing & or ? with ,
  char *pNext = strchr((char *)cPtr, '&');
  while (pNext) {
    *pNext = ',';
    pNext = strchr((char *)cPtr, '&');
  }

  pNext = strchr((char *)cPtr, '?');
  while (pNext) {
    *pNext = ',';
    pNext = strchr((char *)cPtr, '?');
  }

  client.print((char *)cPtr);
  client.println F("\n");

  // inefficiently read the file a byte at a time, and send it to the client
  memset(cPtr, 0, 20);
  bool b = file.read(cPtr, 1);
  while (b) {
    client.print((char *)cPtr);
    b = file.read(cPtr, 1);
  }

  file.close();
}

void addSummary() {

  int iOffset = 0;
  int kk = 0;
  switch (eDoFlash) {
    Serial.println F("eDoFlash=");
    Serial.println(eDoFlash);

    case flash:

      {
        iOffset = (nRepeats - 1) * 15;
        // "start,10,20,30,40,50,60,70,80,90%,max1,min1,max2,min2,peak-peak");

        pSummary[iOffset + kk] = erg_in[1];
        //    Serial.println (pSummary[iOffset + kk]);


        for (int ii = max_data / 10; ii < max_data - 1; ii = ii + max_data / 10) {
          pSummary[iOffset + kk] = erg_in[ii];
          kk++;
        }
        int myminsofar = erg_in[0];
        int mymaxsofar = erg_in[0];
        for (int ii = 1; ii < (max_data - 1) / 2; ii++) {
          if (erg_in[ii] < myminsofar) myminsofar = erg_in[ii];
          if (erg_in[ii] > mymaxsofar) mymaxsofar = erg_in[ii];
        }
        pSummary[iOffset + kk] = mymaxsofar;
        kk++;
        pSummary[iOffset + kk] = myminsofar;
        kk++;
        myminsofar = erg_in[(max_data - 1) / 2];
        mymaxsofar = erg_in[(max_data - 1) / 2];
        for (int ii = (max_data - 1) / 2; ii < max_data - 1; ii++) {
          if (erg_in[ii] < myminsofar) myminsofar = erg_in[ii];
          if (erg_in[ii] > mymaxsofar) mymaxsofar = erg_in[ii];
        }
        pSummary[iOffset + kk] = mymaxsofar;
        kk++;
        pSummary[iOffset + kk] = myminsofar;
        kk++;
        pSummary[iOffset + kk] = max(pSummary[iOffset + kk - 2], pSummary[iOffset + kk - 4]) - min(pSummary[iOffset + kk - 1], pSummary[iOffset + kk - 3]);
      }
      break;

    case SSVEP:
      {
        // fft
        iOffset = ((nRepeats * maxContrasts) + iThisContrast) * 10;
        Serial.print F("Offset ");
        Serial.println(iOffset);

        pSummary[iOffset + kk] = time_stamp[max_data - 1];
        kk++;
        pSummary[iOffset + kk] = erg_in[max_data - 1];
        kk++;
        pSummary[iOffset + kk] = nRepeats;
        kk++;

        // save erg as we do an in place FFT
        // For ESP we could save some memory by making erg_tmp a byte (and divide by 4 here)

        byte erg_tmp[max_data];
        for (int iERG = 0; iERG < max_data; iERG++) erg_tmp[iERG] = (byte)(erg_in[iERG] / 4);

        do_fft();

        // F2-F1
        pSummary[iOffset + kk] = erg_in[12];
        kk++;
        pSummary[iOffset + kk] = erg_in[49];
        kk++;
        pSummary[iOffset + kk] = erg_in[61];
        kk++;
        pSummary[iOffset + kk] = erg_in[98];
        kk++;
        pSummary[iOffset + kk] = erg_in[111];
        kk++;
        pSummary[iOffset + kk] = erg_in[221];
        kk++;
        pSummary[iOffset + kk] = erg_in[205];  // 50Hz
        kk++;
        for (int iERG = 0; iERG < max_data; iERG++) erg_in[iERG] = erg_tmp[iERG];
      }
      break;
  }
}

bool writeSummaryFile(const char *cMain) {
  int iCharMaxHere = 100;
  char c[iCharMaxHere];     // will hold filename
  char cTmp[iCharMaxHere];  // to hold text to write
  char *pDot = strchr((char *)cMain, '.');

  Serial.println F("Summarising filename ");
  Serial.println(cMain);
  Serial.flush();
  if (!pDot) {
    Serial.println F("Error in filename");
    Serial.println(c);
    Serial.flush();
    return false;
  }
  Serial.println F("filename extension:");
  Serial.println(pDot);
  Serial.flush();
  int iBytes = pDot - cMain;

  Serial.println F("length of string:");
  Serial.println(iBytes);
  Serial.flush();

  strncpy(c, cMain, iBytes);
  c[iBytes] = 0;
  strcat(c, ".CSV");

  Serial.println F("now writing summary: ");
  Serial.println(c);
  Serial.flush();

  int16_t iBytesWritten;

  if (fileExists(c)) {
    Serial.println F("Error in opening file");
    Serial.println(c);
    Serial.flush();
    return false;  // FIX - send error to usrrs
  }
  file = SD.open(c, FILE_WRITE);
  if (!file) {
    Serial.println F("Error in opening file");
    Serial.println(c);
    Serial.flush();
    return false;
  }

  iBytesWritten = file.write((uint8_t *)cInput, MaxInputStr + 2);
  if (iBytesWritten <= 0) {
    Serial.println F("Error in writing header to file");
    file.close();
    return false;
  }

  // for not bFlash
  int iOfssfet = 10;
  int mm = maxRepeats * maxContrasts;
  Serial.println F("eDoFlash=");
  Serial.println(eDoFlash);
  switch (eDoFlash) {
    case SSVEP:
      strcpy_P(cTmp, (PGM_P)F("\nprobe contrast\t mask\t repeat\t F2-F1\t 1F1\t 2F1\t 2F2\t 1F1+1F2\t 2F1+2F2\t 50 Hz \n"));
      break;

    default:
    case flash:
      strcpy_P(cTmp, (PGM_P)F("\nstart level\t10%\t20%\t30%\t40%\t50%\t60%\t70%\t80%\t90%\tmax1\tmin1\tmax2\tmin2\tpeak-peak\n"));

      iOfssfet = 15;
      mm = maxRepeats;

      break;
  }
  iBytesWritten = file.write((uint8_t *)cTmp, strlen(cTmp));
  if (iBytesWritten <= 0) {
    Serial.println F("Error in writing header to file");
    file.close();
    return false;
  }

  for (int ii = 0; ii < mm; ii++) {
    for (int jj = 0; jj < iOfssfet; jj++) {
      iBytesWritten = iBytesWritten + file.print(pSummary[ii * iOfssfet + jj]);
      iBytesWritten = iBytesWritten + file.print("\t");
    }
    iBytesWritten = iBytesWritten + file.print("\n");
  }

  if (iBytesWritten <= 0) {
    Serial.println F("Error in writing summary data to file");
    file.close();
    return false;
  }

  Serial.print F(" More bytes writen to file.........");
  Serial.print(c);
  Serial.print F(" size now ");
  Serial.println(file.size());
  file.close();
  return true;
}


// due

//////////// based on http://forum.arduino.cc/index.php?topic=130423.0

//void startTimer ()
//{
//  startTimer(TC1, 0, TC3_IRQn, 500); // fixed 0.5 kHz
//}

void startTimer(uint32_t frequency) {
  startTimer(TC1, 0, TC3_IRQn, frequency);  // fixed 0.5 kHz
}

void startTimer(Tc *tc, uint32_t channel, IRQn_Type irq, uint32_t frequency) {
  pmc_set_writeprotect(false);
  pmc_enable_periph_clk((uint32_t)irq);
  TC_Configure(tc, channel, TC_CMR_WAVE | TC_CMR_WAVSEL_UP_RC | TC_CMR_TCCLKS_TIMER_CLOCK4);
  uint32_t rc = VARIANT_MCK / 128 / frequency;  //128 because we selected TIMER_CLOCK4 above
  TC_SetRA(tc, channel, rc / 2);                //50% high, 50% low
  TC_SetRC(tc, channel, rc);
  TC_Start(tc, channel);
  tc->TC_CHANNEL[channel].TC_IER = TC_IER_CPCS;
  tc->TC_CHANNEL[channel].TC_IDR = ~TC_IER_CPCS;
  NVIC_EnableIRQ(irq);
}

void stopTimer() {
  stopTimer(TC1, 0, TC3_IRQn);
}

void stopTimer(Tc *tc, uint32_t channel, IRQn_Type irq) {
  TC_Stop(tc, channel);
  NVIC_DisableIRQ(irq);
}


void TC3_Handler() {
  // acknowledge interrupt
  TC_GetStatus(TC1, 0);

  if (sampleCount >= max_data - 1) {
    stopTimer();
    Serial.println F("Timer done");
    tidyUp_Collection();
    return;
  }

  if (sampleCount == 0) {
    mean = mean / presamples;
  }
  if (sampleCount >= 0) {
    // read  sensor
    erg_in[sampleCount] = myReadADC(analogPin) - mean;
  } else {
    mean = mean + long(myReadADC(analogPin));
  }
  int intensity = stimvalue[sampleCount + presamples];
  analogWrite(usedLED, intensity);
  sampleCount++;

  if (sampleCount >= max_data - 1) {
    stopTimer();
    Serial.println F("Timer done");
    //    tidyUp_Collection();
    return;
  }
}

void StartTo_collect_Data() {
  mStart = millis();
  mean = 0;
  sampleCount = -presamples;
  Serial.println F("eDoFlash=");
  Serial.println(eDoFlash);
  switch (eDoFlash) {
    case flash:

      iThisContrast = maxContrasts;
      nRepeats++;
      for (int i = 0; i < max_data + presamples; i++) {
        stimvalue[i] = fERG_Now(i - presamples);
      }
      startTimer(500);
      return;

    case SSVEP:
      for (int i = 0; i < max_data + presamples; i++) {
        stimvalue[i] = br_Now(i * 4);
      }
      startTimer(250);
      return;

      /*     case zap:
      nRepeats ++;
      for (int i = 0; i < max_data + presamples; i++)
      {
        stimvalue[i] = zap_Now (i - presamples);
      }
      startTimer(5000);
      return ; */
  }
}



void tidyUp_Collection() {
  sampleCount++;
  switch (eDoFlash) {
    case flash:
      analogWrite(usedLED, 0);
      iThisContrast = maxContrasts;  //++;
      for (int i = 0; i < max_data; i++) {
        time_stamp[i] = i * 2;  // fixed 2 ms per sample
      }
      break;
    /* case zap:
      analogWrite(usedLED, 0);
      iThisContrast = maxContrasts ; //++;
      for (int i = 0; i < max_data; i++)
      {
        time_stamp[i] = i * 200 ; // fixed 2 mus per sample
      }
      break ; */
    case SSVEP:
      // now done with sampling....
      for (int i = 0; i < max_data; i++) {
        time_stamp[i] = i * 4;  // fixed 4 ms per sample
      }
      //save contrasts we've used...
      int randomnumber = contrastOrder[iThisContrast];
      int F2index = 0;
      if (randomnumber > F2contrastchange) F2index = 1;
      time_stamp[max_data - 1] = F1contrast[randomnumber];
      erg_in[max_data - 1] = F2contrast[F2index];

      sampleCount++;
      analogWrite(usedLED, 127);
  }


  if (!bTestFlash) {
    if (!writeFile(cFile)) {
      Serial.println F("File not written :");
      Serial.println(cFile);
    } else {
      Serial.println F("Now try summary file");
      addSummary();
    }
  }

  switch (eDoFlash) {
    case SSVEP:
      iThisContrast++;
      if (iThisContrast >= maxContrasts) {
        iThisContrast = 0;
        nRepeats++;
        doShuffle();
      }
      break;

    default:
      break;
  }
  long mEnd = millis();
  Serial.print F("took AD ");
  Serial.println(mEnd - mStart);  // fERG: with timer driven this was exactly 2253 ms ( should be ~2248 ) and 4644 for SSVEP
}


void flickerPage() {

  sendHeader("Sampling", "onload=\"init()\"");

  // script to reload ...
  client.println F("<script>");
  client.println F("var myVar = setInterval(function(){myTimer()}, 10500);");  //mu sec
  client.println F("function myTimer() {");
  client.println F("location.reload(true);");
  client.println F("};");

  client.println F("function myStopFunction() {");
  client.println F("var b = confirm(\"Really Stop Data Acqusition ?\"); \n if ( b == true )  ");
  client.print F("{ \n clearInterval(myVar); ");
  client.print F("\n history.back();");
  client.print F(" } }");
  client.println F("");
  client.println F("</script>");


  switch (eDoFlash) {
    case flash:

      if (nWaits > 0) {
        AppendWaitReport();
      } else {
        AppendFlashReport();
      }
      break;

    case SSVEP:
      AppendSSVEPReport();
  }
  sendFooter();
}

void AppendWaitReport() {
  if (bTestFlash) {
    client.print F("waiting for first sample ");
  } else {
    client.print F("waiting ");
    if (nMaxWaits > 1) client.print F("(warming) ");
    client.print(nWaits);
    client.print F(" of ");
    client.print(nMaxWaits);
    //   client.println F(" time so far " );
  }
  client.println F(" <button onclick=\"myStopFunction()\">Stop Data Acquisition</button><BR>");
  client.println(cInput);
  client.println("<BR> ");
  nWaits--;
}

void AppendFlashReport() {
  if (!bTestFlash) {
    client.print F("Acquired ");
    client.print(nRepeats);
    client.print F(" of ");
    client.print(maxRepeats);
    client.println F(" data blocks so far ");
  } else {
    client.print F("Showing one sample ");
  }
  client.println F(" <button onclick=\"myStopFunction()\">Stop Data Acquisition</button><BR>");
  client.println(cInput);
  client.println F("<BR> ");


  if (nRepeats > 0) {
    sendGraphic(eDoFlash);
  }
}

void AppendSSVEPReport() {
  client.print F("Acquired ");
  int iTmp = nRepeats * maxContrasts;  //- maxContrasts ;
  //  Serial.print F("Acquired ");
  //  Serial.print (iTmp);
  iTmp = iTmp + iThisContrast;
  //  Serial.print F(" really ");
  //  Serial.println (iTmp);

  client.print(iTmp);
  client.print F(" of ");
  client.print(maxRepeats * maxContrasts);
  client.println F(" data blocks so far ");
  client.println F("<button onclick=\"myStopFunction()\">Stop Data Acquisition</button><BR>");
  client.println(cInput);
  client.println("<BR> ");

  if (iThisContrast < maxContrasts) {
    int randomnumber = contrastOrder[iThisContrast];
    int F2index = 0;
    if (randomnumber > F2contrastchange) F2index = 1;
    client.print F("Data will flicker at ");
    +client.print(freq1);
    client.print(" Hz with contrast ");
    client.print(F1contrast[randomnumber]);
    client.print F(" and ");
    +client.print(freq2);
    client.print F(" Hz with contrast ");
    client.print(F2contrast[F2index]);
    client.print F(" % <BR> ");
    client.println();

    client.println F("please wait....<BR>");
    //if (iThisContrast > 0)
    if (wfile && (wfile.size() > MaxInputStr + 2 + data_block_size))  // at least one data block
    {
      iThisContrast--;
      client.println F("<canvas id=\"myCanvas\" width=\"620\" height=\"450\" style=\"border:1px solid #d3d3d3;\">");
      client.println F("Your browser does not support the HTML5 canvas tag.</canvas>");

      client.println F("<script>");
      client.println F("var can;");
      client.println F("var ctx;");
      client.println F("var i = 8; ");

      client.println F("function l(v){");
      client.println F("ctx.lineTo(i,v);");
      client.println F("i = i + 8;");  // iStep ??
      client.println F("};");
      client.println F("function m(v){");
      client.println F("ctx.moveTo(0,v);");
      client.println F("i = 8;");
      client.println F("};");

      client.println F("function init() {");
      client.println F(" can = document.getElementById(\"myCanvas\");");
      client.println F(" ctx = can.getContext(\"2d\");");

      int iStep = 2;
      client.print F("m(");
      client.print(myGraphData[0] / 4 + 350);
      client.print F(");");
      for (int i = 1; i < 5 * max_graph_data - 2; i = i + iStep) {
        client.print F("l(");
        client.print(myGraphData[i + iStep] / 4 + 350);
        client.println F(");");
      }
      client.println F("ctx.stroke();");
      client.print F("m(");
      client.print(br_Now(time_stamp[0]));
      client.println F(");");
      for (int i = 1; i < 5 * max_graph_data - 2; i = i + iStep) {
        client.print F("l(");
        client.print(br_Now(time_stamp[i + iStep]));
        client.println F(");");
      }
      client.println F("ctx.stroke(); }");

      client.println F("</script>");
      iThisContrast++;
    }


    for (int i = iThisContrast - 1; i > -1; i--) {
      int randomnumber = contrastOrder[i];
      int F2index = 0;
      if (randomnumber > F2contrastchange) F2index = 1;

      client.print F("<BR>Data has been flickered at ");
      +client.print(freq1);
      client.print(" Hz with contrast ");
      client.print(F1contrast[randomnumber]);
      client.print F(" and ");
      +client.print(freq2);
      client.print F(" Hz with contrast ");
      client.print(F2contrast[F2index]);
      client.print F(" % ");
      client.println();
    }
  }
}


void getData() {
  if (sampleCount < 0) {
    Serial.println F("eDoFlash=");
    Serial.println(eDoFlash);
    if (eDoFlash == flash)  // || eDoFlash == zap)
    {
      if (nWaits > 0) return;
    }
    StartTo_collect_Data();
  }
}

void plotInColour(int iStart, const String &str_col) {
  // 12 Hz in blue ?
  // 4 ms per point 0.25 Hz per point, so 12 Hz expected at 48
  client.println F("ctx.beginPath();");
  client.print F("ctx.moveTo(");
  client.print((iXFactor * iStart) / (iXDiv + 1));
  client.print F(",");
  client.print(iBaseline - (10 * myGraphData[iStart]) / iYFactor);
  client.println F(");");
  for (int i = iStart + istep; i < iStart + 5; i = i + istep) {
    client.print F("ctx.lineTo(");
    client.print((iXFactor * i) / (iXDiv + 1));
    client.print F(",");
    client.print(iBaseline - (10 * myGraphData[i]) / iYFactor);
    client.println F(");");
  }
  client.print F("ctx.strokeStyle = '");
  client.print(str_col);
  client.println F("';");
  client.println F("ctx.closePath();");
  client.print F("ctx.fillStyle='");
  client.print(str_col);
  client.println F("';");
  client.println F("ctx.fill();");
  client.println F("ctx.stroke();");
}

int max_array(int *a, int num_elements) {
  int i, mymax = -32000;
  for (i = 0; i < num_elements; i++) {
    if (a[i] > mymax) {
      mymax = a[i];
    }
  }
  return (mymax);
}

void sendGraphic(StimTypes plot_stimulus) {

  istep = 15;
  plot_limit = max_data - max_data / 6;
  iXFactor = 4;
  iYFactor = 50;
  iBaseline = 260;
  iXDiv = 6;
  if (SSVEP == plot_stimulus) {
    istep = 1;
    plot_limit = plot_limit / 2;
    iXFactor = 10;
    iYFactor = 5;
    iBaseline = 420;
    iXDiv = 4;
  }

  client.println F("<canvas id=\"myCanvas\" width=\"640\" height=\"520\" style=\"border:1px solid #d3d3d3;\">");
  client.println F("Your browser does not support the HTML5 canvas tag.</canvas>");

  client.println F("<script>");
  client.println F("var can;");
  client.println F("var ctx;");
  client.print("var i = ");
  client.print((iXFactor * 2 * istep) / iXDiv);
  client.println F("; ");

  client.println F("function l(v){");
  client.println F("ctx.lineTo(i,v);");
  client.print F("i = i +  ");
  client.print((iXFactor * istep) / iXDiv);
  client.println F("; ");  // iStep ??
  client.println F("};");
  client.println F("function m(v){");
  client.println F("ctx.moveTo(0,v);");
  client.print("i = ");
  client.print((iXFactor * 2 * istep) / iXDiv);
  client.println F("; ");
  client.println F("};");

  client.println F("function init() {");
  client.println F(" can = document.getElementById(\"myCanvas\");");
  client.println F(" ctx = can.getContext(\"2d\");");
  //client.println F(" ctx.scale(0.21,1);");



  if (SSVEP != plot_stimulus) {
    //plot the stimulus
    client.println F("ctx.beginPath();");
    client.print F("m(");
    client.print(10 + (10 * light_NOW(time_stamp[1] - time_stamp[0], plot_stimulus)) / iYFactor);
    client.println F(");");

    for (int i = 2 * istep + 1; i < plot_limit; i = i + 15) {
      client.print F("l(");
      client.print(10 + (10 * light_NOW(time_stamp[i / 2] - time_stamp[0], plot_stimulus)) / iYFactor);
      client.println F(");");
    }
    client.println F("ctx.stroke();");

    // move to start of response line
    client.println F("ctx.beginPath();");
    client.print F("m(");
    client.print(iBaseline - (10 * myGraphData[istep]) / iYFactor);
    client.print F(");\n");

    //now join up the line
    for (int i = 2 * istep + 1; i < plot_limit; i = i + istep)  // default is istep of 15
    {
      client.print F("l(");
      client.print(iBaseline - (10 * max_array(myGraphData + i, istep)) / iYFactor);
      client.print F(");\n");
    }
    client.println F("ctx.stroke();");
  }

  if (SSVEP == plot_stimulus) {
    //plot the FFT
    // move to start of line
    // move to start of line
    client.println F("ctx.beginPath();");
    client.print F("m(");
    client.print(iBaseline - (10 * myGraphData[istep]) / iYFactor);
    client.print F(");\n");

    //now join up the line
    for (int i = 2 * istep + 1; i < plot_limit; i = i + istep)  // default is istep of 15
    {
      client.print F("l(");
      client.print(iBaseline - (10 * max_array(myGraphData + i, istep)) / iYFactor);
      client.print F(");\n");
    }
    client.println F("ctx.stroke();");
    plotInColour(4 * 12, String("#0000FF"));
    plotInColour(4 * 15, String("#0088FF"));
    plotInColour(4 * 12 * 2, String("#8A2BE2"));
    plotInColour(4 * 27, String("#FF8C00"));
    // 1024 rather than 1000
    plotInColour(4 * 51, String("#FF0000"));
  }

  client.println F("} </script>");
}


void sendReply() {
  int exp_size = MaxInputStr + 2;
  Serial.println(MyInputString);
  if (!has_filesystem) {
    sendHeader("Card not working");
    client.println F("SD Card failed");
    sendFooter();
    return;
  }
  if (!bFileOK) {
    sendHeader("File not written");
    client.print F("File write failed on SD Card : ");
    client.print(cFile);
    client.println F("<BR>Disk full (512 files?) <BR>File already exists?<BR>To setup for another test please ");

    send_GoBack_to_Stim_page();
    sendFooter();

    bFileOK = true;
    return;
  }

  int fPOS = MyInputString.indexOf("filename=");
  // asking for new sample
  if (fPOS > 0) {
    bool bNewCommand = false;

    // save the commandline....
    MyInputString.toCharArray(cInput, MaxInputStr + 2);
    unsigned int myCRC = crc32b((unsigned char *)cInput);
    if (myCRC != iLastCRC) {
      bNewCommand = true;
      iLastCRC = myCRC;
      memset(pSummary, 0, maxRepeats * maxContrasts * maxsummaryentries * sizeof(int));
    }
    char *cP = strstr(cInput, "HTTP/");
    if (cP) cP = '\0';

    fPOS = MyInputString.indexOf ("white"); // Check which LED we are using for the SSVEP / ERG
    if (fPOS > 0)
    {
      usedLED = whiteled;
    }
    else {
      usedLED = bluLED;
    } 
    //flash ERG or SSVEP?
    StimTypes lastStim = eDoFlash;
    if (bTestFlash) {
      lastStim = SSVEP;  //if it was a test flash, pretend it was SSVEP to force a wait
    }
    eDoFlash = SSVEP;
    bTestFlash = MyInputString.indexOf("=fERG_T") > 0;
    if (MyInputString.indexOf("=fERG") > 0) eDoFlash = flash;
    //if (MyInputString.indexOf ("=fERG_Z") > 0 ) eDoFlash = zap ;
    bIsSine = MyInputString.indexOf("_SQ&") < 0;  // -1 if not found

    int ibrPos = MyInputString.indexOf("bri=") + 4;
    brightness = atoi(cInput + ibrPos);
    if (bTestFlash) brightness = maxbrightness;


    // find filename
    String sFile = MyInputString.substring(fPOS + 9);  // ignore the leading / should be 9
    // first check for overlong URLs
    if (sFile.indexOf("HTT") < 1) {
      sendHeader("Request too long");
      client.print F("URL is too long : ");
      client.print(MyInputString);

      send_GoBack_to_Stim_page();
      sendFooter();
      return;
    }
    //Serial.println F("  Position of filename= was:" + String(fPOS));
    //Serial.println F(" Proposed saving filename " + sFile );
    fPOS = sFile.indexOf(" ");  // or  & id filename is not the last paramtere
    //Serial.println F("  Position of blankwas:" + String(fPOS));
    sFile = sFile.substring(0, fPOS);
    while (sFile.length() > 8) {
      sFile = sFile.substring(1);
      //Serial.println F(" Proposed saving filename " + sFile );
    }
    switch (eDoFlash) {
      case flash:

        sFile = sFile + (".ERG");
        exp_size = exp_size + (maxRepeats * data_block_size);
        analogPin = 0;
        break;

      case SSVEP:
        sFile = sFile + (".SVP");
        exp_size = exp_size + (maxRepeats * maxContrasts * data_block_size);
        analogPin = 0;
    }

    //Serial.println F(" Proposed filename now" + sFile + ";");

    sFile.toCharArray(cFile, 29);  // adds terminating null

    if (bNewCommand) {
      // no disk space ??
      if (GetFreeSpace(NULL) < exp_size) {
        sendHeader("Disk Full");
        client.print F("No space left on disk (only ");
        client.print(GetFreeSpace(NULL));
        client.print F(" bytes free, ");
        client.print(exp_size);
        client.print F(" bytes needed) <BR><BR> Click here to go back to the ");

        send_GoBack_to_Stim_page();
        sendFooter();
        return;
      }

      //if file exists... ????
      if (fileExists(cFile)) {
        sendHeader("File exists");
        client.print F("File already exists on disk ( ");
        client.print(cFile);
        client.print F(" ) <BR> Click here to go back to the ");

        send_GoBack_to_Stim_page();
        sendFooter();
        return;
      }
      // new file
      nRepeats = iThisContrast = 0;
      nWaits = nMaxWaits;
      if (bTestFlash) {
        nWaits = 1;
      } else {
        //  if (eDoFlash == zap) nWaits = 1;

        // for shibire, always allow time for temperature to change
        if (lastStim == flash) nWaits = 1;
      }
      //turn off any lights we have on...
      goColour(0, false);
    }
    //Serial.println F("repeats now ");
    //Serial.println (nRepeats);
    if (wfile && wfile.size() >= exp_size)  //nRepeats >= maxRepeats)
    {
      // done so tidy up
      Serial.println F("done and tidy up time");
      //turn off any lights we have on...
      nRepeats = iThisContrast = 0;  // ready to start again
      nWaits = nMaxWaits;
      //file.timestamp(T_ACCESS, 2009, 11, 12, 7, 8, 9) ;
      sendHeader("Sampling Complete!", "onload=\"init()\"");
      if (!bTestFlash) {
        client.print F("Sampling Now Complete <BR><BR><A HREF= \"");
        client.print(sFile + "\" >" + sFile + "</A>" + " size: ");
        client.print(wfile.size());
        client.print F(" bytes; expected size ");
        client.print(exp_size);
        wfile.close();
        //writeSummaryFile(cFile);

        String sPicture = sFile;
        switch (eDoFlash) {
          case flash:

            sPicture.replace("ERG", "ERP");
            client.print F("<A HREF= \"");
            client.print(sPicture);
            client.print F("\" > (averaged picture)</A>");
            sPicture.replace("ERP", "CSV");
            break;

          case SSVEP:
            sPicture.replace("SVP", "CSV");
        }
        //   client.print F("<A HREF= \"");
        //       client.print (sPicture) ;
        //        client.print F("\" > (summary file)</A>" );
      } else {
        wfile.close();
      }
      client.print F("<BR><BR>To setup for another test please \n");
      send_GoBack_to_Stim_page();
      client.print F("<BR><A HREF= \"dir=\"  > Full directory</A> <BR><BR> \n");
      switch (eDoFlash) {
        case flash:
          /*  case zap:
          sendGraphic(eDoFlash);
          break ; */

        case SSVEP:
          doFFTFile(cFile, false);
      }
      sendFooter();

      return;
    }

    flickerPage();
    sampleCount = -102;  //implies collectData();
    return;
  }
  // otherwise itd not a stimulus protocol
  // FIX me - would it be better to have a nostim parameter to StimTypes ?
  // eDoFlash = zap;
  // show directory
  fPOS = MyInputString.indexOf("dir=");
  //  Serial.println F("  Position of dir was:" + String(fPOS));
  if (fPOS > 0) {
    serve_dir("/");
    return;
  }

  //light up
  fPOS = MyInputString.indexOf("white/");
  if (fPOS > 0) {
    goColour(255, true);
    return;
  }


  // but classroomsetup can do blue and black
  fPOS = MyInputString.indexOf("blue/");
  if (fPOS > 0) {
    goColour(0, 0, 255, 0, true);
    return;
  }
  fPOS = MyInputString.indexOf("black/");
  if (fPOS > 0) {
    //    Serial.println F("off");
    goColour(0, true);
    return;
  }

  // infrared LED connected to green
  fPOS = MyInputString.indexOf("green/");
  if (fPOS > 0) {
    goColour(0, 255, 0, 0, true);
    return;
  }

  // a file is requested...
  fPOS = MyInputString.indexOf(".SVP");
  if (fPOS == -1) {
    fPOS = MyInputString.indexOf(".SVV");
  }
  if (fPOS == -1) {
    fPOS = MyInputString.indexOf(".ERG");
  }
  if (fPOS == -1) {
    fPOS = MyInputString.indexOf(".ERP");
  }
  if (fPOS == -1) {
    fPOS = MyInputString.indexOf(".CSV");
  }
  if (fPOS == -1) {
    fPOS = MyInputString.indexOf("/");
  }
  //Serial.println F("  Position of .SVP was:" + String(fPOS));
  if (fPOS > 0) {


    // requested a file...
    fPOS = MyInputString.indexOf("/");
    String sFile = MyInputString.substring(fPOS + 1);  // ignore the leading /
    //    Serial.println F(" Proposed filename " + sFile );
    fPOS = sFile.indexOf(" HTTP/");
    sFile = sFile.substring(0, fPOS);
    //    Serial.println F(" Proposed filename now" + sFile + ";");

    if (MyInputString.indexOf(".ERP") > 0) {
      sFile.replace((".ERP"), (".ERG"));
      sFile.toCharArray(cFile, 29);  // adds terminating null
      Serial.print(sFile);
      doplotFile();
      return;
    }
    if (MyInputString.indexOf(".SVV") > 0) {
      sFile.replace((".SVV"), (".SVP"));
      sFile.toCharArray(cFile, 29);  // adds terminating null
      doFFTFile(cFile, true);
      return;
    }
    if ((MyInputString.indexOf(".csv") > 0) || (MyInputString.indexOf(".CSV") > 0)) {
      Serial.println F("csv found");
      sFile.toCharArray(cFile, 29);  // adds terminating null
      doreadSummaryFile(cFile);
      return;
    }
    if ((MyInputString.indexOf(".ERG") > 0) || (MyInputString.indexOf(".SVP") > 0)) {
      sFile.toCharArray(cFile, 29);  // adds terminating null
      doreadFile(cFile);
      return;
    }
    // robots.txt
    if (MyInputString.indexOf("robots.txt") > 0) {
      client.println F("welcome to robots!");
      return;
    }
    //
    //    // otherwise we'll assume its a directory...
    //    sFile = sFile + ("/");
    //    serve_dir(sFile);
    //    return ;
  }

  // default - any other url
  writehomepage();
  //run_graph() ;
  MyInputString = "";
}

void loop() {
  String sTmp = "";
  MyInputString = "";
  getData();
  // delay till we are sure data acq is done ??
  // SSVEP ERG is 250 Hz so 4 ms per sample...
  delay(max_data + presamples * 10);
  if (sampleCount >= max_data - 1) {
    tidyUp_Collection();
    sampleCount = 0;
  }

  boolean currentLineIsBlank = true;
  // listen for incoming clients

  client = server.available();
  if (client) {
    Serial.println F("new client");
    MyInputString = "";
    // an http request ends with a blank line
    while (client.connected()) {
      if (client.available()) {  // if there's bytes to read from the client,
        char c = client.read();

        // if you've gotten to the end of the line (received a newline
        // character) and the line is blank, the http request has ended,
        // so you can send a reply
        if (c == '\n' && currentLineIsBlank) {
          sendReply();
          break;
        }

        if (c == '\n') {
          //Serial.println F("Input string now " );
          //Serial.println (sTmp);

          // you're starting a new line
          // see if we need to save the old one
          if (sTmp.indexOf("GET") >= 0) {
            MyInputString = sTmp;
          }
          int iTmp = sTmp.indexOf F("Referer:");
          sTmp = "";

          currentLineIsBlank = true;
        } else if (c != '\r') {
          // you've gotten a character on the current line
          currentLineIsBlank = false;
          if (sTmp.length() < MaxInputStr) {
            sTmp.concat(c);
            //Serial.println (sTmp);
          }
        }
      }
    }
    // give the web browser time to receive the data
    delay(1);
    // close the connection:
    client.stop();
    //Serial.println F("client disonnected: Input now:" + MyInputString + "::::");
  }
}

void writehomepage() {

  sendHeader(String("Fly lab here!"));
  client.print F("Please try <a href=\'https://wadelab.github.io/flyCode/collectData/fly_arduino/pages/sitran/'>Git Server</a> for starter page");
  sendFooter();
}

void do_fft() {

  //  read it  in erg_in, transfer it to f_ and then put the fft back in erg_in
  // FFT_SIZE IS DEFINED in Header file Radix4.h
  // #define   FFT_SIZE           1024
  //  static int         f_r[FFT_SIZE]   = { 0};

#define f_r (int *)erg_in
  // static int         f_i[FFT_SIZE]   = { 0 };

  //  static int         out[FFT_SIZE / 2]     = { 0};     // Magnitudes

  Radix4 radix;
  //  for ( uint16_t i = 0, k = (NWAVE / FFT_SIZE); i < FFT_SIZE; i++ )
  //  {
  //    f_r[i] = erg_in[i];
  //  }
  memset(f_i, 0, sizeof(f_i));  // Image -zero.

  radix.rev_bin(f_r, FFT_SIZE);
  delay(0);
  radix.fft_radix4_I(f_r, f_i, LOG2_FFT);
  radix.gain_Reset(f_r, LOG2_FFT - 1);
  radix.gain_Reset(f_i, LOG2_FFT - 1);
  radix.get_Magnit(f_r, f_i, (int *)erg_in);
}
