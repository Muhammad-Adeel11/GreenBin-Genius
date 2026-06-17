import 'package:flutter/material.dart';
import '../utils/responsive.dart';
import '../services/translation_service.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: TranslationService.instance.languageNotifier,
      builder: (context, lang, _) {
        final isUrdu = TranslationService.isUrdu;
        final textAlign = isUrdu ? TextAlign.right : TextAlign.left;
        final crossAxis = isUrdu ? CrossAxisAlignment.end : CrossAxisAlignment.start;

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
              TranslationService.translate('privacy_title'),
              style: TextStyle(
                color: Colors.white,
                fontSize: R.fs(context, 18),
                fontWeight: FontWeight.bold,
              ),
            ),
            centerTitle: true,
          ),
          body: SingleChildScrollView(
            padding: R.pagePadding(context).add(EdgeInsets.symmetric(vertical: R.sp(context) * 1.5)),
            child: Column(
              crossAxisAlignment: crossAxis,
              children: [
                // Last Updated badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE3F2FD),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.access_time_rounded, size: 14, color: Color(0xFF2196F3)),
                      const SizedBox(width: 6),
                      Text(
                        TranslationService.translate('privacy_last_updated'),
                        style: TextStyle(
                          color: const Color(0xFF2196F3),
                          fontSize: R.fs(context, 12),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: R.sp(context) * 2),

                _PrivacySection(
                  icon: Icons.info_outline_rounded,
                  iconColor: const Color(0xFF2196F3),
                  bgColor: const Color(0xFFE3F2FD),
                  title: TranslationService.translate('privacy_intro_title'),
                  body: TranslationService.translate('privacy_intro_body'),
                  textAlign: textAlign,
                  crossAxis: crossAxis,
                ),

                _PrivacySection(
                  icon: Icons.storage_rounded,
                  iconColor: const Color(0xFF4CAF50),
                  bgColor: const Color(0xFFE8F5E9),
                  title: TranslationService.translate('privacy_data_title'),
                  body: TranslationService.translate('privacy_data_body'),
                  textAlign: textAlign,
                  crossAxis: crossAxis,
                ),

                _PrivacySection(
                  icon: Icons.lock_outline_rounded,
                  iconColor: const Color(0xFF9C27B0),
                  bgColor: const Color(0xFFF3E5F5),
                  title: TranslationService.translate('privacy_security_title'),
                  body: TranslationService.translate('privacy_security_body'),
                  textAlign: textAlign,
                  crossAxis: crossAxis,
                ),

                _PrivacySection(
                  icon: Icons.verified_user_outlined,
                  iconColor: const Color(0xFF00BCD4),
                  bgColor: const Color(0xFFE0F7FA),
                  title: TranslationService.translate('privacy_rights_title'),
                  body: TranslationService.translate('privacy_rights_body'),
                  textAlign: textAlign,
                  crossAxis: crossAxis,
                ),

                _PrivacySection(
                  icon: Icons.cookie_outlined,
                  iconColor: const Color(0xFFFF9800),
                  bgColor: const Color(0xFFFFF3E0),
                  title: TranslationService.translate('privacy_cookies_title'),
                  body: TranslationService.translate('privacy_cookies_body'),
                  textAlign: textAlign,
                  crossAxis: crossAxis,
                ),

                // Contact card
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(R.sp(context) * 2),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF2196F3), Color(0xFF1565C0)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF2196F3).withOpacity(0.3),
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
                          const Icon(Icons.email_outlined, color: Colors.white70, size: 22),
                          const SizedBox(width: 8),
                          Text(
                            TranslationService.translate('privacy_contact_title'),
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
                        TranslationService.translate('privacy_contact_body'),
                        textAlign: textAlign,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.85),
                          fontSize: R.fs(context, 14),
                          height: 1.6,
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: R.sp(context) * 2),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _PrivacySection extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color bgColor;
  final String title;
  final String body;
  final TextAlign textAlign;
  final CrossAxisAlignment crossAxis;

  const _PrivacySection({
    required this.icon,
    required this.iconColor,
    required this.bgColor,
    required this.title,
    required this.body,
    required this.textAlign,
    required this.crossAxis,
  });

  @override
  Widget build(BuildContext context) {
    final sp = R.sp(context);
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: sp * 1.5),
      padding: EdgeInsets.all(sp * 1.5),
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
      child: Column(
        crossAxisAlignment: crossAxis,
        children: [
          Row(
            mainAxisAlignment:
                crossAxis == CrossAxisAlignment.end ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: R.fs(context, 15),
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: sp * 0.75),
          Container(height: 1, color: const Color(0xFFF0F0F0)),
          SizedBox(height: sp * 0.75),
          Text(
            body,
            textAlign: textAlign,
            style: TextStyle(
              fontSize: R.fs(context, 13.5),
              color: Colors.black54,
              height: 1.65,
            ),
          ),
        ],
      ),
    );
  }
}
