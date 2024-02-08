
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
#include <FFT.h> // include the library


// change this to match your SD shield or module;
// Arduino Ethernet shield: pin 4
// Adafruit SD shields and modules: pin 10
// Sparkfun SD shield: pin 8
const int chipSelect = 4;
const int ledPin =  9;      // the number of the LED pin
const int analogPin = 1 ;
int freq = 16 ; // flicker of LED Hz
const int waitTime = 32 ; // start FFTs after 32 x interval ms ;
const int max_data = 1024 + waitTime ;
#define LOG_OUT 1 // use the log output function
#define FFT_N 256 // set to 256 point fft

unsigned int time_stamp [max_data] ;
int erg_in [max_data];
int SummedFFT [FFT_N/2] ;

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

  // zero array 
  for (int i =0; i < FFT_N/2; i++)
  {
    SummedFFT[i] = 0;
  }
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
  pinMode(53, OUTPUT);

  if (!SD.begin(4)) 
  {
    Serial.println("bad SD!");
    return;
  }

  File root = SD.open("/");
  printDirectory(root, 0);
  root.close();
  Serial.println("dir tree done!");
}



//***********************************************************************************************************
void printDirectory(File dir, int numTabs) {
  while(true) {

    File entry =  dir.openNextFile();
    if (! entry) {
      // no more files
      Serial.println("**nomorefiles**");
      break;
    }
    for (uint8_t i=0; i<numTabs; i++) {
      Serial.print('\t');
    }
    Serial.print(entry.name());
    if (entry.isDirectory()) {
      Serial.println("/");
      printDirectory(entry, numTabs+1);
    } 
    else {
      // files have sizes, directories do not
      Serial.print("\t\t");
      Serial.println(entry.size(), DEC);
    }
    entry.close();
  }
}

//***************************************************************************************************
void ReadOutFile(char * cFile)
{
  File ReadFile = SD.open(cFile);

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
void writeFFT (char * cFile)
{
  // if file exists this will append to it
  if(SD.exists(cFile))
  {
    SD.remove(cFile);
  }
  dataFile = SD.open(cFile, FILE_WRITE);

  if (dataFile)
  {
    Serial.print("opened fft file :");
    Serial.println(cFile);

    dataFile.println("Data sampled at " + String(interval) + " ms, Flickered at " + String(freq) + " Hz");
    for (int i = 0 ; i < FFT_N/2 ; i += 2)
    {
      dataFile.print(2*float(i)/float(interval));
      dataFile.print(", ");
      dataFile.println(SummedFFT[i]); // send out the data
    }
    dataFile.close();
    Serial.println("written fft file");
    Serial.println(cFile);
  }  
  else 
  {
    Serial.print("error opening ");
    Serial.println(cFile);
    Serial.println("Data sampled at " + String(interval) + " ms, Flickered at " + String(freq) + " Hz");
    for (int i = 0 ; i < FFT_N/2 ; i += 2)
    {
      Serial.print(2*float(i)/float(interval));
      Serial.print(", ");
      Serial.println(SummedFFT[i]); // send out the data
    }
  } 
}
void writeFile(char * cFile)
{
  // if file exists this will append to it
  if (SD.exists(cFile))
  {
    SD.remove(cFile);
  }
  dataFile = SD.open(cFile, FILE_WRITE);

  if (dataFile)
  {
    Serial.print("opened datafile :");
    Serial.println (cFile);
    int bytesWritten = dataFile.println("No, time, brightness, analog in");
    Serial.print("Now written headeer of file with bytes:");
    Serial.println(bytesWritten);
  }    

  else 
  {
    Serial.print("error opening ");
    Serial.println (cFile);

  }
  for (int i = 0; i < max_data; i++)
  {
    // make a string for assembling the data to log:
    String dataString = String(i);
    dataString += ", ";

    dataString += String(time_stamp[i]-time_stamp[0]);
    dataString += ", ";

    dataString += String(int(sin((double(time_stamp[i])/1000.0)*PI*2.0*freq)*127.0)+127);
    dataString += ", ";

    dataString += String(erg_in[i]);
    if (dataFile)
    {
      dataFile.println(dataString);
    }   
    else 
    {
      Serial.println(dataString);
    }
  } // end of for i
  if (dataFile)
  {
    dataFile.flush();
    dataFile.close();
  }

  String sTmp = "DAQ done : timing stats ";
  sTmp += timing_too_fast ;    
  Serial.println (sTmp);
} // end of writing data to file

//***************************************************************************************************
void do_fft(int iStart)
{
  for (int i = 0 ; i < FFT_N ; i += 2)
  { 
    int k = erg_in[i/2 + iStart];
    k -= 0x0200; // form into a signed int
    k <<= 6; // form into a 16b signed int
    fft_input[i] = k; // put real data into even bins
    fft_input[i+1] = 0; // set odd bins to 0
  }
  fft_window(); // window the data for better frequency response
  fft_reorder(); // reorder the data before doing the fft
  fft_run(); // process the data in the fft
  fft_mag_log(); // take the output of the fft
  // data now in fft_log_out, so add it to the avaerage
  for (int i=0; i < FFT_N/2; i++)
  {
    SummedFFT [i] = SummedFFT [i] + fft_log_out[i] ;
  }

}

//***************************************************************************************************

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
        erg_in[sampleCount] = analogRead(analogPin);  

        time_stamp[sampleCount] = (now_time - loop_start_time) ;
        int intensity =int(sin((double(now_time)/1000.0)*PI*2.0*freq)*127.0)+127;
        //brightness[sampleCount] = int(intensity) ;
        analogWrite(ledPin, intensity);

        sampleCount ++ ;
      }
      if (sampleCount == max_data)
      {
        sampleCount ++ ;  
        analogWrite(ledPin, 127);
        writeFile("datalog.dat");
        for (int i = 0; i <4; i++) // posisble bug if we change max_data
        {
          do_fft(waitTime + i * FFT_N) ;
        }
        writeFFT("datalog.fft");
      }
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

    case 'F':       
      ReadOutFile("datalog.fft");
      stringComplete = false ;
      break ;

    case 'R':
      ReadOutFile("datalog.dat");
      stringComplete = false ;
      break ;
      
    case 'P':
      File root = SD.open("/");
      printDirectory(root, 0);
      root.close();
      stringComplete = false ;
      break ;
    }

  }
}



