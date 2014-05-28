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
// set up variables using the SD utility library functions:
Sd2Card card;
SdVolume volume;
SdFile root;

// change this to match your SD shield or module;
// Arduino Ethernet shield: pin 4
// Adafruit SD shields and modules: pin 10
// Sparkfun SD shield: pin 8
const int chipSelect = 4;
const int ledPin =  9;      // the number of the LED pin
const int analogPin = 1 ;
int freq = 5 ; // Hz

String inputString = "";         // a string to hold incoming data
boolean stringComplete = false;  // whether the string is complete

int ledState = LOW;             // ledState used to set the LED
long previousMillis = 0;        // will store last time LED was updated
long interval = 30;           // interval at which to

File dataFile ;

void setup()
{
 // Open serial communications and wait for port to open:
  Serial.begin(9600);
   while (!Serial) {
    ; // wait for serial port to connect. Needed for Leonardo only
  }

/*
  Serial.print("\nInitializing SD card...");
  // On the Ethernet Shield, CS is pin 4. It's set as an output by default.
  // Note that even if it's not used as the CS pin, the hardware SS pin
  // (10 on most Arduino boards, 53 on the Mega) must be left as an output
  // or the SD library functions will not work.
  pinMode(10, OUTPUT);     // change this to 53 on a mega -- seems to be ok as we can read the card
  digitalWrite(10, HIGH); // Add this line

  // we'll use the initialization code from the utility libraries
  // since we're just testing if the card is working!
  if (!card.init(SPI_HALF_SPEED, chipSelect)) {
    Serial.println("initialization failed. Things to check:");
    Serial.println("* is a card is inserted?");
    Serial.println("* Is your wiring correct?");
    Serial.println("* did you change the chipSelect pin to match your shield or module?");
    return;
  } 
  else 
  {
   Serial.println("Wiring is correct and a card is present.");
  }

  // print the type of card
  Serial.print("\nCard type: ");
  switch(card.type()) {
    case SD_CARD_TYPE_SD1:
      Serial.println("SD1");
      break;
    case SD_CARD_TYPE_SD2:
      Serial.println("SD2");
      break;
    case SD_CARD_TYPE_SDHC:
      Serial.println("SDHC");
      break;
    default:
      Serial.println("Unknown");
  }

  // Now we will try to open the 'volume'/'partition' - it should be FAT16 or FAT32
  if (!volume.init(card)) {
    Serial.println("Could not find FAT16/FAT32 partition.\nMake sure you've formatted the card");
    return;
  }

  // print the type and size of the first FAT-type volume
  uint32_t volumesize;
  Serial.print("\nVolume type is FAT");
  Serial.println(volume.fatType(), DEC);
  Serial.println();

  volumesize = volume.blocksPerCluster();    // clusters are collections of blocks
  volumesize *= volume.clusterCount();       // we'll have a lot of clusters
  volumesize *= 512;                            // SD card blocks are always 512 bytes
  Serial.print("Volume size (bytes): ");
  Serial.println(volumesize);
  Serial.print("Volume size (Kbytes): ");
  volumesize /= 1024;
  Serial.println(volumesize);
  Serial.print("Volume size (Mbytes): ");
  volumesize /= 1024;
  Serial.println(volumesize);

  Serial.println("\nFiles found on the card (name, date and size in bytes): ");
  root.openRoot(volume);

  // list all files in the card with date and size
  root.ls(LS_R | LS_DATE | LS_SIZE);

  // set the digital pin as output:
  pinMode(ledPin, OUTPUT); */
 
  // open the file. note that only one file can be open at a time,
  // so you have to close this one before opening another.
  Serial.print("Initializing SD card...");
  // On the Ethernet Shield, CS is pin 4. It's set as an output by default.
  // Note that even if it's not used as the CS pin, the hardware SS pin 
  // (10 on most Arduino boards, 53 on the Mega) must be left as an output 
  // or the SD library functions will not work. 
   pinMode(10, OUTPUT);
   
  if (!SD.begin(4)) {
    Serial.println("initialization failed!");
    return;
  }
  
 File root = SD.open("/");
  printDirectory(root, 0);
  root.close();
  
  Serial.println("done!");
  
  Serial.println("initialization done.");
   dataFile = SD.open("datalog.txt", FILE_WRITE);

  if (dataFile)
  {
    Serial.println("opened file successfully");
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
    while (ReadFile.available()) {
      Serial.write(ReadFile.read());
    }
    ReadFile.close();
  }  
  // if the file isn't open, pop up an error:
  else {
    Serial.println("error opening datalog.txt");
  } 
}

//***************************************************************************************************


void loop(void) 
{
if (stringComplete)
{
  previousMillis = 0; // so run it all again  
  stringComplete = false ;
}

  while (previousMillis < 1024)
  {
  previousMillis ++ ;

  // make a string for assembling the data to log:
  String dataString = String(previousMillis);
  dataString += ",";

  // read  sensor and append to the string:
    int sensor = analogRead(analogPin);
    dataString += String(sensor);
    dataString += ",";

      double value=sin((double(millis())/1000)*PI*2*freq)*127+127;
      dataString += String(int(value));
    //  Serial.println(dataString  );
  // if the file is available, write to it:
  if (dataFile) 
  {
   dataFile.println(dataString);
   dataFile.flush();
   }
   
   analogWrite(ledPin, value);
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
       
       case 'X':
       dataFile.close();
       break ;
       
       case 'R':
       dataFile.close();
       ReadOutFile();
       stringComplete = false ;
       break ;
            
    }

  }
}

