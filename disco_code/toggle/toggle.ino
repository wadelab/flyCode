/// THIS IS THE CODE IS RUNNING IN ALL THE TUBES.

// an array of pin numbers to which LEDs are attached
// blue pins 
int ledPins[] = { 40, 48, 52 } ;
  

int pinCount=3;

int ledState = LOW;             // ledState used to set the LED
long previousMillis = 0;        // will store last time LED was updated

// the follow variables is a long because the time, measured in miliseconds,
// will quickly become a bigger number than can be stored in an int.
long interval = 1000;           // interval at which to blink (milliseconds)


void setup() 
{

  // The array elements are numbered from 0 to (pinCount - 1).
  // Use a for loop to initialize each pin as an output:
  for (int thisPin = 0; thisPin < pinCount; thisPin++)  
  {
    pinMode(ledPins[thisPin], OUTPUT);     
  }
}



void loop() {
  long currentMillis = (long)millis();

  if(currentMillis - previousMillis > interval) 
  {

    // save the last time you blinked the LED 
    previousMillis = currentMillis;   
    if (0 == rand() % 2)
    {
      // if the LED is off turn it on and vice-versa:
      if (ledState == LOW)
        ledState = HIGH;
      else
        ledState = LOW;
      for (int thisPin = 0; thisPin < pinCount; thisPin++) 
      {
        digitalWrite(ledPins[thisPin], ledState);
      }
    }
  }
}



