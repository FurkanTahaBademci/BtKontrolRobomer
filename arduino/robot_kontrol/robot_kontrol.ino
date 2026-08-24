// ============================================================
//  Mucit Akademisi – BT Kontrol Robomer
//  Arduino Motor Kontrol Kodu
//
//  Desteklenen protokoller:
//    Basit Mod  : F / B / R / L / S
//    Gelişmiş Mod: A / C / G / I / X / Y / Z
//    Hız        : V{0-255}\n
//    Joystick   : J{sol},{sag}\n   (değerler: -255 .. 255)
// ============================================================

// ── Pin Tanımları ────────────────────────────────────────────
// Motor A (Sol motor) — her iki pin PWM, ayrı enable yok
const int MOTOR_A_PIN1 = 9;    // İleri yönü (PWM)
const int MOTOR_A_PIN2 = 10;   // Geri yönü  (PWM)

// Motor B (Sağ motor) — her iki pin PWM, ayrı enable yok
const int MOTOR_B_PIN1 = 5;    // İleri yönü (PWM)
const int MOTOR_B_PIN2 = 6;    // Geri yönü  (PWM)

// ── Değişkenler ──────────────────────────────────────────────
int currentSpeed = 150;         // Basit/Gelişmiş mod hızı (0-255)

// ============================================================
void setup() {
  Serial.begin(9600);           // HC-05 / HC-06 için 9600
  // Serial.begin(115200);      // ESP32 BLE için 115200

  pinMode(MOTOR_A_PIN1, OUTPUT);
  pinMode(MOTOR_A_PIN2, OUTPUT);
  pinMode(MOTOR_B_PIN1, OUTPUT);
  pinMode(MOTOR_B_PIN2, OUTPUT);

  stopMotors();
}

// ============================================================
void loop() {
  if (Serial.available() > 0) {
    String cmd = Serial.readStringUntil('\n');
    cmd.trim();
    if (cmd.length() == 0) return;

    // ── Hız komutu: V{0-255} ─────────────────────────────────
    if (cmd.startsWith("V")) {
      currentSpeed = constrain(cmd.substring(1).toInt(), 0, 255);
      return;
    }

    // ── Joystick komutu: J{sol},{sag} ────────────────────────
    //    sol / sag: -255 (tam geri) .. 255 (tam ileri)
    //    Flutter tarafı Arcade Drive ile hesaplayıp gönderir
    if (cmd.startsWith("J")) {
      String data = cmd.substring(1);
      int comma = data.indexOf(',');
      if (comma > 0) {
        int leftVal  = data.substring(0, comma).toInt();
        int rightVal = data.substring(comma + 1).toInt();
        setMotorValue(MOTOR_A_PIN1, MOTOR_A_PIN2, leftVal);
        setMotorValue(MOTOR_B_PIN1, MOTOR_B_PIN2, rightVal);
      }
      return;
    }

    // ── Basit / Gelişmiş mod (tek karakter) ──────────────────
    if (cmd.length() != 1) return;
    processCommand(cmd.charAt(0));
  }
}

// ============================================================
//  Tek karakter komutlarını işle
// ============================================================
void processCommand(char c) {
  switch (c) {

    // ── Basit Mod ────────────────────────────────────────────
    case 'F':   // İleri
      setMotorValue(MOTOR_A_PIN1, MOTOR_A_PIN2,  currentSpeed);
      setMotorValue(MOTOR_B_PIN1, MOTOR_B_PIN2,  currentSpeed);
      break;

    case 'B':   // Geri
      setMotorValue(MOTOR_A_PIN1, MOTOR_A_PIN2, -currentSpeed);
      setMotorValue(MOTOR_B_PIN1, MOTOR_B_PIN2, -currentSpeed);
      break;

    case 'R':   // Sağa dön (yerinde)
      setMotorValue(MOTOR_A_PIN1, MOTOR_A_PIN2,  currentSpeed);
      setMotorValue(MOTOR_B_PIN1, MOTOR_B_PIN2, -currentSpeed);
      break;

    case 'L':   // Sola dön (yerinde)
      setMotorValue(MOTOR_A_PIN1, MOTOR_A_PIN2, -currentSpeed);
      setMotorValue(MOTOR_B_PIN1, MOTOR_B_PIN2,  currentSpeed);
      break;

    case 'S':   // Dur
      stopMotors();
      break;

    // ── Gelişmiş Mod ─────────────────────────────────────────
    case 'A':   // Sol motor ileri, sağ motor dur
      setMotorValue(MOTOR_A_PIN1, MOTOR_A_PIN2,  currentSpeed);
      setMotorValue(MOTOR_B_PIN1, MOTOR_B_PIN2,  0);
      break;

    case 'C':   // Sol motor geri, sağ motor dur
      setMotorValue(MOTOR_A_PIN1, MOTOR_A_PIN2, -currentSpeed);
      setMotorValue(MOTOR_B_PIN1, MOTOR_B_PIN2,  0);
      break;

    case 'G':   // Sol motor dur, sağ motor ileri
      setMotorValue(MOTOR_A_PIN1, MOTOR_A_PIN2,  0);
      setMotorValue(MOTOR_B_PIN1, MOTOR_B_PIN2,  currentSpeed);
      break;

    case 'I':   // Sol motor dur, sağ motor geri
      setMotorValue(MOTOR_A_PIN1, MOTOR_A_PIN2,  0);
      setMotorValue(MOTOR_B_PIN1, MOTOR_B_PIN2, -currentSpeed);
      break;

    case 'X':   // Her iki motor geri
      setMotorValue(MOTOR_A_PIN1, MOTOR_A_PIN2, -currentSpeed);
      setMotorValue(MOTOR_B_PIN1, MOTOR_B_PIN2, -currentSpeed);
      break;

    case 'Y':   // Hafif sağa dön (sol %60, sağ %100)
      setMotorValue(MOTOR_A_PIN1, MOTOR_A_PIN2, (int)(currentSpeed * 0.6));
      setMotorValue(MOTOR_B_PIN1, MOTOR_B_PIN2,  currentSpeed);
      break;

    case 'Z':   // Hafif sola dön (sol %100, sağ %60)
      setMotorValue(MOTOR_A_PIN1, MOTOR_A_PIN2,  currentSpeed);
      setMotorValue(MOTOR_B_PIN1, MOTOR_B_PIN2, (int)(currentSpeed * 0.6));
      break;

    case 'H':   // Korna aç (opsiyonel buzzer)
      // tone(BUZZER_PIN, 1000);
      break;

    case 'N':   // Korna kapat
      // noTone(BUZZER_PIN);
      break;

    default:
      stopMotors();
      break;
  }
}

// ============================================================
//  val: -255 (tam geri) .. 0 (dur) .. 255 (tam ileri)
//  pin1 ileri PWM, pin2 geri PWM — ayrı enable pini yok
// ============================================================
void setMotorValue(int pin1, int pin2, int val) {
  if (val > 0) {
    analogWrite(pin1, constrain(val, 0, 255));
    analogWrite(pin2, 0);
  } else if (val < 0) {
    analogWrite(pin1, 0);
    analogWrite(pin2, constrain(-val, 0, 255));
  } else {
    analogWrite(pin1, 0);
    analogWrite(pin2, 0);
  }
}

// ============================================================
void stopMotors() {
  setMotorValue(MOTOR_A_PIN1, MOTOR_A_PIN2, 0);
  setMotorValue(MOTOR_B_PIN1, MOTOR_B_PIN2, 0);
}
