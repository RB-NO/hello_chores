const int BUTTON_PIN = 2;   // the arcade button

const int LED_PIN = 9;  // the built-in LED




int lastBtnState = HIGH;    // Default state is HIGH due to internal pull-up resistor




void setup() {

  Serial.begin(9600);

pinMode(BUTTON_PIN, INPUT_PULLUP);    // Set button pin as input with internal pull-up resistor

pinMode(LED_PIN, OUTPUT); // Set LED pin as output

}




void loop() {

int currentBtnState = digitalRead(BUTTON_PIN);    // Read the current state of the button




  // When the button is pressed

if (lastBtnState == HIGH && currentBtnState == LOW) {

delay(50);  // Debounce delay to filter out noise

if (digitalRead(BUTTON_PIN) == LOW) {   // Re-check to confirm actual press

digitalWrite(LED_PIN, HIGH);

      Serial.println("{\"button\": \"pressed\"}");  // Send JSON signal to Python via serial port

    }

  }




  // When the button is released

if (lastBtnState == LOW && currentBtnState == HIGH) {

delay(50);  // Debounce delay to filter out noise

if (digitalRead(BUTTON_PIN) == HIGH) {  // Re-check to confirm actual release

digitalWrite(LED_PIN, LOW);

      Serial.println("{\"button\": \"released\"}"); // Send JSON signal to Python via serial port

    }

  }




lastBtnState = currentBtnState;   // Update the previous button state for the next loop

}