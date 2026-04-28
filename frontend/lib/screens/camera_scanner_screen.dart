import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'dart:ui';
import 'classification_result_screen.dart';
import 'camera_tutorial_screen.dart';
import 'dart:io';
import 'package:image/image.dart' as img;
import 'dart:math' as math;

class AiScannerScreen extends StatefulWidget {
  const AiScannerScreen({super.key});

  @override
  State<AiScannerScreen> createState() => _AiScannerScreenState();
}

class _AiScannerScreenState extends State<AiScannerScreen> with SingleTickerProviderStateMixin {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isInit = false;
  File? _capturedImage;
  bool _isBlurry = false;
  double _blurScore = 0.0;
  bool _isCheckingBlur = false;
  FlashMode _flashMode = FlashMode.off;
  int _cameraIndex = 0;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _initCamera();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.2, end: 1.0).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
  }

  Future<void> _initCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras != null && _cameras!.isNotEmpty) {
        _cameraController = CameraController(
          _cameras![_cameraIndex],
          ResolutionPreset.high,
          enableAudio: false,
        );

        await _cameraController!.initialize();
        await _cameraController!.setFlashMode(_flashMode);
        
        if (mounted) {
          setState(() {
            _isInit = true;
          });
        }
      }
    } catch (e) {
      debugPrint("Camera Error: $e");
    }
  }

  Future<void> _toggleFlash() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) return;

    FlashMode nextMode;
    switch (_flashMode) {
      case FlashMode.off:
        nextMode = FlashMode.always;
        break;
      case FlashMode.always:
        nextMode = FlashMode.auto;
        break;
      case FlashMode.auto:
        nextMode = FlashMode.off;
        break;
      default:
        nextMode = FlashMode.off;
    }

    try {
      await _cameraController!.setFlashMode(nextMode);
      setState(() {
        _flashMode = nextMode;
      });
    } catch (e) {
      debugPrint("Error setting flash mode: $e");
    }
  }

  Future<void> _toggleCamera() async {
    if (_cameras == null || _cameras!.length < 2) return;

    setState(() {
      _isInit = false;
      _cameraIndex = (_cameraIndex + 1) % _cameras!.length;
    });

    await _cameraController?.dispose();
    _initCamera();
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _captureImage() async {
    if (_cameraController != null && _cameraController!.value.isInitialized) {
      try {
        final image = await _cameraController!.takePicture();
        if (mounted) {
          setState(() {
            _capturedImage = File(image.path);
            _isCheckingBlur = true;
          });
          _checkBlur(image.path);
        }
      } catch (e) {
        debugPrint("Error taking picture: $e");
      }
    }
  }

  Future<void> _checkBlur(String path) async {
    try {
      final bytes = await File(path).readAsBytes();
      final image = img.decodeImage(bytes);
      
      if (image == null) return;

      // 1. Downsample for performance (approx 300px)
      final thumbnail = img.copyResize(image, width: 300);
      
      // 2. Grayscale
      final grayscale = img.grayscale(thumbnail);
      
      // 3. Laplacian Variance calculation
      // Kernel: [0, 1, 0, 1, -4, 1, 0, 1, 0]
      double mean = 0;
      List<double> laplacianValues = [];

      for (int y = 1; y < grayscale.height - 1; y++) {
        for (int x = 1; x < grayscale.width - 1; x++) {
          final p1 = img.getLuminance(grayscale.getPixel(x, y - 1));
          final p2 = img.getLuminance(grayscale.getPixel(x - 1, y));
          final p3 = img.getLuminance(grayscale.getPixel(x, y));
          final p4 = img.getLuminance(grayscale.getPixel(x + 1, y));
          final p5 = img.getLuminance(grayscale.getPixel(x, y + 1));

          double lap = (p1 + p2 + p4 + p5 - 4 * p3).toDouble();
          laplacianValues.add(lap);
          mean += lap;
        }
      }

      mean /= laplacianValues.length;
      double variance = 0;
      for (var val in laplacianValues) {
        variance += math.pow(val - mean, 2);
      }
      variance /= laplacianValues.length;

      if (mounted) {
        setState(() {
          _blurScore = variance;
          // Threshold of 100-200 is typical for Laplacian variance blur detection
          // We'll be conservative and use 150.
          _isBlurry = variance < 150.0;
          _isCheckingBlur = false;
        });
      }
    } catch (e) {
      debugPrint("Blur check error: $e");
      if (mounted) {
        setState(() => _isCheckingBlur = false);
      }
    }
  }

  void _onContinue() {
    if (_capturedImage != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ClassificationResultScreen(
            imageFile: _capturedImage!,
          ),
        ),
      );
    }
  }

  void _onRecapture() {
    setState(() {
      _capturedImage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Camera Preview Layer
          if (_isInit && _cameraController != null)
            CameraPreview(_cameraController!)
          else
            const Center(child: CircularProgressIndicator(color: Color(0xFF2196F3))),

          // 2. Dark Overlay Layer for Glassmorphism contrast
          Container(
            color: Colors.black.withOpacity(0.4),
          ),

          // 3. UI Layer
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Dynamically calculate the scanner box height.
                // J5 usable height is ~640dp; larger phones get ~350dp.
                final scannerHeight = (constraints.maxHeight * 0.40).clamp(200.0, 350.0);

                return Column(
                  children: [
                    const SizedBox(height: 12),
                    // Top Bar
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(40),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Container(
                            height: 60,  // reduced from 70
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(40),
                              border: Border.all(color: Colors.white.withOpacity(0.1)),
                            ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.close, color: Colors.white),
                              onPressed: () => Navigator.pop(context),
                            ),
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text(
                                  "Scan Waste",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  "AI RECYCLING DETECTION",
                                  style: TextStyle(
                                    color: const Color(0xFF2196F3).withOpacity(0.9),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ],
                            ),
                            IconButton(
                              icon: const Icon(Icons.help_outline, color: Colors.white),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => const TutorialStep1()),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                    const Spacer(flex: 1),

                    // Center Scanner Area
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Stack(
                        alignment: Alignment.center,
                        clipBehavior: Clip.none,
                        children: [
                          // Scanner Frame – height adapts to screen
                          Container(
                            height: scannerHeight,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: const Color(0xFF2196F3).withOpacity(0.4),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF2196F3).withOpacity(0.1),
                              blurRadius: 40,
                              spreadRadius: 10,
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            const SizedBox(height: 30),
                            Text(
                              "Align item for scanning",
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 14,
                              ),
                            ),
                            // Scanning laser line effect
                            AnimatedBuilder(
                              animation: _pulseAnimation,
                              builder: (context, child) {
                                return Container(
                                  margin: const EdgeInsets.only(top: 16),
                                  height: 2,
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.transparent,
                                        const Color(0xFF2196F3).withOpacity(_pulseAnimation.value),
                                        Colors.transparent,
                                      ],
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF2196F3).withOpacity(_pulseAnimation.value * 0.5),
                                        blurRadius: 10,
                                      )
                                    ],
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),

                      // Center Floating Indicator Badge
                      Positioned(
                        bottom: 40,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(30),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.5),
                                borderRadius: BorderRadius.circular(30),
                                border: Border.all(color: const Color(0xFF2196F3).withOpacity(0.3)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  AnimatedBuilder(
                                    animation: _pulseAnimation,
                                    builder: (context, child) {
                                      return Container(
                                        width: 8,
                                        height: 8,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF2196F3).withOpacity(_pulseAnimation.value),
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color: const Color(0xFF2196F3).withOpacity(_pulseAnimation.value),
                                              blurRadius: 6,
                                            )
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                  const SizedBox(width: 12),
                                  const Icon(Icons.search, color: Colors.white70, size: 16),
                                  const SizedBox(width: 8),
                                  const Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "DETECTING",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        "MATERIAL...",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  )
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      
                      // Floating Controls on Right
                      Positioned(
                        right: -16,
                        top: 100,
                        child: Column(
                          children: [
                            _buildSideButton(
                              _getFlashIcon(), 
                              "FLASH", 
                              onTap: _toggleFlash,
                              isActive: _flashMode != FlashMode.off,
                            ),
                            const SizedBox(height: 24),
                            _buildSideButton(
                              Icons.flip_camera_ios, 
                              "FLIP", 
                              onTap: _toggleCamera,
                            ),
                          ],
                        ),
                      ),
                        ],
                      ),
                    ),

                    const Spacer(flex: 1),

                // Bottom Readout Card
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: Colors.white.withOpacity(0.1)),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.3),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: const Icon(Icons.smart_toy, color: Colors.white70),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        "AI Scanning",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        "Detecting recyclable material...",
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.6),
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    const Text(
                                      "84%",
                                      style: TextStyle(
                                        color: Color(0xFF2196F3),
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      "CONFIDENCE",
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.5),
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            // Progress Bar
                            Stack(
                              children: [
                                Container(
                                  height: 8,
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.3),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                                AnimatedBuilder(
                                  animation: _pulseAnimation,
                                  builder: (context, child) {
                                    return Container(
                                      height: 8,
                                      width: MediaQuery.of(context).size.width * 0.65,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF2196F3),
                                        borderRadius: BorderRadius.circular(4),
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(0xFF2196F3).withOpacity(_pulseAnimation.value * 0.8),
                                            blurRadius: 10,
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.info, color: Colors.white.withOpacity(0.5), size: 14),
                                const SizedBox(width: 8),
                                Text(
                                  "HOLD STEADY FOR BETTER ACCURACY",
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.5),
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.1,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16), // tighter gap

                  // Shutter Button
                  GestureDetector(
                    onTap: _captureImage,
                    child: AnimatedBuilder(
                      animation: _pulseAnimation,
                      builder: (context, child) {
                        return Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0xFF2196F3), width: 3),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF2196F3).withOpacity(_pulseAnimation.value * 0.5),
                                blurRadius: 20,
                                spreadRadius: 5,
                              )
                            ],
                          ),
                          child: Container(
                            width: 56,    // slightly smaller for J5
                            height: 56,
                            decoration: const BoxDecoration(
                              color: Color(0xFF2196F3),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.camera,
                              color: Colors.black87,
                              size: 28,
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 16),  // tighter gap
                ],
              );
            },
          ),
        ),
        
        // 4. Post-Capture Preview Overlay
        if (_capturedImage != null)
          _buildPreviewOverlay(),
      ],
    ),
  );
}

