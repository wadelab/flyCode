/// THIS IS THE CODE IS RUNNING IN ALL THE TUBES.

// an array of pin numbers to which LEDs are attached
// blue pins
int ledPins[] = {  40, 48, 52 } ;


const int pinCount = sizeof(ledPins)/sizeof(int); 

int ledState [pinCount];             // ledState used to set the LED
long previousMillis = 0;        // will store last time LED was updated

// the follow variables is a long because the time, measured in miliseconds,
// will quickly become a bigger number than can be stored in an int.
long interval = 1000;           // interval at which to blink (milliseconds)


void setup()
{
  // Open serial communications and wait for port to open:
  Serial.begin(115200);
  while (!Serial) {
    ; // wait for serial port to connect. Needed for Leonardo only
  }
  Serial.print("Number of Leds is ");
  Serial.println(pinCount);
  // The array elements are numbered from 0 to (pinCount - 1).
  // Use a for loop to initialize each pin as an output:
  for (int thisPin = 0; thisPin < pinCount; thisPin++)
  {
    pinMode(ledPins[thisPin], OUTPUT);
    ledState[thisPin] = HIGH;
    digitalWrite(ledPins[thisPin], ledState[thisPin]);
  }

}



void loop() {
  long currentMillis = (long)millis();

  if (currentMillis - previousMillis > interval)
  {

    // save the last time you blinked the LED
    previousMillis = currentMillis;
    if (0 == rand() % 2)
    {

      for (int thisPin = 0; thisPin < 2; thisPin++)
      {
        //  if the LED is off turn it on and vice-versa:
        if (ledState[thisPin] == LOW)
          ledState[thisPin] = HIGH;
        else
          ledState[thisPin] = LOW;
        digitalWrite(ledPins[thisPin], ledState[thisPin]);
      }

    }
  }
}



