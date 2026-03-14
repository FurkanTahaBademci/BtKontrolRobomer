# 📱 Mucit Akademisi - Uygulama Güncelleme Rehberi

> **Uygulama güncelleme sırasında karşılaşabileceğiniz sorunlar ve çözümleri bu dokümanda bulabilirsiniz.**

---

## 🚀 Otomatik Güncelleme Nasıl Çalışır?

Uygulamayı açtığınız zaman **otomatik olarak** yeni sürüm kontrolü yapılır:

```
1. Uygulama açılır
   ↓
2. Splash Screen (2.5 saniye) gösterilir
   ↓
3. GitHub'da yeni versiyon var mı kontrol edilir
   ↓
4. Yeni versiyon bulunursa "Güncelleme Mevcut" dialog açılır
   ↓
5. Siz "Şimdi Güncelle" butonuna basıp güncellemeyi başlatabilirsiniz
```

---

## 📥 Adım Adım Güncelleme

### **1. Güncelleme Notofisyonunu Takip Edin**

Uygulama açılırken bu dialog ekranını göreceksiniz:

```
┌─────────────────────────────────────────┐
│ ⭐ Güncelleme Mevcut                    │
├─────────────────────────────────────────┤
│                                         │
│ 📦 Yeni Versiyon: 1.0.2                 │
│ 📊 Boyut: 21.4 MB                       │
│ 📅 Tarih: 09 Mart 2026                  │
│                                         │
│ 📝 Değişiklikler:                       │
│    • APK güncelleme sistemi düzeltildi │
│    • Yükleme izin kontrolü eklendi      │
│    • Hata mesajları iyileştirildi       │
│                                         │
├─────────────────────────────────────────┤
│ [ Daha Sonra ]  [ Şimdi Güncelle ]      │
└─────────────────────────────────────────┘
```

### **2. "Şimdi Güncelle" Butonuna Basın**

- Butona basıp indirmeyi başlatın
- Dosya boyutu 21.4 MB'dir (İnternet hızınıza bağlı olarak 2-10 dakika)

### **3. İndirme İlerleme Çubugunu Takip Edin**

```
İndiriliyor... 45%
████████████░░░░░░░░░░░░░░░░░░
```

- İnternet kesintisine maruz kalmazsanız:
  - **4G/5G**: ~1-3 dakika
  - **WiFi**: ~2-5 dakika
  - **Yavaş internet**: ~10 dakika

### **4. Yükleme İzni Vermek**

> ⚠️ **ÖNEMLİ**: Android 8+ cihazlarda yükleme izni istenecek

İzin ekranı çıkarsa:

```
Bilinmeyen kaynaklardan yükleme izni gerekli.

Ayarlar > Uygulamalar > Mucit Akademisi > 
Bilinmeyen uygulamaları yükle seçeneğini açın.
```

**Ne yapmalısınız?**

1. Telefon ayarlarını açın
2. **Uygulamalar** → **Uygulama yönetimi** (veya **Uygulamalar**)
3. **Mucit Akademisi** uygulamasını bulun
4. **Gelişmiş seçenekler** veya **İzinler**
5. **Bilinmeyen uygulamaları yükle** → açın (✅)
6. Geri dönüp **Şimdi Güncelle** butonuna tekrar basın

### **5. Android Yükleyici Açılacak**

İndirme tamamlandığında Android sistem yükleyicisi **otomatik** açılacak:

```
┌─────────────────────────────────────────┐
│  📦 Paket Yükleyici                     │
├─────────────────────────────────────────┤
│                                         │
│  Mucit Akademisi                          │
│  Sürüm: 1.0.2                           │
│                                         │
│  Bu uygulama aşağıdaki işlemleri       │
│  yapabilecektir:                        │
│  • Bluetooth cihazlarına bağlanma       │
│  • Dosya okuma ve yazma                 │
│  • İnternet erişimi                     │
│                                         │
├─────────────────────────────────────────┤
│ [ ıptal ]        [ Yükle ]              │
└─────────────────────────────────────────┘
```

### **6. "Yükle" Butonuna Basın**

- Sistem yükleyici izin verdiğinde **Yükle** butonunu basın
- Yükleme işlemi başlar

### **7. Yükleme Tamamlanır**

```
✅ Yükleme başarılı
   Uygulamayı açmak için "Aç" butonuna basabilirsiniz.
```

---

## 🆘 Sorun Çözme Rehberi

### **❌ Sorun: "İndirme başarısız. İnternet bağlantınızı kontrol edin."**

**Sebepleri:**
- İnternet bağlantısı kesilmiş
- WiFi/4G sinyal zayıf
- GitHub sunucusu erişilemiyor

