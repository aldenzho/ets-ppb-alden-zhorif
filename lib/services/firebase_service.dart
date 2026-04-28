import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

// User Model
class UserData {
  final String uid;
  final String username;
  final String email;
  final DateTime createdAt;

  UserData({
    required this.uid,
    required this.username,
    required this.email,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'username': username,
      'email': email,
      'createdAt': createdAt,
    };
  }

  factory UserData.fromMap(Map<String, dynamic> map, String docId) {
    return UserData(
      uid: docId,
      username: map['username'] ?? '',
      email: map['email'] ?? '',
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }
}

// Road Photo Model (with user reference)
class RoadPhoto {
  final String id;
  final String photoPath;
  final double latitude;
  final double longitude;
  final String status;
  final DateTime timestamp;
  final String userId;
  final String? userUsername; // Denormalized for display

  RoadPhoto({
    required this.id,
    required this.photoPath,
    required this.latitude,
    required this.longitude,
    required this.status,
    required this.timestamp,
    required this.userId,
    this.userUsername,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'photoPath': photoPath,
      'latitude': latitude,
      'longitude': longitude,
      'status': status,
      'timestamp': timestamp,
      'userId': userId,
      'userUsername': userUsername,
    };
  }

  factory RoadPhoto.fromMap(Map<String, dynamic> map, String docId) {
    return RoadPhoto(
      id: docId,
      photoPath: map['photoPath'] ?? '',
      latitude: (map['latitude'] ?? 0.0).toDouble(),
      longitude: (map['longitude'] ?? 0.0).toDouble(),
      status: map['status'] ?? 'jalan belum diperbaiki',
      timestamp: map['timestamp'] != null
          ? (map['timestamp'] as Timestamp).toDate()
          : DateTime.now(),
      userId: map['userId'] ?? '',
      userUsername: map['userUsername'],
    );
  }
}

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();

  factory FirebaseService() {
    return _instance;
  }

  FirebaseService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ValueNotifier<int> photoChangeNotifier = ValueNotifier<int>(0);

  void notifyPhotoChanged() {
    photoChangeNotifier.value++;
  }

  // Upload photo locally and save metadata to Firestore
  Future<RoadPhoto?> uploadRoadPhoto({
    required File photoFile,
    required double latitude,
    required double longitude,
    required String userId,
    required Function(double) onProgress,
  }) async {
    try {
      if (userId.isEmpty || userId == 'default_user') {
        throw Exception('User belum login');
      }

      // Generate unique ID for this photo
      final String photoId = DateTime.now().millisecondsSinceEpoch.toString();
      
      // Get local app documents directory
      final Directory appDir = await getApplicationDocumentsDirectory();
      final String photoDir = '${appDir.path}/road_photos/$userId';
      
      // Create directory if not exists
      await Directory(photoDir).create(recursive: true);
      
      // Save photo to local storage
      final String localPath = '$photoDir/$photoId.jpg';
      await photoFile.copy(localPath);
      
      // Simulate progress callback (local copy is fast)
      onProgress(0.5);

      // Get user data for denormalization (relational structure)
      String? userUsername;
      try {
        final userDoc = await _firestore.collection('users').doc(userId).get();
        if (userDoc.exists) {
          userUsername = userDoc.get('username');
        }
      } catch (e) {
        // Silent fail - continue without username
      }
      
      // Create RoadPhoto object with local path
      final RoadPhoto roadPhoto = RoadPhoto(
        id: photoId,
        photoPath: localPath,
        latitude: latitude,
        longitude: longitude,
        status: 'jalan belum diperbaiki',
        timestamp: DateTime.now(),
        userId: userId,
        userUsername: userUsername,
      );

      // Save metadata to Firestore with relational reference
      await _firestore
          .collection('road_photos')
          .doc(photoId)
          .set(roadPhoto.toMap());

        notifyPhotoChanged();

      print('✅ Photo metadata saved to Firestore successfully!');
      print('📸 Photo ID: $photoId');
      print('📁 Local Path: $localPath');
      print('👤 User ID: $userId');
      print('👤 Username: $userUsername');

      // Add delay to ensure Firestore has fully synced before stream triggers
      await Future.delayed(const Duration(seconds: 1));

      onProgress(1.0);
      return roadPhoto;
    } catch (e) {
      print('❌ Error uploading photo');
      return null;
    }
  }

  // Get last photo for user
  Future<RoadPhoto?> getLastPhoto(String userId) async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection('road_photos')
          .where('userId', isEqualTo: userId)
          .get();

      if (snapshot.docs.isEmpty) {
        return null;
      }