Widget _buildPreviewOverlay() {
  return Container(
    color: Colors.black,
    child: Stack(
      fit: StackFit.expand,
      children: [
        // The Captured Image
        Image.file(_capturedImage!, fit: BoxFit.cover),
        
        // Darkened bottom for buttons
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withOpacity(0.1),
                Colors.black.withOpacity(0.8),
              ],
            ),
          ),
        ),

        SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 20),
              // Top Message
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: Colors.white.withOpacity(0.2)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle_outline, color: Colors.greenAccent, size: 18),
                    SizedBox(width: 8),
                    Text(
                      "IMAGE CAPTURED",
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ],
                ),
              ),
              
              const Spacer(),
              
              // Hint if blurry
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40.0),
                child: Column(
                  children: [
                    if (_isCheckingBlur)
                      const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                    else if (_isBlurry)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.redAccent.withOpacity(0.5)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 20),
                            SizedBox(width: 8),
                            Text(
                              "BLUR DETECTED!",
                              style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ],
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.greenAccent.withOpacity(0.5)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.verified_outlined, color: Colors.greenAccent, size: 20),
                            SizedBox(width: 8),
                            Text(
                              "SHARP IMAGE",
                              style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 16),
                    Text(
                      _isBlurry 
                        ? "This photo looks a bit blurry. For best AI results, we recommend retaking it."
                        : "Is the photo clear? If it's blurry, tap Recapture.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Action Buttons
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24),
                child: Row(
                  children: [
                    // Recapture Button
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _onRecapture,
                        icon: const Icon(Icons.refresh, color: Colors.white),
                        label: const Text("RECAPTURE"),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white30, width: 2),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Continue Button
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _onContinue,
                        icon: const Icon(Icons.analytics, color: Colors.black87),
                        label: const Text("ANALYZE"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2196F3),
                          foregroundColor: Colors.black87,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                          elevation: 8,
                          shadowColor: const Color(0xFF2196F3).withOpacity(0.5),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

  IconData _getFlashIcon() {
    switch (_flashMode) {
      case FlashMode.off: return Icons.flash_off;
      case FlashMode.always: return Icons.flash_on;
      case FlashMode.auto: return Icons.flash_auto;
      default: return Icons.flash_off;
    }
  }

  Widget _buildSideButton(IconData icon, String label, {VoidCallback? onTap, bool isActive = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isActive ? const Color(0xFF2196F3).withOpacity(0.3) : Colors.black.withOpacity(0.5),
              shape: BoxShape.circle,
              border: Border.all(color: isActive ? const Color(0xFF2196F3) : Colors.white.withOpacity(0.1)),
            ),
            child: Icon(icon, color: isActive ? const Color(0xFF2196F3) : Colors.white, size: 24),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              color: isActive ? const Color(0xFF2196F3) : Colors.white.withOpacity(0.8),
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
