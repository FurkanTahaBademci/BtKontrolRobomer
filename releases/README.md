# 📱 Uygulama Güncelleme Sistemi

Bu klasör, uygulamanızın uzaktan güncelleme sistemi için gerekli dosyaları içerir.

## 📂 Dosya Yapısı

```
releases/
├── version.json          ← Güncelleme bilgileri (GitHub'da olmalı)
├── app-release-1.0.1.apk
├── app-release-1.0.2.apk
└── app-release-1.0.3.apk
```

## 🚀 Yeni Versiyon Yayınlama Adımları

### 1. **Versiyon Numarasını Güncelle**
```yaml
# pubspec.yaml
version: 1.0.2+3  # 1.0.2 = versiyon, 3 = build number
```

### 2. **APK Oluştur**
```bash
flutter build apk --release
```

### 3. **GitHub Release Oluştur**
- GitHub repo → Releases → "New Release"
- Tag: `v1.0.2`
- Title: `Versiyon 1.0.2`
- Description: Değişiklikleri açıkla
- APK'yı yükle: `app-release.apk`
- "Publish Release"

### 4. **version.json Güncelle**

GitHub'daki `releases/version.json` dosyasını düzenle:

```json
{
  "latestVersion": "1.0.2",
  "versionCode": 3,
  "downloadUrl": "https://github.com/FurkanTahaBademci/BtKontrolRobomer/releases/download/v1.0.2/app-release.apk",
  "releaseNotes": "🚀 Yeni Özellikler:\n- Bluetooth hız iyileştirmesi\n- UI güncellemeleri",
  "minRequiredVersion": "1.0.0",
  "forceUpdate": false,
  "fileSize": "20.5 MB",
  "releaseDate": "2026-03-15"
}
```

### 5. **Commit ve Push**
```bash
git add releases/version.json
git commit -m "Update version to 1.0.2"
git push
```

✅ **Bitti!** Kullanıcılar uygulamayı açtığında otomatik güncelleme bildirimi alacak.

---

## 📝 version.json Parametreleri

| Parametre | Açıklama | Örnek |
|-----------|----------|-------|
| `latestVersion` | En yeni versiyon numarası | `"1.0.2"` |
| `versionCode` | Build number (pubspec.yaml'daki +3) | `3` |
| `downloadUrl` | APK indirme linki | GitHub release URL'i |
| `releaseNotes` | Değişiklik notları (\n ile satır ayırma) | `"🚀 Yeni:\n- Feature X"` |
| `minRequiredVersion` | Minimum gerekli versiyon | `"1.0.0"` |
| `forceUpdate` | Zorunlu güncelleme mi? | `true` / `false` |
| `fileSize` | APK boyutu | `"20.5 MB"` |
| `releaseDate` | Yayın tarihi | `"2026-03-15"` |

---

## ⚠️ Zorunlu Güncelleme

Kritik bug fix veya güvenlik güncellemeleri için:

```json
{
  "forceUpdate": true,  ← Kullanıcı güncellemeden uygulamayı kullanamaz
  "minRequiredVersion": "1.0.3"  ← Bu versiyondan eski olanlar zorlanır
}
```

---

## 🔍 Test Etme

### Manuel Test (Ayarlar):
1. Ayarlar → Hakkında
2. "Güncelleme Kontrolü" butonuna bas
3. Güncelleme dialog'u açılır

### Otomatik Test (Splash):
1. Uygulamayı kapat
2. version.json'da `latestVersion` değiştir (örn: "2.0.0")
3. Uygulamayı aç
4. Splash screen'den sonra güncelleme dialog'u görülür

---

## 🌐 URL Yapılandırması

UpdateService'de URL'i değiştir:

```dart
// lib/services/update_service.dart
static const String versionCheckUrl =
    'https://raw.githubusercontent.com/KULLANICI_ADINIZ/REPO_ADINIZ/main/releases/version.json';
```

**Önemli:** GitHub Raw URL kullanın (cache bypass için):
- ✅ `raw.githubusercontent.com`
- ❌ `github.com/.../blob/...`

---

## 📱 Kullanıcı Deneyimi

### Normal Güncelleme:
```
Uygulama Açılışı
    ↓
Güncelleme var! (Dialog)
    ↓
[Daha Sonra] veya [Şimdi Güncelle]
    ↓
İndirme... %85
    ↓
Android Yükleme Ekranı
    ↓
✅ Güncelleme Tamamlandı
```

### Zorunlu Güncelleme:
```
Uygulama Açılışı
    ↓
⚠️ Kritik Güncelleme (Kapatılamaz Dialog)
    ↓
[GÜNCELLE] (tek seçenek)
    ↓
İndirme...
    ↓
✅ Güncelleme yapılmadan devam edilemez
```

---

## 🛡️ Güvenlik Notları

- ✅ **HTTPS zorunlu**: HTTP URL'ler Android 9+ çalışmaz
- ✅ **GitHub güvenilir**: Resmi release sistemi kullanılıyor
- ⚠️ **Manuel yükleme**: Kullanıcı "Bilinmeyen kaynaklar" iznini vermelidir
- ⚠️ **İmza kontrolü**: APK'lar aynı keystore ile imzalanmalı

---

## 🐛 Sorun Giderme

### "İndirme başarısız"
- İnternet bağlantısını kontrol et
- version.json URL'ini doğrula
- GitHub release'in public olduğunu kontrol et

### "APK yüklenemedi"
- "Bilinmeyen kaynaklar" izni verilmeli
- APK imzası uyumsuz olabilir (farklı keystore)

### "Güncelleme kontrolü yapılamadı"
- version.json dosyası GitHub'da mı?
- URL doğru mu? (raw.githubusercontent.com)
- İnternet var mı?

---

## 📊 İstatistikler

Güncelleme kullanım verilerini görmek için Firebase Analytics veya başka analitik araç entegre edebilirsiniz.

---

**Son Güncelleme:** 2026-03-08  
**Versiyon:** 1.0.1
