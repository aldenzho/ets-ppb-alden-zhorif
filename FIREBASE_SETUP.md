# Setup Firebase untuk ETS Road Documentation App

## ✅ Status Implementasi
- ✅ Firebase Cloud Firestore integration
- ✅ Firebase Cloud Storage untuk foto
- ✅ Location/GPS service
- ✅ Upload dengan progress tracking
- ✅ Status tracking: "jalan belum diperbaiki" → "jalan sudah diperbaiki"
- ✅ Delete functionality
- ✅ Real-time updates

## 🔧 Langkah Setup Firebase

### 1. Buat Firebase Project
1. Buka [Firebase Console](https://console.firebase.google.com)
2. Klik "Add project"
3. Beri nama: `firebase CRUD basics` (sesuai dengan nama Firebase Anda)
4. Enable analytics (opsional)

### 2. Setup Android
1. Di Firebase Console → Project Settings → General
2. Tambahkan Android app dengan package name: `com.example.ets`
3. Download `google-services.json`
4. Letakkan file di: `android/app/`

### 3. Setup iOS
1. Di Firebase Console → Project Settings → General
2. Tambahkan iOS app dengan bundle ID: `com.example.ets`
3. Download `GoogleService-Info.plist`
4. Di Xcode: Buka `ios/Runner.xcworkspace`
5. Right-click `Runner` folder → Add Files to Runner
6. Pilih `GoogleService-Info.plist` yang sudah didownload
7. Ensure target is `Runner`

### 4. Update Firebase Credentials
Edit file `lib/firebase_options.dart` dengan credentials dari Firebase Console:

Untuk Android:
- Buka `google-services.json`
- Copy API Key, App ID, Messaging Sender ID, Project ID, Storage Bucket

Untuk iOS:
- Buka `GoogleService-Info.plist`
- Copy values dengan key yang sama

### 5. Firestore Database Setup
1. Di Firebase Console → Firestore Database
2. Klik "Create database"
3. Pilih "Start in test mode" (untuk development)
4. Pilih region: "asia-southeast1" (Indonesia)
5. Klik "Enable"

#### Security Rules (untuk production):
```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /road_photos/{document=**} {
      allow read: if true;
      allow create: if request.auth != null;
      allow update: if request.auth != null && request.auth.uid == resource.data.userId;
      allow delete: if request.auth != null && request.auth.uid == resource.data.userId;
    }
  }
}
```

### 6. Firebase Storage Setup
1. Di Firebase Console → Storage
2. Klik "Get Started"
3. Pilih region: "asia-southeast1" (Indonesia)
4. Klik "Done"

#### Storage Rules (untuk production):
```
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /road_photos/{userId}/{fileName} {
      allow read: if true;
      allow create: if request.auth != null && request.auth.uid == userId;
      allow delete: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

### 7. Testing
1. Run aplikasi: `flutter run`
2. Ambil foto
3. Check Firestore di Firebase Console → road_photos collection
4. Check Cloud Storage untuk file foto

## 📱 Fitur yang Sudah Terimplementasi

### Take Photo Screen
- ✅ Custom camera UI
- ✅ Real-time camera preview
- ✅ GPS location capture
- ✅ Upload progress tracking
- ✅ Success/Error notifications

### Last Photo Screen
- ✅ Fetch last photo dari Firestore
- ✅ Display photo dari Cloud Storage
- ✅ Show location metadata
- ✅ Show upload timestamp
- ✅ Update status button (jalan belum diperbaiki → jalan sudah diperbaiki)
- ✅ Delete photo button
- ✅ Loading/Error states
- ✅ Empty state

## 📁 Folder Structure
```
lib/
├── main.dart                    (Firebase initialization)
├── firebase_options.dart        (Firebase credentials)
├── services/                    (Firebase services folder)
│   ├── firebase_service.dart    (Firestore CRUD operations)
│   └── location_service.dart    (GPS location access)
├── camera_screen.dart           (Custom camera UI)
├── take_photo.dart              (Photo capture + upload)
├── get_road_location.dart       (Map display + status management)
├── photos_count.dart
├── notifications.dart
└── photos_count.dart
```

## 🔐 Security Notes
- Jangan commit `google-services.json` atau `GoogleService-Info.plist` ke Git
- Tambahkan ke `.gitignore`:
  ```
  google-services.json
  GoogleService-Info.plist
  ```
- Gunakan authentication untuk production
- Implement proper security rules di Firestore dan Storage

## 🚀 Next Steps
1. Setup Firebase Console dengan langkah-langkah di atas
2. Update `firebase_options.dart` dengan credentials
3. Run `flutter pub get`
4. Test aplikasi

## 📝 API References
- [Firebase Console](https://console.firebase.google.com)
- [Firebase FlutterFire Documentation](https://firebase.flutter.dev)
- [Cloud Firestore Docs](https://firebase.google.com/docs/firestore)
- [Cloud Storage Docs](https://firebase.google.com/docs/storage)
