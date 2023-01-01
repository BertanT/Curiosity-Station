/*
 * Project Curiosity-Station-Firmware
 * Description:
 * Author: Copyright (c) 2021 Mehmet Bertan Tarakçıoğlu
 * Date: April 30 2021
 */

// Include the BME280 Sensor Library written by Adafruit!
#include <Adafruit_BME280.h>
// Include the VEML043 UV sensor and MAX17043 battery gauge library written by SparkFun!
#include <SparkFun_VEML6075_Arduino_Library.h> // Call by "lipo"
#include <SparkFunMAX17043.h>

// Define weather meter pins
#define anemometer D7
#define windVane A0
#define rainGauge A2

// Define the analog light sensor pin
#define lightSensor A1

//Define BME280 software SPI pins and initialize it as bmeSensor
#define BME_SCK D4
#define BME_MISO D3
#define BME_MOSI D2
#define BME_CS D5
Adafruit_BME280 bmeSensor(BME_CS, BME_MOSI, BME_MISO, BME_SCK);

// Define the VEML6075(Uses I2C) as UVSensor
VEML6075 uvSensor;

// Define debounce times for the rain gauge and anemometer in order to prevent false readings caused by reed switches without complex circuitry
#define RG_DEBOUNCE 30000
#define AN_DEBOUNCE 15000
// Define the base sea level pressure to calculate an estimate altitude using the BME280
#define SEALEVELPRESSURE_HPA (1013.25)

// Arrays for detecting wind direction. The first array, expected sensor input is commented out since it is only for reference
// const int windVaneReadingsExp[16] = { 3143, 1624, 1845, 335, 372, 264, 738, 506, 1149, 979, 2520, 2397, 3780, 3309, 3548, 2810 };
const int windVaneReadingsMin[16] = { 2986, 1543, 1753, 318, 353, 251, 701, 481, 1092, 930, 2394, 2277, 3591, 3144, 3371, 2670 };
const int windVaneReadingsMax[16] = { 3300, 1705, 1937, 352, 391, 277, 775, 531, 1206, 1028, 2646, 2517, 3969, 3474, 3725, 2951 };
const double windDirectionsDegrees[16] = {0, 22.5, 45, 67.5, 90, 112.5, 135, 157.5, 180, 202.5, 225, 247.5, 270, 292.5, 315, 337.5 };

// Define variables to store weather data
int updateTime, temperature, relativeHumidity, barometricPressure, estimateAltitude, lightIntensity, uvIndex, batteryPercentage = 0;
double windSpeed, windDirection, rainfall = 0;

// Define a LED status to be used at the time of hardware failure
// If one or more sensors fail, the onboard RGB LED will breathe an orange color

// A soft delay function that doesn't cause cloud errors
LEDStatus breatheOrange(RGB_COLOR_ORANGE, LED_PATTERN_FADE, LED_SPEED_NORMAL, LED_PRIORITY_IMPORTANT);

// The normal delay prevents Particle.process() from being called automatically, which is necessary for maintining cloud connection.
inline void softDelay(uint32_t duration) {
    for (uint32_t ms = millis(); millis() - ms < duration; Particle.process());
}

// Function for reading the value of the wind vane and determine the wind direction
double readWindDirectionDegrees() {
  int windVaneReading = analogRead(windVane);
  double output = 0;
  for (int i=0; i<15; i++) {
    if (windVaneReading >= windVaneReadingsMin[i] && windVaneReading <= windVaneReadingsMax[i]) {
      output = windDirectionsDegrees[i];
      break;
    }
  }
  return output;
}

// Variable to store keep count of rain gauge tips
int rainGaugeTips = 0;

// Variable to store last rain gauge register time - for debounce protection
double tLastRGRegister = 0;

// Count rain gauge registers and fileter out debounces using the predefined RG_DEBOUNCE constant
void countRain() {
  if ((micros() - tLastRGRegister) >= RG_DEBOUNCE) {
    rainGaugeTips++;
    tLastRGRegister = micros();
  }
}

// Variable to store last rain gauge register time - again, for debounce protection ;)
double tLastAnemometerRegister = 0;

// Local variable to keep count of anemometer registers in the current second
int currentAnemometerRegisters = 0;

// Local variable to hold the latest anemometer registers/second reading
int anemometerRegistersPerSecond = 0;

// Count the anemometer registers and filter out debounces using the predefined AN_DEBOUNCE constant
void countAnemometer() {
if ((micros() - tLastAnemometerRegister) >= AN_DEBOUNCE) {
  currentAnemometerRegisters++;
  tLastAnemometerRegister = micros();
  }
}

void readWindSpeed() {
  anemometerRegistersPerSecond = currentAnemometerRegisters;
  currentAnemometerRegisters = 0;
}

Timer anemometerTimer(1000, readWindSpeed);

// A function for putting sensors into sleep and waking them up :)
// BME280 is excluded since the force mode puts the sensor into sleep between measurements automatically!
void setSensorSleep(bool enable=true) {
  if (enable) {
  lipo.sleep();
  uvSensor.shutdown();
  // Report!
  Serial.println("\nPut sensors to sleep for saving power!");
  }else {
  lipo.wake(),
  uvSensor.powerOn();
  Serial.println("\nYour sensors have woken up from sleep :)");
  }
}

// Define variables to hold device info
String csID = "CuriosityStationBeta1";
bool hardwareFailure = false;

