
//#define test_on_mac

/*

Prototype : put the grey wire in ground, and purple wire in pin7

 Based on Web Server

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
//#include <FixFFT.h>

const int max_graph_data = 32 ;
int * myGraphData ;  // will share erg_in space, see below
int iIndex = 0 ;


//
byte usedLED  = 0;
const byte redled = 5;
const byte grnled = 6;
const byte bluLED = 7;

const byte analogPin = 0 ;

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

boolean has_filesystem = true;
Sd2Card card;
SdVolume volume;
SdFile root;
SdFile file;

boolean bDoFlash = false ;
byte freq1 = 12 ; // flicker of LED Hz
byte freq2 = 15 ; // flicker of LED Hz
// as of 18 June, maxdata of 2048 is too big for the mega....
const int max_data = 1025  ;
unsigned int time_stamp [max_data] ;
int erg_in [max_data];
long sampleCount = 0;        // will store number of A/D samples taken
unsigned long interval = 4;           // interval (5ms) at which to - 2 ms is also ok in this version
unsigned long last_time = 0;
unsigned int start_time = 0;
unsigned long timing_too_fast = 0 ;

byte second, minute, hour, day, month;
int year ;

const int MaxInputStr = 130 ;
String MyInputString = String(MaxInputStr + 1);
char cFile [30];
char cInput [MaxInputStr + 2] = "";



// Enter a MAC address and IP address for your controller below.
// The IP address will be dependent on your local network:
byte mac[] = {
#ifdef  test_on_mac
  0x90, 0xA2, 0xDA, 0x0F, 0x42, 0x02
}; //biolpc2804
#else
  0xDE, 0xAD, 0xBE, 0xEF, 0xFE, 0xED
}; //biolpc2793
#endif
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
  digitalWrite(SS_ETHERNET, HIGH); // HIGH means Ethernet not active


  // Open serial communications and wait for port to open:
  Serial.begin(115200);
  while (!Serial) {
    ; // wait for serial port to connect. Needed for Leonardo only
  }
  myGraphData = erg_in ;
  for (int i = 0; i < max_graph_data; i++)
  {
    myGraphData[i] = 0;
  }

  // initialize the SD card
  Serial.println F("Setting up SD card...\n");

  if (!card.init(SPI_FULL_SPEED, 4)) {
    Serial.println F("card failed\n");
    has_filesystem = false;
  }
  // initialize a FAT volume
  if (!volume.init(&card)) {
    Serial.println F("vol.init failed!\n");
    has_filesystem = false;
  }
  if (!root.openRoot(&volume)) {
    Serial.println F("openRoot failed");
    has_filesystem = false;
  }
  if (has_filesystem)
  {
    Serial.println F("SD card ok\n");
  }
  Serial.println F("Setting up the Ethernet card...\n");
  // start the Ethernet connection and the server:
  Ethernet.begin(mac);
  server.begin();
  Serial.print F("server is at ");
  Serial.println(Ethernet.localIP());

  //set up PWM
  //http://forum.arduino.cc/index.php?topic=72092.0
  // timer 4 (controls pin 8, 7, 6);
  int myEraser = 7;             // this is 111 in binary and is used as an eraser
  TCCR4B &= ~myEraser;   // this operation (AND plus NOT),  set the three bits in TCCR2B to 0

  // CS02, CS01, CS00  are clear, we write on them a new value:
  //prescaler = 1 ---> PWM frequency is 31000 Hz
  //prescaler = 2 ---> PWM frequency is 4000 Hz
  //prescaler = 3 ---> PWM frequency is 490 Hz (default value)
  int myPrescaler = 1;         // this could be a number in [1 , 6]. In this case, 3 corresponds in binary to 011.
  TCCR4B |= myPrescaler;  //this operation (OR), replaces the last three bits in TCCR2B with our new value 011

  goColour(0, 0, 0, false);

  doShuffle();
}




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





void sendHeader (const String & sTitle, const String & sINBody = "", bool isHTML = true)
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
  client.println F("Connection: close");  // the connection will be closed after completion of the response
  client.println();
  if (isHTML)
  {
    client.println F("<!DOCTYPE HTML>");
    client.println F("<html>");
    client.println F("<title>");
    client.println (sTitle);
    client.println F("</title>");
    client.println F("<body ");
    client.println (sINBody);
    client.println F(">");
  }
}

void sendFooter()
{
  client.println F("</body></html>");
}

void goColour(const byte r, const byte g, const byte b, const bool boolUpdatePage)
{
  analogWrite( redled, r );
  analogWrite( grnled, g );
  analogWrite( bluLED, b );
  if (boolUpdatePage)
  {
    sendHeader ("Lit up ?", "onload=\"goBack()\" ");

    client.println F(" <script>");
    client.println F("function goBack() ");
     client.println F("{ window.history.back() }");
    client.println F("</script>");

    sendFooter();
  }
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
  goColour(0, 0, 0, false);

  // read the value of  analog input pin and turn light on if in mid-stimulus...
  int sensorReading = analogRead(analogPin);
  myGraphData[iIndex] = sensorReading ;
  iIndex ++ ;
  if (iIndex > max_graph_data / 10 && iIndex < max_graph_data / 2)
  {
    analogWrite(bluLED, 255);
  }
  else
  {
    analogWrite(bluLED, 0);
  }

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
    if (i < iIndex || i > iIndex + 1)
    {
      client.print("ctx.moveTo(");
      client.print(i * 20);
      client.print(",");
      client.print(myGraphData[i] / 2);
      client.println F(");");
      client.print("ctx.lineTo(");
      client.print((i + 1) * 20);
      client.print(",");
      client.print(myGraphData[i + 1] / 2);
      client.println F(");");
      client.println F("ctx.strokeStyle=\"blue\";");
      client.println F("ctx.stroke();");
    }
  }
  //draw stimulus...
  client.print("ctx.moveTo(");
  client.print((max_graph_data / 10) * 20);
  client.print(",");
  client.print(30);
  client.println F(");");

  client.print("ctx.lineTo(");
  client.print(max_graph_data / 2 * 20);
  client.print(",");
  client.print(30);
  client.println F(");");

  client.println F("ctx.strokeStyle=\"blue\";");
  //              client.println("ctx.lineWidth=5;");
  client.println F("ctx.stroke();");

  client.println F("</script>");
  client.println F("<BR><BR><button onclick=\"myStopFunction()\">Stop display</button>");
#ifdef test_on_mac
  client.println F("To run a flicker test please stop and then load <A HREF=\"http://biolpc22.york.ac.uk/cje2/form04.html\"> form04.html</A>  ");
#else
  client.println F("To run a flicker test please stop and then load <A HREF=\"http://biolpc22.york.ac.uk/cje2/form.html\"> form.html</A>  ");
#endif
  sendFooter();

}

void printTwoDigits(uint8_t v)
{
  char str[3];
  str[0] = '0' + v / 10;
  str[1] = '0' + v % 10;
  str[2] = 0;
  client.print(str);
}

//code to print date...
void myPrintFatDateTime(const dir_t & pFile)
{
  client.write(' ');
  client.print(FAT_YEAR(pFile.lastWriteDate));
  client.write('-');
  printTwoDigits(FAT_MONTH(pFile.lastWriteDate));
  client.write('-');
  printTwoDigits(FAT_DAY(pFile.lastWriteDate));
  client.write(' ');
  printTwoDigits(FAT_HOUR(pFile.lastWriteTime));
  client.print(':');
  printTwoDigits(FAT_MINUTE(pFile.lastWriteTime));
  client.print(':');
  printTwoDigits(FAT_SECOND(pFile.lastWriteTime));
  client.print(' ');
}

void printDirectory(uint8_t flags) {
  // This code is just copied from SdFile.cpp in the SDFat library
  // and tweaked to print to the client output in html!
  dir_t p;

  root.rewind();
  client.println F("<ul>");
  while (root.readDir(p) > 0) {
    // done if past last used entry
    if (p.name[0] == DIR_NAME_FREE) break;

    // skip deleted entry and entries for . and  ..
    if (p.name[0] == DIR_NAME_DELETED || p.name[0] == '.') continue;

    // only list subdirectories and files
    if (!DIR_IS_FILE_OR_SUBDIR(&p)) continue;

    // print any indent spaces
    client.print("<li><a href=\"");
    for (uint8_t i = 0; i < 11; i++)
    {
      if (p.name[i] == ' ') continue;
      if (i == 8) {
        client.print('.');
      }
      client.print(char(p.name[i]));
    }
    client.print("\">");

    // print file name with possible blank fill
    for (uint8_t i = 0; i < 11; i++)
    {
      if (p.name[i] == ' ') continue;
      if (i == 8) {
        client.print('.');
      }
      client.print(char(p.name[i]));
    }

    client.print("</a>");

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



void serve_dummy()
{
  sendHeader("Request not found");
  client.println F("Dummy page; <BR> To run a flicker test please load <A HREF=\"http://biolpc22.york.ac.uk/cje2/form.html\"> form.html</A>  ");
  sendFooter() ;
}

int br_Now(double t)
{
  int randomnumber = contrastOrder[iThisContrast];
  int F2index = 0 ;
  if (randomnumber > F2contrastchange) F2index = 1;
  return int(sin((t / 1000.0) * PI * 2.0 * double(freq1)) * 1.270 * double(F1contrast[randomnumber]) + sin((t / 1000.0) * PI * 2.0 * double(freq2)) * 1.270 * double(F2contrast[F2index])) + 127;
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
  EthernetClient timeclient;
  // default values ...
  year = 2014;
  second = minute = hour = day = month = 0;

  // Just choose any reasonably busy web server, the load is really low
  if (timeclient.connect("biolpc22.york.ac.uk", 80))
  {
    // Make an HTTP 1.1 request which is missing a Host: header
    // compliant servers are required to answer with an error that includes
    // a Date: header.
    timeclient.print(F("GET / HTTP/1.1 \r\n\r\n"));

    char buf[5];			// temporary buffer for characters
    timeclient.setTimeout(5000);
    if (timeclient.find((char *)"\r\nDate: ") // look for Date: header
        && timeclient.readBytes(buf, 5) == 5) // discard
    {
      day = timeclient.parseInt();	   // day
      timeclient.readBytes(buf, 1);	   // discard
      timeclient.readBytes(buf, 3);	   // month
      year = timeclient.parseInt();	   // year
      hour = timeclient.parseInt();   // hour
      minute = timeclient.parseInt(); // minute
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
      month -- ; // zero based, I guess

    }
  }
  delay(10);
  timeclient.flush();
  timeclient.stop();

  return ;
}


void writeFile(const char * c)
{
  // file format
  //    MyInputString viz. char cInput [MaxInputStr+2];
  //    int contrastOrder[ maxContrasts ];
  //    unsigned int time_stamp [max_data] ;
  //    int erg_in [max_data];

  int16_t iBytesWritten ;

  if (!fileExists(c))
  {

    if ( !file.open(root, c /*myName*/,   O_CREAT | O_APPEND | O_WRITE))
    {
      Serial.println F ("Error in opening file");
      Serial.println (c);
      return ;
    }
    webTime();
    if (!file.timestamp(T_CREATE | T_ACCESS | T_WRITE, year, month, day, hour, minute, second)) {
      Serial.println F ("Error in timestamping file");
      Serial.println (c);
    }
    iBytesWritten = file.write(cInput, MaxInputStr + 2);
    if (iBytesWritten <= 0)
    {
      Serial.println F ("Error in writing header to file");
      file.close();
      return ;
    }

    //    iBytesWritten = file.write(contrastOrder, maxContrasts * sizeof(int));
    //    if (iBytesWritten <= 0)
    //    {
    //      Serial.println F ("Error in writing contrast data to file");
    //      file.close();
    //      return ;
    //    }

  }
  else // file exists, so just append...
  {
    if ( !file.open(root, c /*myName*/,  O_APPEND | O_WRITE))
    {
      Serial.println F ("Error in opening file");
      Serial.println (c);
      return ;
    }

  }


  // always write the erg and time data, and on last line contrast data
  iBytesWritten = file.write(erg_in, max_data * sizeof(int));
  if (iBytesWritten <= 0)
  {
    Serial.println F ("Error in writing erg data to file");
    file.close();
    return ;
  }

  // Serial.println("File success: written bytes " + String(iBytesWritten));
  iBytesWritten = file.write(time_stamp, max_data * sizeof(unsigned int));
  if (iBytesWritten <= 0)
  {
    Serial.println F ("Error in writing timing data to file");
  }
  Serial.print F(" More bytes writen to file.........");
  Serial.print  (c);
  Serial.print F(" size now ");
  Serial.println (file.fileSize());
  file.sync();
}

