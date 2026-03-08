# Arduino Genişletilmiş Motor Kontrolü

## Görseldeki Scratch Blokları İçin Arduino Kodu

Bu kod, uygulamanın "Gelişmiş Mod" ayarında kullanılan karakter bazlı motor kontrolünü destekler.

### Pin Tanımları
```cpp
// Motor A pinleri (Sol motor)
const int MOTOR_A_PIN1 = 11;
const int MOTOR_A_PIN2 = 12;
const int MOTOR_A_SPEED = 10; // PWM pin

// Motor B pinleri (Sağ motor)
const int MOTOR_B_PIN1 = 8;
const int MOTOR_B_PIN2 = 9;
const int MOTOR_B_SPEED = 5; // PWM pin

int currentSpeed = 150; // Varsayılan hız
```

### Setup
```cpp
void setup() {
  Serial.begin(9600); // HC-05/06 için
  // Serial.begin(115200); // ESP32 BLE için
  
  // Motor pinlerini çıkış olarak ayarla
  pinMode(MOTOR_A_PIN1, OUTPUT);
  pinMode(MOTOR_A_PIN2, OUTPUT);
  pinMode(MOTOR_A_SPEED, OUTPUT);
  pinMode(MOTOR_B_PIN1, OUTPUT);
  pinMode(MOTOR_B_PIN2, OUTPUT);
  pinMode(MOTOR_B_SPEED, OUTPUT);
  
  // Başlangıçta motorları durdur
  stopMotors();
}
```

### Ana Döngü
```cpp
void loop() {
  if (Serial.available() > 0) {
    String command = Serial.readStringUntil('\\n');
    command.trim();
    
    // Hız komutu kontrolü
    if (command.startsWith("V")) {
      currentSpeed = command.substring(1).toInt();
      currentSpeed = constrain(currentSpeed, 0, 255);
      return;
    }
    
    // Karakter uzunluğu kontrolü
    if (command.length() != 1) return;
    
    char cmd = command.charAt(0);
    processCommand(cmd);
  }
}
```

### Komut İşleme (Scratch Bloklarına Göre)
```cpp
void processCommand(char cmd) {
  switch(cmd) {
    // Basit Mod Komutları (F/B/R/L/S)
    case 'F': // İleri
      digitalWrite(MOTOR_A_PIN1, HIGH);
      digitalWrite(MOTOR_A_PIN2, LOW);
      digitalWrite(MOTOR_B_PIN1, HIGH);
      digitalWrite(MOTOR_B_PIN2, LOW);
      analogWrite(MOTOR_A_SPEED, currentSpeed);
      analogWrite(MOTOR_B_SPEED, currentSpeed);
      break;
      
    case 'B': // Geri
      digitalWrite(MOTOR_A_PIN1, LOW);
      digitalWrite(MOTOR_A_PIN2, HIGH);
      digitalWrite(MOTOR_B_PIN1, LOW);
      digitalWrite(MOTOR_B_PIN2, HIGH);
      analogWrite(MOTOR_A_SPEED, currentSpeed);
      analogWrite(MOTOR_B_SPEED, currentSpeed);
      break;
      
    case 'R': // Sağ (yerinde dön)
      digitalWrite(MOTOR_A_PIN1, HIGH);
      digitalWrite(MOTOR_A_PIN2, LOW);
      digitalWrite(MOTOR_B_PIN1, LOW);
      digitalWrite(MOTOR_B_PIN2, HIGH);
      analogWrite(MOTOR_A_SPEED, currentSpeed);
      analogWrite(MOTOR_B_SPEED, currentSpeed);
      break;
      
    case 'L': // Sol (yerinde dön)
      digitalWrite(MOTOR_A_PIN1, LOW);
      digitalWrite(MOTOR_A_PIN2, HIGH);
      digitalWrite(MOTOR_B_PIN1, HIGH);
      digitalWrite(MOTOR_B_PIN2, LOW);
      analogWrite(MOTOR_A_SPEED, currentSpeed);
      analogWrite(MOTOR_B_SPEED, currentSpeed);
      break;
      
    case 'S': // Dur
      stopMotors();
      break;
    
    // Genişletilmiş Mod Komutları (A-Z)
    // Görseldeki Scratch bloklarına göre
    case 'A': // Motor A İleri, Motor B Dur
      digitalWrite(MOTOR_A_PIN1, HIGH);
      digitalWrite(MOTOR_A_PIN2, LOW);
      digitalWrite(MOTOR_B_PIN1, LOW);
      digitalWrite(MOTOR_B_PIN2, LOW);
      analogWrite(MOTOR_A_SPEED, currentSpeed);
      analogWrite(MOTOR_B_SPEED, 0);
      break;
      
    case 'C': // Motor A Geri, Motor B Dur
      digitalWrite(MOTOR_A_PIN1, LOW);
      digitalWrite(MOTOR_A_PIN2, HIGH);
      digitalWrite(MOTOR_B_PIN1, LOW);
      digitalWrite(MOTOR_B_PIN2, LOW);
      analogWrite(MOTOR_A_SPEED, currentSpeed);
      analogWrite(MOTOR_B_SPEED, 0);
      break;
      
    case 'G': // Motor A Dur, Motor B İleri
      digitalWrite(MOTOR_A_PIN1, LOW);
      digitalWrite(MOTOR_A_PIN2, LOW);
      digitalWrite(MOTOR_B_PIN1, HIGH);
      digitalWrite(MOTOR_B_PIN2, LOW);
      analogWrite(MOTOR_A_SPEED, 0);
      analogWrite(MOTOR_B_SPEED, currentSpeed);
      break;
      
    case 'I': // Motor A Dur, Motor B Geri
      digitalWrite(MOTOR_A_PIN1, LOW);
      digitalWrite(MOTOR_A_PIN2, LOW);
      digitalWrite(MOTOR_B_PIN1, LOW);
      digitalWrite(MOTOR_B_PIN2, HIGH);
      analogWrite(MOTOR_A_SPEED, 0);
      analogWrite(MOTOR_B_SPEED, currentSpeed);
      break;
      
    case 'X': // Her iki motor geri
      digitalWrite(MOTOR_A_PIN1, LOW);
      digitalWrite(MOTOR_A_PIN2, HIGH);
      digitalWrite(MOTOR_B_PIN1, LOW);
      digitalWrite(MOTOR_B_PIN2, HIGH);
      analogWrite(MOTOR_A_SPEED, currentSpeed);
      analogWrite(MOTOR_B_SPEED, currentSpeed);
      break;
      
    case 'Y': // Motor A İleri düşük hız, Motor B İleri yüksek hız (hafif sağ)
      digitalWrite(MOTOR_A_PIN1, HIGH);
      digitalWrite(MOTOR_A_PIN2, LOW);
      digitalWrite(MOTOR_B_PIN1, HIGH);
      digitalWrite(MOTOR_B_PIN2, LOW);
      analogWrite(MOTOR_A_SPEED, currentSpeed * 0.6);
      analogWrite(MOTOR_B_SPEED, currentSpeed);
      break;
      
    case 'Z': // Motor A İleri yüksek hız, Motor B İleri düşük hız (hafif sol)
      digitalWrite(MOTOR_A_PIN1, HIGH);
      digitalWrite(MOTOR_A_PIN2, LOW);
      digitalWrite(MOTOR_B_PIN1, HIGH);
      digitalWrite(MOTOR_B_PIN2, LOW);
      analogWrite(MOTOR_A_SPEED, currentSpeed);
      analogWrite(MOTOR_B_SPEED, currentSpeed * 0.6);
      break;
      
    default:
      // Bilinmeyen komut, dur
      stopMotors();
      break;
  }
}
```

