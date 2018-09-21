// SQW/OUT pin mode using a DS1307 RTC connected via I2C.
//
// According to the data sheet (http://datasheets.maxim-ic.com/en/ds/DS1307.pdf), the
// DS1307's SQW/OUT pin can be set to low, high, 1Hz, 4.096kHz, 8.192kHz, or 32.768kHz.
//
// This sketch reads the state of the pin, then iterates through the possible values at
// 5 second intervals.
//

// NOTE:
// You must connect a pull up resistor (~10kohm) from the SQW pin up to VCC.  Without
// this pull up the wave output will not work!

#include <Wire.h>
#include "RTClib.h"

#if defined(ARDUINO_ARCH_SAMD)  // for Zero, output on USB Serial console, remove line below if using programming port to program the Zero!
#define Serial SerialUSB
#endif

RTC_DS1307 rtc;

int mode_index = 0;

Ds1307SqwPinMode modes[] = {OFF, ON, SquareWave1HZ, SquareWave4kHz, SquareWave8kHz, SquareWave32kHz};

void setup () {

#ifndef ESP8266
  while (!Serial); // for Leonardo/Micro/Zero
#endif

  Serial.begin(115200);
  if (! rtc.begin()) {
    Serial.println("Couldn't find RTC");
    while (1);
  }


  // initialize digital pin LED_BUILTIN as an output.
  // on due, use PIN 13 - Lumier E2005, white LED
  pinMode(LED_BUILTIN, OUTPUT);
  for (int i = 35; i < 54; i = i + 2)
  {
    pinMode(i, OUTPUT);
  }


  if (! rtc.isrunning()) {
    //    Serial.println("RTC is NOT running!");
    //    // following line sets the RTC to the date & time this sketch was compiled
    rtc.adjust(DateTime(F(__DATE__), F(__TIME__)));
    //    // This line sets the RTC with an explicit date & time, for example to set
    //    // January 21, 2014 at 3am you would call:
    //    // rtc.adjust(DateTime(2014, 1, 21, 3, 0, 0));
  }


}

void loop () {

  DateTime now = rtc.now();
  int h = now.hour() ; // minute
  Serial.println(h, DEC);

  if (h < 8 || h > 20)
  {
    rtc.writeSqwPinMode(modes[1]); // RTC board led off
    digitalWrite(LED_BUILTIN, LOW);
    for (int i = 35; i < 54; i = i + 2)
    {
      digitalWrite(i, LOW);
    }
  }
  else
  {
    rtc.writeSqwPinMode(modes[0]); // led on
    digitalWrite(LED_BUILTIN, HIGH);
    for (int i = 35; i < 54; i = i + 2)
    {
      digitalWrite(i, HIGH);
    }
  }

  delay(5000);
}
