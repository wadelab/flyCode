

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
const int ledPin =  9;
const int analogPin = 1 ;

const byte maxContrasts = 9 ;
const byte F2contrastchange = 4; 
const float F1contrast[] = {
  5.0, 10.0, 30.0, 70.0, 100.0,  5.0, 10.0, 30.0, 70.0 }; 
const float F2contrast[] = {  
  0.0, 30.0 };
int contrastOrder[ maxContrasts ]; 
int iThisContrast = 0 ;

boolean has_filesystem = true;
Sd2Card card;
SdVolume volume;
SdFile root;
SdFile file;


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


//#define N_WAVE          1024    /* dimension of Sinewave[] */
//#define LOG2_N_WAVE     10      /* log2(N_WAVE) */
//#define N_LOUD          100     /* dimension of Loudampl[] */


const int MaxInputStr = 130 ;
String MyInputString = String(MaxInputStr+1);
char cFile [30];
char cInput [MaxInputStr+2] = "";



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
  myGraphData = erg_in ;
  for (int i =0; i < max_graph_data; i++)
  {
    myGraphData[i] = 0;    
  }


  pinMode(10, OUTPUT); // set the SS pin as an output (necessary!)
  digitalWrite(10, HIGH); // but turn off the W5100 chip!
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

  Serial.println F("Setting up the Ethernet card...\n");


  // start the Ethernet connection and the server:
  Ethernet.begin(mac);
  server.begin();
  Serial.print F("server is at ");
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
  randomSeed(analogRead(analogPin));
  int randomnumber = random(maxContrasts);
  int tmp ;

  for (int i = maxContrasts - 1; i > 0; i--)
  {
    int n = random(i + 1);
    //Swap(contrastOrder[i], contrastOrder[n]);
    tmp = contrastOrder[i];
    contrastOrder[n] = contrastOrder[i];
    contrastOrder[i] = tmp ;
  }
}


void sendHeader (bool isHTML = true)
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
    client.println F("<body>");
  }
}

void sendFooter()
{
  client.println F("</body></html>");
}


void serve_dir ()
{
  sendHeader();
  printDirectory(0) ; //LS_SIZE);
  sendFooter();
}

void run_graph()
{

  // read the value of  analog input pin and turn light on if in mid-stimulus...
  int sensorReading = analogRead(analogPin);
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

  sendHeader () ;
  client.println("<script>");

  // script to reload ...
  client.println F("var myVar = setInterval(function(){myTimer()}, 400);"); //mu sec
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
  for (int i=0; i < max_graph_data-2; i++)
  {
    client.print("ctx.moveTo("); 
    client.print(i*20); 
    client.print(","); 
    client.print(myGraphData[i]/2); 
    client.println F(");");
    client.print("ctx.lineTo("); 
    client.print((i+1)*20); 
    client.print(","); 
    client.print(myGraphData[i+1]/2); 
    client.println F(");");
    client.println F("ctx.stroke();");
  }
  //draw stimulus...
  client.print("ctx.moveTo(");
  client.print((max_graph_data /10)*20);
  client.print(",");
  client.print(30);
  client.println F(");");

  client.print("ctx.lineTo(");
  client.print(max_graph_data /2*20);
  client.print(",");
  client.print(30);
  client.println F(");");

  client.println F("ctx.strokeStyle=\"blue\";");
  //              client.println("ctx.lineWidth=5;");
  client.println F("ctx.stroke();");

  client.println F("</script>");
  client.println F("<BR><BR><button onclick=\"myStopFunction()\">Stop display</button>");
  client.println F("To run a flicker test please stop and then load <A HREF=\"http://biolpc22.york.ac.uk/cje2/form.html\"> form.html</A>  ");

  sendFooter();

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
    for (uint8_t i = 0; i < 11; i++) {
      if (p.name[i] == ' ') continue;
      if (i == 8) {
        client.print('.');
      }
      client.print(char(p.name[i]));
    }
    client.print("\">");

    // print file name with possible blank fill
    for (uint8_t i = 0; i < 11; i++) {
      if (p.name[i] == ' ') continue;
      if (i == 8) {
        client.print('.');
      }
      client.print(char(p.name[i]));
    }

    client.print("</a>");

    if (DIR_IS_SUBDIR(&p)) {
      client.print('/');
    }

    // print modify date/time if requested
    if (flags & LS_DATE) {
      root.printFatDate(p.lastWriteDate);
      client.print(' ');
      root.printFatTime(p.lastWriteTime);
    }
    // print size if requested
    if (!DIR_IS_SUBDIR(&p) && (flags & LS_SIZE)) {
      client.print(' ');
      client.print(p.fileSize);
    }
    client.println F("</li>");
  }
  client.println F("</ul>");
}


