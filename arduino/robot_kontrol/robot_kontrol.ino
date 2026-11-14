// ============================================================
//  Mucit Akademisi – BT Kontrol Robomer
//  Arduino Nano Motor Kontrol Kodu  (v2 – düşük gecikme)
//
//  Desteklenen komutlar (uygulama → robot):
//    Basit Mod   : F / B / R / L / S        (tek karakter, sonlandırıcı YOK)
//    Gelişmiş Mod: A / C / G / I / X / Y / Z (tek karakter)
//    Korna       : H (aç) / N (kapat)
//    Hız         : V{0-255}\n               örn. "V150\n"
//    Joystick    : J{sol},{sag}\n           örn. "J200,-150\n"  (-255..255)
//    Ping        : P  → robot hemen "P\r\n" cevabı yollar (gecikme testi)
//
//  ── Bu sürümde neden değişiklik yapıldı? ──────────────────────
//  1) GECİKME: Eski kod komutları Serial.readStringUntil('\n') ile
//     okuyordu. Uygulama F/B/S gibi tek karakterli komutları '\n'
//     OLMADAN gönderiyor. readStringUntil '\n' gelmeyince Serial
//     timeout süresini (varsayılan 1000 ms) bekliyor. Sonuç: her tuş
//     komutu robota ~1 saniye geç uygulanıyordu (ölçülen: ~1010 ms).
//  2) KAYBOLAN KOMUTLAR: Bu 1 saniye içinde "F" ve ardından "S"
//     gelirse ikisi "FS" diye birleşiyor, uzunluğu 1 olmadığı için
//     tamamen yok sayılıyordu. Kısa dokunuşlar robotu hiç oynatmıyordu.
//  ÇÖZÜM: Veri artık bayt bayt okunuyor. Tek karakterli komut geldiği
//     anda uygulanıyor (ölçülen: ~6 ms). Sadece çok karakterli V ve J
//     komutları '\n' gelene kadar tamponda biriktiriliyor.
//
//  3) PİNLER: HC-05 artık D0/D1 yerine D8/D4'e bağlı (SoftwareSerial).
//     D0/D1 USB ile ortak olduğu için eskiden kod yüklerken HC-05'i
//     sökmek gerekiyordu, yoksa yükleme "not in sync" hatası veriyordu.
//     Artık USB portu boşta: kablo sökmeden kod yüklenebiliyor ve
//     PC'den Seri Monitör (115200) ile gelen komutlar canlı izlenebiliyor.
// ============================================================

#include <SoftwareSerial.h>

// ── Motor Pinleri ────────────────────────────────────────────
// Motor sürücüde ayrı "enable" pini yok; her motorun iki girişi de
// PWM pinine bağlı. Bir pine PWM verilip diğeri 0 yapılarak yön ve
// hız aynı anda ayarlanıyor.
const int MOTOR_A_PIN1 = 9;    // Sol motor ileri (PWM)
const int MOTOR_A_PIN2 = 10;   // Sol motor geri  (PWM)
const int MOTOR_B_PIN1 = 5;    // Sağ motor ileri (PWM)
const int MOTOR_B_PIN2 = 6;    // Sağ motor geri  (PWM)

// ── Bluetooth Modülü Bağlantısı ──────────────────────────────
//   HC-05 TX  →  Arduino D8   (Arduino bu pinden OKUR)
//   HC-05 RX  →  Arduino D4   (Arduino bu pinden YAZAR)
//   Dikkat: TX ve RX çapraz bağlanır. Ters takılırsa telefondan
//   gelen hiçbir komut robota ulaşmaz.
const int BT_RX_PIN = 8;
const int BT_TX_PIN = 4;
const long BT_BAUD  = 9600;     // HC-05 fabrika ayarı (AT+UART? → 9600)
const long USB_BAUD = 115200;   // PC Seri Monitör hızı (log ve test için)
SoftwareSerial bt(BT_RX_PIN, BT_TX_PIN);

