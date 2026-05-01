import 'dart:io';
import 'package:flutter/material.dart';
import '../utils/responsive.dart';
import '../services/api_service.dart';
import 'bin_locator_screen.dart';

class ClassificationResultScreen extends StatefulWidget {
  final File? imageFile;
  final String? imageUrl;
  final ClassificationResult? preloadedResult;

  const ClassificationResultScreen({super.key, this.imageFile, this.imageUrl, this.preloadedResult});

  @override
  State<ClassificationResultScreen> createState() =>
      _ClassificationResultScreenState();
}

class _ClassificationResultScreenState
    extends State<ClassificationResultScreen> {
  bool _isAnalyzing = true;
  ClassificationResult? _result;
  String? _errorMessage;
  Size? _imageSize;

  @override
  void initState() {
    super.initState();
    if (widget.preloadedResult != null) {
      _result = widget.preloadedResult;
      _isAnalyzing = false;
      // Get dimensions for network image if available
      if (widget.imageUrl != null) {
        final Image image = Image.network(widget.imageUrl!);
        image.image.resolve(const ImageConfiguration()).addListener(
          ImageStreamListener((ImageInfo info, bool _) {
            if (mounted) {
              setState(() {
                _imageSize = Size(info.image.width.toDouble(), info.image.height.toDouble());
              });
            }
          }),
        );
      }
    } else {
      _runClassification();
    }
  }

  Future<void> _runClassification() async {
    if (widget.imageFile == null) return;
    try {
      // Get image dimensions first
      final bytes = await widget.imageFile!.readAsBytes();
      final decodedImage = await decodeImageFromList(bytes);
      if (mounted) {
        setState(() {
          _imageSize = Size(decodedImage.width.toDouble(), decodedImage.height.toDouble());
        });
      }

      final result = await ApiService.instance.classifyImage(widget.imageFile!);
      if (mounted) {
        setState(() {
          _result = result;
          _isAnalyzing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
          _isAnalyzing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final sp = R.sp(context);
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          "Classification Result",
          style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: R.fs(context, 17)),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: R.pagePadding(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: sp),
              // ── Captured Image with Bounding Boxes
              Container(
                height: R.h(context, 35),
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return Stack(
                        fit: StackFit.expand,
                        children: [
                          // The actual image
                          widget.imageFile != null
                              ? Image.file(widget.imageFile!, fit: BoxFit.cover, key: const ValueKey('image'))
                              : (widget.imageUrl != null 
                                  ? Image.network(widget.imageUrl!, fit: BoxFit.cover) 
                                  : Container(color: Colors.grey[200], child: const Center(child: Icon(Icons.image, color: Colors.grey, size: 50)))),
                          
                          // Draw YOLO Detections
                          if (_result != null && _result!.detections.isNotEmpty)
                            _buildDetectionsOverlay(constraints),

                          // Analyzing Overlay
                          if (_isAnalyzing)
                            Container(
                              color: Colors.black26,
                              child: const Center(child: CircularProgressIndicator(color: Colors.white)),
                            ),
                        ],
                      );
                    },
                  ),
                ),
              ),
              SizedBox(height: sp * 2),

              // Loading
              if (_isAnalyzing) ...[
                const CircularProgressIndicator(color: Color(0xFF2196F3)),
                const SizedBox(height: 16),
                Text(
                  "Analyzing image with GreenBin Genius AI...",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: R.fs(context, 15), color: Colors.grey),
                ),
              ]

              // ── Error ─────────────────────────────────────────
              else if (_errorMessage != null) ...[
                Icon(Icons.error_outline,
                    color: Colors.red, size: R.icon(context, 48)),
                SizedBox(height: sp * 0.75),
                Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: R.fs(context, 14), color: Colors.red),
                ),
                SizedBox(height: sp * 1.5),
                OutlinedButton.icon(
                  onPressed: () {
                    setState(() {
                      _isAnalyzing = true;
                      _errorMessage = null;
                    });
                    _runClassification();
                  },
                  icon: const Icon(Icons.refresh),
                  label: Text("Retry",
                      style: TextStyle(fontSize: R.fs(context, 14))),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF2196F3),
                    side: const BorderSide(color: Color(0xFF2196F3)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                ),
              ]

              // ── Results ───────────────────────────────────────
              else if (_result != null) ...[
                // Recyclable badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  decoration: BoxDecoration(
                    color: _result!.recyclable
                        ? const Color(0xFF4CAF50).withOpacity(0.12)
                        : Colors.orange.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(50),
                    border: Border.all(
                      color: _result!.recyclable
                          ? const Color(0xFF4CAF50)
                          : Colors.orange,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _result!.recyclable
                            ? Icons.recycling
                            : Icons.delete_outline,
                        size: 18,
                        color: _result!.recyclable
                            ? const Color(0xFF4CAF50)
                            : Colors.orange,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _result!.recyclable ? "Recyclable" : "Non-Recyclable",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: _result!.recyclable
                              ? const Color(0xFF4CAF50)
                              : Colors.orange,
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: sp * 1.5),

                // ── AI Model Insights (Transparency Breakdown)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.analytics_outlined, color: Colors.grey[700], size: 18),
                          const SizedBox(width: 8),
                          Text(
                            "AI MODEL INSIGHTS",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.2,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      
                      // YOLO Section
                      _buildModelBar(
                        modelName: "YOLO v8",
                        taskName: "Object Detection",
                        prediction: _result!.objectDetected,
                        confidence: _result!.yoloConfidence,
                        icon: Icons.filter_center_focus,
                      ),
                      
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16.0),
                        child: Divider(height: 1),
                      ),
                      
                      // CNN Section
                      _buildModelBar(
                        modelName: "InceptionV3",
                        taskName: "Category & Material",
                        prediction: "${_result!.category} (${_result!.material})",
                        confidence: _result!.cnnConfidence,
                        icon: Icons.layers_outlined,
                      ),
                    ],
                  ),
                ),

                SizedBox(height: sp * 1.75),

                // Disposal tip card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE3F2FD),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: const Color(0xFF2196F3).withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.info_outline,
                              color: Color(0xFF2196F3), size: 18),
                          const SizedBox(width: 8),
                          const Text(
                            "Disposal Tip",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Color(0xFF2196F3),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _result!.disposalTip,
                        style: const TextStyle(
                            fontSize: 13, color: Colors.black87),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _result!.disposalTipUr,
                        textDirection: TextDirection.rtl,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.black54,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: sp * 2),

                // Find Nearest Bin button
                SizedBox(
                  width: double.infinity,
                  height: R.buttonHeight(context),
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => BinLocatorScreen(
                            wasteCategory: _result!.category,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.location_on),
                    label: Text(
                      'FIND NEAREST BIN',
                      style: TextStyle(
                          fontSize: R.fs(context, 14),
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4CAF50),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30)),
                      elevation: 0,
                    ),
                  ),
                ),
                SizedBox(height: sp * 0.9),
                SizedBox(
                  width: double.infinity,
                  height: R.buttonHeight(context),
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.camera_alt_outlined),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF2196F3),
                      side: const BorderSide(color: Color(0xFF2196F3)),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30)),
                    ),
                    label: Text(
                      'RETAKE PHOTO / SCAN NEW',
                      style: TextStyle(
                          fontSize: R.fs(context, 14),
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8),
                    ),
                  ),
                ),
                SizedBox(height: sp * 1.5),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetectionsOverlay(BoxConstraints constraints) {
    if (_imageSize == null || _result == null) return const SizedBox.shrink();

    final viewW = constraints.maxWidth;
    final viewH = constraints.maxHeight;
    final origW = _imageSize!.width;
    final origH = _imageSize!.height;

    // Calculate scale for BoxFit.cover
    final scale = (viewW / origW > viewH / origH) ? viewW / origW : viewH / origH;
    
    // Calculate offsets
    final dx = (viewW - origW * scale) / 2;
    final dy = (viewH - origH * scale) / 2;

    return Stack(
      children: _result!.detections.map((det) {
        final box = det.box; // [x1, y1, x2, y2]
        
        final left = box[0] * scale + dx;
        final top = box[1] * scale + dy;
        final width = (box[2] - box[0]) * scale;
        final height = (box[3] - box[1]) * scale;

        return Positioned(
          left: left,
          top: top,
          width: width,
          height: height,
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFF00E5FF), width: 2),
            ),
            child: Align(
              alignment: Alignment.topLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                color: const Color(0xFF00E5FF),
                child: Text(
                  "${det.label} ${(det.confidence * 100).toStringAsFixed(0)}%",
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildModelBar({
    required String modelName,
    required String taskName,
    required String prediction,
    required double confidence,
    required IconData icon,
  }) {
    final color = confidence >= 0.8 ? const Color(0xFF4CAF50) : 
                  confidence >= 0.6 ? Colors.orange : Colors.red;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Icon(icon, size: 16, color: Colors.black87),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    modelName,
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 0.5),
                  ),
                  Text(
                    taskName,
                    style: TextStyle(color: Colors.grey[600], fontSize: 11),
                  ),
                ],
              ),
            ),
            Text(
              "${(confidence * 100).toStringAsFixed(0)}%",
              style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: confidence,
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                  minHeight: 6,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          "PREDICTION: ${prediction.toUpperCase()}",
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: Colors.grey[500],
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}
