
#define test_on_mac

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


//
int usedLED  = 0;
const int redled = 5;
const int grnled = 6;
const int bluLED = 7;
const int BledPin = 9;// 9 for normal blue diode
const int analogPin = 1 ;

const byte maxContrasts = 9 ;
const byte F2contrastchange = 4;
const float F1contrast[] = {
  5.0, 10.0, 30.0, 70.0, 100.0,  5.0, 10.0, 30.0, 70.0
};
const float F2contrast[] = {
  0.0, 30.0
};
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
  digitalWrite(SS_ETHERNET, LOW); // HIGH means Ethernet not active


  // Open serial communications and wait for port to open:
  Serial.begin(38400);
  while (!Serial) {
    ; // wait for serial port to connect. Needed for Leonardo only
  }
  myGraphData = erg_in ;
  for (int i = 0; i < max_graph_data; i++)
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

  goBlack ();

  doShuffle();
}

void goBlack()
{
  analogWrite( redled, 0 );
  analogWrite( grnled, 0 );
  analogWrite( bluLED, 0 );
  analogWrite( BledPin, 0 );
}

void goWhite()
{
  analogWrite( redled, 255 );
  analogWrite( grnled, 255 );
  analogWrite( bluLED, 255 );
  analogWrite( BledPin, 255 );
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


void sendHeader (const String & sTitle, bool isHTML = true)
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
    client.println F("<body>");
  }
}

void sendFooter()
{
  client.println F("</body></html>");
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
  goBlack();

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
  for (int i = 0; i < max_graph_data - 2; i++)
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
    client.println F("ctx.stroke();");
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
    //if (flags & LS_DATE) {
    root.printFatDate(p.lastWriteDate);
    client.print(' XX ');
    root.printFatTime(p.lastWriteTime);
    //}
    // print size if requested
    /*if (!DIR_IS_SUBDIR(&p) && (flags & LS_SIZE))*/ {
      client.print(' ');
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
  return int(sin((t / 1000.0) * PI * 2.0 * double(freq1)) * 1.270 * F1contrast[randomnumber] + sin((t / 1000.0) * PI * 2.0 * double(freq2)) * 1.270 * F2contrast[F2index]) + 127;
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

    iBytesWritten = file.write(cInput, MaxInputStr + 2);
    if (iBytesWritten <= 0)
    {
      Serial.println F ("Error in writing header to file");
      file.close();
      return ;
    }

    iBytesWritten = file.write(contrastOrder, maxContrasts * sizeof(int));
    if (iBytesWritten <= 0)
    {
      Serial.println F ("Error in writing contrast data to file");
      file.close();
      return ;
    }

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


  // always write the erg and time data
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

  sendHeader(String(c),  false);
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
      for (int i = 0; i < maxContrasts; i++)
      {
        cPtr = (char *) time_stamp ;
        // save space, put the floats as strings in the time_stamp buffer
        dataString = String(i);
        dataString += ", ";
        iOldContrast = erg_in [i];
        dataString += String(dtostrf(F1contrast[iOldContrast], 10, 2, cPtr));
        dataString += ", ";
        if (iOldContrast > F2contrastchange)
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
      for (int iC = 0; iC < maxContrasts; iC++)
      {
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

              dataString += String(time_stamp[i] - time_stamp[0]);
              dataString += ", ";

              dataString += String(br_Now(time_stamp[i]));
              dataString += ", ";

              dataString += String(erg_in[i]);
              //            dataString += "<BR>";

              client.println(dataString);
            } //for
          } // timing data ok
        } //erg data ok
      }
    } // contrasts ok
  }// header ok
  file.close();
  // sendFooter();
}

