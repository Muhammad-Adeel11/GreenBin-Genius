import 'package:flutter/material.dart';
import '../utils/responsive.dart';
import '../services/translation_service.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: TranslationService.instance.languageNotifier,
      builder: (context, lang, _) {
        final isUrdu = TranslationService.isUrdu;
        final textAlign = isUrdu ? TextAlign.right : TextAlign.left;
        final crossAxis = isUrdu ? CrossAxisAlignment.end : CrossAxisAlignment.start;

        final topics = [
          _HelpTopic(
            icon: Icons.camera_alt_outlined,
            iconColor: const Color(0xFF2196F3),
            bgColor: const Color(0xFFE3F2FD),
            title: TranslationService.translate('help_scan_title'),
            body: TranslationService.translate('help_scan_body'),
          ),
          _HelpTopic(
            icon: Icons.recycling_rounded,
            iconColor: const Color(0xFF4CAF50),
            bgColor: const Color(0xFFE8F5E9),
            title: TranslationService.translate('help_disposal_title'),
            body: TranslationService.translate('help_disposal_body'),
          ),
          _HelpTopic(
            icon: Icons.emoji_events_outlined,
            iconColor: const Color(0xFFFF9800),
            bgColor: const Color(0xFFFFF3E0),
            title: TranslationService.translate('help_leaderboard_title'),
            body: TranslationService.translate('help_leaderboard_body'),
          ),
          _HelpTopic(
            icon: Icons.map_outlined,
            iconColor: const Color(0xFF9C27B0),
            bgColor: const Color(0xFFF3E5F5),
            title: TranslationService.translate('help_map_title'),
            body: TranslationService.translate('help_map_body'),
          ),
        ];

        return Scaffold(
          backgroundColor: const Color(0xFFF5F8FF),
          appBar: AppBar(
            backgroundColor: const Color(0xFF2196F3),
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              TranslationService.translate('help_title'),
              style: TextStyle(
                color: Colors.white,
                fontSize: R.fs(context, 18),
                fontWeight: FontWeight.bold,
              ),
            ),
            centerTitle: true,
          ),
          body: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: crossAxis,
              children: [
                // Hero header
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.fromLTRB(
                    R.w(context, 5),
                    R.sp(context) * 2,
                    R.w(context, 5),
                    R.sp(context) * 3,
                  ),
                  decoration: const BoxDecoration(
                    color: Color(0xFF2196F3),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(32),
                      bottomRight: Radius.circular(32),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: crossAxis,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.support_agent_rounded, color: Colors.white, size: 36),
                      ),
                      SizedBox(height: R.sp(context)),
                      Text(
                        TranslationService.translate('help_subtitle'),
                        textAlign: textAlign,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: R.fs(context, 16),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

                // Topics list
                Padding(
                  padding: R.pagePadding(context).add(EdgeInsets.only(top: R.sp(context) * 2)),
                  child: Column(
                    crossAxisAlignment: crossAxis,
                    children: [
                      ...topics.map((topic) => _HelpExpansionTile(
                            topic: topic,
                            textAlign: textAlign,
                            crossAxis: crossAxis,
                          )),

                      SizedBox(height: R.sp(context)),

                      // Contact card
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(R.sp(context) * 2),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF1565C0), Color(0xFF0D47A1)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF1565C0).withOpacity(0.3),
                              blurRadius: 15,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: crossAxis,
                          children: [
                            Row(
                              mainAxisAlignment: isUrdu
                                  ? MainAxisAlignment.end
                                  : MainAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.headset_mic_rounded,
                                      color: Colors.white, size: 22),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  TranslationService.translate('help_contact_title'),
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: R.fs(context, 16),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: R.sp(context)),
                            Text(
                              TranslationService.translate('help_contact_body'),
                              textAlign: textAlign,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.85),
                                fontSize: R.fs(context, 13.5),
                                height: 1.6,
                              ),
                            ),
                            SizedBox(height: R.sp(context) * 1.5),
                            // Email button
                            GestureDetector(
                              onTap: () {
                                // Could launch mailto: url if url_launcher is available
                              },
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: R.w(context, 6),
                                  vertical: R.sp(context),
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.email_rounded,
                                        color: Color(0xFF1565C0), size: 18),
                                    const SizedBox(width: 8),
                                    Text(
                                      'support@greenbin.ai',
                                      style: TextStyle(
                                        color: const Color(0xFF1565C0),
                                        fontSize: R.fs(context, 13),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: R.sp(context) * 2),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _HelpTopic {
  final IconData icon;
  final Color iconColor;
  final Color bgColor;
  final String title;
  final String body;

  const _HelpTopic({
    required this.icon,
    required this.iconColor,
    required this.bgColor,
    required this.title,
    required this.body,
  });
}

class _HelpExpansionTile extends StatefulWidget {
  final _HelpTopic topic;
  final TextAlign textAlign;
  final CrossAxisAlignment crossAxis;

  const _HelpExpansionTile({
    required this.topic,
    required this.textAlign,
    required this.crossAxis,
  });

  @override
  State<_HelpExpansionTile> createState() => _HelpExpansionTileState();
}

class _HelpExpansionTileState extends State<_HelpExpansionTile>
    with SingleTickerProviderStateMixin {
  bool _expanded = false;
  late AnimationController _controller;
  late Animation<double> _heightAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _heightAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _expanded = !_expanded);
    if (_expanded) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final sp = R.sp(context);
    return GestureDetector(
      onTap: _toggle,
      child: Container(
        width: double.infinity,
        margin: EdgeInsets.only(bottom: sp * 1.2),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: widget.crossAxis,
          children: [
            // Header row
            Padding(
              padding: EdgeInsets.all(sp * 1.2),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: widget.topic.bgColor,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(widget.topic.icon,
                        color: widget.topic.iconColor, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.topic.title,
                      textAlign: widget.textAlign,
                      style: TextStyle(
                        fontSize: R.fs(context, 14.5),
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 300),
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: Colors.grey[400],
                      size: 22,
                    ),
                  ),
                ],
              ),
            ),
            // Expandable body
            SizeTransition(
              sizeFactor: _heightAnimation,
              child: Column(
                crossAxisAlignment: widget.crossAxis,
                children: [
                  Container(
                    height: 1,
                    color: const Color(0xFFF0F0F0),
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      sp * 1.5, sp, sp * 1.5, sp * 1.5,
                    ),
                    child: Text(
                      widget.topic.body,
                      textAlign: widget.textAlign,
                      style: TextStyle(
                        fontSize: R.fs(context, 13.5),
                        color: Colors.black54,
                        height: 1.7,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