void serve_dummy()
{
  sendHeader();
  client.println F("Dummy page; <BR> To run a flicker test please load <A HREF=\"http://biolpc22.york.ac.uk/cje2/form.html\"> form.html</A>  ");
  sendFooter() ;
}

int br_Now(double t)
{
  int randomnumber = contrastOrder[iThisContrast];
  int F2index = 0 ;
  if (randomnumber > F2contrastchange) F2index = 1;
  return int(sin((t/1000.0)*PI*2.0*double(freq1))*1.270 * F1contrast[randomnumber] + sin((t/1000.0)*PI*2.0*double(freq2))*1.270 * F2contrast[F2index])+127;
}




void writeFile(const char * c)
{ 
  if (file.isOpen()) file.close();
  //overwrite any similar file
  if ( !file.open(root, c /*myName*/  , O_CREAT | O_APPEND | O_WRITE))
  {
    Serial.println F ("Error in opening file");
    Serial.println (c);
    return ;
  }
  int16_t iBytesWritten ;
  // file format
  //    MyInputString viz. char cInput [MaxInputStr+2];
  //    int contrastOrder[ maxContrasts ]; 
  //    unsigned int time_stamp [max_data] ;
  //    int erg_in [max_data];

  iBytesWritten = file.write(cInput, MaxInputStr+2);
  if (iBytesWritten < 0)
  {
    Serial.println F ("Error in writing header to file");
  }
  else
  {
    iBytesWritten = file.write(contrastOrder, maxContrasts * sizeof(int));
    if (iBytesWritten < 0)
    {
      Serial.println F ("Error in writing contrast data to file");
    }
    else
    {
      iBytesWritten = file.write(erg_in, max_data * sizeof(int));
      if (iBytesWritten < 0)
      {
        Serial.println F ("Error in writing erg data to file");
      }
      else
      {
        // Serial.println("File success: written bytes " + String(iBytesWritten));
        iBytesWritten = file.write(time_stamp, max_data * sizeof(unsigned int));
        if (iBytesWritten < 0)
        {
          Serial.println F ("Error in writing timing data to file");
        }
      }
    }
  }
  file.close();
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

  sendHeader(false);
  if (file.isOpen()) file.close();
  file.open(root, c, O_READ);
  int iBytesRequested, iBytesRead;
  // note this overwrites any data already in memeory...
  //first read the header string ...
  iBytesRequested = MaxInputStr+2;
  iBytesRead = file.read(cPtr, iBytesRequested);
  if (iBytesRead < iBytesRequested)
  {
    client.println F("Error reading header data in file ");
    client.println(c);
  }
  else
  {
    // write out the string ....
    client.print(cPtr);
    //    client.println F("<BR>");

    // now try the contrast table
    iBytesRequested = maxContrasts * sizeof(int);
    iBytesRead = file.read(erg_in, iBytesRequested);
    if (iBytesRead < iBytesRequested)
    {
      client.println F("Error reading contrast data in file ");
      client.println(c);
    }
    else
    {
      // write out the contast table
      for (int i=0; i < maxContrasts; i++)
      {
        cPtr = (char *) time_stamp ;
        // save space, put the floats as strings in the time_stamp buffer
        dataString = String(i);
        dataString += ", ";
        dataString += String(dtostrf(F1contrast[i], 10, 2, cPtr));
        dataString += ", ";
        if (i > F2contrastchange)
        {
          dataString += String(dtostrf(F2contrast[1], 10, 2, cPtr));
        }
        else
        {
          dataString += String(dtostrf(F2contrast[0], 10, 2, cPtr));
        }
        //      dataString += "<BR>";

        client.println(dataString);
      }

      // now on to the data
      int iBytesRequested = max_data * sizeof(int);
      int iBytesRead = file.read(erg_in, iBytesRequested);
      if (iBytesRead < iBytesRequested)
      {
        client.println F("Error reading ERG data in file ");
        client.println(c);
      }
      else
      {
        iBytesRequested = max_data * sizeof(unsigned int);
        iBytesRead = file.read (time_stamp, iBytesRequested );
        file.close();
        if (iBytesRead < iBytesRequested)
        {
          client.println F("Error reading Timing data in file ");
          client.println(c);
        } 
        else
        {
          for (int i = 0; i < max_data; i++)
          {
            // make a string for assembling the data to log:
            dataString = String(i);
            dataString += ", ";

            dataString += String(time_stamp[i]-time_stamp[0]);
            dataString += ", ";

            dataString += String(br_Now(time_stamp[i]));
            dataString += ", ";

            dataString += String(erg_in[i]);
            //            dataString += "<BR>";

            client.println(dataString);
          } //for
        } // timing data ok
      } //erg data ok
    } // contrasts ok
  }// header ok
 // sendFooter();
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
  iThisContrast ++;
  if (iThisContrast >= maxContrasts) iThisContrast = 0;

  writeFile(cFile);
  //  //destructive in place fft
  //  int imag_in [max_data];
  //  int real_in [max_data];
  //  for (int i=0; i < max_data; i++)
  //  {
  //    imag_in [i] = 0;
  //    real_in [i] = erg_in[i] ;
  //  }
  //  //  int iResult = fix_fft(real_in, imag_in, 10, 0 ); //2 ^ 10 1024

}