bool fileExists(const char * c)
{
  if (file.isOpen()) file.close();
  bool bExixsts = file.open(root, c, O_READ);
  if (bExixsts) file.close();
  return bExixsts ;
}

void doreadFile (const char * c)
{
  String dataString ;
  char * cPtr;
  cPtr = (char *) erg_in ;
  int iOldContrast ;

  sendHeader(String(c), "", false);
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
  client.print(cPtr);
  // test if its an ERG
  boolean bERG = ( NULL != strstr ( cPtr, "stim=fERG&") ) ;

  // now on to the data
  iBytesRequested = max_data * sizeof(int);
  iBytesRead = file.read(erg_in, iBytesRequested);
  int nBlocks = 0;
  while (iBytesRead == iBytesRequested)
  {
    iBytesRequested = max_data * sizeof(unsigned int);
    iBytesRead = file.read (time_stamp, iBytesRequested );
    nBlocks ++;
    Serial.print F("Reading file blocks ");
    Serial.println (nBlocks);

    for (int i = 0; i < max_data - 1; i++)
    {
      // make a string for assembling the data to log:
      dataString = String(time_stamp[i]);
      dataString += ", ";
      if (bERG)
      {
        dataString += String( fERG_Now (time_stamp[i] - time_stamp[0] ) );
      }
      else
      {
        dataString += String(br_Now(time_stamp[i]));
      }
      dataString += ", ";

      dataString += String(erg_in[i]);
      client.println(dataString);
    } //for

    // write out contrast

    dataString = "-99, ";

    dataString += String(time_stamp[max_data - 1]);
    dataString += ", ";

    dataString += String(erg_in[max_data - 1]);
    client.println(dataString);
    //read next block
    iBytesRequested = max_data * sizeof(int);
    iBytesRead = file.read(erg_in, iBytesRequested);
  } // end of while

  file.close();

}