// Function for taking a measurement and updating cloud variables
void takeWeatherMeasurement() {
  // Wake the sensors!
  setSensorSleep(false);
  // Let the serial know
  Serial.println("\nTaking new mesurements and pushing it to the cloud...");

  bmeSensor.takeForcedMeasurement();
  temperature = bmeSensor.readTemperature();
  relativeHumidity = bmeSensor.readHumidity();
  barometricPressure = bmeSensor.readPressure() / 100 ;
  estimateAltitude = bmeSensor.readAltitude(SEALEVELPRESSURE_HPA);

  // Convert rain gauge tips to millimeters of rainfall
  rainfall = rainGaugeTips * 0.2794;

  // Convert anemometer registers/second to wind speed km/h
  windSpeed = anemometerRegistersPerSecond * 2.4011;

  windDirection = readWindDirectionDegrees();

  uvIndex = uvSensor.index();
  lightIntensity = map(analogRead(lightSensor), 0, 4095, 0, 100);

  // Li-Po reading can be more than 100% when plugged in without a battery
  // The if clause prevents reading more than 100%
  int fuelGaugeReading = lipo.getSOC();
  if (fuelGaugeReading > 100) {
      batteryPercentage = 100;
  }else {
      batteryPercentage = fuelGaugeReading;
  }
  updateTime = Time.now();

  // Put 'em back to sleep :)
  setSensorSleep(true);
  
  // Let the cloud know ;)
  Particle.publish("newMeasurement");
}

// Switch to external antenna for better WiFi reception
// Uncomment the next line if you have an external antenna plugged into your device
STARTUP(WiFi.selectAntenna(ANT_EXTERNAL));

// The one and the only setup
void setup() {
  // Start the serial monitor at 9600 baud and greet our dear user :))
  Serial.begin(9600);
  Serial.print("Hey! Welcome to" + csID + ":)");
  Serial.println("Hope you are having an amazing day. Lets get started!");
  Wire.begin();
  // Pin modes!
  pinMode(anemometer, INPUT);
  pinMode(windVane, INPUT);
  pinMode(rainGauge, INPUT_PULLDOWN);
  pinMode(lightSensor, INPUT);

  // Begin sensors and report to serial monitor
  Serial.println("\n Starting sensors:");
  const bool bmeBeginSucceeded = bmeSensor.begin();
  const bool uvBeginSucceeded = uvSensor.begin();
  const bool lipoBeginSucceeded = lipo.begin();
  if (bmeBeginSucceeded) {
    Serial.println("\t* Successfully started BME280 - the temperature, relative humidity, and barometric pressure sensor!");
    // Set up BME280 mode and sampling
    // Force mode automatically puts the station to sleep between measurements
    // Sampling rates are the recommended values from the manufacturer for weather monitoring
    bmeSensor.setSampling(Adafruit_BME280::MODE_FORCED, 
                        Adafruit_BME280::SAMPLING_X1,
                        Adafruit_BME280::SAMPLING_X1,
                        Adafruit_BME280::SAMPLING_X1, 
                        Adafruit_BME280::FILTER_OFF);
  }else {
    Serial.println("\t* Cannot start BME280 :( - the temperature, relative humidity, and barometric pressure sensor!");
  }
  if (uvBeginSucceeded) {
    Serial.println("\t* Successfully VEML6075 - the UV sensor!");
    uvSensor.setIntegrationTime(VEML6075::IT_200MS);
    uvSensor.setHighDynamic(VEML6075::DYNAMIC_HIGH);
  }else {
    Serial.println("\t* Cannot start VEML6075 :( - the UV sensor!");
  }
  if (lipoBeginSucceeded) {
    Serial.println("\t* Successfully started MAX17043 - the Li-Po battery gauge!");
  }else {
    Serial.println("\t* Cannot start MAX17043 :( - the Li-Po battery gauge!");
  }

  //Report hardware error to the cloud and report to serial monitor
  if (!(bmeBeginSucceeded && uvBeginSucceeded && lipoBeginSucceeded)) {
    Serial.println("\nThe station couldn't start all of the sensors :( The station will keep functioning as good as it can.");
    Serial.println("Hardware failure is reported to the cloud. Please make sure your wiring is correct and your sensors are functioning.");

    hardwareFailure = true;

    // Make the LED fade orange instad of blue if hardware failure was detected
    breatheOrange.setActive(true);
  }

  // Time to register cloud variables - and report to the serial monitor as usual
  // If failed, wait one minute and restart the station try again
  const bool cloudRegisterSucceeded = (
    Particle.variable("firmwareID", csID) &&
    Particle.variable("hardwareFailure", hardwareFailure) &&
    Particle.variable("updateTimeEpoch", updateTime) &&
    Particle.variable("batteryPercentage", batteryPercentage) &&
    Particle.variable("temperatureC", temperature) &&
    Particle.variable("relativeHumidity", relativeHumidity) &&
    Particle.variable("barometricPressureMB", barometricPressure) &&
    Particle.variable("estimateAltitudeM", estimateAltitude) &&
    Particle.variable("uvIndex", uvIndex) &&
    Particle.variable("lightPercentage", lightIntensity) &&
    Particle.variable("windSpeedKMH", windSpeed) &&
    Particle.variable("windDirectionDeg", windDirection) &&
    Particle.variable("rainfallMM", rainfall));
    
  if (cloudRegisterSucceeded) {
    Serial.println("\nSuccessfully registered all variables and functions to the cloud!");
  }else {
    Serial.println("\nCannot register all variables and/or functions to the cloud :(\n Restarting station to try again in a minute");
    softDelay(60000);
    System.reset();
  }
  
  Serial.println("\nStation startup complete! :)");

  // Attach interupts for anemometer and rain gauge pins
  attachInterrupt(anemometer, countAnemometer, RISING);
  attachInterrupt(rainGauge, countRain, RISING);

  // Start the anemometer timer!
  anemometerTimer.start();
}

void loop() {
  // Take a measurement every minute
  takeWeatherMeasurement();
  softDelay(60000);
}