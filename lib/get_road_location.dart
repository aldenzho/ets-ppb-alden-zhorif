import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'dart:io';
import 'package:ets/services/firebase_service.dart';

class GetRoadLocation extends StatefulWidget {
  const GetRoadLocation({super.key, required this.title});

  final String title;

  @override
  State<GetRoadLocation> createState() => _GetRoadLocationState();
}

class _GetRoadLocationState extends State<GetRoadLocation>
    with TickerProviderStateMixin {
  final FirebaseService _firebaseService = FirebaseService();
  MapController mapController = MapController();
  late LatLng _initialLocation = const LatLng(-6.2088, 106.8456);
  bool _mapLoaded = false;

  @override
  void initState() {
    super.initState();
    // Hide loading after short delay (FlutterMap renders fast)
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        setState(() => _mapLoaded = true);
        print('✅ Map loaded (delay trigger)');
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: _firebaseService.photoChangeNotifier,
      builder: (context, _, __) {
        return StreamBuilder<List<RoadPhoto>>(
          key: ValueKey(_firebaseService.photoChangeNotifier.value),
          stream: _firebaseService.getPhotosStream('all'),
          builder: (context, snapshot) {
            print('🔄 Stream: ${snapshot.connectionState}, Data: ${snapshot.data?.length ?? 0}');

            if (snapshot.connectionState == ConnectionState.waiting && snapshot.data == null) {
              return _buildLoadingWidget();
            }

            if (snapshot.hasError) {
              print('❌ Error: ${snapshot.error}');
              return _buildErrorWidget(snapshot.error?.toString() ?? 'Unknown error');
            }

            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              print('📍 No photos');
              return _buildEmptyWidget();
            }

            final photos = snapshot.data!;
            print('✅ Got ${photos.length} photos');

            final markers = _buildMarkers(photos);

            if (photos.isNotEmpty) {
              _initialLocation = LatLng(photos[0].latitude, photos[0].longitude);
            }

            return _buildMapWidget(markers, photos);
          },
        );
      },
    );
  }

  Widget _buildLoadingWidget() {
    return Container(
      color: Colors.white,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            const Text('Loading peta...', style: TextStyle(fontSize: 14)),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorWidget(String error) {
    return Container(
      color: Colors.white,
      child: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 40),
              const SizedBox(height: 12),
              const Text('Error Loading Map'),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  error,
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyWidget() {
    return Container(
      color: Colors.white,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.location_off, color: Colors.grey, size: 40),
            const SizedBox(height: 12),
            const Text('Belum ada lokasi jalan'),
            const SizedBox(height: 24),
            Text(
              'Ambil foto jalan untuk tampil di peta',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapWidget(List<Marker> markers, List<RoadPhoto> photos) {
    return Stack(
      children: [
        FlutterMap(
          mapController: mapController,
          options: MapOptions(
            initialCenter: _initialLocation,
            initialZoom: 14,
            interactionOptions: const InteractionOptions(
              flags: ~InteractiveFlag.doubleTapZoom,
            ),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.ets',
            ),
            MarkerLayer(
              markers: markers,
            ),
          ],
        ),
        // Loading overlay
        if (!_mapLoaded)
          Container(
            color: Colors.black.withOpacity(0.3),
            child: Center(
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(
                      height: 40,
                      width: 40,
                      child: CircularProgressIndicator(strokeWidth: 3),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Loading peta...',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${markers.length} lokasi ditemukan',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  List<Marker> _buildMarkers(List<RoadPhoto> photos) {
    final markers = <Marker>[];
    
    for (final photo in photos) {
      try {
        final isFixed = photo.status == 'jalan sudah diperbaiki';
        
        final marker = Marker(
          point: LatLng(photo.latitude, photo.longitude),
          width: 50,
          height: 50,
          child: GestureDetector(
            onTap: () => _showStatusDialog(photo),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isFixed ? Colors.green : Colors.red,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.4),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  isFixed ? '✓' : '⚠',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        );
        markers.add(marker);
      } catch (e) {
        print('❌ Error building marker: $e');
      }
    }


    print('✅ Built ${markers.length} markers');
    return markers;
  }

  void _showStatusDialog(RoadPhoto photo) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Apakah jalan ini sudah diperbaiki?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Status saat ini: ${photo.status}'),
            const SizedBox(height: 12),
            if (photo.photoPath.isNotEmpty)
              Container(
                height: 150,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Image.file(
                  File(photo.photoPath),
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return const Center(
                      child: Icon(Icons.image_not_supported, color: Colors.grey),
                    );
                  },
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _updateRoadStatus(photo, true);
            },
            icon: const Icon(Icons.check),
            label: const Text('Sudah Diperbaiki'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _updateRoadStatus(RoadPhoto photo, bool isFixed) async {
    final newStatus = isFixed ? 'jalan sudah diperbaiki' : 'jalan belum diperbaiki';

    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final success = await _firebaseService.updatePhotoStatus(photo.id, newStatus);
      if (!mounted) return;
      Navigator.pop(context);

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('✅ Status: $newStatus')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal mengubah status di database'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Error: $e')),
      );
    }
  }
}
