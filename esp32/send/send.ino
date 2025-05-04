//T2
//Send

#include <Wire.h>
#include <WiFi.h>
#include <esp_now.h>
#include "esp_wifi.h"
#include "DHT.h"
#include <Adafruit_MPU6050.h>
#include <Adafruit_Sensor.h>
#include "MAX30105.h"
#include <HTTPClient.h>
#include <ArduinoJson.h>
#include <algorithm>
#include "heartRate.h"

// ---------- Pin Definitions ----------
#define DHTPIN 14            // DHT11 data pin
#define DHTTYPE DHT11        // DHT11 sensor type
#define SDA_PIN 13           // I2C SDA pin
#define SCL_PIN 27           // I2C SCL pin
#define FLAME_DO 25          // Flame sensor digital pin
#define FLAME_AO 34          // Flame sensor analog pin
#define GAS_DO 33            // Gas sensor digital pin
#define GAS_AO 35            // Gas sensor analog pin

// ---------- WiFi & ESP-NOW Config ----------
const char* ssid = "BSC-Resident";                  // WiFi SSID
const char* password = "brookside6551";             // WiFi password
uint8_t receiverMac[] = {0x88, 0x13, 0xBF, 0x07, 0xD3, 0x70};  // MAC address of receiver board

// ---------- HTTP Server Config ----------
const char* serverUrl = "http://172.31.99.212:8888/api/post-data";

// ---------- Sensor Objects ----------
DHT dht(DHTPIN, DHTTYPE);              // DHT11 temperature/humidity sensor
Adafruit_MPU6050 mpu;                  // MPU6050 accelerometer/gyroscope
MAX30105 maxSensor;                    // MAX30105 pulse sensor

// ---------- Data Structure ----------
typedef struct struct_message {
  float temperature;
  float humidity;
  float accX, accY, accZ;
  int flameDigital, flameAnalog;
  int gasDigital, gasAnalog;
  long irValue;
  float bpm;
  float spo2;
} struct_message;

struct_message sensorData;

// ---------- Heart Rate Detection State ----------
const int bufferSize = 30;          // Buffer size for IR signal
long irBuffer[bufferSize];          // IR signal buffer
int irIndex = 0;                    // Current index in buffer
unsigned long lastPeakTime = 0;     // Last detected heartbeat time
bool previousFingerPresent = false; // Previous finger detection state
const float bpmCalibrationOffset = 20.0;  // Calibration offset for BPM
float bpmBuffer[5] = {0};           // Buffer for averaging BPM
int bpmIndex = 0;                   // Index for BPM buffer
bool wasAboveThreshold = false;     // Peak detection flag

void setup() {
  Serial.begin(115200);

  // Initialize Wi-Fi
  WiFi.mode(WIFI_STA);
  WiFi.begin(ssid, password);
  Serial.print("Connecting to WiFi");
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }
  Serial.println("\nWiFi connected!");
  Serial.println(WiFi.localIP());

  // Get current Wi-Fi channel
  uint8_t primaryChan;
  wifi_second_chan_t second;
  esp_wifi_get_channel(&primaryChan, &second);

  // Initialize I2C and sensors
  Wire.begin(SDA_PIN, SCL_PIN);
  dht.begin();
  pinMode(FLAME_DO, INPUT);
  pinMode(GAS_DO, INPUT);

  // Initialize MPU6050
  if (!mpu.begin()) Serial.println("MPU6050 initialization failed");

  // Initialize MAX30105
  if (!maxSensor.begin(Wire)) {
    Serial.println("MAX30105 initialization failed");
    while (1);
  } else {
    maxSensor.setup();
    maxSensor.setPulseAmplitudeRed(0x2F);
    maxSensor.setPulseAmplitudeIR(0x2F);
    maxSensor.setPulseWidth(411);
    maxSensor.setSampleRate(75);
    maxSensor.setPulseAmplitudeGreen(0);
    Serial.println("MAX30105 initialization successful");
  }

  // Initialize ESP-NOW
  if (esp_now_init() != ESP_OK) {
    Serial.println("ESP-NOW initialization failed!");
    return;
  }

  // Register ESP-NOW peer
  esp_now_del_peer(receiverMac);
  esp_now_peer_info_t peerInfo = {};
  memcpy(peerInfo.peer_addr, receiverMac, 6);
  peerInfo.channel = primaryChan;
  peerInfo.encrypt = false;
  if (esp_now_add_peer(&peerInfo) != ESP_OK) {
    Serial.println("❌ Failed to add ESP-NOW peer");
  }
}

