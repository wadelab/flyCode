
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
#include <SD.h>
#include <Arduino.h>


// change this to match your SD shield or module;
// Arduino Ethernet shield: pin 4
// Adafruit SD shields and modules: pin 10
// Sparkfun SD shield: pin 8
const int chipSelect = 4;
const int ledPin =  9;      // the number of the LED pin
const int analogPin = 1 ;
int freq = 16 ; // flicker of LED Hz
const int max_data = 1024;

// this version compiles, but fails to start if max_data > 150
// see http://forum.arduino.cc/index.php/topic,41062.0.html
// out of memory error
unsigned int time_stamp [max_data] ;
int erg_in [max_data];

String inputString = "";         // a string to hold incoming data
boolean stringComplete = false;  // whether the string is complete

long sampleCount = 0;        // will store number of A/D samples taken
long interval = 2;           // interval (5ms) at which to - 2 ms is also ok in this version
unsigned long last_time = 0; 
unsigned long loop_start_time = 0; 
unsigned long now_time ;
unsigned long timing_too_fast = 0 ;

File dataFile ;

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
  Serial.println("Init SD.");
  // On the Ethernet Shield, CS is pin 4. It's set as an output by default.
  // Note that even if it's not used as the CS pin, the hardware SS pin 
  // (10 on most Arduino boards, 53 on the Mega) must be left as an output 
  // or the SD library functions will not work. 
   pinMode(10, OUTPUT);
   
  if (!SD.begin(4)) 
  {
    Serial.println("bad SD!");
    return;
  }
  
 File root = SD.open("/");
  printDirectory(root, 0);
  root.close();
  Serial.println("dir tree done!");
  
  // if file exists this will append to it
  SD.remove("datalog.txt");
  dataFile = SD.open("datalog.txt", FILE_WRITE);

  if (dataFile)
  {
    Serial.println("opened datafile");
    dataFile.println("No, time, analog in, brightness");
  }
  // if the file isn't open, pop up an error:
  else 
  {
    Serial.println("error opening datalog.txt");
  } 
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
void ReadOutFile()
{
    File ReadFile = SD.open("datalog.txt");

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

//***************************************************************************************************

int br_now (unsigned long t)
{
  if ( t < max_data/8) return 0;
  if ( t > (3*max_data)/4) return 0;
  return 255 ;
}

void loop(void) 
{
if (stringComplete)
{
  sampleCount = 0; // so run it all again  
  loop_start_time = 0;
  stringComplete = false ;
}

if (sampleCount >= 0) 
    {
      unsigned long now_time = millis();
      if (now_time < last_time + interval)
      {
        timing_too_fast ++ ;
      }
      else
          {
          if (sampleCount < max_data)
              {
              // Initial test showed it could write this to the card at 12 ms intervals
               last_time = now_time ;
                
              // read  sensor 
                erg_in[sampleCount] = -1 * analogRead(analogPin);  
                time_stamp[sampleCount] = (now_time - loop_start_time) ;
                int intensity =br_now(sampleCount);
                //brightness[sampleCount] = int(intensity) ;
                analogWrite(ledPin, intensity);
                sampleCount ++ ;
              }
          if (sampleCount == max_data)
              {
              sampleCount ++ ;  
              analogWrite(ledPin, 0);
              for (int i = 0; i < max_data; i++)
              {
                  // make a string for assembling the data to log:
                  String dataString = String(i);
                  dataString += ", ";
              
                 
                dataString += String(time_stamp[i]-time_stamp[0]);
                dataString += ", ";
    
                dataString += String(br_now(i));
                dataString += ", ";

                dataString += String(erg_in[i]);
                                
              // if the file is available, write to it:
                  if (dataFile) 
                  {
                   dataFile.println(dataString);
                  }
                  else 
                  {
                  Serial.println (dataString);
                  }
                  
               } // end of for i
                if (dataFile) 
                  {
                  dataFile.flush();
                  }
              String sTmp = "DAQ done : timing stats ";
              sTmp += timing_too_fast ;    
              Serial.println (sTmp);
              } // end of writing data to file
           
          } // end of if we've had enough time elapse
      } // end of samplecount > 0
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
       
       case '5':
       freq = 16 ;
       break ;
       
       case 'X':
       dataFile.close();
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

