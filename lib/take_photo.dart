import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ets/camera_screen.dart';
import 'package:ets/services/firebase_service.dart';
import 'package:ets/services/location_service.dart';
import 'package:ets/services/notification_service.dart';
import 'dart:io';

class TakePhoto extends StatefulWidget {
  const TakePhoto({super.key});

  @override
  State<TakePhoto> createState() => _TakePhotoState();
}

class _TakePhotoState extends State<TakePhoto> {
  XFile? _imageFile;
  bool _isUploading = false;
  double _uploadProgress = 0.0;

  Future<void> _takePhoto() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Kamera tidak tersedia di perangkat ini'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      if (mounted) {
        final XFile? photo = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CameraScreen(cameras: cameras),
          ),
        );

        if (photo != null) {
          setState(() {
            _imageFile = photo;
          });

          // Show upload dialog
          if (mounted) {
            _showUploadDialog(photo);
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengambil foto: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showUploadDialog(XFile photo) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Unggah Foto',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 24),
                    if (_isUploading) ...[
                      CircularProgressIndicator(
                        value: _uploadProgress,
                        strokeWidth: 3,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Mengupload: ${(_uploadProgress * 100).toStringAsFixed(0)}%',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ] else ...[
                      ElevatedButton.icon(
                        onPressed: () => _uploadPhotoWithUpdate(photo, dialogContext, setState),
                        icon: const Icon(Icons.cloud_upload_rounded),
                        label: const Text('Unggah ke Firebase'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          backgroundColor: const Color(0xFF1E88E5),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        child: const Text('Batal'),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _uploadPhotoWithUpdate(
    XFile photo,
    BuildContext dialogContext,
    StateSetter setState,
  ) async {
    try {
      setState(() {
        _isUploading = true;
        _uploadProgress = 0.0;
      });

      final notificationService = NotificationService();

      // Get location
      final locationService = LocationService();
      final location = await locationService.getCurrentLocation();

      if (location == null && mounted) {
        Navigator.pop(dialogContext);
        notificationService.showUploadErrorNotification('Lokasi GPS tidak tersedia');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tidak dapat mengakses lokasi GPS'),
            backgroundColor: Colors.orange,
          ),
        );
        setState(() {
          _isUploading = false;
        });
        return;
      }

      // Upload to Firebase
      final firebaseService = FirebaseService();
      final photoFile = File(photo.path);
      final currentUser = FirebaseAuth.instance.currentUser;
      final userId = currentUser?.uid;

      if (userId == null || userId.isEmpty) {
        if (mounted) {
          Navigator.pop(dialogContext);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Silakan login ulang sebelum upload foto'),
              backgroundColor: Colors.red,
            ),
          );
        }
        this.setState(() {
          _isUploading = false;
        });
        return;
      }

      final uploadedPhoto = await firebaseService.uploadRoadPhoto(
        photoFile: photoFile,
        latitude: location?.latitude ?? 0.0,
        longitude: location?.longitude ?? 0.0,
        userId: userId,
        onProgress: (progress) {
          setState(() {
            _uploadProgress = progress;
          });
          // Show progress notification
          final progressPercent = (progress * 100).toInt();
          notificationService.showUploadProgressNotification(progressPercent);
          print('📤 Upload progress: $progressPercent%');
        },
      );

      print('✅ Upload completed! Photo: $uploadedPhoto');

      if (mounted) {
        Navigator.pop(dialogContext);

        if (uploadedPhoto != null) {
          firebaseService.notifyPhotoChanged();

          if (mounted) {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => const Center(
                child: CircularProgressIndicator(),
              ),
            );
          }

          await Future.delayed(const Duration(milliseconds: 800));

          if (mounted) {
            Navigator.pop(context);
          }

          // Dismiss progress notification
          await notificationService.dismissUploadNotification();
          
          // Show success notification
          await notificationService.showUploadSuccessNotification();
          
          print('✨ Upload success! Showing success notification');
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Foto berhasil diupload!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
          
          // Wait untuk allow Firestore + Stream to sync
          await Future.delayed(const Duration(seconds: 1));
          
          // Clear image file after successful upload
          this.setState(() {
            _imageFile = null;
            _isUploading = false;
          });
        } else {
          // Show error notification
          await notificationService.showUploadErrorNotification('Gagal menyimpan foto ke database');
          
          print('❌ Upload failed!');
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Gagal mengupload foto'),
              backgroundColor: Colors.red,
            ),
          );
          this.setState(() {
            _isUploading = false;
          });
        }
      } else {
        this.setState(() {
          _isUploading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(dialogContext);
        await NotificationService().showUploadErrorNotification(e.toString());
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      this.setState(() {
        _isUploading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      primary: false,
      shrinkWrap: true,
      padding: EdgeInsets.zero,
      crossAxisSpacing: 0,
      mainAxisSpacing: 0,
      crossAxisCount: 1,
      childAspectRatio: 2.2,
      children: [
        // Always show the button/input area
        InkWell(
          onTap: _takePhoto,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF2196F3), Color(0xFF1976D2)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: _takePhoto,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Ambil Foto Baru',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white70,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Dokumentasikan Kondisi Jalan',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.camera_alt_rounded,
                        color: Colors.white,
                        size: 32,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        // Show preview if photo is captured
        if (_imageFile != null)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                children: [
                  Image.file(
                    File(_imageFile!.path),
                    fit: BoxFit.cover,
                  ),
                  if (_isUploading)
                    Positioned.fill(
                      child: Container(
                        color: Colors.black.withOpacity(0.4),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircularProgressIndicator(
                                value: _uploadProgress,
                                strokeWidth: 3,
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Mengupload: ${(_uploadProgress * 100).toStringAsFixed(0)}%',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}