// ── Ayar Anahtarları ─────────────────────────────────────────
// LOG_ENABLED 1: İşlenen her komut USB'ye "<ms> <kaynak> <komut>"
//   şeklinde yazılır. Kaynak: B = Bluetooth, U = USB.
//   Robot PC'ye bağlı değilken de zararsızdır, kapatmaya gerek yok.
#ifndef LOG_ENABLED
#define LOG_ENABLED 1
#endif
// ACK_DEBUG 1: Her komuttan sonra komutun geldiği kanala "K<komut>"
//   yazılır. Sadece test içindir, normal kullanımda 0 kalmalı.
#ifndef ACK_DEBUG
#define ACK_DEBUG 0
#endif

// ── Değişkenler ──────────────────────────────────────────────
int currentSpeed = 150;   // Basit ve gelişmiş mod hızı (0-255), V komutu değiştirir

// V ve J komutları birden fazla karakterden oluşur ve '\n' ile biter.
// '\n' gelene kadar karakterler burada biriktirilir. Bluetooth ve USB
// aynı anda veri gönderebileceği için her kanalın ayrı tamponu var;
// böylece iki kanalın karakterleri birbirine karışmaz.
struct LineReader {
  char buf[24];     // "J-255,-255" en fazla 10 karakter; 24 yeterince geniş
  uint8_t len;      // Tamponda şu an kaç karakter var (0 = boş)
};
LineReader btReader  = {{0}, 0};
LineReader usbReader = {{0}, 0};

// ============================================================
void setup() {
  Serial.begin(USB_BAUD);   // USB: log ve PC'den test
  bt.begin(BT_BAUD);        // Bluetooth modülü

  pinMode(MOTOR_A_PIN1, OUTPUT);
  pinMode(MOTOR_A_PIN2, OUTPUT);
  pinMode(MOTOR_B_PIN1, OUTPUT);
  pinMode(MOTOR_B_PIN2, OUTPUT);

  stopMotors();             // Açılışta motorlar kesinlikle dursun
#if LOG_ENABLED
  Serial.println(F("# Robomer hazir (BT: RX=D8 TX=D4 9600)"));
#endif
}

// ============================================================
//  Ana döngü: loop() içinde HİÇ bekleme (delay, readString,
//  readStringUntil, parseInt) yok. Gelen her bayt hemen işlenir.
//  Gecikmenin asıl kaynağı bu tür bekleyen fonksiyonlardı.
// ============================================================
void loop() {
  while (bt.available() > 0)     feed(btReader,  (char)bt.read(),     bt,     'B');
  while (Serial.available() > 0) feed(usbReader, (char)Serial.read(), Serial, 'U');
}

// ============================================================
//  Bir kanaldan gelen TEK baytı işler.
//    r   : o kanalın V/J tamponu
//    c   : gelen karakter
//    src : cevap yazılacak kanal (ping için)
//    tag : log etiketi ('B' veya 'U')
// ============================================================
void feed(LineReader &r, char c, Stream &src, char tag) {
  // Bazı uygulama ve terminal ayarları satır sonuna '\r' ekler; yok say.
  if (c == '\r') return;

  // '\n' = çok karakterli komutun sonu. Tamponda V/J komutu varsa uygula.
  // Tampon boşken gelen '\n' (örn. "F\n" gönderen eski ayarlar) zararsızca
  // yok sayılır.
  if (c == '\n') {
    if (r.len > 0) {
      r.buf[r.len] = '\0';
      handleLine(r.buf);
      report(src, tag, r.buf);
      r.len = 0;
    }
    return;
  }

  // Tampon boş: bu karakter yeni bir komutun ilk karakteri.
  if (r.len == 0) {
    if (c == 'V' || c == 'J') {
      // Çok karakterli komut başlıyor: '\n' gelene kadar biriktir.
      r.buf[r.len++] = c;
    } else if (c == 'P') {
      // Ping: uygulamanın gecikme testi 'P' gönderip bu cevabı bekler.
      // Gidiş-dönüş süresi telefon → BT → robot → BT → telefon yolunu ölçer.
      src.print(F("P\r\n"));
      report(src, tag, "P");
    } else if (c != ' ') {
      // Tek karakterli komut: hiç beklemeden HEMEN uygula.
      // Eski koddaki 1 saniyelik gecikme bu sayede ortadan kalktı.
      processCommand(c);
      char one[2] = {c, '\0'};
      report(src, tag, one);
    }
    return;
  }

  // Buraya gelindiyse V/J komutunun devam karakteri bekleniyor.
  if (r.len < sizeof(r.buf) - 1) {
    r.buf[r.len++] = c;
  } else {
    // Tampon taştı ('\n' hiç gelmedi, veri bozuk). Tamponu boşalt ki
    // sonraki komutlar takılmasın.
    r.len = 0;
  }
}

