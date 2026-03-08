# Arduino Kod Güncelleme Önerisi

## Mevcut Durum

Şu anda Arduino kodunuz sadece yön komutlarını destekliyor:
- `F` - İleri
- `B` - Geri  
- `R` - Sağ
- `L` - Sol
- `S` - Dur

Motor hızları sabit (PWM 150).

## Flutter Uygulaması ile Tam Uyumluluk için Güncellemeler

### 1. Hız Kontrolü Ekleme

Flutter uygulaması `V{hız}\n` formatında hız komutları gönderiyor (örn: `V200\n`).

#### Güncellenmiş Arduino Kodu:

```cpp
// Motor pinlerini tanımlıyoruz
#define SOL_MOTOR1 5   
#define SOL_MOTOR2 6   
#define SAG_MOTOR1 9   
#define SAG_MOTOR2 10 

char komut; // Telefon'dan gelen komut
int motorHiz = 150; // Varsayılan hız (0-255)
String gelenVeri = ""; // Hız komutu için string buffer

void setup() {
  // Motor pinlerini çıkış olarak ayarlıyoruz
  pinMode(SOL_MOTOR1, OUTPUT);
  pinMode(SOL_MOTOR2, OUTPUT);
  pinMode(SAG_MOTOR1, OUTPUT);
  pinMode(SAG_MOTOR2, OUTPUT);

  // Seri haberleşme (Hem Bluetooth hem USB Serial aynı hattan gelir)
  Serial.begin(9600);   
  Serial.println("Bluetooth araba hazır. Komut bekleniyor...");
}

void loop() {
  if (Serial.available()) {      // Bluetooth'tan veri geldiyse
    komut = Serial.read();       // Karakteri oku
    
    // Hız komutu kontrolü
    if (komut == 'V') {
      // Hız değerini oku (V karakterinden sonra gelen sayı)
      delay(10); // Tüm verinin gelmesini bekle
      while (Serial.available()) {
        char c = Serial.read();
        if (c == '\n' || c == '\r') {
          break;
        }
        gelenVeri += c;
      }
      
      // String'i integer'a çevir
      int yeniHiz = gelenVeri.toInt();
      
      // Hız aralığını kontrol et (0-255)
      if (yeniHiz >= 0 && yeniHiz <= 255) {
        motorHiz = yeniHiz;
        Serial.print("Hız güncellendi: ");
        Serial.println(motorHiz);
      }
      
      gelenVeri = ""; // Buffer'ı temizle
    }
    // Yön komutları
    else {
      Serial.println(komut);       // Seri monitöre yaz

      // Gelen komuta göre hareket et
      if (komut == 'F') ileri();    // Forward
      else if (komut == 'B') geri(); // Backward
      else if (komut == 'R') sag();  // Right
      else if (komut == 'L') sol();  // Left
      else if (komut == 'S') dur();  // Stop
    }
  }
}

// ----------------- Fonksiyonlar -----------------

void ileri() {
  analogWrite(SOL_MOTOR1, motorHiz);   
  analogWrite(SOL_MOTOR2, 0);

  analogWrite(SAG_MOTOR1, motorHiz);   
  analogWrite(SAG_MOTOR2, 0);
}

void geri() {
  analogWrite(SOL_MOTOR1, 0);
  analogWrite(SOL_MOTOR2, motorHiz);   

  analogWrite(SAG_MOTOR1, 0);
  analogWrite(SAG_MOTOR2, motorHiz);   
}

void sag() {
  analogWrite(SOL_MOTOR1, motorHiz);   
  analogWrite(SOL_MOTOR2, 0);

  analogWrite(SAG_MOTOR1, 0);
  analogWrite(SAG_MOTOR2, motorHiz);   
}

void sol() {
  analogWrite(SOL_MOTOR1, 0);
  analogWrite(SOL_MOTOR2, motorHiz);   

  analogWrite(SAG_MOTOR1, motorHiz);   
  analogWrite(SAG_MOTOR2, 0);
}

void dur() {
  analogWrite(SOL_MOTOR1, 0);
  analogWrite(SOL_MOTOR2, 0);
  analogWrite(SAG_MOTOR1, 0);
  analogWrite(SAG_MOTOR2, 0);
}
```

### 2. BLE Modül Kullanımı (Opsiyonel)

Eğer BLE (HM-10, ESP32, vb.) kullanacaksanız:

#### HM-10 için:
- Baud rate: 9600 (varsayılan)
- AT komutları ile yapılandırma: `AT+NAMERobotBT` (isim değiştirme)
- Arduino kodunda değişiklik gerekmez, yukarıdaki kod çalışır

#### ESP32 için BLE Server:

ESP32 kullanıyorsanız, BLE GATT server kurmanız gerekir. Bu daha karmaşık bir yapıdır.

