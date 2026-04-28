import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_fonts/google_fonts.dart';

class CameraScreen extends StatefulWidget {
  final List<CameraDescription> cameras;

  const CameraScreen({
    super.key,
    required this.cameras,
  });

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraAppBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback onClose;

  const _CameraAppBar({required this.onClose});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        bottomLeft: Radius.circular(24),
        bottomRight: Radius.circular(24),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1E88E5), Color(0xFF0D47A1)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: AppBar(
          title: Text(
            'Ambil Foto',
            style: GoogleFonts.poppins(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: onClose,
          ),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _CameraScreenState extends State<CameraScreen> {
  late CameraController _cameraController;
  late Future<void> _initializeControllerFuture;
  bool _isTakingPicture = false;
  int _selectedCameraIdx = 0;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  void _initializeCamera() {
    _cameraController = CameraController(
      widget.cameras[_selectedCameraIdx],
      ResolutionPreset.high,
    );

    _initializeControllerFuture = _cameraController.initialize();
  }

  @override
  void dispose() {
    _cameraController.dispose();
    super.dispose();
  }

  Future<void> _takePicture() async {
    if (_isTakingPicture) return;

    try {
      setState(() => _isTakingPicture = true);
      await _initializeControllerFuture;

      final XFile picture = await _cameraController.takePicture();

      if (!mounted) return;

      Navigator.pop(context, picture);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengambil foto: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      setState(() => _isTakingPicture = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _CameraAppBar(onClose: () => Navigator.pop(context)),
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return Stack(
              children: [
                // Camera preview
                SizedBox.expand(
                  child: CameraPreview(_cameraController),
                ),
                // Bottom controls
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 32,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.7),
                        ],
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Cancel button
                            SizedBox(
                              width: 60,
                              height: 60,
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () => Navigator.pop(context),
                                  borderRadius: BorderRadius.circular(30),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.red.withOpacity(0.3),
                                      borderRadius: BorderRadius.circular(30),
                                      border: Border.all(
                                        color: Colors.red,
                                        width: 2,
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.close,
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 30),
                            // Capture button
                            SizedBox(
                              width: 80,
                              height: 80,
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: _isTakingPicture ? null : _takePicture,
                                  borderRadius: BorderRadius.circular(40),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(40),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.3),
                                          blurRadius: 8,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: _isTakingPicture
                                        ? const Padding(
                                            padding: EdgeInsets.all(20),
                                            child: CircularProgressIndicator(
                                              strokeWidth: 3,
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                Color(0xFF2196F3),
                                              ),
                                            ),
                                          )
                                        : const Icon(
                                            Icons.camera_alt_rounded,
                                            color: Color(0xFF2196F3),
                                            size: 40,
                                          ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 30),
                            // Flip camera button
                            SizedBox(
                              width: 60,
                              height: 60,
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: widget.cameras.length > 1
                                      ? () async {
                                          await _cameraController.dispose();
                                          _selectedCameraIdx =
                                              (_selectedCameraIdx + 1) %
                                                  widget.cameras.length;
                                          _initializeCamera();
                                          setState(() {});
                                        }
                                      : null,
                                  borderRadius: BorderRadius.circular(30),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: widget.cameras.length > 1
                                          ? Colors.blue.withOpacity(0.3)
                                          : Colors.grey.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(30),
                                      border: Border.all(
                                        color: widget.cameras.length > 1
                                            ? Colors.blue
                                            : Colors.grey,
                                        width: 2,
                                      ),
                                    ),
                                    child: Icon(
                                      Icons.flip_camera_android_rounded,
                                      color: widget.cameras.length > 1
                                          ? Colors.white
                                          : Colors.grey,
                                      size: 24,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Dokumentasikan Kondisi Jalan',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          } else {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  Color(0xFF2196F3),
                ),
              ),
            );
          }
        },
      ),
    );
  }
}