void collectData ()
{
  const long presamples = 102;
  long mean = 0;
  if (iThisContrast == 0 && file.isOpen()) file.close();

  if (iThisContrast >= maxContrasts) iThisContrast = 0;

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
      if (sampleCount == 0)
      {
        mean = mean / presamples ;
      }
      if (sampleCount >= 0)
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
      analogWrite(usedLED, intensity);

      sampleCount ++ ;
    }
  }
  // now done with sampling....
  sampleCount ++ ;
  analogWrite(usedLED, 127);
  iThisContrast ++;

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

  sendHeader("Sampling");

  if (iThisContrast < maxContrasts)
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
    client.println ("Acquired " + String(iThisContrast) + " data blocks so far <BR>" );
    client.println (cInput);
    client.println F( "<BR> ");// retrieve the flicker rates we sampled with...


  int randomnumber = contrastOrder[iThisContrast];
  int F2index = 0 ;
  if (randomnumber > F2contrastchange) F2index = 1;
  
    client.println("Data will flicker at " + String(freq1) + " Hz with contrast " + String(F1contrast[randomnumber]) +
                   " and " + String(freq2) + " Hz with contrast " + String(F2contrast[F2index]) + " % <BR> " );

    client.println("please wait....<BR>");
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
        client.print("ctx.moveTo(");
        client.print(i * 4);
        client.print(",");
        client.print(myGraphData[i] + 350);
        client.println F(");");
        client.print("ctx.lineTo(");
        client.print((i + 1) * 4);
        client.print(",");
        client.print(myGraphData[i + 1] + 350);
        client.println F(");");
        client.println F("ctx.stroke();");

        client.print("ctx.moveTo(");
        client.print(i * 4);
        client.print(",");
        client.print(br_Now(time_stamp[i]) );
        client.println F(");");
        client.print("ctx.lineTo(");
        client.print((i + 1) * 4);
        client.print(",");
        client.print(br_Now(time_stamp[i + 1]));
        client.println F(");");
        client.println F("ctx.stroke();");
      }
      client.println F("</script>");
      iThisContrast ++ ;
    }
  }

  for (int i = iThisContrast - 1; i > -1 ; i--)
  {
    int randomnumber = contrastOrder[i];
  int F2index = 0 ;
  if (randomnumber > F2contrastchange) F2index = 1;
  
    client.println("<BR>Data has been flickered at " + String(freq1) + " Hz with contrast " + String(F1contrast[randomnumber]) +
                   " and " + String(freq2) + " Hz with contrast " + String(F2contrast[F2index]) + " %  " );
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
            MyInputString.toCharArray(cInput, MaxInputStr + 2);
            // now choose the colour
            int oldLED = usedLED ;
            if (MyInputString.indexOf("colour=blue&") > 0 ) usedLED  = BledPin ; //
            if (MyInputString.indexOf("colour=blue (K)&") > 0 ) usedLED  = bluLED ; //
            if (MyInputString.indexOf("colour=red&") > 0 ) usedLED  = redled ; //
            if (MyInputString.indexOf("colour=green&") > 0 ) usedLED  = grnled ; //
            if (oldLED != usedLED) goBlack ();

            //Serial.println F("saving ???");
            String sFile = MyInputString.substring(fPOS + 15); // ignore the leading / should be 9
            //Serial.println("  Position of filename= was:" + String(fPOS));
            //Serial.println(" Proposed saving filename " + sFile );
            fPOS = sFile.indexOf(" ");  // or  & id filename is not the last paramtere
            //Serial.println("  Position of blankwas:" + String(fPOS));
            sFile = sFile.substring(0, fPOS);
            sFile = sFile + ".SVP";
            //Serial.println(" Proposed filename now" + sFile + ";");
            //if file exists... ????
            sFile.toCharArray(cFile, 29); // adds terminating null
            if (fileExists(cFile) &&  iThisContrast >= maxContrasts)
            {
              // done so tidy up
              iThisContrast = 0 ; // ready to start again
              file.close();

              sendHeader ("Sampling Complete!");
              client.println( "<A HREF= \"" + sFile + "\" >" + sFile + "</A>" + " Now Complete <BR>");
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
            pageServed = true ;
          }
          // show directory
          fPOS = MyInputString.indexOf("dir=");
          //Serial.println("  Position of dir was:" + String(fPOS));
          if (fPOS > 0)
          {
            serve_dir() ;
            pageServed = true ;
          }
          else
          {
            fPOS = MyInputString.indexOf(".SVP");
            //Serial.println("  Position of .SVP was:" + String(fPOS));
            if (fPOS > 0)
            {
              // requested a file...
              fPOS = MyInputString.indexOf("/");
              String sFile = MyInputString.substring(fPOS + 1); // ignore the leading /
              //Serial.println(" Proposed filename " + sFile );
              fPOS = sFile.indexOf(" ");
              sFile = sFile.substring(0, fPOS);
              //Serial.println(" Proposed filename now" + sFile + ";");
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

