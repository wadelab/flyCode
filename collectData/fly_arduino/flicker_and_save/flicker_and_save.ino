#include <Time.h>

/*
fly test : grey wire to GND, purple to pin 9
black wire to GND, white wire to pin 1 of analog in
*/

/*
  SD card test

 This example shows how use the utility libraries on which the'
 SD library is based in order to get info about your SD card.
 Very useful for testing a card when you're not sure whether its working or not.

 The circuit:
  * SD card attached to SPI bus as follows:
 ** MOSI - pin 11 on Arduino Uno/Duemilanove/Diecimila
 ** MISO - pin 12 on Arduino Uno/Duemilanove/Diecimila
 ** CLK - pin 13 on Arduino Uno/Duemilanove/Diecimila
 ** CS - depends on your SD card shield or module.
 	Pin 4 used here for consistency with other Arduino examples

 created  28 Mar 2011
 by Limor Fried
 modified 9 Apr 2012
 by Tom Igoe
 */
 // include the SD library:

#include <Arduino.h>
#include <Time.h>
#include <SD.h>

// change this to match your SD shield or module;
// Arduino Ethernet shield: pin 4
// Adafruit SD shields and modules: pin 10
// Sparkfun SD shield: pin 8
const int chipSelect = 4;
const int ledPin =  9;      // the number of the LED pin
const int analogPin = 1 ;
double freq = 5.0 ; // Hz for stimulus
const char comma = ',';
const char underscore = '_';
const int max_data = 1024 ;

String inputString = "";         // a string to hold incoming data
boolean stringComplete = false;  // whether the string is complete

unsigned int sampleCount = 0;        // will store number of A/D samples taken
unsigned int timing_errors = 0;
long interval = 10;                   // interval (10 ms is ok) at which to sample
unsigned long last_time = 0; 
unsigned long now_time ;
char sFileName [14] ;

		  // make a structure for assembling the data to log:
struct data_struct 
{
  unsigned int iCount;      // bytes 2
  char c1  ;         // 1
  unsigned int analog_data; // 2
  char c2  ;         // 1
  unsigned int brightness;  // 2
  char c3  ;         // 1
  unsigned long event_time; // 4 
  char c4  ;         // 1 total 14
};

union{
        data_struct data;
        byte b[14];
      } uData;
      
File dataFile ;

void sFileNow()
{
  // this time is always zero...
  time_t tt = now();
  String sTime ;
  sTime += month(tt);
  sTime += underscore ;
  sTime += day(tt);
  sTime += underscore ;
  sTime += hour(tt);
  sTime += 'h' ;
  sTime += minute(tt);
  sTime += "m.dat" ;
  sTime.toCharArray(sFileName,13);
  sFileName[sTime.length()+1] = 0;
  Serial.println (sTime);
  return ;
  }

void setup()
{
 // Open serial communications and wait for port to open:
  Serial.begin(38400);
   while (!Serial) 
   {
    ; // wait for serial port to connect. Needed for Leonardo only
  }
 
  // open the file. note that only one file can be open at a time,
  // so you have to close this one before opening another.
  Serial.println("Initializing SD card...");
  // On the Ethernet Shield, CS is pin 4. It's set as an output by default.
  // Note that even if it's not used as the CS pin, the hardware SS pin 
  // (10 on most Arduino boards, 53 on the Mega) must be left as an output 
  // or the SD library functions will not work. 
   pinMode(10, OUTPUT);
   
  if (!SD.begin(4)) 
  {
    Serial.println("initialization failed!");
    return;
  }
  
 File root = SD.open("/");
  printDirectory(root, 0);
  root.close();
  Serial.println("directrory tree done!");
  Serial.print("File will be : ");
  Serial.println(sFileName);

  
  
  sFileNow();
  // if file exists this will append to it
  SD.remove(sFileName);
  dataFile = SD.open(sFileName, FILE_WRITE);

  if (dataFile)
  {
    Serial.println("opened file successfully");
    dataFile.println("No, analog in, brightness, time");
  }
  // if the file isn't open, pop up an error:
  else 
  {
    Serial.println("error opening file");
  } 
// store commas only once  
uData.data.c1 = comma ;
uData.data.c2 = comma ;
uData.data.c3 = comma ;
uData.data.c4 = comma ;
}

