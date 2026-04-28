import 'dart:io';

import 'package:ets/services/firebase_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class PhotosCount extends StatefulWidget {
  const PhotosCount({super.key});

  @override
  State<PhotosCount> createState() => _PhotosCountState();
}

class _PhotosCountState extends State<PhotosCount> {
  final FirebaseService _firebaseService = FirebaseService();

  String? get _currentUserId => FirebaseAuth.instance.currentUser?.uid;

  void _openUserPhotosSheet(BuildContext context, String userId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return DraggableScrollableSheet(
          initialChildSize: 0.78,
          minChildSize: 0.45,
          maxChildSize: 0.95,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  Container(
                    width: 48,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        const Icon(Icons.photo_library_rounded, color: Color(0xFF1E88E5)),
                        const SizedBox(width: 8),
                        Text(
                          'Foto yang Kamu Upload',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ValueListenableBuilder<int>(
                      valueListenable: _firebaseService.photoChangeNotifier,
                      builder: (context, _, __) {
                        return StreamBuilder<List<RoadPhoto>>(
                          key: ValueKey(_firebaseService.photoChangeNotifier.value),
                          stream: _firebaseService.getPhotosStreamByUser(userId),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                              return const Center(child: CircularProgressIndicator());
                            }

                            final photos = snapshot.data ?? const <RoadPhoto>[];

                            if (photos.isEmpty) {
                              return const Center(
                                child: Text('Belum ada foto yang diupload'),
                              );
                            }

                            return ListView.separated(
                              controller: scrollController,
                              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                              itemCount: photos.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 12),
                              itemBuilder: (context, index) {
                                final photo = photos[index];
                                final file = File(photo.photoPath);

                                return Container(
                                  decoration: BoxDecoration(
                                    color: Colors.grey[50],
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: Colors.grey.shade200),
                                  ),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.all(12),
                                    leading: ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: SizedBox(
                                        width: 64,
                                        height: 64,
                                        child: Image.file(
                                          file,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) {
                                            return Container(
                                              color: Colors.grey[300],
                                              child: const Icon(Icons.image_not_supported),
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                                    title: Text(
                                      photo.status,
                                      style: const TextStyle(fontWeight: FontWeight.w600),
                                    ),
                                    subtitle: Text(
                                      'Lat: ${photo.latitude.toStringAsFixed(5)}\nLng: ${photo.longitude.toStringAsFixed(5)}',
                                    ),
                                    isThreeLine: true,
                                    trailing: IconButton(
                                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                                      onPressed: () async {
                                        final shouldDelete = await showDialog<bool>(
                                          context: context,
                                          builder: (dialogContext) => AlertDialog(
                                            title: const Text('Hapus foto?'),
                                            content: const Text('Foto ini akan dihapus dari perangkat dan database.'),
                                            actions: [
                                              TextButton(
                                                onPressed: () => Navigator.pop(dialogContext, false),
                                                child: const Text('Batal'),
                                              ),
                                              TextButton(
                                                onPressed: () => Navigator.pop(dialogContext, true),
                                                child: const Text('Hapus', style: TextStyle(color: Colors.red)),
                                              ),
                                            ],
                                          ),
                                        );

                                        if (shouldDelete == true) {
                                          final success = await _firebaseService.deletePhoto(photo.id, userId);
                                          if (!context.mounted) return;
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text(success ? 'Foto dihapus' : 'Gagal menghapus foto'),
                                              backgroundColor: success ? Colors.green : Colors.red,
                                            ),
                                          );
                                        }
                                      },
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final userId = _currentUserId;

    return GridView.count(
      primary: false,
      shrinkWrap: true,
      padding: EdgeInsets.zero,
      crossAxisSpacing: 0,
      mainAxisSpacing: 0,
      crossAxisCount: 1,
      childAspectRatio: 2.2,
      children: [
        ValueListenableBuilder<int>(
          valueListenable: _firebaseService.photoChangeNotifier,
          builder: (context, refreshTick, __) {
            if (userId == null) {
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2196F3), Color(0xFF1976D2)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Center(
                  child: Text(
                    'Belum login',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              );
            }

            return FutureBuilder<List<RoadPhoto>>(
              key: ValueKey(refreshTick),
              future: _firebaseService.getAllPhotos(userId),
              builder: (context, snapshot) {
                final photoCount = snapshot.data?.length ?? 0;

                return InkWell(
                  onTap: () => _openUserPhotosSheet(context, userId),
                  borderRadius: BorderRadius.circular(16),
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
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.image_search_rounded,
                                  color: Colors.white,
                                  size: 28,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Foto Diambil',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.white70,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Jumlah Foto: $photoCount',
                                      style: const TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    const Text(
                                      'Tap untuk lihat & hapus foto',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.white70,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }
}