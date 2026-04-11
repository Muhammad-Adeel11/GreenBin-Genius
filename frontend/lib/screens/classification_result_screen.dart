import 'dart:io';
import 'package:flutter/material.dart';
import '../utils/responsive.dart';
import '../services/api_service.dart';

class ClassificationResultScreen extends StatefulWidget {
  final File imageFile;

  const ClassificationResultScreen({super.key, required this.imageFile});

  @override
  State<ClassificationResultScreen> createState() =>
      _ClassificationResultScreenState();
}

class _ClassificationResultScreenState
    extends State<ClassificationResultScreen> {
  bool _isAnalyzing = true;
  ClassificationResult? _result;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _runClassification();
  }

  Future<void> _runClassification() async {
    try {
      final result = await ApiService.instance.classifyImage(widget.imageFile);
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
              // ── Captured Image
              Container(
                height: R.h(context, 30),
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.file(widget.imageFile, fit: BoxFit.cover),
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

                // Classification tags
                _buildTagRow('Category', _result!.category, isFirst: true),
                _buildTagRow('Object', _result!.objectDetected),
                _buildTagRow('Material', _result!.material),
                _buildTagRow(
                  'Confidence',
                  _result!.confidencePercent,
                  isLast: true,
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

                // Action buttons
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // TODO: Navigate to Bin Locator with result category
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
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.black54,
                      side: const BorderSide(color: Colors.grey),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30)),
                    ),
                    child: Text(
                      'SCAN ANOTHER ITEM',
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

  Widget _buildTagRow(String label, String value,
      {bool isFirst = false, bool isLast = false}) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 40,
            child: Column(
              children: [
                Expanded(
                  child: Container(
                    width: 1,
                    color: isFirst ? Colors.transparent : Colors.grey[300],
                    margin: const EdgeInsets.only(left: 20),
                  ),
                ),
                Row(children: [
                  const SizedBox(width: 20),
                  Container(width: 12, height: 1, color: Colors.grey[300]),
                ]),
                Expanded(
                  child: Container(
                    width: 1,
                    color: isLast ? Colors.transparent : Colors.grey[300],
                    margin: const EdgeInsets.only(left: 20),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                children: [
                  SizedBox(
                    width: 90,
                    child: Text(
                      label,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Colors.black87),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2196F3),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      value,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
