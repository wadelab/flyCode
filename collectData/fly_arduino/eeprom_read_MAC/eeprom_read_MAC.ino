/*
 * EEPROM Read
 *
 * Reads the value of each byte of the EEPROM and prints it
 * to the computer.
 * This example code is in the public domain.
 */

#include <EEPROM.h>
#include <SPI.h>
#include <Ethernet.h>

// start reading from the first byte (address 0) of the EEPROM


byte mac[6]  ;


EthernetServer server(80);

void setup()
{
  // initialize serial and wait for port to open:
  Serial.begin(115200);
  while (!Serial) {
    ; // wait for serial port to connect. Needed for Leonardo only
  }
  Serial.println ();
  Serial.println ();
  Serial.println ();
  Serial.println("Looking for Mac address ");
  if (readaddress())
  {
  FindServer() ;
  }
  else 
  {
    Serial.println("No Mac address found");
  }
}

bool readaddress()
{
  // read a byte from the current address of the EEPROM
  // start at 0
  int address = 0;
  byte value;
  char cMac [4];
  cMac[3] = '\0' ;
  while (address < 20)
  {
    value = EEPROM.read(address);
    char * c = " ";
    *c = value ;
    if (address < 3)
    {
      cMac [address] = (char)value  ;
    }
    else
    {
      if (address < 9)
      {
        mac [address - 3] = value ;
      }
    }


    Serial.print(address);
    Serial.print("\t");
    Serial.print (c);
    Serial.print("\t");
    Serial.print(value, DEC);
    Serial.print("\t");
    Serial.print(value, HEX);
    Serial.println();

    // advance to the next address of the EEPROM
    address = address + 1;
  }
  int iComp = strncmp (cMac, "MAC", 3);
  Serial.print ("Comparing :") ;
  Serial.print (cMac);
  Serial.print (" with MAC gives ");
  Serial.println (iComp);
  
  return ( 0 == iComp) ;
  delay(500);
}


bool FindServer()
{
  Serial.println F("Setting up the Ethernet card...\n");
  // start the Ethernet connection and the server:

  if (Ethernet.begin(mac) == 0)
  {
    Serial.println("Failed to configure Ethernet using DHCP");
  }
  server.begin();
  Serial.print F("server is at ");
  Serial.println(Ethernet.localIP());
}

void loop()
{
}
