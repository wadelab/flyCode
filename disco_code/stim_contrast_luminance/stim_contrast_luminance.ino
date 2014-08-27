/// THIS IS THE CODE IS RUNNING IN ALL THE TUBES.

// an array of pin numbers to which LEDs are attached
int ledPins[] = { 2,3,4,5,6,7,8,9}; 


// These are percent contrast modulations
float ledConts[] = {.30,.30,.30,.30 ,0.0,.25,.50,.99};


// These are expressed as percentages of the max (128)
float ledMeanLum[] = {.05,.2,.4,.75,.5,.5,.5,.5 };
float flickerHz=5;

int pinCount=8;


void setup() {

  // The array elements are numbered from 0 to (pinCount - 1).
  // Use a for loop to initialize each pin as an output:
  for (int thisPin = 0; thisPin < pinCount; thisPin++)  
  {
    pinMode(ledPins[thisPin], OUTPUT);     
  }
}



void loop() {

  // Loop from the lowest pin to the highest:
  for (int thisPin = 0; thisPin < pinCount; thisPin++) 
  {
    // Turn the pin on:
    float val = sin(float(millis())/1000.0*2*3.1415927*flickerHz)*(ledMeanLum[thisPin]*ledConts[thisPin])+ledMeanLum[thisPin];
    analogWrite(ledPins[thisPin], int(val*128));
  }
}