```cpp
#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>
#include <BLE2902.h>

// UUID'ler (Flutter uygulaması ile uyumlu)
#define SERVICE_UUID        "0000ffe0-0000-1000-8000-00805f9b34fb"
#define CHARACTERISTIC_UUID "0000ffe1-0000-1000-8000-00805f9b34fb"

BLECharacteristic *pCharacteristic;
bool deviceConnected = false;
int motorHiz = 150;

// Motor pinleri
#define SOL_MOTOR1 5   
#define SOL_MOTOR2 6   
#define SAG_MOTOR1 9   
#define SAG_MOTOR2 10 

class MyServerCallbacks: public BLEServerCallbacks {
    void onConnect(BLEServer* pServer) {
      deviceConnected = true;
      Serial.println("BLE bağlandı");
    };

    void onDisconnect(BLEServer* pServer) {
      deviceConnected = false;
      Serial.println("BLE bağlantısı kesildi");
    }
};

class MyCallbacks: public BLECharacteristicCallbacks {
    void onWrite(BLECharacteristic *pCharacteristic) {
      std::string value = pCharacteristic->getValue();

      if (value.length() > 0) {
        char komut = value[0];
        
        if (komut == 'V') {
          // Hız komutu
          String hizStr = "";
          for (int i = 1; i < value.length(); i++) {
            if (value[i] == '\n' || value[i] == '\r') break;
            hizStr += value[i];
          }
          int yeniHiz = hizStr.toInt();
          if (yeniHiz >= 0 && yeniHiz <= 255) {
            motorHiz = yeniHiz;
            Serial.printf("Hız: %d\n", motorHiz);
          }
        } else {
          // Yön komutları
          Serial.printf("Komut: %c\n", komut);
          if (komut == 'F') ileri();
          else if (komut == 'B') geri();
          else if (komut == 'R') sag();
          else if (komut == 'L') sol();
          else if (komut == 'S') dur();
        }
      }
    }
};

void setup() {
  Serial.begin(115200);
  
  // Motor pinlerini ayarla
  pinMode(SOL_MOTOR1, OUTPUT);
  pinMode(SOL_MOTOR2, OUTPUT);
  pinMode(SAG_MOTOR1, OUTPUT);
  pinMode(SAG_MOTOR2, OUTPUT);

  // BLE başlat
  BLEDevice::init("RobotBT");
  BLEServer *pServer = BLEDevice::createServer();
  pServer->setCallbacks(new MyServerCallbacks());

  BLEService *pService = pServer->createService(SERVICE_UUID);
  pCharacteristic = pService->createCharacteristic(
                      CHARACTERISTIC_UUID,
                      BLECharacteristic::PROPERTY_READ |
                      BLECharacteristic::PROPERTY_WRITE |
                      BLECharacteristic::PROPERTY_NOTIFY
                    );

  pCharacteristic->setCallbacks(new MyCallbacks());
  pCharacteristic->addDescriptor(new BLE2902());

  pService->start();
  
  BLEAdvertising *pAdvertising = BLEDevice::getAdvertising();
  pAdvertising->addServiceUUID(SERVICE_UUID);
  pAdvertising->start();
  
  Serial.println("BLE robot hazır!");
}

void loop() {
  delay(10);
}

// Motor fonksiyonları aynı
void ileri() {
  analogWrite(SOL_MOTOR1, motorHiz);   
  analogWrite(SOL_MOTOR2, 0);
  analogWrite(SAG_MOTOR1, motorHiz);   
  analogWrite(SAG_MOTOR2, 0);
}

void geri() {
  analogWrite(SOL_MOTOR1, 0);
  analogWrite(SOL_MOTOR2, motorHiz);   
  analogWrite(SAG_MOTOR1, 0);
  analogWrite(SAG_MOTOR2, motorHiz);   
}

void sag() {
  analogWrite(SOL_MOTOR1, motorHiz);   
  analogWrite(SOL_MOTOR2, 0);
  analogWrite(SAG_MOTOR1, 0);
  analogWrite(SAG_MOTOR2, motorHiz);   
}

void sol() {
  analogWrite(SOL_MOTOR1, 0);
  analogWrite(SOL_MOTOR2, motorHiz);   
  analogWrite(SAG_MOTOR1, motorHiz);   
  analogWrite(SAG_MOTOR2, 0);
}

void dur() {
  analogWrite(SOL_MOTOR1, 0);
  analogWrite(SOL_MOTOR2, 0);
  analogWrite(SAG_MOTOR1, 0);
  analogWrite(SAG_MOTOR2, 0);
}
```

## Test Adımları

### Classic Bluetooth (HC-05/06) Test:
1. Arduino'ya güncellenmiş kodu yükle
2. HC-05/06 modülünü bağla (RX, TX, VCC, GND)
3. Seri monitörde "Bluetooth araba hazır" mesajını kontrol et
4. Flutter uygulamasında "Classic BT" seç ve tara
5. HC-05/06 cihazını bul ve bağlan
6. Yön butonlarını test et
7. Hız slider'ını değiştir ve motor hızının değiştiğini gözlemle

### BLE Test (ESP32):
1. ESP32'ye BLE kodunu yükle
2. Seri monitörde "BLE robot hazır!" mesajını kontrol et
3. Flutter uygulamasında "BLE" seç ve tara
4. "RobotBT" cihazını bul ve bağlan
5. Yön butonlarını test et
6. Hız slider'ını değiştir

## Önemli Notlar

1. **Baud Rate**: HC-05/06 için 9600, ESP32 için 115200 kullanılıyor
2. **Pin Numaraları**: Motor pinlerini kendi devre şemanıza göre ayarlayın
3. **Hız Formatı**: Flutter uygulaması `V{sayı}\n` formatında gönderiyor
4. **BLE UUID'ler**: Flutter uygulamasındaki UUID'ler HM-10 default değerleridir
5. **ESP32 Kütüphane**: ESP32 BLE kodu için Arduino IDE'de ESP32 board desteği gerekli

## Sorun Giderme

- **Bağlantı kurulamıyor**: Bluetooth modülünün doğru pin bağlantısını kontrol et
- **Komutlar gitmiyor**: Serial monitörde gelen komutları kontrol et
- **Hız değişmiyor**: Hız komutunun doğru formatını (`V150\n`) kontrol et
- **ESP32 BLE çalışmıyor**: UUID'leri ve GATT service yapısını kontrol et

## Gelişmiş Özellikler (Opsiyonel)

Ekleyebileceğiniz özellikler:
- Batarya voltaj ölçümü (Arduino'dan telefona gönder)
- Mesafe sensörü (otomatik dur)
- LED kontrolleri
- Buzzer sesi
- Hız profilleri (yavaş, orta, hızlı butonlar)