### Motor Durdurma Fonksiyonu
```cpp
void stopMotors() {
  digitalWrite(MOTOR_A_PIN1, LOW);
  digitalWrite(MOTOR_A_PIN2, LOW);
  digitalWrite(MOTOR_B_PIN1, LOW);
  digitalWrite(MOTOR_B_PIN2, LOW);
  analogWrite(MOTOR_A_SPEED, 0);
  analogWrite(MOTOR_B_SPEED, 0);
}
```

## Komut Listesi

### Basit Mod (F/B/R/L/S)
- `F` - İleri (her iki motor ileri)
- `B` - Geri (her iki motor geri)
- `R` - Sağa dön (sol motor ileri, sağ motor geri)
- `L` - Sola dön (sağ motor ileri, sol motor geri)
- `S` - Dur (her iki motor stop)
- `V{hız}\\n` - Hız ayarla (0-255)

### Gelişmiş Mod (A-Z)
- `A` - Sol motor ileri, sağ motor dur
- `C` - Sol motor geri, sağ motor dur
- `G` - Sol motor dur, sağ motor ileri
- `I` - Sol motor dur, sağ motor geri
- `X` - Her iki motor geri (B ile aynı)
- `Y` - Hafif sağa dön (sol motor %60, sağ motor %100)
- `Z` - Hafif sola dön (sol motor %100, sağ motor %60)

## Test Etme

1. Arduino IDE'de bu kodu yükleyin
2. Serial Monitor'ü açın (9600 baud)
3. Önce hız ayarı gönderin: `V200` (Enter)
4. Yön komutları gönderin: `F`, `B`, `L`, `R`, `S`
5. Gelişmiş komutları deneyin: `A`, `C`, `G`, `I`, `Y`, `Z`

## Uygulama Ayarları

Flutter uygulamasında:
1. Ayarlar'a gidin
2. "Komut Sistemi" bölümünde mod seçin:
   - **Basit Mod**: Temel 4 yön + dur (F/B/R/L/S)
   - **Gelişmiş Mod**: Detaylı motor kontrolü (A-Z)

## Not

Bu kod Arduino Uno, Nano ve benzeri kartlarda çalışır. ESP32 için BLE kullanıyorsanız Serial.begin değerini 115200'e çıkarın ve BLE karakteristik notifikasyonlarını ekleyin.
