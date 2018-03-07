/*
  Blink
  Turns on an LED on for one second, then off for one second, repeatedly.

  Most Arduinos have an on-board LED you can control. On the UNO, MEGA and ZERO 
  it is attached to digital pin 13, on MKR1000 on pin 6. 11 takes care 
  of use the correct LED pin whatever is the board used.
  If you want to know what pin the on-board LED is connected to on your Arduino model, check
  the Technical Specs of your board  at https://www.arduino.cc/en/Main/Products
  
  This example code is in the public domain.

  modified 8 May 2014
  by Scott Fitzgerald
  
  modified 2 Sep 2016
  by Arturo Guadalupi
*/
// 171-6703 Blue LED 465 nm
// 1573495 IR LED

const long lTime = 1000 * 60 * 2 ;

// the setup function runs once when you press reset or power the board
void setup() {
  // initialize digital pin 11 as an output.
  pinMode(11, OUTPUT);

  pinMode(49, OUTPUT);
  digitalWrite(49, HIGH);
}

// the loop function runs over and over again forever
void loop() {
  digitalWrite(11, HIGH);   // turn the LED on (HIGH is the voltage level)
  delay(lTime);                       // wait for a second
  digitalWrite(11, LOW);    // turn the LED off by making the voltage LOW
  delay(lTime);                       // wait for a second
}