void collectSSVEPData ()
{
  const long presamples = 102;
  long mean = 0;
  unsigned int iTime ;
  if (iThisContrast == 0 && file.isOpen()) file.close();

  Serial.print F("collecting data with ");
  Serial.print (nRepeats);
  Serial.print ("r : c");
  Serial.println (iThisContrast);

  if (iThisContrast >= maxContrasts)
  {
    iThisContrast = 0;
    nRepeats ++;
  }

  Serial.print F("update collecting data with ");
  Serial.print (nRepeats);
  Serial.print ("r : c");
  Serial.println (iThisContrast);

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

  writeFile(cFile);


}


void collect_fERG_Data ()
{
  const long presamples = 102;
  long mean = 0;
  unsigned int iTime ;
  if (iThisContrast == 0 && file.isOpen()) file.close();

  iThisContrast = maxContrasts;
  nRepeats ++;
  Serial.print F("collecting fERG data with ");
  Serial.print (nRepeats);
  Serial.print ("r : c");
  Serial.println (iThisContrast);

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

  // now done with sampling....
  //  //save contrasts we've used...
  //  int randomnumber = contrastOrder[iThisContrast];
  //  int F2index = 0 ;
  //  if (randomnumber > F2contrastchange) F2index = 1;
  //  time_stamp [max_data - 1] = F1contrast[randomnumber];
  //  erg_in [max_data - 1] = F2contrast[F2index] ;

  sampleCount ++ ;
  analogWrite(usedLED, 0);
  iThisContrast = maxContrasts ; //++;

  writeFile(cFile);


}

