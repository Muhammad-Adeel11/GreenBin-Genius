import 'package:flutter/material.dart';
import '../utils/responsive.dart';
import '../utils/disposal_data.dart';
import '../services/translation_service.dart';
import '../services/api_service.dart';

class DisposalGuidanceScreen extends StatefulWidget {
  final DisposalGuidance guidance;
  final String? classificationId;

  const DisposalGuidanceScreen({
    super.key,
    required this.guidance,
    this.classificationId,
  });

  @override
  State<DisposalGuidanceScreen> createState() => _DisposalGuidanceScreenState();
}

class _DisposalGuidanceScreenState extends State<DisposalGuidanceScreen> {
  late DisposalGuidance _guidance;
  bool _feedbackSubmitted = false;
  bool _submittingFeedback = false;
  String? _feedbackCategory;
  String? _feedbackError;
  bool _feedbackPanelOpen = false;

  static const _kCategories = [
    'plastic', 'glass', 'metal', 'e-waste', 'textile',
    'wood', 'food_waste', 'not_food_waste',
  ];

  @override
  void initState() {
    super.initState();
    _guidance = widget.guidance;
  }

  Color _hexColor(String hex) {
    final h = hex.replaceAll('#', '');
    return Color(int.parse('FF$h', radix: 16));
  }

