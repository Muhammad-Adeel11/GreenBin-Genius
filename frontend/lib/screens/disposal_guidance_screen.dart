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

class _DisposalGuidanceScreenState extends State<DisposalGuidanceScreen> with SingleTickerProviderStateMixin {
  late DisposalGuidance _guidance;
  bool _feedbackSubmitted = false;
  bool _submittingFeedback = false;
  String? _feedbackCategory;
  String? _feedbackError;
  bool _feedbackPanelOpen = false;

  // Interactive step checklist
  final Set<int> _completedSteps = {};
  
  // Tab controller for Guide vs Dos/Don'ts
  late TabController _tabController;

  static const _kCategories = [
    'plastic', 'glass', 'metal', 'e-waste', 'textile',
    'wood', 'food_waste', 'not_food_waste',
  ];

  @override
  void initState() {
    super.initState();
    _guidance = widget.guidance;
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Color _hexColor(String hex) {
    final h = hex.replaceAll('#', '');
    return Color(int.parse('FF$h', radix: 16));
  }

  Future<void> _submitFeedback() async {
    if (_feedbackCategory == null) return;
    setState(() {
      _submittingFeedback = true;
      _feedbackError = null;
    });
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
        if (live != null) {
          _guidance = live;
          _completedSteps.clear();
        }
      });
    } catch (e) {
      setState(() {
        _feedbackError      = e.toString().replaceFirst('Exception: ', '');
        _submittingFeedback = false;
      });
    }
  }

  // Generate a beautiful premium gradient based on the bin color
  LinearGradient _getBinGradient(String binColor) {
    switch (binColor.toLowerCase()) {
      case 'blue':
        return const LinearGradient(
          colors: [Color(0xFF1E88E5), Color(0xFF1565C0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'green':
        return const LinearGradient(
          colors: [Color(0xFF43A047), Color(0xFF2E7D32)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'yellow':
        return const LinearGradient(
          colors: [Color(0xFFFFB300), Color(0xFFF57F17)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'red':
        return const LinearGradient(
          colors: [Color(0xFFE53935), Color(0xFFC62828)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'purple':
        return const LinearGradient(
          colors: [Color(0xFF8E24AA), Color(0xFF6A1B9A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'brown':
        return const LinearGradient(
          colors: [Color(0xFF6D4C41), Color(0xFF4E342E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'black':
        return const LinearGradient(
          colors: [Color(0xFF424242), Color(0xFF212121)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'orange':
        return const LinearGradient(
          colors: [Color(0xFFFB8C00), Color(0xFFEF6C00)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      default:
        return const LinearGradient(
          colors: [Color(0xFF757575), Color(0xFF424242)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
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
        final isDark = Theme.of(context).brightness == Brightness.dark;

        return Scaffold(
          backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF8FAFC),
          appBar: AppBar(
            backgroundColor: binColor,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              isUrdu ? 'ڈسپوزل گائیڈ' : 'Disposal Guide',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
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
                    color: Colors.white.withValues(alpha: 0.25),
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
          body: Column(
            children: [
              // ── Top Gradient Hero Card ──────────────────────────────────
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: _getBinGradient(_guidance.binColor),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(32),
                    bottomRight: Radius.circular(32),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: binColor.withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
                child: Column(
                  children: [
                    Row(
                      textDirection: textDir,
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 2),
                          ),
                          child: Center(
                            child: Text(
                              _guidance.icon,
                              style: const TextStyle(fontSize: 32),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: crossStart,
                            children: [
                              Text(
                                _guidance.category.replaceAll('_', ' ').toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.25),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '${_guidance.binColor} Bin',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Quick Lightbulb Tip Banner
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.1), width: 1),
                      ),
                      child: Row(
                        textDirection: textDir,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.lightbulb_outline_rounded, color: Color(0xFFFFD54F), size: 22),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              isUrdu ? _guidance.tipUr : _guidance.tipEn,
                              textDirection: textDir,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13.5,
                                fontWeight: FontWeight.w500,
                                height: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // ── Tab Bar for Guide & Dos/Don'ts ────────────────────────
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: TabBar(
                  controller: _tabController,
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicator: BoxDecoration(
                    color: binColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  labelColor: Colors.white,
                  unselectedLabelColor: isDark ? Colors.white60 : Colors.black54,
                  labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  padding: const EdgeInsets.all(4),
                  tabs: [
                    Tab(text: isUrdu ? 'مرحلہ وار گائیڈ' : 'Step Guide'),
                    Tab(text: isUrdu ? 'احتیاطی تدابیر' : "Do's & Don'ts"),
                  ],
                ),
              ),

              // ── Tab View Content ──────────────────────────────────────
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // Tab 1: Interactive Checklist Step Guide
                    ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: steps.length + 1, // +1 for the feedback card at the bottom
                      itemBuilder: (context, index) {
                        if (index == steps.length) {
                          // Feedback card
                          return Padding(
                            padding: const EdgeInsets.only(top: 8, bottom: 24),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.03),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: _buildFeedbackSection(context, binColor, isUrdu),
                            ),
                          );
                        }
                        
                        final stepNum = index + 1;
                        final stepText = steps[index];
                        final isCompleted = _completedSteps.contains(stepNum);

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                if (isCompleted) {
                                  _completedSteps.remove(stepNum);
                                } else {
                                  _completedSteps.add(stepNum);
                                }
                              });
                            },
                            borderRadius: BorderRadius.circular(16),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 250),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: isCompleted
                                    ? binColor.withValues(alpha: 0.08)
                                    : (isDark ? const Color(0xFF1E1E1E) : Colors.white),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isCompleted ? binColor : Colors.transparent,
                                  width: 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.02),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                textDirection: textDir,
                                children: [
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: isCompleted ? binColor : binColor.withValues(alpha: 0.12),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: isCompleted
                                          ? const Icon(Icons.check, color: Colors.white, size: 18)
                                          : Text(
                                              '$stepNum',
                                              style: TextStyle(
                                                color: binColor,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 13,
                                              ),
                                            ),
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Text(
                                      stepText,
                                      textDirection: textDir,
                                      style: TextStyle(
                                        color: isCompleted
                                            ? (isDark ? Colors.white60 : Colors.black54)
                                            : (isDark ? Colors.white : Colors.black87),
                                        fontSize: 14,
                                        height: 1.45,
                                        decoration: isCompleted ? TextDecoration.lineThrough : null,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),

                    // Tab 2: Do's & Don'ts Layout
                    SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      child: Column(
                        children: [
                          if (_guidance.doList.isNotEmpty) ...[
                            _buildDoDontCard(
                              context: context,
                              title: isUrdu ? 'کریں (Dos)' : 'Things to Do',
                              items: _guidance.doList,
                              isDo: true,
                              isDark: isDark,
                            ),
                            const SizedBox(height: 16),
                          ],
                          if (_guidance.dontList.isNotEmpty) ...[
                            _buildDoDontCard(
                              context: context,
                              title: isUrdu ? 'نہ کریں (Don\'ts)' : 'Things to Avoid',
                              items: _guidance.dontList,
                              isDo: false,
                              isDark: isDark,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDoDontCard({
    required BuildContext context,
    required String title,
    required List<String> items,
    required bool isDo,
    required bool isDark,
  }) {
    final themeColor = isDo ? const Color(0xFF2E7D32) : const Color(0xFFC62828);
    final cardBg = isDo
        ? (isDark ? const Color(0xFF1B2E1C) : const Color(0xFFE8F5E9))
        : (isDark ? const Color(0xFF3E1F1F) : const Color(0xFFFFEBEE));

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: themeColor.withValues(alpha: 0.2), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: themeColor.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isDo ? Icons.check_circle_rounded : Icons.cancel_rounded,
                color: themeColor,
                size: 24,
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: TextStyle(
                  color: themeColor,
                  fontWeight: FontWeight.w900,
                  fontSize: 15,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, thickness: 1),
          ),
          ...items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isDo ? '•' : '×',
                      style: TextStyle(
                        color: themeColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        item,
                        style: TextStyle(
                          color: isDark ? Colors.white.withValues(alpha: 0.87) : Colors.black.withValues(alpha: 0.87),
                          fontSize: 13,
                          height: 1.4,
                        ),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_feedbackSubmitted) {
      return Container(
        padding: EdgeInsets.symmetric(horizontal: sp, vertical: sp * 0.8),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1B2E1C) : const Color(0xFFE8F5E9),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF4CAF50).withValues(alpha: 0.4)),
        ),
        child: Row(
          textDirection: isUrdu ? TextDirection.rtl : TextDirection.ltr,
          children: [
            const Icon(Icons.check_circle_rounded, color: Color(0xFF4CAF50), size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                isUrdu
                    ? 'شکریہ! آپ کے فیڈ بیک سے ہمیں مزید بہتر بنانے میں مدد ملتی ہے۔'
                    : 'Thank you! Your feedback helps improve our AI.',
                style: const TextStyle(color: Color(0xFF388E3C), fontSize: 13, fontWeight: FontWeight.w600),
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
                color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.rate_review_outlined, color: Color(0xFF007AFF), size: 16),
            ),
            const SizedBox(width: 8),
            Text(
              isUrdu ? 'کیا یہ معلومات درست تھیں؟' : 'WAS THIS INFORMATION CORRECT?',
              style: TextStyle(
                color: isDark ? Colors.white60 : Colors.black54,
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
                onTap: () {
                  setState(() {
                    _feedbackSubmitted = true;
                  });
                  ApiService.instance.submitFeedback(
                    classificationId: widget.classificationId ?? '',
                    correctedCategory: _guidance.category,
                  ).catchError((_) => <String, dynamic>{});
                },
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: sp * 0.9),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1B2E1C) : const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF4CAF50).withValues(alpha: 0.5)),
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
                    color: isDark ? const Color(0xFF3E1F1F) : const Color(0xFFFFEBEE),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE53935).withValues(alpha: 0.5)),
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
            value: _feedbackCategory,
            dropdownColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 13),
            decoration: InputDecoration(
              filled: true,
              fillColor: isDark ? Colors.white10 : const Color(0xFFF1F5F9),
              hintText: isUrdu ? 'درست زمرہ چنیں…' : 'Choose correct category…',
              hintStyle: TextStyle(color: isDark ? Colors.white38 : Colors.black38, fontSize: 13),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: accent.withValues(alpha: 0.3)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: accent.withValues(alpha: 0.3)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: accent, width: 1.5),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
            items: _kCategories.map((c) => DropdownMenuItem(
              value: c,
              child: Text(c.replaceAll('_', ' ').toUpperCase(), style: TextStyle(color: isDark ? Colors.white : Colors.black87)),
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
                disabledBackgroundColor: isDark ? Colors.white12 : Colors.grey[200],
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