//***********************************************************************************************************
void printDirectory(File dir, int numTabs) {
   while(true) {
     
     File entry =  dir.openNextFile();
     if (! entry) {
       // no more files
       //Serial.println("**nomorefiles**");
       break;
     }
     for (uint8_t i=0; i<numTabs; i++) {
       Serial.print('\t');
     }
     Serial.print(entry.name());
     if (entry.isDirectory()) {
       Serial.println("/");
       printDirectory(entry, numTabs+1);
     } else {
       // files have sizes, directories do not
       Serial.print("\t\t");
       Serial.println(entry.size(), DEC);
     }
     entry.close();
   }
}

//***************************************************************************************************

void ReadOutFile1()
{
    File ReadFile = SD.open(sFileName);

  // if the file is available, write to it:
  if (ReadFile) {
    while (ReadFile.available()) 
	{
      Serial.write(ReadFile.read());
    }
    ReadFile.close();
  }  
  // if the file isn't open, pop up an error:
  else 
  {
    Serial.println("error opening datalog.txt");
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

void ReadOutFile()
{
        
   int lf = 10;
    char hdr[80];
    
    File ReadFile = SD.open(sFileName);

  // if the file is available, write to it:
  if (ReadFile) {
    //read the header

    int iRead = ReadFile.readBytesUntil(lf, hdr, 80);
    hdr[iRead] = '\0';
   // ReadFile.seek(ReadFile.position());
    
    Serial.println(hdr);
    // now read the rest of the file
    while (ReadFile.available()) 
	{
          for (int i = 0; i <3; i++)
            {
         //hi, lo, comma
         int iTmp = ReadInt (ReadFile);
              Serial.print(iTmp);
              Serial.print(comma);
              }
                 //hi, lo, hi, lo, comma 4 bytes...
              Serial.print(ReadUL (ReadFile));
              Serial.print(comma);      
              Serial.println ();
    }
    ReadFile.close();
  }  
  // if the file isn't open, pop up an error:
  else 
  {
    Serial.println("error opening datalog.txt");
  } 
}

//***************************************************************************************************


void loop(void) 
{
if (stringComplete)
{
  sampleCount = 0; // so run it all again  
  stringComplete = false ;
}

if (sampleCount >= 0 && dataFile) //not really sure what to do if datafile has died...
	{
	  unsigned long now_time = millis();
	  if (now_time < last_time + interval)
          {
            timing_errors ++ ;
          }
          else
          {
	  if (sampleCount < max_data)
		  {
			// Initial test showed it could write this to the card at 12 ms intervals
		  sampleCount ++ ;
		  last_time = now_time ;
			

                         
                        uData.data.iCount = sampleCount;			
		  // read  sensor and append to the structure:
			uData.data.analog_data = analogRead(analogPin);
	
			uData.data.brightness=int(sin((double(now_time)/1000.0)*PI*2.0*freq)*127.0+127.0);
			analogWrite(ledPin, uData.data.brightness);
                        uData.data.event_time = now_time ;

                         dataFile.write(uData.b, 14);
		         dataFile.flush();
		   
		  } //end of doing a sample
	  if (sampleCount == max_data)
                {
                  sampleCount ++ ;
                  dataFile.flush();
                  analogWrite(ledPin, 127); // or whatever the intermediate value should be    
                  String sTmp = "DAQ done, timin errors were " ;
                  sTmp += timing_errors ;
                  Serial.println(sTmp) ;
                }

	  } 
	}
}

/*
  SerialEvent occurs whenever a new data comes in the
 hardware serial RX.  This routine is run between each
 time loop() runs, so using delay inside loop can delay
 response.  Multiple bytes of data may be available.
 */
 // It reads up to a newline...
void serialEvent() 
{
  while (Serial.available()) 
  {
    // get the new byte:
    char inChar = (char)Serial.read();
    // add it to the inputString:
    inputString += inChar;
    // if the incoming character is a newline, set a flag
    // so the main loop can do something about it:    
    stringComplete = true;

    switch (inChar) 
    {
       case '1':
       freq = 1 ;
       break ;
       
       case '2':
       freq = 2 ;
       break ;
       
       case '3':
       freq = 4 ;
       break ;
       
       case '4':
       freq = 8 ;
       break ;
       
       case 'D':
       dataFile.close();
       ReadOutFile1();
       stringComplete = false ;
       break ;
     
       case 'R':
       dataFile.close();
       ReadOutFile();
       stringComplete = false ;
       break ;
            
    }

  }
}

