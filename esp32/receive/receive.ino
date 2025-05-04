//T2
//Receive

#include <Wire.h>
#include <esp_now.h>
#include <WiFi.h>
#include <LiquidCrystal_I2C.h>

// Define I2C pins for LCD
#define I2C_SDA 4
#define I2C_SCL 16

// Initialize LCD with I2C address 0x27, 16 columns and 2 rows
LiquidCrystal_I2C lcd(0x27, 16, 2);

// Define structure for received sensor data
typedef struct struct_message {
  float temperature, humidity;
  float accX, accY, accZ;
  int flameDigital, flameAnalog;
  int gasDigital, gasAnalog;
  long irValue;
  float bpm;
  float spo2;
} struct_message;

// Global variable to hold the latest received data
struct_message incomingData;

// Timing control for page switching
unsigned long lastSwitch = 0;
int displayPage = 0;

// ESP-NOW callback when data is received
void OnDataRecv(const esp_now_recv_info_t *info, const uint8_t *data, int len) {
  if (len == sizeof(incomingData)) {
    memcpy(&incomingData, data, sizeof(incomingData));
  }
}

void setup() {
  // Set Wi-Fi mode to station (STA) and disconnect from any network
  WiFi.mode(WIFI_STA);
  WiFi.disconnect();
  delay(100);

  // Initialize I2C and LCD
  Wire.begin(I2C_SDA, I2C_SCL);
  lcd.init();
  lcd.backlight();
  lcd.print("Waiting for data...");

  // Initialize ESP-NOW
  if (esp_now_init() != ESP_OK) {
    return;
  }
  // Register receive callback
  esp_now_register_recv_cb(OnDataRecv);
}

void loop() {
  // Switch display page every 3 seconds
  if (millis() - lastSwitch > 3000) {
    displayPage = (displayPage + 1) % 7;
    lastSwitch = millis();
    lcd.clear();
  }

  switch (displayPage) {
    case 0:
      // Display temperature and humidity
      lcd.setCursor(0, 0);
      lcd.print("T:");
      lcd.print(incomingData.temperature, 1);
      lcd.print("C H:");
      lcd.print(incomingData.humidity, 1);
      lcd.print("%");
      break;

    case 1: {
        // Display motion status based on acceleration
        lcd.setCursor(0, 0);
        lcd.print("Accel State:");
        lcd.setCursor(0, 1);
        float magnitude = sqrt(incomingData.accX * incomingData.accX +
                              incomingData.accY * incomingData.accY +
                              incomingData.accZ * incomingData.accZ);
        if (magnitude < 2.0) {
          lcd.print("Possible Fall!");
        } else if (magnitude > 12.0) {
          lcd.print("Moving");
        } else {
          lcd.print("Still");
        }
        break;
      }

    case 2:
      // Display fire detection result
      lcd.setCursor(0, 0);
      if (incomingData.flameDigital == 0 || incomingData.flameAnalog < 2000) {
        lcd.print("Fire Detected!");
      } else {
        lcd.print("No Fire");
      }
      break;

    case 3:
      // Display air quality status based on gas sensor
      lcd.setCursor(0, 0);
      if (incomingData.gasDigital == 0) {
        lcd.print("Gas Alert!");
      } else {
        lcd.print("Air Status:");
        int gasLevel = incomingData.gasAnalog;
        if (gasLevel <= 800) {
          lcd.print("Good ");
        } else if (gasLevel <= 900) {
          lcd.print("Fair ");
        } else if (gasLevel <= 1000) {
          lcd.print("LightPol"); // Light Pollution
        } else if (gasLevel <= 1100 ) {
          lcd.print("ModPol");   // Moderate Pollution
        } else if (gasLevel <= 1200 ) {
          lcd.print("HeaPol");   // Heavy Pollution
        } else{
          lcd.print("SevPol");   // Severe Pollution
        }
      }
      break;

    case 4:
      // Display heart rate if valid
      lcd.setCursor(0, 0);
      lcd.print("HR: ");
      if (incomingData.irValue >= 5000 && incomingData.irValue <= 250000 && incomingData.bpm > 30 && incomingData.bpm < 220) {
        lcd.print(incomingData.bpm, 1);
        lcd.print(" BPM");
      } else {
        lcd.print("No Data");
      }
      break;

    case 5:
      // Display blood oxygen level if valid
      lcd.setCursor(0, 0);
      lcd.print("SPO2: ");
      if (incomingData.spo2 > 50 && incomingData.spo2 <= 100) {
        lcd.print(incomingData.spo2, 1);
        lcd.print(" %");
      } else {
        lcd.print("No Data");
      }
      break;
  }
}

