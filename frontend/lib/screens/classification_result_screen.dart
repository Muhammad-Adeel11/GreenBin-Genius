import 'dart:io';
import 'package:flutter/material.dart';
import '../utils/responsive.dart';
import '../utils/disposal_data.dart';
import '../services/api_service.dart';
import '../services/tflite_classifier_service.dart';
import '../services/translation_service.dart';
import 'bin_locator_screen.dart';
import 'disposal_guidance_screen.dart';

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
  String? _classificationId;   // MongoDB _id of the saved record
  int? _inferenceMs;           // On-device inference time in milliseconds
  bool _usedOnDevice = false;  // Whether TFLite on-device was used

  // Guidance
  DisposalGuidance? _guidance;

  @override
  void initState() {
    super.initState();
    if (widget.preloadedResult != null) {
      _result   = widget.preloadedResult;
      _guidance = getDisposalGuidance(_result!.category);
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

      ClassificationResult result;

      if (widget.mode == 'single') {
        // ── On-Device TFLite path ────────────────────────────────────────
        final loaded = await TFLiteClassifierService.instance.load();
        if (loaded) {
          final tfliteOut = await TFLiteClassifierService.instance.classify(widget.imageFile!);
          if (tfliteOut != null) {
            result = _tfliteToResult(tfliteOut);
            if (mounted) {
              setState(() {
                _inferenceMs  = tfliteOut.inferenceMs;
                _usedOnDevice = true;
              });
            }
            // Save to backend history in background (non-blocking)
            _saveToHistory(widget.imageFile!);
          } else {
            // TFLite ran but returned null — fallback to backend
            result = await ApiService.instance.classifyImage(widget.imageFile!, mode: 'single');
          }
        } else {
          // Model failed to load — fallback to backend
          result = await ApiService.instance.classifyImage(widget.imageFile!, mode: 'single');
        }
      } else {
        // ── Backend path for multiple / food modes ───────────────────────
        result = await ApiService.instance.classifyImage(widget.imageFile!, mode: widget.mode);
      }

      if (mounted) {
        setState(() {
          _result   = result;
          _guidance = getDisposalGuidance(result.category);
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

  /// Convert TFLite output to the unified [ClassificationResult] model.
  ClassificationResult _tfliteToResult(TFLiteClassificationOutput out) {
    // Material and recyclability lookup per label
    const materialMap = <String, (String, bool)>{
      'e-waste': ('Electronic Components', false),
      'glass':   ('Glass', true),
      'metal':   ('Metal', true),
      'plastic': ('Plastic', true),
      'textile': ('Textile / Fabric', false),
      'wood':    ('Wood', false),
    };
    final (material, recyclable) = materialMap[out.label] ?? ('Unknown', false);
    final guidance = getDisposalGuidance(out.label);
    return ClassificationResult(
      mode:           'single',
      category:       out.label,
      objectDetected: out.label,
      material:       material,
      confidence:     out.confidence,
      cnnConfidence:  out.confidence,
      disposalTip:    guidance.tipEn,
      disposalTipUr:  guidance.tipUr,
      recyclable:     recyclable,
      timestamp:      DateTime.now(),
    );
  }

  /// Fire-and-forget: send the image to the backend so the scan is logged
  /// in MongoDB (Activity tab, leaderboard points, streak).
  void _saveToHistory(File imageFile) {
    ApiService.instance
        .classifyImage(imageFile, mode: 'single')
        .catchError((_) {});
  }

  @override
  Widget build(BuildContext context) {
    final sp = R.sp(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: isDark ? Colors.white : Colors.black),
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
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              SizedBox(height: sp * 2),

              // ── Image Card (Shadowed White Card like Tutorial)
              Container(
                height: R.h(context, 35),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
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
                              color: isDark ? Colors.black54 : Colors.white70,
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
                // ── Waste Type Heading (Badge) ──────────────────────
                _buildWasteTypeHeading(_result!),

                SizedBox(height: sp * 1.5),
                
                // ── Info Section (Dynamic based on Mode) ──
                if (widget.mode == "multiple") ...[
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: R.w(context, 4)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "DETECTIONS",
                              style: TextStyle(fontWeight: FontWeight.w900, color: isDark ? Colors.white60 : Colors.black54, fontSize: 11, letterSpacing: 1.0),
                            ),
                            Text(
                              "OBJECT COUNT: ${_result!.objectCount}",
                              style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF2196F3), fontSize: 11, letterSpacing: 1.0),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ..._result!.detections.map((det) {
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
                              ],
                              border: Border.all(color: isDark ? Colors.white10 : Colors.grey.withOpacity(0.1)),
                            ),
                            child: Column(
                              children: [
                                _buildSimpleInfoRow(context, "Class", det.label),
                                Divider(height: 16, color: isDark ? Colors.white10 : Colors.grey[200]),
                                _buildSimpleInfoRow(context, "Material", det.material),
                                Divider(height: 16, color: isDark ? Colors.white10 : Colors.grey[200]),
                                _buildSimpleInfoRow(context, "Confidence", "${(det.confidence * 100).toStringAsFixed(0)}%"),
                              ],
                            ),
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
                        _buildInfoRow(context, "Food", _result!.category.replaceAll('_', ' ').toUpperCase(), true, false),
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
                        // ⚡ On-Device AI badge
                        if (_usedOnDevice && _inferenceMs != null)
                          Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF1A2340)
                                  : const Color(0xFFE8EAF6),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: const Color(0xFF3F51B5).withValues(alpha: 0.3)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text('🤖', style: TextStyle(fontSize: 14)),
                                const SizedBox(width: 6),
                                Text(
                                  'On-Device AI',
                                  style: TextStyle(
                                    color: const Color(0xFF3F51B5),
                                    fontWeight: FontWeight.w800,
                                    fontSize: R.fs(context, 11),
                                    letterSpacing: 0.3,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                const Text('⚡', style: TextStyle(fontSize: 13)),
                                const SizedBox(width: 4),
                                Text(
                                  '${_inferenceMs}ms',
                                  style: TextStyle(
                                    color: isDark ? Colors.white70 : Colors.black54,
                                    fontWeight: FontWeight.w700,
                                    fontSize: R.fs(context, 11),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        _buildInfoRow(context, "Class", _result!.category.toUpperCase(), true, false),
                        _buildInfoRow(context, "Material", _result!.material, false, false),
                        _buildInfoRow(context, "Confidence", "${(_result!.confidence * 100).toStringAsFixed(0)}%", false, true),
                      ],
                    ),
                  ),
                ],

                SizedBox(height: sp * 3),

                // ── Disposal Guidance Button → navigates to full screen
                if (_guidance != null) Builder(builder: (context) {
                  return ValueListenableBuilder<String>(
                    valueListenable: TranslationService.instance.languageNotifier,
                    builder: (context, lang, _) {
                      final isU = TranslationService.isUrdu;
                      final bc  = Color(int.parse('FF${_guidance!.binColorHex.replaceAll("#", "")}', radix: 16));
                      return GestureDetector(
                        onTap: () => Navigator.push(context, MaterialPageRoute(
                          builder: (_) => DisposalGuidanceScreen(
                            guidance: _guidance!,
                            classificationId: _classificationId,
                          ),
                        )),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: bc.withOpacity(0.25), width: 1.5),
                            boxShadow: [BoxShadow(color: bc.withOpacity(0.08), blurRadius: 16, offset: const Offset(0, 6))],
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 52, height: 52,
                                decoration: BoxDecoration(
                                  color: bc.withOpacity(0.10),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: bc.withOpacity(0.3), width: 1.5),
                                ),
                                child: Center(child: Text(_guidance!.icon, style: const TextStyle(fontSize: 24))),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: isU ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      isU ? 'ڈسپوزل گائیڈنس' : 'DISPOSAL GUIDANCE',
                                      style: TextStyle(color: bc, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      isU ? _guidance!.tipUr : _guidance!.tipEn,
                                      textDirection: isU ? TextDirection.rtl : TextDirection.ltr,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(color: isDark ? Colors.white60 : Colors.black54, fontSize: 13, height: 1.4),
                                    ),
                                    const SizedBox(height: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: bc.withOpacity(0.18),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        '${_guidance!.binColor} Bin  •  ${isU ? "تفصیل دیکھیں" : "View Full Guide"}  →',
                                        style: TextStyle(color: bc, fontSize: 11, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(Icons.chevron_right_rounded, color: bc, size: 26),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                }),

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
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
                    child: Container(width: 1, color: isDark ? Colors.white10 : Colors.grey[300]),
                  ),
                if (!isFirst)
                  Positioned(
                    top: -25, bottom: 25,
                    child: Container(width: 1, color: isDark ? Colors.white10 : Colors.grey[300]),
                  ),
                Container(width: 12, height: 1, color: isDark ? Colors.white10 : Colors.grey[300]),
              ],
            ),
          ),
          
          Text(
            label,
            style: TextStyle(fontSize: R.fs(context, 15), fontWeight: FontWeight.w500, color: isDark ? Colors.white70 : Colors.black87),
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

  Widget _buildSimpleInfoRow(BuildContext context, String label, String value) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: isDark ? Colors.white60 : Colors.black54, fontSize: 13, fontWeight: FontWeight.w500)),
        Text(value, style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 13, fontWeight: FontWeight.bold)),
      ],
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
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: themeColor, width: 2),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildWasteTypeHeading(ClassificationResult result) {
    bool isRecyclable = result.recyclable;
    bool isFood = widget.mode == "food";

    bool isWaste = result.category == "food_waste";

    Color badgeColor = isFood 
        ? (isWaste ? const Color(0xFFE53935) : const Color(0xFF4CAF50)) // Red for Waste, Green for Fresh
        : (isRecyclable ? const Color(0xFF4CAF50) : const Color(0xFFE53935)); // Green vs Red

    String label = isFood
        ? (isWaste ? "FOOD WASTE" : "EDIBLE / FRESH")
        : (isRecyclable ? "RECYCLABLE" : "NON-RECYCLABLE");

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(40),
        border: Border.all(color: badgeColor.withOpacity(0.5), width: 2),
        boxShadow: [
          BoxShadow(
            color: badgeColor.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isFood 
              ? (isWaste ? Icons.delete_outline : Icons.check_circle_outline)
              : (isRecyclable ? Icons.recycling : Icons.delete_outline),
            color: badgeColor,
            size: 20,
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              color: badgeColor,
              fontWeight: FontWeight.w900,
              fontSize: 16,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }

}
