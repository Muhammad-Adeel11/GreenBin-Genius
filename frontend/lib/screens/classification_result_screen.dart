import 'dart:io';
import 'package:flutter/material.dart';
import '../utils/responsive.dart';
import '../services/api_service.dart';
import 'bin_locator_screen.dart';

class ClassificationResultScreen extends StatefulWidget {
  final File? imageFile;
  final String? imageUrl;
  final String mode; // "single" or "multiple"
  final ClassificationResult? preloadedResult;

  const ClassificationResultScreen({
    super.key, 
    this.imageFile, 
    this.imageUrl, 
    this.mode = "single", 
    this.preloadedResult
  });

  @override
  State<ClassificationResultScreen> createState() => _ClassificationResultScreenState();
}

class _ClassificationResultScreenState extends State<ClassificationResultScreen> {
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
      final bytes = await widget.imageFile!.readAsBytes();
      final decodedImage = await decodeImageFromList(bytes);
      if (mounted) {
        setState(() {
          _imageSize = Size(decodedImage.width.toDouble(), decodedImage.height.toDouble());
        });
      }

      final result = await ApiService.instance.classifyImage(widget.imageFile!, mode: widget.mode);
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: R.w(context, 8)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                "Classification Result",
                style: TextStyle(
                  fontSize: R.fs(context, 26),
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              SizedBox(height: sp * 2),

              // ── Image Card (Shadowed White Card like Tutorial)
              Container(
                height: R.h(context, 35),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 30,
                      offset: const Offset(0, 15),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(16),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return Stack(
                        fit: StackFit.expand,
                        children: [
                          (_result != null && (_result!.annotatedImageUrl != null || _result!.imageUrl != null))
                              ? Image.network(_result!.annotatedImageUrl ?? _result!.imageUrl!, fit: BoxFit.cover)
                              : (widget.imageFile != null
                                  ? Image.file(widget.imageFile!, fit: BoxFit.cover)
                                  : (widget.imageUrl != null 
                                      ? Image.network(widget.imageUrl!, fit: BoxFit.cover) 
                                      : Container(color: Colors.grey[100], child: const Icon(Icons.image, color: Colors.grey, size: 50)))),
                          
                          if (_result != null && _result!.detections.isNotEmpty && _result!.annotatedImageUrl == null)
                            _buildDetectionsOverlay(constraints),

                          if (_isAnalyzing)
                            Container(
                              color: Colors.white70,
                              child: const Center(child: CircularProgressIndicator(color: Color(0xFF2196F3))),
                            ),
                        ],
                      );
                    },
                  ),
                ),
              ),

              SizedBox(height: sp * 3),

              if (_isAnalyzing) ...[
                const CircularProgressIndicator(color: Color(0xFF2196F3)),
                const SizedBox(height: 16),
                Text("Analyzing...", style: TextStyle(color: Colors.grey, fontSize: R.fs(context, 16))),
              ]
              else if (_errorMessage != null) ...[
                Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
                TextButton(onPressed: _runClassification, child: const Text("Retry")),
              ]
              else if (_result != null) ...[
                
                // ── Info Section (Dynamic based on Mode) ──
                if (widget.mode == "multiple") ...[
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: R.w(context, 4)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "DETECTIONS (${_result!.detections.length})",
                          style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.black54, fontSize: 11, letterSpacing: 1.0),
                        ),
                        const SizedBox(height: 12),
                        ..._result!.detections.asMap().entries.map((entry) {
                          int idx = entry.key;
                          var det = entry.value;
                          return _buildInfoRow(
                            context, 
                            det.label, 
                            "${(det.confidence * 100).toStringAsFixed(0)}%", 
                            idx == 0, 
                            idx == _result!.detections.length - 1
                          );
                        }),
                      ],
                    ),
                  ),
                ]
                else if (widget.mode == "food") ...[
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: R.w(context, 4)),
                    child: Column(
                      children: [
                        _buildInfoRow(context, "Food Status", _result!.category.replaceAll('_', ' ').toUpperCase(), true, false),
                        _buildInfoRow(context, "Confidence", "${(_result!.confidence * 100).toStringAsFixed(0)}%", false, true),
                      ],
                    ),
                  ),
                ]
                else ...[
                  // Single Mode
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: R.w(context, 4)),
                    child: Column(
                      children: [
                        _buildInfoRow(context, "Class", _result!.category.toUpperCase(), true, false),
                        _buildInfoRow(context, "Material", _result!.material, false, false),
                        _buildInfoRow(context, "Confidence", "${(_result!.confidence * 100).toStringAsFixed(0)}%", false, true),
                      ],
                    ),
                  ),
                ],

                SizedBox(height: sp * 3),

                // ── Disposal Tip Section
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE3F2FD),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "DISPOSAL TIP",
                        style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF1E88E5), fontSize: 11, letterSpacing: 1.0),
                      ),
                      const SizedBox(height: 8),
                      Text(_result!.disposalTip, style: const TextStyle(fontSize: 14, color: Colors.black87)),
                      const SizedBox(height: 4),
                      Text(_result!.disposalTipUr, textDirection: TextDirection.rtl, style: const TextStyle(fontSize: 14, color: Colors.black54, fontStyle: FontStyle.italic)),
                    ],
                  ),
                ),

                SizedBox(height: sp * 3),

                // ── Action Buttons
                SizedBox(
                  width: double.infinity,
                  height: R.h(context, 7.5),
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => BinLocatorScreen(wasteCategory: _result!.category)));
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4CAF50),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40)),
                      elevation: 0,
                    ),
                    child: Text("FIND NEAREST BIN", style: TextStyle(fontSize: R.fs(context, 14), fontWeight: FontWeight.w900, letterSpacing: 1.0)),
                  ),
                ),
                SizedBox(height: sp * 1.5),
                SizedBox(
                  width: double.infinity,
                  height: R.h(context, 7.5),
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF2196F3),
                      side: const BorderSide(color: Color(0xFF2196F3), width: 2),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40)),
                    ),
                    child: Text("SCAN NEW", style: TextStyle(fontSize: R.fs(context, 14), fontWeight: FontWeight.w900, letterSpacing: 1.0)),
                  ),
                ),
                SizedBox(height: sp * 4),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value, bool isFirst, bool isLast) {
    return SizedBox(
      height: 50,
      child: Row(
        children: [
          // Connector Line
          SizedBox(
            width: 30,
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (!isLast)
                  Positioned(
                    top: 25, bottom: -25,
                    child: Container(width: 1, color: Colors.grey[300]),
                  ),
                if (!isFirst)
                  Positioned(
                    top: -25, bottom: 25,
                    child: Container(width: 1, color: Colors.grey[300]),
                  ),
                Container(width: 12, height: 1, color: Colors.grey[300]),
              ],
            ),
          ),
          
          Text(
            label,
            style: TextStyle(fontSize: R.fs(context, 15), fontWeight: FontWeight.w500, color: Colors.black87),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF2196F3),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              value,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetectionsOverlay(BoxConstraints constraints) {
    if (_imageSize == null || _result == null) return const SizedBox.shrink();
    final viewW = constraints.maxWidth;
    final viewH = constraints.maxHeight;
    final origW = _imageSize!.width;
    final origH = _imageSize!.height;
    final scale = (viewW / origW > viewH / origH) ? viewW / origW : viewH / origH;
    final dx = (viewW - origW * scale) / 2;
    final dy = (viewH - origH * scale) / 2;

    return Stack(
      children: _result!.detections.map((det) {
        final box = det.box;
        final left = box[0] * scale + dx;
        final top = box[1] * scale + dy;
        final width = (box[2] - box[0]) * scale;
        final height = (box[3] - box[1]) * scale;
        const themeColor = Color(0xFF00FFD4);
        return Positioned(
          left: left, top: top, width: width, height: height,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(decoration: BoxDecoration(border: Border.all(color: themeColor, width: 2))),
              Positioned(
                top: -18, left: -1,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  color: themeColor,
                  child: Text(
                    "${det.label.toUpperCase()} ${det.confidence.toStringAsFixed(2)}",
                    style: const TextStyle(color: Colors.black, fontSize: 9, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