void loop() {
  // 1. Read environmental and motion sensors
  sensorData.temperature = dht.readTemperature();
  sensorData.humidity = dht.readHumidity();
  sensors_event_t a, g, temp;
  mpu.getEvent(&a, &g, &temp);
  sensorData.accX = a.acceleration.x;
  sensorData.accY = a.acceleration.y;
  sensorData.accZ = a.acceleration.z;
  sensorData.flameDigital = digitalRead(FLAME_DO);
  sensorData.flameAnalog = analogRead(FLAME_AO);
  sensorData.gasDigital = digitalRead(GAS_DO);
  sensorData.gasAnalog = analogRead(GAS_AO);

  // 2. Read PPG signal and calculate SpO2
  long ir = maxSensor.getIR();
  long red = maxSensor.getRed();
  sensorData.irValue = ir;

  if (red > 5000 && ir > 5000) {
    float ratio = (float)red / ir;
    sensorData.spo2 = constrain(104.0 - 17.0 * ratio, 80.0, 100.0);
  } else {
    sensorData.spo2 = 0;
  }

  // 3. BPM Detection with peak detection
  static bool previousFingerPresent = false;
  bool fingerPresent = (ir >= 5000 && ir <= 250000);
  if (fingerPresent && !previousFingerPresent) {
    lastPeakTime = millis();
    sensorData.bpm = 0;
  }

  if (fingerPresent) {
    if (checkForBeat(ir)) {
      unsigned long now = millis();
      unsigned long delta = now - lastPeakTime;
      lastPeakTime = now;
      float beatBPM = 60000.0 / delta;
      sensorData.bpm = beatBPM;
    }
  } else {
    sensorData.bpm = 0;
  }

  previousFingerPresent = fingerPresent;

  // Add to IR buffer for adaptive thresholding
  if (fingerPresent) {
    irBuffer[irIndex] = ir;
    irIndex = (irIndex + 1) % bufferSize;
  }

  // Dynamic threshold detection for smoother BPM
  long sortedBuffer[bufferSize];
  memcpy(sortedBuffer, irBuffer, sizeof(irBuffer));
  std::sort(sortedBuffer, sortedBuffer + bufferSize);
  long localMax = sortedBuffer[bufferSize - 1];
  long localMin = sortedBuffer[0];
  long threshold = (localMax + localMin) / 2;

  // Peak detection logic
  int i0 = (irIndex - 3 + bufferSize) % bufferSize;
  int i1 = (irIndex - 2 + bufferSize) % bufferSize;
  int i2 = (irIndex - 1 + bufferSize) % bufferSize;
  long prev = irBuffer[i0];
  long mid = irBuffer[i1];
  long next = irBuffer[i2];
  bool above = ir > threshold;
  if (above && !wasAboveThreshold) {
    unsigned long now = millis();
    unsigned long interval = now - lastPeakTime;
    if (interval >= 300 && interval < 2000) {
      lastPeakTime = now;
      float currentBPM = 60000.0 / interval;

      // Moving average smoothing
      bpmBuffer[bpmIndex % 5] = currentBPM;
      bpmIndex++;
      float sum = 0;
      int cnt = 0;
      for (int i = 0; i < 5; i++) {
        if (bpmBuffer[i] > 40 && bpmBuffer[i] < 200) {
          sum += bpmBuffer[i];
          cnt++;
        }
      }
      if (cnt > 0) {
        sensorData.bpm = (sum / cnt) + bpmCalibrationOffset;
      }
    }
  }
  wasAboveThreshold = above;

  // 4. Send data to HTTP server
  if (WiFi.status() == WL_CONNECTED) {
    HTTPClient http;
    http.begin(serverUrl);
    http.addHeader("Content-Type", "application/json");

    // Build JSON payload
    DynamicJsonDocument doc(512);
    doc["temperature"] = sensorData.temperature;
    doc["humidity"] = sensorData.humidity;
    doc["bpm"] = sensorData.bpm;
    doc["spo2"] = sensorData.spo2;
    doc["ir"] = sensorData.irValue;
    doc["accX"] = sensorData.accX;
    doc["accY"] = sensorData.accY;
    doc["accZ"] = sensorData.accZ;
    doc["flameDigital"] = sensorData.flameDigital;
    doc["flameAnalog"] = sensorData.flameAnalog;
    doc["gasDigital"] = sensorData.gasDigital;
    doc["gasAnalog"] = sensorData.gasAnalog;
    doc["timestamp"] = millis();

    // Serialize and send
    char jsonData[512];
    serializeJson(doc, jsonData, sizeof(jsonData));
    Serial.print("Plain JSON Data: ");
    Serial.println(jsonData);

    int httpCode = http.POST(jsonData);
    if (httpCode > 0) {
      Serial.printf("[HTTP] Response code: %d\n", httpCode);
    } else {
      Serial.printf("[HTTP] Error: %s\n", http.errorToString(httpCode).c_str());
    }
    http.end();
  }

  // 5. Send data via ESP-NOW
  esp_err_t result;
  int attempts = 0;
  for (attempts = 0; attempts < 3; attempts++) {
    result = esp_now_send(receiverMac, (uint8_t *)&sensorData, sizeof(sensorData));
    if (result == ESP_OK) break;
    delay(10);
  }

  delay(200);  // Short delay between cycles
}
