# BT Kontrol Robomer 🤖

Android için Bluetooth (Classic ve BLE) ile robot kontrolü yapabilen Flutter uygulaması.

## 📱 Özellikler

- ✅ **Dual Bluetooth Desteği**: Hem Classic Bluetooth (HC-05/HC-06) hem de BLE modülleri
- 🎮 **Yön Kontrolü**: İleri, geri, sağ, sol butonları ile basılı tut kontrolü
- ⚡ **Hız Kontrolü**: 0-255 PWM aralığında motor hızı ayarı
- 📜 **Bağlantı Geçmişi**: Son bağlanan 10 cihazı kaydeder
- 🔍 **Cihaz Tarama**: Yakındaki Bluetooth cihazları tarar ve listeler
- 🌙 **Dark Mode**: Sistem teması desteği
- 🎯 **Modern UI**: Material Design 3 ile güncel arayüz

## 🛠️ Teknik Detaylar

### Kullanılan Teknolojiler

- **Flutter**: 3.7.2+
- **State Management**: Provider
- **Bluetooth Classic**: flutter_bluetooth_serial
- **BLE**: flutter_blue_plus
- **İzinler**: permission_handler
- **Local Storage**: shared_preferences

### Proje Yapısı

```
lib/
├── core/                           # Core katmanı
│   ├── bluetooth/                  # Bluetooth altyapısı
│   │   ├── models/                 # Veri modelleri
│   │   ├── bluetooth_controller.dart
│   │   ├── classic_bluetooth_controller.dart
│   │   └── ble_bluetooth_controller.dart
│   ├── constants/                  # Sabitler
│   └── permissions/                # İzin yönetimi
├── providers/                      # State management
├── screens/                        # UI ekranları
├── widgets/                        # Yeniden kullanılabilir widget'lar
└── main.dart                       # Ana dosya
```

## 🚀 Kurulum

### 1. Gereksinimler

- Flutter SDK 3.7.2 veya üzeri
- Android SDK (minSdk 21)
- Android telefon veya emülatör
- Arduino + HC-05/HC-06 veya BLE modülü

### 2. Projeyi Çalıştırma

```bash
# Bağımlılıkları yükle
flutter pub get

# Android cihaza yükle
flutter run
```

### 3. Arduino Kurulumu

Arduino kodunuzu güncellemek için `ARDUINO_GUNCELLEME.md` dosyasına bakın.

**Hızlı Arduino Kodu (Hız Kontrolü ile):**

