import 'dart:io';
import 'package:flutter/material.dart';
import '../utils/responsive.dart';
import '../utils/disposal_data.dart';
import '../services/api_service.dart';
import '../services/translation_service.dart';
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
  String? _classificationId;   // MongoDB _id of the saved record

  // Guidance card state
  DisposalGuidance? _guidance;
  bool _feedbackSubmitted = false;
  bool _submittingFeedback = false;
  String? _feedbackCategory;     // selected corrected category
  String? _feedbackError;
  bool _feedbackPanelOpen = false;

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

      final result = await ApiService.instance.classifyImage(widget.imageFile!, mode: widget.mode);
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
                              style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.black54, fontSize: 11, letterSpacing: 1.0),
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
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
                              ],
                              border: Border.all(color: Colors.grey.withOpacity(0.1)),
                            ),
                            child: Column(
                              children: [
                                _buildSimpleInfoRow("Class", det.label),
                                const Divider(height: 16),
                                _buildSimpleInfoRow("Material", det.material),
                                const Divider(height: 16),
                                _buildSimpleInfoRow("Confidence", "${(det.confidence * 100).toStringAsFixed(0)}%"),
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
                        _buildInfoRow(context, "Class", _result!.category.toUpperCase(), true, false),
                        _buildInfoRow(context, "Material", _result!.material, false, false),
                        _buildInfoRow(context, "Confidence", "${(_result!.confidence * 100).toStringAsFixed(0)}%", false, true),
                      ],
                    ),
                  ),
                ],

                SizedBox(height: sp * 3),

                // ── Disposal Guidance Card
                if (_guidance != null) _buildGuidanceCard(_guidance!, sp),

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

  Widget _buildSimpleInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.black54, fontSize: 13, fontWeight: FontWeight.w500)),
        Text(value, style: const TextStyle(color: Colors.black, fontSize: 13, fontWeight: FontWeight.bold)),
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

  // ── Disposal Guidance Card ─────────────────────────────────────────────────

  static const _kCategories = [
    'plastic', 'glass', 'metal', 'e-waste', 'textile',
    'wood', 'food_waste', 'not_food_waste',
  ];

  Color _hexColor(String hex) {
    final h = hex.replaceAll('#', '');
    return Color(int.parse('FF$h', radix: 16));
  }

  Future<void> _submitFeedback() async {
    if (_feedbackCategory == null) return;
    setState(() { _submittingFeedback = true; _feedbackError = null; });
    try {
      final data = await ApiService.instance.submitFeedback(
        classificationId:  _classificationId ?? '',
        correctedCategory: _feedbackCategory!,
      );
      // Parse the live guidance returned by the server
      final rawGuidance = data['updated_guidance'];
      DisposalGuidance? live;
      if (rawGuidance is Map<String, dynamic>) {
        live = guidanceFromJson(rawGuidance);
      }
      setState(() {
        _feedbackSubmitted  = true;
        _submittingFeedback = false;
        _feedbackPanelOpen  = false;
        if (live != null) _guidance = live;   // <-- live card update
      });
    } catch (e) {
      setState(() {
        _feedbackError      = e.toString().replaceFirst('Exception: ', '');
        _submittingFeedback = false;
      });
    }
  }

  Widget _buildGuidanceCard(DisposalGuidance g, double sp) {
    final binHex   = g.binColorHex;
    final binColor = _hexColor(binHex);
    final steps    = TranslationService.isUrdu ? g.stepsUr : g.steps;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: binColor.withOpacity(0.3), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: binColor.withOpacity(0.12),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Row(
              children: [
                Text(g.icon, style: const TextStyle(fontSize: 28)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'DISPOSAL GUIDANCE',
                        style: TextStyle(
                          color: binColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: binColor.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${g.binColor} Bin',
                          style: TextStyle(color: binColor, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
                // Language toggle
                GestureDetector(
                  onTap: () async {
                    await TranslationService.instance.toggleLanguage();
                    setState(() {});
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: TranslationService.isUrdu ? binColor : Colors.white12,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      TranslationService.isUrdu ? 'اردو' : 'EN',
                      style: TextStyle(
                        color: TranslationService.isUrdu ? Colors.white : Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Short tip
                Text(
                  TranslationService.isUrdu ? g.tipUr : g.tipEn,
                  textDirection: TranslationService.isUrdu ? TextDirection.rtl : TextDirection.ltr,
                  style: const TextStyle(color: Colors.white70, fontSize: 14, fontStyle: FontStyle.italic),
                ),
                const SizedBox(height: 20),

                // ── Steps ─────────────────────────────────────
                Text('Step-by-Step Guide',
                  style: TextStyle(color: binColor, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.0)),
                const SizedBox(height: 12),
                ...steps.asMap().entries.map((e) => _buildStep(e.key + 1, e.value, binColor, TranslationService.isUrdu)),

                if (g.doList.isNotEmpty || g.dontList.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  // ── Do / Don't ────────────────────────────────
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (g.doList.isNotEmpty)
                        Expanded(child: _buildList('✅ Do', g.doList, const Color(0xFF4CAF50))),
                      if (g.doList.isNotEmpty && g.dontList.isNotEmpty)
                        const SizedBox(width: 12),
                      if (g.dontList.isNotEmpty)
                        Expanded(child: _buildList('❌ Don\'t', g.dontList, const Color(0xFFF44336))),
                    ],
                  ),
                ],

                const SizedBox(height: 20),
                // ── Feedback row ──────────────────────────────
                _buildFeedbackRow(binColor),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep(int num, String text, Color accent, bool isUrdu) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        textDirection: isUrdu ? TextDirection.rtl : TextDirection.ltr,
        children: [
          Container(
            width: 24, height: 24,
            margin: const EdgeInsets.only(top: 1),
            decoration: BoxDecoration(color: accent.withOpacity(0.15), shape: BoxShape.circle,
              border: Border.all(color: accent, width: 1.5)),
            child: Center(
              child: Text('$num', style: TextStyle(color: accent, fontSize: 11, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text,
              textDirection: isUrdu ? TextDirection.rtl : TextDirection.ltr,
              style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.5)),
          ),
        ],
      ),
    );
  }

  Widget _buildList(String title, List<String> items, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 0.8)),
        const SizedBox(height: 6),
        ...items.map((item) => Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.circle, size: 5, color: color.withOpacity(0.7)),
              const SizedBox(width: 6),
              Expanded(child: Text(item, style: const TextStyle(color: Colors.white54, fontSize: 12, height: 1.4))),
            ],
          ),
        )),
      ],
    );
  }

  Widget _buildFeedbackRow(Color accent) {
    if (_feedbackSubmitted) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF4CAF50).withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF4CAF50).withOpacity(0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.check_circle, color: Color(0xFF4CAF50), size: 16),
            const SizedBox(width: 8),
            const Expanded(child: Text('Thank you! Your feedback helps improve our AI.',
              style: TextStyle(color: Color(0xFF4CAF50), fontSize: 12))),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('WAS THIS CORRECT?',
          style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.2)),
        const SizedBox(height: 8),
        Row(
          children: [
            // Thumbs up
            GestureDetector(
              onTap: () { _submitFeedback(); },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF4CAF50).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF4CAF50).withOpacity(0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.thumb_up_outlined, color: Color(0xFF4CAF50), size: 16),
                    SizedBox(width: 6),
                    Text('Correct', style: TextStyle(color: Color(0xFF4CAF50), fontSize: 13, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
            // Thumbs down → opens correction panel
            GestureDetector(
              onTap: () => setState(() => _feedbackPanelOpen = !_feedbackPanelOpen),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF44336).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFF44336).withOpacity(0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.thumb_down_outlined, color: Color(0xFFF44336), size: 16),
                    SizedBox(width: 6),
                    Text('Wrong', style: TextStyle(color: Color(0xFFF44336), fontSize: 13, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
          ],
        ),

        // Correction dropdown panel
        if (_feedbackPanelOpen) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: accent.withOpacity(0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Select the correct category:',
                  style: TextStyle(color: Colors.white60, fontSize: 12)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _feedbackCategory,
                  dropdownColor: const Color(0xFF1A1A2E),
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white10,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  hint: const Text('Choose category…', style: TextStyle(color: Colors.white38, fontSize: 13)),
                  items: _kCategories.map((c) => DropdownMenuItem(
                    value: c,
                    child: Text(c.replaceAll('_', ' ').toUpperCase()),
                  )).toList(),
                  onChanged: (v) => setState(() => _feedbackCategory = v),
                ),
                if (_feedbackError != null) ...[
                  const SizedBox(height: 6),
                  Text(_feedbackError!, style: const TextStyle(color: Color(0xFFF44336), fontSize: 12)),
                ],
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _feedbackCategory == null || _submittingFeedback ? null : _submitFeedback,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: _submittingFeedback
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Submit Correction', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