void flickerPage()
{
  Serial.println ("Sampling at :" + String(sampleCount));

  sendHeader();

  if (sampleCount < max_data)
  {
    client.println F("<script>");

    // script to reload ...
    client.println F("var myVar = setInterval(function(){myTimer()}, 4500);"); //mu sec
    client.println F("function myTimer() {");
    client.println F("location.reload(true);");
    client.println F("};");

    client.println F("function myStopFunction() {");
    client.println F("clearInterval(myVar); }");
    client.println F("");
    client.println F("</script>");
    client.println ("Acquiring, " + String(sampleCount) + " samples so far <BR>"  + MyInputString + "<BR> please wait....");

  }
  //  else
  //  {
  //    client.println("Acquired, " +  MyInputString + "<BR> Saved to ");
  //
  //    //    // retrieve the flicker rates we sampled with...
  //    int randomnumber = contrastOrder[iThisContrast];
  //    int F1 = int(F1contrast[randomnumber]);
  //    int F2 = int(F2contrast[randomnumber]);
  //    client.println("Data acquired at " + String(freq1) + " Hz with contrast " + String(F1) + 
  //      " and " + String(freq2) + " Hz with contrast " + String(F1) +" % <BR> " ); 
  //
  //  }


  //  }
  //  else
  //  {
  //    sendHeader();// false);
  //    // retrieve the flicker rates we sampled with...
  //    int randomnumber = contrastOrder[iThisContrast];
  //    int F1 = int(F1contrast[randomnumber]);
  //    int F2 = int(F2contrast[randomnumber]);
  //    client.println("Data acquired at " + String(freq1) + " Hz with contrast " + String(F1) + 
  //      " and " + String(freq2) + " Hz with contrast " + String(F1) +" % <BR> " ); 
  //    client.println(MyInputString + "<BR>");
  //    client.println("No, time, brightness, analog in <BR>");
  //    for (int i = 0; i < max_data; i++)
  //    {
  //      // make a string for assembling the data to log:
  //      String dataString = String(i);
  //      dataString += ", ";
  //
  //      dataString += String(time_stamp[i]-time_stamp[0]);
  //      dataString += ", ";
  //
  //      dataString += String(br_Now(time_stamp[i]));
  //      dataString += ", ";
  //
  //      dataString += String(erg_in[i]);
  //      dataString += "<BR>";
  //
  //      client.println(dataString);
  //    }
  //  }
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
          bool pageServed = false ;
          Serial.print(MyInputString); 
          int fPOS = MyInputString.indexOf("filename=");
          // asking for new sample
          Serial.println("  Position of file was:" + String(fPOS));
          if (fPOS > 0)
          {
            // save the commandline....
            MyInputString.toCharArray(cInput, MaxInputStr+2);

            //Serial.println F("saving ???");
            String sFile = MyInputString.substring(fPOS+15); // ignore the leading / should be 9
            //Serial.println("  Position of filename= was:" + String(fPOS));
            //Serial.println(" Proposed saving filename " + sFile );
            fPOS = sFile.indexOf(" ");  // or  & id filename is not the last paramtere
            //Serial.println("  Position of blankwas:" + String(fPOS));
            sFile = sFile.substring(0, fPOS);
            sFile = sFile + ".SVP";
            //Serial.println(" Proposed filename now" + sFile + ";");
            //if file exists... ????
            sFile.toCharArray(cFile, 29); // adds terminating null
            if (fileExists(cFile))
            {
              sendHeader ();
              client.println( "<A HREF= \"" + sFile + "\" >" + sFile + "</A>" + " Exists <BR>");
              client.println F( "<A HREF= \"dir=\"  > Full directory</A> <BR>");
              sendFooter ();
            }
            else
            {
              flickerPage(); 
              sampleCount = -102 ; //implies collectData(); 
            }
            pageServed = true ;
          }
          // show directory
          fPOS = MyInputString.indexOf("dir=");
          Serial.println("  Position of dir was:" + String(fPOS));
          if (fPOS > 0)
          {
            serve_dir() ;
            pageServed = true ;
          }   
          else
          {       
            fPOS = MyInputString.indexOf(".SVP");
            Serial.println("  Position of .SVP was:" + String(fPOS));
            if (fPOS > 0)
            {
              // requested a file...
              fPOS = MyInputString.indexOf("/");
              String sFile = MyInputString.substring(fPOS+1); // ignore the leading /
              Serial.println(" Proposed filename " + sFile );
              fPOS = sFile.indexOf(" ");
              sFile = sFile.substring(0, fPOS);
              Serial.println(" Proposed filename now" + sFile + ";");
              sFile.toCharArray(cFile, 29); // adds terminating null
              doreadFile(cFile) ;
              pageServed = true ;
            }
          }
          if (!pageServed)
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


//
///* -------------------------------------------
// **/
//#if N_WAVE != 1024
//ERROR: 
//N_WAVE != 1024
//#endif
//int PROGMEM Sinewave[1024] = {
//  0,    201,    402,    603,    804,   1005,   1206,   1406,
//  1607,   1808,   2009,   2209,   2410,   2610,   2811,   3011,
//  3211,   3411,   3611,   3811,   4011,   4210,   4409,   4608,
//  4807,   5006,   5205,   5403,   5601,   5799,   5997,   6195,
//  6392,   6589,   6786,   6982,   7179,   7375,   7571,   7766,
//  7961,   8156,   8351,   8545,   8739,   8932,   9126,   9319,
//  9511,   9703,   9895,  10087,  10278,  10469,  10659,  10849,
//  11038,  11227,  11416,  11604,  11792,  11980,  12166,  12353,
//  12539,  12724,  12909,  13094,  13278,  13462,  13645,  13827,
//  14009,  14191,  14372,  14552,  14732,  14911,  15090,  15268,
//  15446,  15623,  15799,  15975,  16150,  16325,  16499,  16672,
//  16845,  17017,  17189,  17360,  17530,  17699,  17868,  18036,
//  18204,  18371,  18537,  18702,  18867,  19031,  19194,  19357,
//  19519,  19680,  19840,  20000,  20159,  20317,  20474,  20631,
//  20787,  20942,  21096,  21249,  21402,  21554,  21705,  21855,
//  22004,  22153,  22301,  22448,  22594,  22739,  22883,  23027,
//  23169,  23311,  23452,  23592,  23731,  23869,  24006,  24143,
//  24278,  24413,  24546,  24679,  24811,  24942,  25072,  25201,
//  25329,  25456,  25582,  25707,  25831,  25954,  26077,  26198,
//  26318,  26437,  26556,  26673,  26789,  26905,  27019,  27132,
//  27244,  27355,  27466,  27575,  27683,  27790,  27896,  28001,
//  28105,  28208,  28309,  28410,  28510,  28608,  28706,  28802,
//  28897,  28992,  29085,  29177,  29268,  29358,  29446,  29534,
//  29621,  29706,  29790,  29873,  29955,  30036,  30116,  30195,
//  30272,  30349,  30424,  30498,  30571,  30643,  30713,  30783,
//  30851,  30918,  30984,  31049,
//  31113,  31175,  31236,  31297,
//  31356,  31413,  31470,  31525,  31580,  31633,  31684,  31735,
//  31785,  31833,  31880,  31926,  31970,  32014,  32056,  32097,
//  32137,  32176,  32213,  32249,  32284,  32318,  32350,  32382,
//  32412,  32441,  32468,  32495,  32520,  32544,  32567,  32588,
//  32609,  32628,  32646,  32662,  32678,  32692,  32705,  32717,
//  32727,  32736,  32744,  32751,  32757,  32761,  32764,  32766,
//  32767,  32766,  32764,  32761,  32757,  32751,  32744,  32736,
//  32727,  32717,  32705,  32692,  32678,  32662,  32646,  32628,
//  32609,  32588,  32567,  32544,  32520,  32495,  32468,  32441,
//  32412,  32382,  32350,  32318,  32284,  32249,  32213,  32176,
//  32137,  32097,  32056,  32014,  31970,  31926,  31880,  31833,
//  31785,  31735,  31684,  31633,  31580,  31525,  31470,  31413,
//  31356,  31297,  31236,  31175,  31113,  31049,  30984,  30918,
//  30851,  30783,  30713,  30643,  30571,  30498,  30424,  30349,
//  30272,  30195,  30116,  30036,  29955,  29873,  29790,  29706,
//  29621,  29534,  29446,  29358,  29268,  29177,  29085,  28992,
//  28897,  28802,  28706,  28608,  28510,  28410,  28309,  28208,
//  28105,  28001,  27896,  27790,  27683,  27575,  27466,  27355,
//  27244,  27132,  27019,  26905,  26789,  26673,  26556,  26437,
//  26318,  26198,  26077,  25954,  25831,  25707,  25582,  25456,
//  25329,  25201,  25072,  24942,  24811,  24679,  24546,  24413,
//  24278,  24143,  24006,  23869,  23731,  23592,  23452,  23311,
//  23169,  23027,  22883,  22739,  22594,  22448,  22301,  22153,
//  22004,  21855,  21705,  21554,  21402,  21249,  21096,  20942,
//  20787,  20631,  20474,  20317,  20159,  20000,  19840,  19680,
//  19519,  19357,  19194,  19031,  18867,  18702,  18537,  18371,
//  18204,  18036,  17868,  17699,  17530,  17360,  17189,  17017,
//  16845,  16672,  16499,  16325,  16150,  15975,  15799,  15623,
//  15446,  15268,  15090,  14911,  14732,  14552,  14372,  14191,
//  14009,  13827,  13645,  13462,  13278,  13094,  12909,  12724,
//  12539,  12353,  12166,  11980,  11792,  11604,  11416,  11227,
//  11038,  10849,  10659,  10469,  10278,  10087,   9895,   9703,
//  9511,   9319,   9126,   8932,   8739,   8545,   8351,   8156,
//  7961,   7766,   7571,   7375,   7179,   6982,   6786,   6589,
//  6392,   6195,   5997,   5799,   5601,   5403,   5205,   5006,
//  4807,   4608,   4409,   4210,   4011,   3811,   3611,   3411,
//  3211,   3011,   2811,   2610,   2410,   2209,   2009,   1808,
//  1607,   1406,   1206,   1005,    804,    603,    402,    201,
//  0,   -201,   -402,   -603,   -804,  -1005,  -1206,  -1406,
//  -1607,  -1808,  -2009,  -2209,  -2410,  -2610,  -2811,  -3011,
//  -3211,  -3411,  -3611,  -3811,  -4011,  -4210,  -4409,  -4608,
//  -4807,  -5006,  -5205,  -5403,  -5601,  -5799,  -5997,  -6195,
//  -6392,  -6589,  -6786,  -6982,  -7179,  -7375,  -7571,  -7766,
//  -7961,  -8156,  -8351,  -8545,  -8739,  -8932,  -9126,  -9319,
//  -9511,  -9703,  -9895, -10087, -10278, -10469, -10659, -10849,
//  -11038, -11227, -11416, -11604, -11792, -11980, -12166, -12353,
//  -12539, -12724, -12909, -13094, -13278, -13462, -13645, -13827,
//  -14009, -14191, -14372, -14552, -14732, -14911, -15090, -15268,
//  -15446, -15623, -15799, -15975, -16150, -16325, -16499, -16672,
//  -16845, -17017, -17189, -17360, -17530, -17699, -17868, -18036,
//  -18204, -18371, -18537, -18702, -18867, -19031, -19194, -19357,
//  -19519, -19680, -19840, -20000, -20159, -20317, -20474, -20631,
//  -20787, -20942, -21096, -21249, -21402, -21554, -21705, -21855,
//  -22004, -22153, -22301, -22448, -22594, -22739, -22883, -23027,
//  -23169, -23311, -23452, -23592, -23731, -23869, -24006, -24143,
//  -24278, -24413, -24546, -24679, -24811, -24942, -25072, -25201,
//  -25329, -25456, -25582, -25707, -25831, -25954, -26077, -26198,
//  -26318, -26437, -26556, -26673, -26789, -26905, -27019, -27132,
//  -27244, -27355, -27466, -27575, -27683, -27790, -27896, -28001,
//  -28105, -28208, -28309, -28410, -28510, -28608, -28706, -28802,
//  -28897, -28992, -29085, -29177, -29268, -29358, -29446, -29534,
//  -29621, -29706, -29790, -29873, -29955, -30036, -30116, -30195,
//  -30272, -30349, -30424, -30498, -30571, -30643, -30713, -30783,
//  -30851, -30918, -30984, -31049, -31113, -31175, -31236, -31297,
//  -31356, -31413, -31470, -31525, -31580, -31633, -31684, -31735,
//  -31785, -31833, -31880, -31926, -31970, -32014, -32056, -32097,
//  -32137, -32176, -32213, -32249, -32284, -32318, -32350, -32382,
//  -32412, -32441, -32468, -32495, -32520, -32544, -32567, -32588,
//  -32609, -32628, -32646, -32662, -32678, -32692, -32705, -32717,
//  -32727, -32736, -32744, -32751, -32757, -32761, -32764, -32766,
//  -32767, -32766, -32764, -32761, -32757, -32751, -32744, -32736,
//  -32727, -32717, -32705, -32692, -32678, -32662, -32646, -32628,
//  -32609, -32588, -32567, -32544, -32520, -32495, -32468, -32441,
//  -32412, -32382, -32350, -32318, -32284, -32249, -32213, -32176,
//  -32137, -32097, -32056, -32014, -31970, -31926, -31880, -31833,
//  -31785, -31735, -31684, -31633, -31580, -31525, -31470, -31413,
//  -31356, -31297, -31236, -31175, -31113, -31049, -30984, -30918,
//  -30851, -30783, -30713, -30643, -30571, -30498, -30424, -30349,
//  -30272, -30195, -30116, -30036, -29955, -29873, -29790, -29706,
//  -29621, -29534, -29446, -29358, -29268, -29177, -29085, -28992,
//  -28897, -28802, -28706, -28608, -28510, -28410, -28309, -28208,
//  -28105, -28001, -27896, -27790, -27683, -27575, -27466, -27355,
//  -27244, -27132, -27019, -26905, -26789, -26673, -26556, -26437,
//  -26318, -26198, -26077, -25954, -25831, -25707, -25582, -25456,
//  -25329, -25201, -25072, -24942, -24811, -24679, -24546, -24413,
//  -24278, -24143, -24006, -23869, -23731, -23592, -23452, -23311,
//  -23169, -23027, -22883, -22739, -22594, -22448, -22301, -22153,
//  -22004, -21855, -21705, -21554, -21402, -21249, -21096, -20942,
//  -20787, -20631, -20474, -20317, -20159, -20000, -19840, -19680,
//  -19519, -19357, -19194, -19031, -18867, -18702, -18537, -18371,
//  -18204, -18036, -17868, -17699, -17530, -17360, -17189, -17017,
//  -16845, -16672, -16499, -16325, -16150, -15975, -15799, -15623,
//  -15446, -15268, -15090, -14911, -14732, -14552, -14372, -14191,
//  -14009, -13827, -13645, -13462, -13278, -13094, -12909, -12724,
//  -12539, -12353, -12166, -11980, -11792, -11604, -11416, -11227,
//  -11038, -10849, -10659, -10469, -10278, -10087,  -9895,  -9703,
//  -9511,  -9319,  -9126,  -8932,  -8739,  -8545,  -8351,  -8156,
//  -7961,  -7766,  -7571,  -7375,  -7179,  -6982,  -6786,  -6589,
//  -6392,  -6195,  -5997,  -5799,  -5601,  -5403,  -5205,  -5006,
//  -4807,  -4608,  -4409,  -4210,  -4011,  -3811,  -3611,  -3411,
//  -3211,  -3011,  -2811,  -2610,  -2410,  -2209,  -2009,  -1808,
//  -1607,  -1406,  -1206,  -1005,   -804,   -603,   -402,   -201,
//};
//
//
//
///** Return an integer indexed into the Sinewave table in flash */
//int getSinewave(int index) {
//  int val;
//
//  // Get the value from the flash memory
//  memcpy_P(&val, &Sinewave[index], sizeof(int));
//  return val;
//}
//
///**  fix_mpy() - fixed-point multiplication */
//int fix_mpy(int a, int b) {
//  return ((long)(a) * (long)(b))>>15;
//}
//
//
//
//
///** fix_fft() - perform fast Fourier transform. */
//int fix_fft(int fr[], int fi[], int m, int inverse) {
//  // fr[n],fi[n] are real,imaginary arrays, INPUT AND RESULT.
//  // size of data = 2**m
//  // set inverse to 0=dft, 1=idft
//
//  int mr, nn, i, j, l, k, istep, n, scale, shift;
//  int qr, qi, tr, ti, wr, wi;
//
//  n = 1<<m;
//
//  if(n > N_WAVE)
//    return -1;
//
//  mr = 0;
//  nn = n - 1;
//  scale = 0;
//
//  // decimation in time - re-order data
//  for(m=1; m<=nn; ++m) {
//    l = n;
//    do {
//      l >>= 1;
//    } 
//    while(mr+l > nn);
//    mr = (mr & (l-1)) + l;
//
//    if(mr <= m) continue;
//    tr = fr[m];
//    fr[m] = fr[mr];
//    fr[mr] = tr;
//    ti = fi[m];
//    fi[m] = fi[mr];
//    fi[mr] = ti;
//  }
//
//  l = 1;
//  k = LOG2_N_WAVE-1;
//  while(l < n) {
//    if(inverse) {
//      // variable scaling, depending upon data
//      shift = 0;
//      for(i=0; i<n; ++i) {
//        j = fr[i];
//        if(j < 0) j = -j;
//        m = fi[i];
//        if(m < 0) m = -m;
//        if(j > 16383 || m > 16383) {
//          shift = 1;
//          break;
//        }
//      }
//      if(shift)
//        ++scale;
//    }
//    else {
//      // fixed scaling, for proper normalization -
//      // there will be log2(n) passes, so this
//      // results in an overall factor of 1/n,
//      // distributed to maximize arithmetic accuracy.
//      shift = 1;
//    }
//    // it may not be obvious, but the shift will be performed
//    // on each data point exactly once, during this pass.
//    istep = l << 1;
//    for(m=0; m<l; ++m) {
//      j = m << k;
//      // 0 <= j < N_WAVE/2
//      wr =  getSinewave(j+N_WAVE/4);
//      wi = -getSinewave(j);
//      if(inverse) wi = -wi;
//      if(shift) {
//        wr >>= 1;
//        wi >>= 1;
//      }
//      for(i=m; i<n; i+=istep) {
//        j = i + l;
//        tr = fix_mpy(wr, fr[j]) - fix_mpy(wi, fi[j]);
//        ti = fix_mpy(wr, fi[j]) + fix_mpy(wi, fr[j]);
//        qr = fr[i];
//        qi = fi[i];
//        if(shift) {
//          qr >>= 1;
//          qi >>= 1;
//        }
//        fr[j] = qr - tr;
//        fi[j] = qi - ti;
//        fr[i] = qr + tr;
//        fi[i] = qi + ti;
//      }
//    }
//    --k;
//    l = istep;
//  }
//  return scale;
//}
//
//
//