void flickerPage()
{
  Serial.print F("Sampling at :");
  Serial.println (String(sampleCount));

  sendHeader("Sampling");

  // script to reload ...
  client.println F("<script>");
  client.println F("var myVar = setInterval(function(){myTimer()}, 7500);"); //mu sec
  client.println F("function myTimer() {");
  client.println F("location.reload(true);");
  client.println F("};");

  client.println F("function myStopFunction() {");
  client.println F("clearInterval(myVar); }");
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
  client.print (" of ");
  client.print (maxRepeats);
  client.println F(" data blocks so far <BR>" );
  client.println (cInput);
  client.println F( "<BR> ");

  if(nRepeats >0)
  {
  client.println F("<canvas id=\"myCanvas\" width=\"640\" height=\"520\" style=\"border:1px solid #d3d3d3;\">");
  client.println F("Your browser does not support the HTML5 canvas tag.</canvas>");

  client.println F("<script>");
  client.println F("var c = document.getElementById(\"myCanvas\");");
  client.println F("var ctx = c.getContext(\"2d\");");

  for (int i = 0; i < max_data - max_data/6; i = i + 15)
  {
    client.print F("ctx.moveTo(");
    client.print((8*i)/10 );
    client.print F(",");
    client.print(350-myGraphData[i]);
    client.println F(");");
    client.print F("ctx.lineTo(");
    client.print((8*(i + 15))/10 );
    client.print F(",");
    client.print(350-myGraphData[i + 15]);
    client.println F(");");
    client.println F("ctx.stroke();");

    client.print F("ctx.moveTo(");
    client.print((8*i)/10 );
    client.print F(",");
    client.print(10 + fERG_Now(time_stamp[i] - time_stamp[0]) );
    client.println F(");");
    client.print F("ctx.lineTo(");
   client.print((8*(i + 13))/10 );
     client.print F(",");
    client.print(10 + fERG_Now(time_stamp[i + 13] - time_stamp[0]));
    client.println F(");");
    client.println F("ctx.stroke();");
  }
  client.println F("</script>");
  }
}

