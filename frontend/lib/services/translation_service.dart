import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TranslationService {
  static final TranslationService instance = TranslationService._();
  TranslationService._();

  // ValueNotifier for language code ('en' or 'ur')
  final ValueNotifier<String> languageNotifier = ValueNotifier<String>('en');

  // Load language preference from Local Storage
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final savedLang = prefs.getString('app_language') ?? 'en';
    languageNotifier.value = savedLang;
  }

  // Toggle active language
  Future<void> toggleLanguage() async {
    final newLang = languageNotifier.value == 'en' ? 'ur' : 'en';
    languageNotifier.value = newLang;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_language', newLang);
  }

  // Set specific language
  Future<void> setLanguage(String langCode) async {
    if (langCode == 'en' || langCode == 'ur') {
      languageNotifier.value = langCode;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('app_language', langCode);
    }
  }

  // Check if active language is Urdu
  static bool get isUrdu => instance.languageNotifier.value == 'ur';

  // Translate helper method
  static String translate(String key, {String? fallback}) {
    final lang = instance.languageNotifier.value;
    return _dictionary[key]?[lang] ?? fallback ?? key;
  }

  // Translation Dictionary mapping
  static const Map<String, Map<String, String>> _dictionary = {
    // Shared / Navigation / Actions
    'app_name': {
      'en': 'GreenBin Genius',
      'ur': 'گرین بن جینئس',
    },
    'next': {
      'en': 'Next',
      'ur': 'اگلا',
    },
    'cancel': {
      'en': 'Cancel',
      'ur': 'منسوخ کریں',
    },
    'save': {
      'en': 'Save',
      'ur': 'محفوظ کریں',
    },
    'retry': {
      'en': 'Retry',
      'ur': 'دوبارہ کوشش کریں',
    },
    'view_all': {
      'en': 'View All',
      'ur': 'سب دیکھیں',
    },

    // Tabs
    'tab_activity': {
      'en': 'Activity',
      'ur': 'سرگرمی',
    },
    'tab_bins': {
      'en': 'Bins',
      'ur': 'کوڑے دان',
    },
    'tab_impact': {
      'en': 'Impact',
      'ur': 'اثرات',
    },
    'tab_tips': {
      'en': 'Eco Tips',
      'ur': 'صفائی گائیڈ',
    },
    'tab_profile': {
      'en': 'Profile',
      'ur': 'پروفائل',
    },

    // Notifications Screen
    'notifications': {
      'en': 'Notifications',
      'ur': 'اطلاعات',
    },
    'no_notifications': {
      'en': 'No Notifications Yet',
      'ur': 'ابھی تک کوئی اطلاع نہیں ہے',
    },
    'notifications_subtitle': {
      'en': 'Your scan results & updates will appear here.',
      'ur': 'آپ کے اسکین کے نتائج اور اپ ڈیٹس یہاں ظاہر ہوں گے۔',
    },

    // Impact Screen
    'impact_world_title': {
      'en': 'Impact your world',
      'ur': 'اپنی دنیا کو صاف بنائیں',
    },
    'overall_pickup': {
      'en': 'Overall Global Pickup',
      'ur': 'کل عالمی کچرا جمع کیا گیا',
    },
    'stories_impact': {
      'en': 'Stories of Impact',
      'ur': 'کامیابی کی کہانیاں',
    },
    'no_stories': {
      'en': 'No stories available',
      'ur': 'کوئی کہانیاں دستیاب نہیں ہیں',
    },
    'watch_video_btn': {
      'en': 'Watch Video / Read Full Story',
      'ur': 'ویڈیو دیکھیں / مکمل کہانی پڑھیں',
    },

    // Classification Result Screen
    'scan_result': {
      'en': 'Scan Result',
      'ur': 'اسکین کا نتیجہ',
    },
    'disposal_guidance': {
      'en': 'Disposal Guidance',
      'ur': 'ضائع کرنے کی رہنمائی',
    },
    'recyclability_score': {
      'en': 'Recyclability Score',
      'ur': 'ری سائیکلنگ سکور',
    },
    'environmental_impact': {
      'en': 'Environmental Impact',
      'ur': 'ماحولیاتی اثرات',
    },
    'eco_tip_of_day': {
      'en': 'Eco Tip of the Day',
      'ur': 'آج کی مفید معلوماتی ٹپ',
    },
    'correct_disposal_title': {
      'en': 'Correct Disposal Steps:',
      'ur': 'ضائع کرنے کے صحیح اقدامات:',
    },
    'co2_saved': {
      'en': 'CO2 Saved',
      'ur': 'CO2 کی بچت',
    },
    'water_saved': {
      'en': 'Water Saved',
      'ur': 'پانی کی بچت',
    },
    'points_earned': {
      'en': 'Points Earned',
      'ur': 'حاصل کردہ پوائنٹس',
    },
    // Settings Screen
    'settings': {
      'en': 'Settings',
      'ur': 'سیٹنگز',
    },
    'appearance': {
      'en': 'APPEARANCE',
      'ur': 'شکل و صورت',
    },
    'dark_mode': {
      'en': 'Dark Mode',
      'ur': 'ڈارک موڈ',
    },
    'preferences': {
      'en': 'PREFERENCES',
      'ur': 'ترجیحات',
    },
    'greenbin_suggestions': {
      'en': 'GreenBin Suggestions',
      'ur': 'گرین بن تجاویز',
    },
    'receive_eco_tips': {
      'en': 'Receive Daily Eco Tips',
      'ur': 'روزانہ ماحولیاتی تجاویز حاصل کریں',
    },

    'upload_wifi': {
      'en': 'Upload only via Wi-Fi',
      'ur': 'صرف وائی فائی پر اپ لوڈ کریں',
    },
    'location_accuracy': {
      'en': 'Maximum Location Accuracy',
      'ur': 'زیادہ سے زیادہ لوکیشن کی درستگی',
    },
    'app_language': {
      'en': 'App Language',
      'ur': 'ایپ کی زبان',
    },
    'account': {
      'en': 'ACCOUNT',
      'ur': 'اکاؤنٹ',
    },
    'log_out': {
      'en': 'Log Out',
      'ur': 'لاگ آؤٹ',
    },
    'clear_cache': {
      'en': 'Clear History Cache',
      'ur': 'ہسٹری کیشے صاف کریں',
    },
    'show_tutorial': {
      'en': 'Show Camera Tutorial Again',
      'ur': 'کیمرہ ٹیوٹوریل دوبارہ دکھائیں',
    },
    'about': {
      'en': 'ABOUT',
      'ur': 'ایپ کے بارے میں',
    },
    'app_version': {
      'en': 'App Version',
      'ur': 'ایپ کا ورژن',
    },
    'logout_confirm_title': {
      'en': 'Logout',
      'ur': 'لاگ آؤٹ',
    },
    'logout_confirm_desc': {
      'en': 'Are you sure you want to log out?',
      'ur': 'کیا آپ واقعی لاگ آؤٹ کرنا چاہتے ہیں؟',
    },
    // Navigation & Tabs
    'tab_map': {
      'en': 'Map',
      'ur': 'نقشہ',
    },
    'tab_leaderboard': {
      'en': 'Leaderboard',
      'ur': 'لیڈر بورڈ',
    },
    'tab_tasks': {
      'en': 'Tasks',
      'ur': 'کام',
    },
    // Tasks Tab
    'litter_data_desc': {
      'en': 'Want To Collect More Detailed Litter Data?',
      'ur': 'کیا آپ کچرے کا مزید تفصیلی ڈیٹا جمع کرنا چاہتے ہیں؟',
    },
    'apply_researcher': {
      'en': 'APPLY TO BECOME A GREENBIN\nRESEARCHER NOW',
      'ur': 'ابھی گرین بن محقق بننے کے لیے درخواست دیں',
    },
    'apply_now': {
      'en': 'APPLY NOW!',
      'ur': 'ابھی درخواست دیں!',
    },
    'task_active': {
      'en': 'Active Tasks',
      'ur': 'سرگرم ٹاسک',
    },
    'task_mine': {
      'en': 'My Tasks',
      'ur': 'میرے ٹاسک',
    },
    'task_points': {
      'en': 'Points',
      'ur': 'پوائنٹس',
    },
    'task_difficulty': {
      'en': 'Difficulty',
      'ur': 'مشکل',
    },
    'task_deadline': {
      'en': 'Deadline',
      'ur': 'آخری تاریخ',
    },
    'task_days_left': {
      'en': 'days left',
      'ur': 'دن باقی',
    },
    'task_completed': {
      'en': 'COMPLETED',
      'ur': 'مکمل ہو گیا',
    },
    'task_expired': {
      'en': 'EXPIRED',
      'ur': 'میعاد ختم',
    },
    'task_in_progress': {
      'en': 'IN PROGRESS',
      'ur': 'جاری ہے',
    },
    'task_empty': {
      'en': 'No tasks available at the moment.',
      'ur': 'اس وقت کوئی ٹاسک دستیاب نہیں ہے۔',
    },
    'task_mine_empty': {
      'en': "You haven't enrolled in any tasks yet.",
      'ur': 'آپ نے ابھی تک کسی ٹاسک میں حصہ نہیں لیا ہے۔',
    },
    'task_enrolled_success': {
      'en': 'Enrolled successfully!',
      'ur': 'کامیابی سے شامل ہو گئے!',
    },
    'task_apply_now': {
      'en': 'APPLY NOW',
      'ur': 'شامل ہوں',
    },
    // Leaderboard Tab
    'leaderboard_members': {
      'en': 'Members',
      'ur': 'ارکان',
    },
    'leaderboard_countries': {
      'en': 'Countries',
      'ur': 'ممالک',
    },
    'leaderboard_fail': {
      'en': 'Failed to load leaderboard',
      'ur': 'لیڈر بورڈ لوڈ کرنے میں ناکامی',
    },
    'no_records': {
      'en': 'No records found',
      'ur': 'کوئی ریکارڈ نہیں ملا',
    },
    // Activity Tab
    'history_fail': {
      'en': 'Failed to load history',
      'ur': 'ہسٹری لوڈ کرنے میں ناکامی',
    },
    'no_scans': {
      'en': 'No Scans Yet',
      'ur': 'ابھی تک کوئی اسکین نہیں',
    },
    'delete_confirm_desc': {
      'en': 'Are you sure you want to delete these records?',
      'ur': 'کیا آپ واقعی ان ریکارڈز کو حذف کرنا چاہتے ہیں؟',
    },
    'yes': {
      'en': 'YES',
      'ur': 'جی ہاں',
    },
    'no': {
      'en': 'NO',
      'ur': 'نہیں',
    },
    'delete_records': {
      'en': 'DELETE RECORD(S)',
      'ur': 'ریکارڈز حذف کریں',
    },
    // Impact Tab
    'total_global_litter': {
      'en': 'Total Global Litter Pickup',
      'ur': 'کل عالمی کچرا جمع کیا گیا',
    },
    'pickup_this_month': {
      'en': 'Overall Pickup This Month',
      'ur': 'اس مہینے کا کل کچرا جمع کیا گیا',
    },
    'my_activity_week': {
      'en': 'My Activity This Week',
      'ur': 'اس ہفتے میری سرگرمی',
    },
    // Profile Screen
    'profile_member_title': {
      'en': 'GreenBin Member',
      'ur': 'گرین بن ممبر',
    },
    'profile_member_since': {
      'en': 'Member Since April, 2026',
      'ur': 'اپریل 2026 سے رکن',
    },
    'claim_account': {
      'en': 'CLAIM YOUR ACCOUNT',
      'ur': 'اپنا اکاؤنٹ کلیم کریں',
    },
    'faqs_resources': {
      'en': 'FAQs & Resources',
      'ur': 'سوالات اور وسائل',
    },
    'privacy_policy': {
      'en': 'Privacy Policy',
      'ur': 'رازداری کی پالیسی',
    },
    'help': {
      'en': 'Help',
      'ur': 'مدد',
    },
    // Privacy Policy Screen
    'privacy_title': {
      'en': 'Privacy Policy',
      'ur': 'رازداری کی پالیسی',
    },
    'privacy_last_updated': {
      'en': 'Last updated: June 2026',
      'ur': 'آخری تازہ کاری: جون 2026',
    },
    'privacy_intro_title': {
      'en': 'Introduction',
      'ur': 'تعارف',
    },
    'privacy_intro_body': {
      'en': 'GreenBin Genius ("we", "our", or "us") is committed to protecting your personal information and your right to privacy. This Privacy Policy explains how we collect, use, and safeguard your data when you use our application.',
      'ur': 'گرین بن جینئس ("ہم") آپ کی ذاتی معلومات اور رازداری کے حق کے تحفظ کے لیے پرعزم ہے۔ یہ پالیسی بتاتی ہے کہ ہم آپ کی ایپ کے استعمال کے دوران ڈیٹا کیسے جمع، استعمال اور محفوظ کرتے ہیں۔',
    },
    'privacy_data_title': {
      'en': 'Data We Collect',
      'ur': 'ہم کون سا ڈیٹا جمع کرتے ہیں',
    },
    'privacy_data_body': {
      'en': 'When you use the AI Scanner, we temporarily process camera frames to classify waste items. We do not store raw image data. We store classification results (category, confidence, timestamp) linked to an anonymous session token. If you claim your account, your display name is stored securely.',
      'ur': 'جب آپ AI اسکینر استعمال کرتے ہیں، ہم کچرے کی اشیاء کی درجہ بندی کرنے کے لیے کیمرے کے فریم عارضی طور پر پروسیس کرتے ہیں۔ ہم خام تصویری ڈیٹا محفوظ نہیں کرتے۔ ہم درجہ بندی کے نتائج (زمرہ، اعتماد، ٹائم اسٹامپ) ایک گمنام سیشن ٹوکن سے منسلک کرکے محفوظ کرتے ہیں۔',
    },
    'privacy_security_title': {
      'en': 'Data Security',
      'ur': 'ڈیٹا کی سیکیورٹی',
    },
    'privacy_security_body': {
      'en': 'All data is transmitted over HTTPS and stored in a secured MongoDB database hosted on Hugging Face infrastructure. We implement industry-standard encryption and access control to protect your information from unauthorized access.',
      'ur': 'تمام ڈیٹا HTTPS کے ذریعے منتقل کیا جاتا ہے اور Hugging Face انفراسٹرکچر پر میزبان ایک محفوظ MongoDB ڈیٹا بیس میں ذخیرہ کیا جاتا ہے۔',
    },
    'privacy_rights_title': {
      'en': 'Your Rights',
      'ur': 'آپ کے حقوق',
    },
    'privacy_rights_body': {
      'en': 'You can delete your scan history at any time from the Activity tab. You may also request full account deletion by contacting us. We do not sell your personal data to third parties.',
      'ur': 'آپ کسی بھی وقت Activity ٹیب سے اپنی اسکین ہسٹری حذف کر سکتے ہیں۔ آپ ہم سے رابطہ کرکے مکمل اکاؤنٹ حذف کرنے کی درخواست بھی کر سکتے ہیں۔ ہم آپ کا ذاتی ڈیٹا تیسری فریق کو فروخت نہیں کرتے۔',
    },
    'privacy_cookies_title': {
      'en': 'Cookies & Local Storage',
      'ur': 'کوکیز اور مقامی اسٹوریج',
    },
    'privacy_cookies_body': {
      'en': 'We use SharedPreferences on your device to remember your language preference, dark mode setting, and tutorial completion status. No cross-site tracking or third-party cookies are used.',
      'ur': 'ہم آپ کی زبان کی ترجیح، ڈارک موڈ سیٹنگ، اور ٹیوٹوریل کی تکمیل کی حیثیت یاد رکھنے کے لیے آپ کے آلے پر SharedPreferences استعمال کرتے ہیں۔',
    },
    'privacy_contact_title': {
      'en': 'Contact Us',
      'ur': 'ہم سے رابطہ کریں',
    },
    'privacy_contact_body': {
      'en': 'If you have questions about this Privacy Policy, please contact us at:\n\nprivacy@greenbin.ai',
      'ur': 'اگر آپ کے اس پرائیویسی پالیسی کے بارے میں سوالات ہیں، براہ کرم ہم سے رابطہ کریں:\n\nprivacy@greenbin.ai',
    },
    // Help Screen
    'help_title': {
      'en': 'Help & Support',
      'ur': 'مدد اور سپورٹ',
    },
    'help_subtitle': {
      'en': 'How can we help you today?',
      'ur': 'آج ہم آپ کی کیسے مدد کر سکتے ہیں؟',
    },
    'help_scan_title': {
      'en': 'How to Scan Waste?',
      'ur': 'کچرا کیسے اسکین کریں؟',
    },
    'help_scan_body': {
      'en': '1. Tap the blue camera button at the bottom center of the app.\n2. Point your camera at the waste item.\n3. Tap "Scan" or "Classify" to analyze the item.\n4. View the AI result with disposal guidance and eco-tips.\n5. Your scan is automatically saved to your Activity history.',
      'ur': '١. ایپ کے نیچے درمیان میں نیلے کیمرے بٹن پر ٹیپ کریں۔\n٢. کیمرہ کچرے کی چیز پر لے جائیں۔\n٣. "اسکین" یا "درجہ بندی" پر ٹیپ کریں۔\n٤. AI نتیجہ ڈسپوزل گائیڈنس کے ساتھ دیکھیں۔\n٥. آپ کا اسکین خودکار طور پر Activity میں محفوظ ہو جائے گا۔',
    },
    'help_disposal_title': {
      'en': 'Understanding Disposal Advice',
      'ur': 'ڈسپوزل مشورہ سمجھنا',
    },
    'help_disposal_body': {
      'en': 'GreenBin classifies items into categories such as Recyclable, Organic, Hazardous, and General Waste. Each classification includes step-by-step disposal guidance and eco-tips to minimize environmental impact. Tap the guidance card after scanning to see detailed steps.',
      'ur': 'گرین بن اشیاء کو Recyclable، Organic، Hazardous، اور General Waste جیسی اقسام میں درجہ بند کرتا ہے۔ ہر درجہ بندی میں ڈسپوزل کے مرحلہ وار ہدایات اور ماحولیاتی نکات شامل ہیں۔',
    },
    'help_leaderboard_title': {
      'en': 'Leaderboard & Points',
      'ur': 'لیڈر بورڈ اور پوائنٹس',
    },
    'help_leaderboard_body': {
      'en': 'Every scan you make contributes to the global litter pickup counter. The Leaderboard ranks users by their total scan count, filterable by time period (24 hours, 7 days, 30 days). Claim your account in Profile to appear with your display name on the leaderboard.',
      'ur': 'آپ کا ہر اسکین عالمی کچرے کی گنتی میں اضافہ کرتا ہے۔ لیڈر بورڈ صارفین کو ان کی کل اسکین تعداد کے مطابق ترتیب دیتا ہے۔ لیڈر بورڈ پر نام ظاہر کرنے کے لیے پروفائل میں اکاؤنٹ کلیم کریں۔',
    },
    'help_map_title': {
      'en': 'Finding Disposal Bins',
      'ur': 'ڈسپوزل بنز تلاش کرنا',
    },
    'help_map_body': {
      'en': 'The Map tab shows nearby waste disposal locations using your device location. Tap any pin to view bin details. Make sure you have granted location permission to the app in your device Settings for the map to work correctly.',
      'ur': 'Map ٹیب آپ کے آلے کی لوکیشن استعمال کرتے ہوئے قریبی کچرے کے ڈبے دکھاتا ہے۔ کسی بھی پن پر ٹیپ کریں تو ڈبے کی تفصیلات دیکھیں۔ یقینی بنائیں کہ آپ نے اپنے آلے کی ترتیبات میں لوکیشن اجازت دی ہے۔',
    },
    'help_contact_title': {
      'en': 'Still Need Help?',
      'ur': 'ابھی بھی مدد چاہیے؟',
    },
    'help_contact_body': {
      'en': 'Our support team is here for you. Reach out and we\'ll get back to you within 24 hours.',
      'ur': 'ہماری سپورٹ ٹیم آپ کے لیے موجود ہے۔ ہم سے رابطہ کریں اور ہم 24 گھنٹوں میں جواب دیں گے۔',
    },
    'help_email_label': {
      'en': 'Email Support',
      'ur': 'ای میل سپورٹ',
    },
  };
}
