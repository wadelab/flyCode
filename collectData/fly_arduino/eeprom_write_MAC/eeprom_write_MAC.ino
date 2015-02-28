/*
 * EEPROM Write
 *
 * Stores values read from analog input 0 into the EEPROM.
 * These values will stay in the EEPROM when the board is
 * turned off and may be retrieved later by another sketch.
 */

#include <EEPROM.h>

// the current address in the EEPROM (i.e. which byte
// we're going to write to next)
int addr = 0;


#define due2

//_____________________________________________________

#ifdef mega1
#define MAC_OK 0xDE, 0xAD, 0xBE, 0xEF, 0xFE, 0xED
//biolpc2793 [in use in lab with Emily and Richard]
#endif

#ifdef mega2
#define MAC_OK 0x90, 0xA2, 0xDA, 0x0F, 0x42, 0x02
//biolpc2804

#endif

#ifdef due1
#define MAC_OK 0x90, 0xA2, 0xDA, 0x0E, 0x09, 0xA2
//90-A2-DA-0E-09-A2 biolpc2886 [in use for Sultan]
#endif

#ifdef due2
#define MAC_OK 0x90, 0xA2, 0xDA, 0x0F, 0x6F, 0x9E
//90-A2-DA-0E-09-A2 biolpc2898 [used in testing...]
#endif

#ifdef due3
#define MAC_OK 0x90, 0xA2, 0xDA, 0x0F, 0x75, 0x17
//90-A2-DA-0E-09-A2 biolpc2899
#endif

#ifdef __wifisetup__
#define MAC_OK
#endif

byte mac[] = { MAC_OK } ;
const char * cMac = "MAC" ;

void setup()
{
  Serial.begin(115200);
  Serial.println ("Hello: !");

  // write :MAC" as id code we can test for
  while (addr < 3)
  {
    EEPROM.write(addr, cMac[addr]);
    addr = addr + 1;
    delay(100);
  }
  Serial.print ("Written: !") ;
  Serial.println ( cMac) ;

  while (addr < 9)
  {
    EEPROM.write(addr, mac[addr - 3]);
    addr = addr + 1;
    delay(100);
  }
  Serial.print ("Written: address !") ;
  //Serial.println ( mac ) ;

  Serial.println ("Done: !");
}

void loop()
{



}