  Future<void> _submitFeedback() async {
    if (_feedbackCategory == null) return;
    setState(() { _submittingFeedback = true; _feedbackError = null; });
    try {
      final data = await ApiService.instance.submitFeedback(
        classificationId: widget.classificationId ?? '',
        correctedCategory: _feedbackCategory!,
      );
      final rawGuidance = data['updated_guidance'];
      DisposalGuidance? live;
      if (rawGuidance is Map<String, dynamic>) {
        live = guidanceFromJson(rawGuidance);
      }
      setState(() {
        _feedbackSubmitted  = true;
        _submittingFeedback = false;
        _feedbackPanelOpen  = false;
        if (live != null) _guidance = live;
      });
    } catch (e) {
      setState(() {
        _feedbackError      = e.toString().replaceFirst('Exception: ', '');
        _submittingFeedback = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: TranslationService.instance.languageNotifier,
      builder: (context, lang, _) {
        final isUrdu   = TranslationService.isUrdu;
        final binColor = _hexColor(_guidance.binColorHex);
        final steps    = isUrdu ? _guidance.stepsUr : _guidance.steps;
        final textDir  = isUrdu ? TextDirection.rtl : TextDirection.ltr;
        final crossStart = isUrdu ? CrossAxisAlignment.end : CrossAxisAlignment.start;

        return Scaffold(
          backgroundColor: const Color(0xFFF5F8FF),
          appBar: AppBar(
            backgroundColor: const Color(0xFF2196F3),
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_guidance.icon, style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 8),
                Text(
                  isUrdu ? 'ڈسپوزل گائیڈ' : 'Disposal Guide',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            centerTitle: true,
            actions: [
              GestureDetector(
                onTap: () async {
                  await TranslationService.instance.toggleLanguage();
                  setState(() {});
                },
                child: Container(
                  margin: const EdgeInsets.only(right: 14),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isUrdu ? 'اردو' : 'EN',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: R.pagePadding(context).add(EdgeInsets.symmetric(vertical: R.sp(context) * 1.5)),
            child: Column(
              crossAxisAlignment: crossStart,
              children: [
                // ── Bin Hero Banner ──────────────────────────────────
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(R.sp(context) * 1.5),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: binColor.withOpacity(0.25), width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: binColor.withOpacity(0.10),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    textDirection: textDir,
                    children: [
                      Container(
                        width: 60, height: 60,
                        decoration: BoxDecoration(
                          color: binColor.withOpacity(0.12),
                          shape: BoxShape.circle,
                          border: Border.all(color: binColor.withOpacity(0.4), width: 2),
                        ),
                        child: Center(
                          child: Text(_guidance.icon, style: const TextStyle(fontSize: 28)),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: crossStart,
                          children: [
                            Text(
                              isUrdu ? 'ڈسپوزل گائیڈنس' : 'DISPOSAL GUIDANCE',
                              style: TextStyle(
                                color: binColor,
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _guidance.category.replaceAll('_', ' ').toUpperCase(),
                              style: const TextStyle(
                                color: Colors.black87,
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: binColor.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${_guidance.binColor} Bin',
                                style: TextStyle(
                                  color: binColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: R.sp(context) * 1.5),

                // ── Quick Tip ─────────────────────────────────────────
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(R.sp(context) * 1.5),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    textDirection: textDir,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF3E0),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.lightbulb_outline_rounded, color: Color(0xFFFF9800), size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          isUrdu ? _guidance.tipUr : _guidance.tipEn,
                          textDirection: textDir,
                          style: const TextStyle(
                            color: Colors.black87,
                            fontSize: 14,
                            fontStyle: FontStyle.italic,
                            height: 1.55,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: R.sp(context) * 2),

                // ── Section Label ─────────────────────────────────────
                Row(
                  textDirection: textDir,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: binColor.withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.format_list_numbered_rounded, color: binColor, size: 16),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isUrdu ? 'مرحلہ وار ہدایات' : 'STEP-BY-STEP GUIDE',
                      style: TextStyle(
                        color: binColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),

                SizedBox(height: R.sp(context)),

                // ── Steps ─────────────────────────────────────────────
                ...steps.asMap().entries.map((e) => _buildStep(context, e.key + 1, e.value, binColor, isUrdu)),

                SizedBox(height: R.sp(context) * 1.5),

                // ── Do / Don't ────────────────────────────────────────
                if (_guidance.doList.isNotEmpty || _guidance.dontList.isNotEmpty)
                  Row(
                    textDirection: textDir,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_guidance.doList.isNotEmpty)
                        Expanded(child: _buildList(context, '✅  Do', _guidance.doList, const Color(0xFF4CAF50), const Color(0xFFE8F5E9))),
                      if (_guidance.doList.isNotEmpty && _guidance.dontList.isNotEmpty)
                        const SizedBox(width: 12),
                      if (_guidance.dontList.isNotEmpty)
                        Expanded(child: _buildList(context, "❌  Don't", _guidance.dontList, const Color(0xFFE53935), const Color(0xFFFFEBEE))),
                    ],
                  ),

                SizedBox(height: R.sp(context) * 2),

                // ── Feedback Section ───────────────────────────────────
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(R.sp(context) * 1.5),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: _buildFeedbackSection(context, binColor, isUrdu),
                ),

                SizedBox(height: R.sp(context) * 2),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStep(BuildContext context, int num, String text, Color accent, bool isUrdu) {
    final sp = R.sp(context);
    return Padding(
      padding: EdgeInsets.only(bottom: sp * 1.2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        textDirection: isUrdu ? TextDirection.rtl : TextDirection.ltr,
        children: [
          Container(
            width: 30, height: 30,
            decoration: BoxDecoration(
              color: accent.withOpacity(0.12),
              shape: BoxShape.circle,
              border: Border.all(color: accent, width: 1.5),
            ),
            child: Center(
              child: Text(
                '$num',
                style: TextStyle(color: accent, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: sp, vertical: sp * 0.9),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                text,
                textDirection: isUrdu ? TextDirection.rtl : TextDirection.ltr,
                style: const TextStyle(color: Colors.black87, fontSize: 13.5, height: 1.55),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList(BuildContext context, String title, List<String> items, Color color, Color bgColor) {
    final sp = R.sp(context);
    return Container(
      padding: EdgeInsets.all(sp * 1.2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
            ),
          ),
          SizedBox(height: sp * 0.6),
          ...items.map((item) => Padding(
            padding: EdgeInsets.only(bottom: sp * 0.5),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.circle, size: 5, color: color),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    item,
                    style: TextStyle(color: color.withOpacity(0.8), fontSize: 12, height: 1.4),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildFeedbackSection(BuildContext context, Color accent, bool isUrdu) {
    final sp = R.sp(context);
    if (_feedbackSubmitted) {
      return Container(
        padding: EdgeInsets.symmetric(horizontal: sp, vertical: sp * 0.8),
        decoration: BoxDecoration(
          color: const Color(0xFFE8F5E9),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF4CAF50).withOpacity(0.4)),
        ),
        child: Row(
          textDirection: isUrdu ? TextDirection.rtl : TextDirection.ltr,
          children: [
            const Icon(Icons.check_circle_rounded, color: Color(0xFF4CAF50), size: 20),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Thank you! Your feedback helps improve our AI.',
                style: TextStyle(color: Color(0xFF388E3C), fontSize: 13, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          textDirection: isUrdu ? TextDirection.rtl : TextDirection.ltr,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFFE3F2FD),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.rate_review_outlined, color: Color(0xFF2196F3), size: 16),
            ),
            const SizedBox(width: 8),
            Text(
              isUrdu ? 'کیا یہ درست تھا؟' : 'WAS THIS CORRECT?',
              style: const TextStyle(
                color: Colors.black54,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.0,
              ),
            ),
          ],
        ),
        SizedBox(height: sp),
        Row(
          textDirection: isUrdu ? TextDirection.rtl : TextDirection.ltr,
          children: [
            Expanded(
              child: GestureDetector(
                onTap: _submitFeedback,
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: sp * 0.9),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF4CAF50).withOpacity(0.5)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.thumb_up_outlined, color: Color(0xFF4CAF50), size: 18),
                      const SizedBox(width: 6),
                      Text(
                        isUrdu ? 'درست' : 'Correct',
                        style: const TextStyle(color: Color(0xFF388E3C), fontSize: 13, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _feedbackPanelOpen = !_feedbackPanelOpen),
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: sp * 0.9),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFEBEE),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE53935).withOpacity(0.5)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.thumb_down_outlined, color: Color(0xFFE53935), size: 18),
                      const SizedBox(width: 6),
                      Text(
                        isUrdu ? 'غلط' : 'Wrong',
                        style: const TextStyle(color: Color(0xFFC62828), fontSize: 13, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),

        if (_feedbackPanelOpen) ...[
          SizedBox(height: sp),
          DropdownButtonFormField<String>(
            initialValue: _feedbackCategory,
            dropdownColor: Colors.white,
            style: const TextStyle(color: Colors.black87, fontSize: 13),
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFFF5F8FF),
              hintText: isUrdu ? 'درست زمرہ چنیں…' : 'Choose correct category…',
              hintStyle: const TextStyle(color: Colors.black38, fontSize: 13),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: accent.withOpacity(0.3)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: accent.withOpacity(0.3)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: accent, width: 1.5),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
            items: _kCategories.map((c) => DropdownMenuItem(
              value: c,
              child: Text(c.replaceAll('_', ' ').toUpperCase()),
            )).toList(),
            onChanged: (v) => setState(() => _feedbackCategory = v),
          ),
          if (_feedbackError != null) ...[
            SizedBox(height: sp * 0.5),
            Text(_feedbackError!, style: const TextStyle(color: Color(0xFFE53935), fontSize: 12)),
          ],
          SizedBox(height: sp),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _feedbackCategory == null || _submittingFeedback ? null : _submitFeedback,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2196F3),
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey[200],
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: EdgeInsets.symmetric(vertical: sp),
                elevation: 0,
              ),
              child: _submittingFeedback
                  ? const SizedBox(
                      width: 18, height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Text(
                      isUrdu ? 'تصحیح جمع کروائیں' : 'Submit Correction',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
            ),
          ),
        ],
      ],
    );
  }
}