// ============================================================
//  İşlenen komutu USB'ye logla (ve testte ACK gönder).
// ============================================================
void report(Stream &src, char tag, const char *cmd) {
#if LOG_ENABLED
  Serial.print(millis()); Serial.print(' ');
  Serial.print(tag);      Serial.print(' ');
  Serial.println(cmd);
#endif
#if ACK_DEBUG
  src.print('K'); src.println(cmd);
#else
  (void)src; (void)tag; (void)cmd;   // Kullanılmayan parametre uyarısını sustur
#endif
}

// ============================================================
//  Çok karakterli komutlar:  V{0-255}  veya  J{sol},{sag}
//  (Eskiden String sınıfı kullanılıyordu. String her komutta bellek
//  ayırıp bıraktığı için 2 KB RAM'li Nano'da uzun kullanımda belleği
//  parçalayabilir. Sabit boyutlu char dizisi ve atoi bu riski taşımaz.)
// ============================================================
void handleLine(char *line) {
  // ── Hız: V{0-255} → basit/gelişmiş mod hızını ayarla ──────
  if (line[0] == 'V') {
    currentSpeed = constrain(atoi(line + 1), 0, 255);
  }
  // ── Joystick: J{sol},{sag} → iki motora doğrudan hız ver ──
  //    Değerler -255 (tam geri) .. 255 (tam ileri). Uygulama joystick
  //    konumundan bu değerleri hesaplayıp gönderir (Arcade Drive).
  else if (line[0] == 'J') {
    char *comma = strchr(line + 1, ',');
    if (comma == NULL) return;          // Virgül yoksa komut bozuk, yok say
    int leftVal  = atoi(line + 1);
    int rightVal = atoi(comma + 1);
    setMotorValue(MOTOR_A_PIN1, MOTOR_A_PIN2, leftVal);
    setMotorValue(MOTOR_B_PIN1, MOTOR_B_PIN2, rightVal);
  }
}

// ============================================================
//  Tek karakterli komutlar (butonlar ve özel bloklar)
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

    case 'S':   // Dur (uygulama buton bırakılınca gönderir)
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

    // ── Aksesuar ─────────────────────────────────────────────
    case 'H':   // Korna aç (buzzer takılıysa satırın yorumunu kaldırın)
      // tone(BUZZER_PIN, 1000);
      break;

    case 'N':   // Korna kapat
      // noTone(BUZZER_PIN);
      break;

    // ── Bilinmeyen komut ─────────────────────────────────────
    // Güvenlik için: tanınmayan her karakterde motorları durdur.
    default:
      stopMotors();
      break;
  }
}

// ============================================================
//  Bir motoru sür.
//    val: -255 (tam geri) .. 0 (dur) .. 255 (tam ileri)
//    pin1 ileri yön PWM, pin2 geri yön PWM.
//  İki pine aynı anda PWM verilmez; biri her zaman 0 tutulur.
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
//  İki motoru da durdur.
// ============================================================
void stopMotors() {
  setMotorValue(MOTOR_A_PIN1, MOTOR_A_PIN2, 0);
  setMotorValue(MOTOR_B_PIN1, MOTOR_B_PIN2, 0);
}