```cpp
#define SOL_MOTOR1 5   
#define SOL_MOTOR2 6   
#define SAG_MOTOR1 9   
#define SAG_MOTOR2 10 

char komut;
int motorHiz = 150;
String gelenVeri = "";

void setup() {
  pinMode(SOL_MOTOR1, OUTPUT);
  pinMode(SOL_MOTOR2, OUTPUT);
  pinMode(SAG_MOTOR1, OUTPUT);
  pinMode(SAG_MOTOR2, OUTPUT);
  Serial.begin(9600);   
}

void loop() {
  if (Serial.available()) {
    komut = Serial.read();
    
    if (komut == 'V') {
      delay(10);
      while (Serial.available()) {
        char c = Serial.read();
        if (c == '\n' || c == '\r') break;
        gelenVeri += c;
      }
      int yeniHiz = gelenVeri.toInt();
      if (yeniHiz >= 0 && yeniHiz <= 255) {
        motorHiz = yeniHiz;
      }
      gelenVeri = "";
    }
    else {
      if (komut == 'F') ileri();
      else if (komut == 'B') geri();
      else if (komut == 'R') sag();
      else if (komut == 'L') sol();
      else if (komut == 'S') dur();
    }
  }
}

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

## 📲 Kullanım

### 1. İlk Açılış

- Uygulamayı açın
- Bluetooth ve Location izinlerini verin
- Bluetooth Classic veya BLE seçin

### 2. Cihaz Bağlantısı

- "Cihaz Tara" butonuna basın
- Listeden cihazınızı seçin
- Bağlantı kurulana kadar bekleyin

### 3. Robot Kontrolü

- **Yön Butonları**: Basılı tutun, bıraktığınızda robot durur
- **Hız Slider**: Motor PWM hızını ayarlayın (0-255)
- **Acil Dur**: Anında durma için büyük kırmızı buton

### 4. Bağlantı Geçmişi

- Son bağlanan cihazlar üst kısımda görünür
- Hızlıca yeniden bağlanabilirsiniz

## � Uygulama Güncelleme

Uygulamayı açtığınızda yeni versiyon bulunursa otomatik olarak kontrol edilir.

> 📖 **Detaylı güncelleme rehberi için**: [UPDATE_GUIDE.md](releases/UPDATE_GUIDE.md) dosyasını okuyun
> - Adım adım güncelleme talimatları
> - Sorun çözme rehberi
> - Manuel kurulum yöntemi

**Hızlı Güncelleme:**
1. Uygulamayı açın
2. "Güncelleme Mevcut" dialog'u göreceğiniz
3. "Şimdi Güncelle" butonuna basın
4. İndirme başlar → Android yükleyicisi açılır → Yükle

## �🔧 Sorun Giderme

### Bağlantı Kurulamıyor

- ✅ Bluetooth'un açık olduğundan emin olun
- ✅ İzinlerin verildiğini kontrol edin
- ✅ HC-05/06 modülünün baud rate'ini kontrol edin (9600)
- ✅ Arduino'nun çalıştığından emin olun

### Komutlar İletilmiyor

- ✅ Bağlantı durumunu kontrol edin (yeşil nokta)
- ✅ Arduino Serial Monitor'de komutları görüyor musunuz?
- ✅ Motor pinlerinin doğru bağlı olduğunu kontrol edin

### BLE Bulunamıyor

- ✅ Location servisinin açık olduğundan emin olun
- ✅ BLE modülünüzün açık olduğunu kontrol edin
- ✅ UUID'lerin uyumlu olduğunu kontrol edin

## 🎯 Robot Komutları

| Komut | Açıklama |
|-------|----------|
| `F` | İleri git |
| `B` | Geri git |
| `R` | Sağa dön |
| `L` | Sola dön |
| `S` | Dur |
| `V{sayı}\n` | Hız ayarla (örn: V200\n) |

## 📝 Geliştirme Notları

### Yeni Özellik Eklemek

1. Model ekle: `lib/core/bluetooth/models/`
2. Provider güncelle: `lib/providers/bluetooth_provider.dart`
3. UI ekle: `lib/screens/` veya `lib/widgets/`

### BLE UUID Değiştirme

`lib/core/constants/bluetooth_constants.dart` dosyasındaki UUID'leri güncelleyin.

### Farklı Motor Sürücü Kullanma

Arduino kodundaki pin numaralarını ve motor fonksiyonlarını güncelleyin.

## 🤝 Katkıda Bulunma

1. Fork yapın
2. Feature branch oluşturun (`git checkout -b feature/amazing-feature`)
3. Commit yapın (`git commit -m 'feat: Add amazing feature'`)
4. Push edin (`git push origin feature/amazing-feature`)
5. Pull Request açın

## 📄 Lisans

Bu proje eğitim amaçlıdır. Özgürce kullanabilir ve geliştirebilirsiniz.

## 🙏 Teşekkürler

- Flutter ekibine
- flutter_bluetooth_serial ve flutter_blue_plus paket geliştiricilerine
- Arduino topluluğuna

---

**Not**: Bu uygulama sadece Android'i desteklemektedir. iOS'un Classic Bluetooth'u desteklememesi nedeniyle iOS versiyonu sadece BLE ile çalışabilir.

**İyi Kodlamalar! 🚀**