void AppendSSVEPReport()
{
  client.print F("Acquired ") ;
  int iTmp = iThisContrast + (nRepeats * maxContrasts) - maxContrasts ;
  client.print (iTmp);
  client.print F(" of ");
  client.print (maxRepeats * maxContrasts);
  client.println F(" data blocks so far <BR>" );
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
      client.println F("<canvas id=\"myCanvas\" width=\"640\" height=\"520\" style=\"border:1px solid #d3d3d3;\">");
      client.println F("Your browser does not support the HTML5 canvas tag.</canvas>");

      client.println F("<script>");
      client.println F("var c = document.getElementById(\"myCanvas\");");
      client.println F("var ctx = c.getContext(\"2d\");");

      for (int i = 0; i < 5 * max_graph_data - 2; i++)
      {
        client.print F("ctx.moveTo(");
        client.print(i * 4);
        client.print F(",");
        client.print(myGraphData[i] + 350);
        client.println F(");");
        client.print F("ctx.lineTo(");
        client.print((i + 1) * 4);
        client.print F(",");
        client.print(myGraphData[i + 1] + 350);
        client.println F(");");
        client.println F("ctx.stroke();");

        client.print F("ctx.moveTo(");
        client.print(i * 4);
        client.print F(",");
        client.print(br_Now(time_stamp[i]) );
        client.println F(");");
        client.print F("ctx.lineTo(");
        client.print((i + 1) * 4);
        client.print F(",");
        client.print(br_Now(time_stamp[i + 1]));
        client.println F(");");
        client.println F("ctx.stroke();");
      }
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




void loop() {
  if (sampleCount < 0)
  {
    if (bDoFlash)
    {
      collect_fERG_Data ();
    }
    else
    {
      collectSSVEPData ();
    }
  }
  // listen for incoming clients
  client = server.available();
  if (client) {
    Serial.println F("new client");
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
          bool pageNotServed = true ;
          Serial.print(MyInputString);
          if (!has_filesystem)
          {
            sendHeader F("Card not working");
            client.println F("SD Card failed");
            sendFooter();
            pageNotServed = false;
          }

          int fPOS = MyInputString.indexOf F("filename=");
          // asking for new sample
          //Serial.println("  Position of file was:" + String(fPOS));
          if (pageNotServed && fPOS > 0)
          {
            // save the commandline....
            MyInputString.toCharArray(cInput, MaxInputStr + 2);
            // now choose the colour
            int oldLED = usedLED ;
            if (MyInputString.indexOf F("col=blue&") > 0 ) usedLED  = bluLED ; //
            if (MyInputString.indexOf F("col=red&") > 0 ) usedLED  = redled ; //
            if (MyInputString.indexOf F("col=green&") > 0 ) usedLED  = grnled ; //
            //if (oldLED != usedLED) 
            goColour(0, 0, 0, false);

            //flash ERG or SSVEP?
            bDoFlash = MyInputString.indexOf F("stim=fERG&") > 0  ;

            //Serial.println F("saving ???");
            String sFile = MyInputString.substring(fPOS + 15); // ignore the leading / should be 9
            //Serial.println("  Position of filename= was:" + String(fPOS));
            //Serial.println(" Proposed saving filename " + sFile );
            fPOS = sFile.indexOf F(" ");  // or  & id filename is not the last paramtere
            //Serial.println("  Position of blankwas:" + String(fPOS));
            sFile = sFile.substring(0, fPOS);
            if (bDoFlash)
            {
              sFile = sFile + F(".ERG");
            }
            else
            {
              sFile = sFile + F(".SVP");
            }
            //Serial.println(" Proposed filename now" + sFile + ";");
            //if file exists... ????
            sFile.toCharArray(cFile, 29); // adds terminating null
            if (fileExists(cFile) &&  iThisContrast >= maxContrasts && nRepeats >= maxRepeats)
            {
              // done so tidy up
              nRepeats = 0 ; // ready to start again
              //file.timestamp(T_ACCESS, 2009, 11, 12, 7, 8, 9) ;
              file.close();

              sendHeader F("Sampling Complete!");
              client.println( "<A HREF= \"" + sFile + "\" >" + sFile + "</A>" + " Now Complete <BR><BR>");
#ifdef test_on_mac
              client.println F("Setup Next Test <A HREF=\"http://biolpc22.york.ac.uk/cje2/form04.html\"> form04.html</A> <BR><BR> ");
#else
              client.println F("Setup Next Test <A HREF=\"http://biolpc22.york.ac.uk/cje2/form.html\"> form.html</A> <BR><BR> ");
#endif
              client.println F( "<A HREF= \"dir=\"  > Full directory</A> <BR>");
              sendFooter ();
            }
            else
            {
              flickerPage();
              sampleCount = -102 ; //implies collectData();
            }
            pageNotServed = false ;
          }
          // show directory
          fPOS = MyInputString.indexOf F("dir=");
          //Serial.println("  Position of dir was:" + String(fPOS));
          if (pageNotServed && fPOS > 0)
          {
            serve_dir() ;
            pageNotServed = false ;
          }

          //light up
          fPOS = MyInputString.indexOf F("white/");
          //Serial.println("  Position of dir was:" + String(fPOS));
          if (pageNotServed && fPOS > 0)
          {
            goColour(255, 255, 255, true) ;
            pageNotServed = false ;
          }
          fPOS = MyInputString.indexOf F("red/");
          //Serial.println("  Position of dir was:" + String(fPOS));
          if (pageNotServed && fPOS > 0)
          {
            goColour(255, 0, 0, true) ;
            pageNotServed = false ;
          }
          fPOS = MyInputString.indexOf F("blue/");
          //Serial.println("  Position of dir was:" + String(fPOS));
          if (pageNotServed && fPOS > 0)
          {
            goColour(0, 0, 255, true) ;
            pageNotServed = false ;
          }
          fPOS = MyInputString.indexOf F("green/");
          //Serial.println("  Position of dir was:" + String(fPOS));
          if (pageNotServed && fPOS > 0)
          {
            goColour(0, 255, 0, true) ;
            pageNotServed = false ;
          }
          fPOS = MyInputString.indexOf F("black/");
          //Serial.println("  Position of dir was:" + String(fPOS));
          if (pageNotServed && fPOS > 0)
          {
            goColour(0, 0, 0, true) ;
            pageNotServed = false ;
          }

          //          // get date
          //          fPOS = MyInputString.indexOf("date=");
          //          //Serial.println("  Position of dir was:" + String(fPOS));
          //          if (pageNotServed && fPOS > 0)
          //          {
          //            getDate () ;
          //            pageNotServed = false ;
          //          }


          fPOS = MyInputString.indexOf F(".SVP");
          if (fPOS == -1)
          {
            fPOS = MyInputString.indexOf F(".ERG");
          }
          //Serial.println("  Position of .SVP was:" + String(fPOS));
          if (pageNotServed && fPOS > 0)
          {
            // requested a file...
            fPOS = MyInputString.indexOf F("/");
            String sFile = MyInputString.substring(fPOS + 1); // ignore the leading /
            //Serial.println(" Proposed filename " + sFile );
            fPOS = sFile.indexOf(" ");
            sFile = sFile.substring(0, fPOS);
            //Serial.println(" Proposed filename now" + sFile + ";");
            sFile.toCharArray(cFile, 29); // adds terminating null
            doreadFile(cFile) ;
            pageNotServed = false ;

          }
          if (pageNotServed)
          {
            run_graph() ;
          }
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

