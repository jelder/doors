#include <DigiUSB.h>
#include <stdarg.h>

/*
  State change detection (edge detection)
 	
 Often, you don't need to know the state of a digital input all the time,
 but you just need to know when the input changes from one state to another.
 For example, you want to know when a button goes from OFF to ON.  This is called
 state change detection, or edge detection.
 
 This example shows how to detect when a button or button changes from off to on
 and on to off.
 	
 The circuit:
 * pushbutton attached to pin 2 from +5V
 * 10K resistor attached to pin 2 from ground
 * LED attached from pin 13 to ground (or use the built-in LED on
   most Arduino boards)
 
 created  27 Sep 2005
 modified 30 Aug 2011
 by Tom Igoe

This example code is in the public domain.
 	
 http://arduino.cc/en/Tutorial/ButtonStateChange
 
 */

#define NELEMS(x)  (sizeof(x) / sizeof(x[0]))

const int ledPin = 1;        // the pin that the LED is attached to
const int doorPins[] = {2};
// const int doorPins[] = {0, 2, 3, 4, 5};

int doorStates[] = {LOW, LOW, LOW, LOW, LOW};
int lastDoorStates[] = {LOW, LOW, LOW, LOW, LOW};

void setup() {
  int i;

  // initialize the door pins as input:
  for(i=0; i<NELEMS(doorPins); i++){
    pinMode(doorPins[i], INPUT);
  }

  // initialize the LED as output:
  pinMode(ledPin, OUTPUT);
  // initialize serial communication:
  DigiUSB.begin();
}

void handleDoor(const int pinId) {
  int pin = doorPins[pinId];
  int lastDoorState = lastDoorStates[pinId];
  int doorState = digitalRead(pin);
  char* digiUSBLine;


  // // compare the doorState to its previous state
  if (doorState != lastDoorState) {
    // if the pin is low, the door is open. Otherwise it's closed
    if(doorState == LOW) {
      digiUSBLine = "sensor:# state:open";
    } else {
      digiUSBLine = "sensor:# state:closed";
    }

    // horrible, horrible hack to write the sensor pin.
    // Doing this because sprintf is crashing for some reason...
    if(pin >= 0 && pin <= 9) {
      digiUSBLine[7] = ('0' + pin);
    }
    
    DigiUSB.println(digiUSBLine);
  }

  // save the current state as the last state, 
  //for next time through the loop
  lastDoorStates[pinId] = doorState;  
}

void loop() {
  DigiUSB.refresh();
  
  int i;
  int ledState = LOW;
  for(i=0; i<NELEMS(doorPins); i++){
    handleDoor(i);
    ledState |= doorStates[i];
  }
  digitalWrite(ledPin, ledState);

  // Delay a little bit to avoid bouncing
  delay(50);
}

