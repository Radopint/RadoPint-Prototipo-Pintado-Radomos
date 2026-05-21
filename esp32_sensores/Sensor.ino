#include <Arduino.h>
#include <Wire.h>
#include <Adafruit_VL53L0X.h>

// ==========================
// Pines ESP32
// ==========================
static const int PIN_I2C_SDA   = 21;
static const int PIN_I2C_SCL   = 22;
static const int PIN_XSHUT     = 4;    // opcional, solo si lo conectas
static const int PIN_ALARM_OUT = 27;
static const int PIN_LED       = 2;    // LED interno opcional

// Entradas
static const int PIN_BOTON     = 32;   // botón NO
static const int PIN_MICRO_1   = 33;   // microswitch NC
static const int PIN_MICRO_2   = 25;   // microswitch NC

// ==========================
// Parámetros
// ==========================
static const uint16_t DIST_STOP_MM = 55;
static const uint32_t I2C_FREQ_HZ  = 400000;

// Si quieres que un fallo del sensor también active alarma,
// cambia esto a true.
static const bool ALARM_ON_SENSOR_ERROR = false;

// ==========================
// Sensor VL53L0X
// ==========================
Adafruit_VL53L0X lox = Adafruit_VL53L0X();

// ==========================
// Variables
// ==========================
int16_t lastDistanceMm = -1;
uint32_t lastPrintMs = 0;

// --------------------------------------------------
// LOW  = alarma / mandar señal a RAMPS
// HIGH = normal
// --------------------------------------------------
void setAlarmOutput(bool danger)
{
  digitalWrite(PIN_ALARM_OUT, danger ? LOW : HIGH);
  digitalWrite(PIN_LED, danger ? HIGH : LOW);
}

// --------------------------------------------------
// Botón conectado en NO
//
// COM -> GND
// NO  -> GPIO 32
//
// Sin presionar = HIGH
// Presionado    = LOW
// --------------------------------------------------
bool botonPresionado()
{
  return digitalRead(PIN_BOTON) == LOW;
}

// --------------------------------------------------
// Microswitch conectado en NC
//
// COM -> GND
// NC  -> GPIO
//
// En reposo  = LOW
// Presionado = HIGH
// Cable roto = HIGH, también alarma
// --------------------------------------------------
bool microNCPresionado(int pin)
{
  return digitalRead(pin) == HIGH;
}

// --------------------------------------------------
// Lee distancia del VL53L0X
// Devuelve distancia en mm
// Devuelve -1 si no hay lectura válida
// --------------------------------------------------
int16_t readDistanceMm()
{
  VL53L0X_RangingMeasurementData_t measure;

  lox.rangingTest(&measure, false);

  // RangeStatus 4 suele indicar fuera de rango en la librería Adafruit.
  // También descartamos distancia 0.
  if (measure.RangeStatus != 4 && measure.RangeMilliMeter > 0) {
    return (int16_t)measure.RangeMilliMeter;
  }

  return -1;
}

// --------------------------------------------------
// Debug serial
// --------------------------------------------------
void printStatus(
  int16_t distanceMm,
  bool sensorDanger,
  bool boton,
  bool micro1,
  bool micro2,
  bool sensorError
)
{
  uint32_t now = millis();
  if (now - lastPrintMs < 100) return;
  lastPrintMs = now;

  Serial.print("Distancia: ");
  if (distanceMm < 0) {
    Serial.print("sin dato valido");
  } else {
    Serial.print(distanceMm);
    Serial.print(" mm");
  }

  Serial.print(" | sensor=");
  if (sensorError) {
    Serial.print("SIN DATO");
  } else {
    Serial.print(sensorDanger ? "ALARMA" : "OK");
  }

  Serial.print(" | boton_NO=");
  Serial.print(boton ? "PRESIONADO" : "suelto");

  Serial.print(" | micro1_NC=");
  Serial.print(micro1 ? "PRESIONADO/ABIERTO" : "reposo");

  Serial.print(" | micro2_NC=");
  Serial.print(micro2 ? "PRESIONADO/ABIERTO" : "reposo");

  Serial.print(" | salida GPIO27=");
  Serial.println((digitalRead(PIN_ALARM_OUT) == LOW) ? "ALARMA" : "NORMAL");
}

void setup()
{
  pinMode(PIN_ALARM_OUT, OUTPUT);
  pinMode(PIN_LED, OUTPUT);

  pinMode(PIN_BOTON, INPUT_PULLUP);
  pinMode(PIN_MICRO_1, INPUT_PULLUP);
  pinMode(PIN_MICRO_2, INPUT_PULLUP);

  // Estado normal al arrancar
  setAlarmOutput(false);

  Serial.begin(115200);
  delay(300);

  Serial.println();
  Serial.println("Iniciando VL53L0X con ESP32...");

  // I2C del ESP32
  Wire.begin(PIN_I2C_SDA, PIN_I2C_SCL);
  Wire.setClock(I2C_FREQ_HZ);

  // XSHUT es opcional.
  // Si tu módulo VL53L0X no tiene XSHUT conectado, esto no afecta.
  pinMode(PIN_XSHUT, OUTPUT);
  digitalWrite(PIN_XSHUT, LOW);
  delay(10);
  digitalWrite(PIN_XSHUT, HIGH);
  delay(10);

  // Dirección normal del VL53L0X: 0x29
  if (!lox.begin(0x29, false, &Wire)) {
    Serial.println("ERROR: No se detecta el VL53L0X.");
    Serial.println("Revisa SDA, SCL, 3.3V, GND y direccion I2C.");

    // Por seguridad puedes dejarlo en alarma si falla el sensor
    if (ALARM_ON_SENSOR_ERROR) {
      setAlarmOutput(true);
    }

    while (1) {
      delay(100);
    }
  }

  Serial.println("VL53L0X iniciado correctamente.");
  Serial.print("DIST_STOP_MM = ");
  Serial.println(DIST_STOP_MM);
}

void loop()
{
  lastDistanceMm = readDistanceMm();

  bool sensorError = lastDistanceMm < 0;

  bool sensorDanger = false;
  if (lastDistanceMm > 0 && lastDistanceMm <= DIST_STOP_MM) {
    sensorDanger = true;
  }

  bool botonActivo  = botonPresionado();
  bool micro1Activo = microNCPresionado(PIN_MICRO_1);
  bool micro2Activo = microNCPresionado(PIN_MICRO_2);

  // Todos hacen exactamente lo mismo:
  // sensor, botón o microswitch activado => GPIO 27 en LOW
  bool danger = sensorDanger || botonActivo || micro1Activo || micro2Activo;

  if (ALARM_ON_SENSOR_ERROR && sensorError) {
    danger = true;
  }

  setAlarmOutput(danger);

  printStatus(
    lastDistanceMm,
    sensorDanger,
    botonActivo,
    micro1Activo,
    micro2Activo,
    sensorError
  );

  delay(20);
}