      final photos = snapshot.docs
          .map((doc) => RoadPhoto.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList()
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

      return photos.first;
    } catch (e) {
      print('Error getting last photo');
      return null;
    }
  }

  // Get all photos for user
  Future<List<RoadPhoto>> getAllPhotos(String userId) async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection('road_photos')
          .where('userId', isEqualTo: userId)
          .get();

      final photos = snapshot.docs
          .map((doc) => RoadPhoto.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList()
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

      return photos;
    } catch (e) {
      print('Error getting all photos');
      return [];
    }
  }

  // Update photo status
  Future<bool> updatePhotoStatus(String photoId, String newStatus) async {
    try {
      final docRef = _firestore.collection('road_photos').doc(photoId);
      final existing = await docRef.get();
      if (!existing.exists) {
        return false;
      }

      // Use set+merge to avoid failing when some documents have schema differences.
      await docRef.set(
        {
          'status': newStatus,
          'updatedAt': Timestamp.now(),
        },
        SetOptions(merge: true),
      );

      final verify = await docRef.get();
      final data = verify.data();
      if (data == null || data['status'] != newStatus) {
        return false;
      }

      notifyPhotoChanged();
      return true;
    } catch (e) {
      print('Error updating photo status: $e');
      return false;
    }
  }

  // Delete photo
  Future<bool> deletePhoto(String photoId, String userId) async {
    try {
      // Get photo data to find local path
      final doc = await _firestore.collection('road_photos').doc(photoId).get();
      if (!doc.exists) {
        return false;
      }

      final data = doc.data();
      if (data == null) {
        return false;
      }
      final photoPath = data['photoPath'];

      // Delete local file
      if (photoPath != null) {
        try {
          final file = File(photoPath);
          if (await file.exists()) {
            await file.delete();
          }
        } catch (e) {
          print('Error deleting local file: $e');
          // Continue to delete from Firestore even if file delete fails
        }
      }

      // Delete metadata from Firestore
      await _firestore.collection('road_photos').doc(photoId).delete();
      notifyPhotoChanged();
      return true;
    } catch (e) {
      print('Error deleting photo: $e');
      return false;
    }
  }

  // Stream of photos for real-time updates (all photos)
  Stream<List<RoadPhoto>> getPhotosStream(String userId) {
    print('🔄 Subscribing to photos stream for user: $userId');
    
    return _firestore
        .collection('road_photos')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
          print('📊 Stream update received: ${snapshot.docs.length} photos');
          
          final photos = snapshot.docs
              .map((doc) =>
                  RoadPhoto.fromMap(doc.data(), doc.id))
              .toList();
          
          for (var photo in photos) {
            print('  📷 Photo: ${photo.id} - ${photo.photoPath}');
          }
          
          return photos;
        });
  }

  // Stream of photos for specific user only
  Stream<List<RoadPhoto>> getPhotosStreamByUser(String userId) {
    print('🔄 Subscribing to user photos stream for user: $userId');
    
    return _firestore
        .collection('road_photos')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
          print('📊 User stream update: ${snapshot.docs.length} photos for user $userId');
          
          final photos = snapshot.docs
              .map((doc) =>
                  RoadPhoto.fromMap(doc.data(), doc.id))
              .toList()
            ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
          
          return photos;
        });
  }

  // Get user data by ID (relational query)
  Future<UserData?> getUserById(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        return UserData.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }
      return null;
    } catch (e) {
      print('Error getting user');
      return null;
    }
  }

  // Get all users (for statistics or admin)
  Future<List<UserData>> getAllUsers() async {
    try {
      final snapshot = await _firestore.collection('users').get();
      return snapshot.docs
          .map((doc) => UserData.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print('❌ Error getting all users: $e');
      return [];
    }
  }

  // Get photos grouped by user (relational aggregation)
  Future<Map<String, List<RoadPhoto>>> getPhotosGroupedByUser() async {
    try {
      final snapshot = await _firestore
          .collection('road_photos')
          .orderBy('timestamp', descending: true)
          .get();

      final Map<String, List<RoadPhoto>> groupedPhotos = {};

      for (var doc in snapshot.docs) {
        final photo = RoadPhoto.fromMap(doc.data(), doc.id);
        if (!groupedPhotos.containsKey(photo.userId)) {
          groupedPhotos[photo.userId] = [];
        }
        groupedPhotos[photo.userId]!.add(photo);
      }

      print('📊 Photos grouped by ${groupedPhotos.length} users');
      return groupedPhotos;
    } catch (e) {
      print('Error grouping photos');
      return {};
    }
  }
}

