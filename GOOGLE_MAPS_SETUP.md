# 🗺️ Google Maps API Setup Guide

## ⚠️ Current Issue
Aplikasi memerlukan Google Maps API Key untuk menampilkan peta. Saat ini placeholder value masih di `AndroidManifest.xml`.

## 📋 Langkah-Langkah Mendapatkan API Key

### 1. Buka Google Cloud Console
- Kunjungi https://console.cloud.google.com/
- Login dengan akun Google Anda

### 2. Buat Project Baru (atau gunakan yang existing)
- Klik dropdown project di atas
- Pilih "NEW PROJECT"
- Nama project: `FixMyRoad` (atau nama lain)
- Klik "CREATE"

### 3. Enable Google Maps Platform APIs
- Di search bar, cari `Maps SDK for Android`
- Klik hasil, kemudian `ENABLE`
- Tunggu beberapa saat hingga active

### 4. Buat API Key
- Di sidebar kiri, pilih "Credentials"
- Klik "CREATE CREDENTIALS" > "API Key"
- Copy API Key yang muncul

### 5. Update AndroidManifest.xml
- Buka file: `android/app/src/main/AndroidManifest.xml`
- Cari: `android:value="YOUR_GOOGLE_MAPS_API_KEY_HERE"`
- Replace dengan API Key Anda
- Contoh:
  ```xml
  <meta-data
      android:name="com.google.android.geo.API_KEY"
      android:value="AIzaSyD1234567890abcdefghijklmnop" />
  ```

### 6. (Optional) Set API Key Restrictions
Untuk security, sebaiknya restrict API Key:
- Di Google Cloud Console, buka API Key settings
- Pilih "Application restrictions" > "Android apps"
- Klik "Add"
- Masukkan:
  - Package name: `com.example.ets`
  - SHA-1 fingerprint: (lihat langkah 7)
- Pilih "API restrictions" > pilih hanya "Maps SDK for Android"

### 7. Dapatkan SHA-1 Fingerprint (untuk restriction)
```bash
cd android
./gradlew signingReport
```
Cari bagian `Variant: debug` dan copy SHA-1 value

### 8. Test Aplikasi
```bash
flutter clean
flutter pub get
flutter run
```

## 🔑 Free API Key
Google Maps memiliki quota gratis:
- 28,000 map loads per hari (Maps SDK)
- $7/1000 setelahnya
- Cukup untuk development dan testing

## ❓ Troubleshooting

### "API key not found" Error
- Pastikan API Key sudah di-copy dengan benar
- Tidak ada spasi di awal/akhir
- Sudah enable Maps SDK for Android di Console

### "invalid API key" Error  
- API Key mungkin belum active (tunggu 5-10 menit)
- Atau API Key dari project yang berbeda
- Atau Maps SDK belum di-enable

### Maps tidak tampil (blank)
- Billing perlu di-enable (Google Cloud Console > Billing)
- Meskipun gratis, perlu link billing untuk authentication

## 📚 References
- [Google Maps Android SDK](https://developers.google.com/maps/documentation/android-sdk/overview)
- [API Keys Documentation](https://developers.google.com/maps/documentation/android-sdk/get-api-key)