**Çözüm:**
1. **İnternet bağlantısını kontrol edin** (WiFi/4G aktif mi?)
2. Sinyal düşükse **başka yere gidin** (WiFi'ya daha yakın)
3. **Tekrar deneyin**: Ayarlar → Güncelleme Kontrolü
4. Sorun devam ederse: **YouTube, WhatsApp vs test edin** (çalışıyorsa cihazınız tamam)

---

### **❌ Sorun: "Bilinmeyen kaynaklardan yükleme izni gerekli"**

**Sebep:** Android 8+ cihazlarda sistemin kendi APK yüklemesi için izin gerekli

**Çözüm:**
```
Android 10+:
├─ Ayarlar (Settings)
├─ Uygulamalar (Apps)
├─ Mucit Akademisi seçin
├─ İleri → Gelişmiş Seçenekler (Advanced)
├─ Bilinmeyen uygulamaları yükle
└─ Aç (ON)

Android 8-9:
├─ Ayarlar (Settings)
├─ Güvenlik (Security)
├─ Bilinmeyen Kaynakları Etkinleştir
└─ Aç (ON)
```

---

### **❌ Sorun: "APK dosyası bulunamadı"**

**Sebep:** İndirme sırasında dosya silinmiş veya yazılamıyor

**Çözüm:**
1. **Depolama alanını kontrol edin**: Ayarlar → Depolama → Boş alan
   - Minimum 500 MB boş alan gerekli
2. **Boş alan yoksa**: Fotoğraf/video silin
3. **Tekrar deneyin**
4. Hala başarısız → **Telefonu yeniden başlatın** (Uygulamalar hata yapabilir)

---

### **❌ Sorun: "Yükleme başarısız" veya "Uygulamayı açamadı"**

**Sebep:** APK dosyasında sorun, yükleme bağlantısı koptu

**Çözüm:**
1. **Tekrar deneyin** (basit ama genelde çalışır)
2. **Cihazı yeniden başlatın**
3. **Uygulamayı sil sonnra kurun**:
   - Ayarlar → Uygulamalar → Mucit Akademisi → Sil
   - [GitHub'tan en son APK indir](https://github.com/FurkanTahaBademci/BtKontrolRobomer/releases) ve manuel kur
4. Sorun devam ederse → **Geliştiriciyle iletişime geçin**

---

### **❌ Sorun: "Yükleme başlamıyor" (Yükleyici açılmıyor)**

**Sebep:** MIME type sorunu veya izin engeli

**Sorun Giderme Adımları:**
1. **Bilinmeyen uygulamalara izin verin** (yukarıya bakın)
2. **Yönetici modu kontrol edin**: 
   - Ayarlar → Geliştirici Seçenekleri → USB Hata Ayıklamayı Kapatın (OFF)
3. **Varsayılan APK uygulamasını ayarlayın**:
   - Ayarlar → Uygulamalar → Varsayılan Uygulamalar
   - Paket Yükleyiciyi ara ve seç
4. **Tekrar deneyin**

---

## 📚 El İle Güncelleme (Manuel Kurulum)

Otomatik yükleme başarısız olursa:

1. **GitHub Release sayfasını açın**:
   - https://github.com/FurkanTahaBademci/BtKontrolRobomer/releases

2. **En son sürüm bulun** (v1.0.2)

3. **app-release.apk dosyasını indirin**:
   - "Assets" bölümünde APK dosyası var
   - Android telefonunuza indirin

4. **İndiren dosyayı açın**:
   - Dosya → Downloads → app-release.apk
   - Dokunun ve yükleme başlasın

5. **Bilinmeyen kaynaklar izni verin** (gerekirse)

6. **"Yükle" butonuna basın**

7. **"Aç" butonuna basarak uygulamayı başlatın**

---

## ⚙️ Ayarlardan Manuel Kontrol

Otomatik kontrol istemiyor veya kontrol başarısız olduysa:

1. **Mucit Akademisi uygulamasını açın**
2. **Ana ekrana gitmek yerine** sol üstte ← basın
3. **Ayarlar (⚙️)** butonuna basın
4. **Güncelleme Kontrolü** seçeneğini tap edin
5. Sistem yeni versiyon araştıracak

---

## 💡 İpuçları

| İpucu | Açıklama |
|-------|----------|
| 📡 WiFi kullanın | İndirme daha hızlı ve güvenilir olur |
| 🔌 Şarj edin | Yükleme sırasında şarj % olması tavsiye edilir |
| ⏱️ Sabır | Yükleme sırasında uygulamayı kapatmayın |
| 📴 Uçak modu | Yükleme sırasında uçak modunu kapatın |
| 🔄 Yeniden başlat | Herhangi bir sorun çözülemezse telefonu yeniden başlatın |

---

## 📞 Yardım Alma

Sorun devam ederse:

1. **Bu dokümanı okuyup tüm adımları takip edin**
2. **Telefonunuzu yeniden başlatın**
3. **WiFi bağlantısını kontrol edin**
4. **Hala başarısız ise**: 
   - GitHub Issues: [BtKontrolRobomer/issues](https://github.com/FurkanTahaBademci/BtKontrolRobomer/issues)
   - Geliştiriciyle iletişime geçin

---

## 🔄 Versiyon Karşılaştırması

```
Mevcut Sürüm: 1.0.1
Yeni Sürüm: 1.0.2

Farklar:
✨ APK güncelleme sistemi düzeltildi
✨ Yükleme izin kontrolü eklendi
✨ Hata mesajları iyileştirildi
```

---

**Son Güncelleme: 09 Mart 2026**  
**Yazar: Mucit Akademisi Geliştirme Ekibi**  
**Versiyon: 1.0**
