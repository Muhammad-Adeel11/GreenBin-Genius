import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../utils/responsive.dart';
import '../services/api_service.dart';

class FAQsResourcesScreen extends StatefulWidget {
  const FAQsResourcesScreen({super.key});

  @override
  State<FAQsResourcesScreen> createState() => _FAQsResourcesScreenState();
}

class _FAQsResourcesScreenState extends State<FAQsResourcesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  
  bool _isLoading = true;
  bool _showUrdu = false;
  String _searchQuery = '';

  List<dynamic> _faqs = [];
  List<dynamic> _resources = [];

  // Offline local fallback data for resilience
  final List<Map<String, dynamic>> _fallbackFAQs = [
    {
      "question_en": "What is GreenBin Genius?",
      "question_ur": "گرین بن جینیئس کیا ہے؟",
      "answer_en": "GreenBin Genius is an AI-powered waste classification assistant designed to help users identify recyclables and locate nearby disposal bins.",
      "answer_ur": "گرین بن جینیئس ایک اے آئی سے چلنے والا کوڑا کرکٹ کی درجہ بندی کا معاون ہے جو صارفین کو ری سائیکل کی جانے والی اشیاء کی شناخت اور قریبی ڈبوں کو تلاش کرنے میں مدد کرتا ہے۔",
      "category": "general",
      "is_active": true
    },
    {
      "question_en": "How does the AI waste classification work?",
      "question_ur": "اے آئی کوڑے کی درجہ بندی کیسے کام کرتی ہے؟",
      "answer_en": "Our system uses a combined deep learning approach (CNN and YOLOv8 models) to analyze the waste image you upload and identify the waste material and category.",
      "answer_ur": "ہمارا سسٹم آپ کی اپ لوڈ کردہ تصویر کا تجزیہ کرنے اور کوڑے کے مواد اور زمرے کی شناخت کرنے کے لیے ایک گہری لرننگ اپروچ (CNN اور YOLOv8 ماڈلز) کا استعمال کرتا ہے۔",
      "category": "classification",
      "is_active": true
    },
    {
      "question_en": "What should I do if the AI makes a mistake?",
      "question_ur": "اگر اے آئی کوئی غلطی کرے تو مجھے کیا کرنا چاہئے؟",
      "answer_en": "You can submit a correction by tapping the 'Wrong' button on the classification result screen. Correcting classification mistakes awards you +5 contribution points!",
      "answer_ur": "آپ درجہ بندی کے نتیجے کی اسکرین پر 'غلط' بٹن پر ٹیپ کر کے تصحیح جمع کر سکتے ہیں۔ غلطیوں کی تصحیح کرنے پر آپ کو +5 کنٹریبیوشن پوائنٹس ملیں گے!",
      "category": "classification",
      "is_active": true
    },
    {
      "question_en": "How do I find a recycling bin near me?",
      "question_ur": "میں اپنے قریب ری سائیکلنگ بن کیسے تلاش کروں؟",
      "answer_en": "Go to the 'Bin Locator' page or tap 'Find Nearest Bin' on any classification result to see nearby active bins sorted by distance.",
      "answer_ur": "قریبی ڈبوں کو فاصلے کے لحاظ سے ترتیب وار دیکھنے کے لیے 'بن لوکیٹر' صفحہ پر جائیں یا کسی بھی درجہ بندی کے نتیجے پر 'قریبی بن تلاش کریں' پر ٹیپ کریں۔",
      "category": "locator",
      "is_active": true
    }
  ];

  final List<Map<String, dynamic>> _fallbackResources = [
    {
      "title": "Official EPA Recycling Guide",
      "url": "https://www.epa.gov/recycle",
      "category": "Education",
      "icon": "📖",
      "description": "Comprehensive guide on what and how to recycle household materials.",
      "is_active": true
    },
    {
      "title": "Home Composting Basics",
      "url": "https://www.epa.gov/recycle/composting-home",
      "category": "Composting",
      "icon": "🌱",
      "description": "Learn how to turn organic waste into nutrient-rich soil at home.",
      "is_active": true
    },
    {
      "title": "Reducing Household Plastic",
      "url": "https://www.plasticfreejuly.org/",
      "category": "Tips",
      "icon": "🚫",
      "description": "Simple challenges and ideas to help reduce your everyday plastic consumption.",
      "is_active": true
    },
    {
      "title": "Electronic Waste (e-Waste) Disposal",
      "url": "https://www.consumerreports.org/recycling/how-to-recycle-electronics/",
      "category": "E-Waste",
      "icon": "💻",
      "description": "Safety guidelines and centers for responsible electronic device recycling.",
      "is_active": true
    }
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final faqs = await ApiService.instance.getFAQs();
      final resources = await ApiService.instance.getResources();
      setState(() {
        _faqs = faqs.where((f) => f['is_active'] == true).toList();
        _resources = resources.where((r) => r['is_active'] == true).toList();
        _isLoading = false;
      });
    } catch (e) {
      // Graceful fallback to offline defaults
      setState(() {
        _faqs = _fallbackFAQs;
        _resources = _fallbackResources;
        _isLoading = false;
      });
    }
  }

  Future<void> _launchURL(String urlString) async {
    final Uri url = Uri.parse(urlString);
    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        throw 'Could not launch $urlString';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open: $urlString')),
        );
      }
    }
  }

  List<dynamic> get _filteredFAQs {
    if (_searchQuery.isEmpty) return _faqs;
    return _faqs.where((faq) {
      final qEn = (faq['question_en'] ?? '').toString().toLowerCase();
      final qUr = (faq['question_ur'] ?? '').toString().toLowerCase();
      final aEn = (faq['answer_en'] ?? '').toString().toLowerCase();
      final aUr = (faq['answer_ur'] ?? '').toString().toLowerCase();
      final cat = (faq['category'] ?? '').toString().toLowerCase();
      return qEn.contains(_searchQuery) ||
          qUr.contains(_searchQuery) ||
          aEn.contains(_searchQuery) ||
          aUr.contains(_searchQuery) ||
          cat.contains(_searchQuery);
    }).toList();
  }

  List<dynamic> get _filteredResources {
    if (_searchQuery.isEmpty) return _resources;
    return _resources.where((res) {
      final title = (res['title'] ?? '').toString().toLowerCase();
      final desc = (res['description'] ?? '').toString().toLowerCase();
      final cat = (res['category'] ?? '').toString().toLowerCase();
      return title.contains(_searchQuery) ||
          desc.contains(_searchQuery) ||
          cat.contains(_searchQuery);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final sp = R.sp(context);
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF121212) : Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF2196F3),
        foregroundColor: Colors.white,
        title: Text(
          _showUrdu ? "معلومات اور وسائل" : "FAQs & Resources",
          style: TextStyle(fontSize: R.fs(context, 18), fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          // Urdu/English toggle button
          IconButton(
            icon: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                _showUrdu ? "EN" : "اردو",
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
            onPressed: () {
              setState(() => _showUrdu = !_showUrdu);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Search & Header Section ────────────────────────────────
          Container(
            color: const Color(0xFF2196F3),
            padding: EdgeInsets.fromLTRB(
              R.w(context, 5),
              0,
              R.w(context, 5),
              R.h(context, 2.5),
            ),
            child: Column(
              children: [
                Text(
                  _showUrdu
                      ? "ماحول دوست معلومات اور رہنما اصول"
                      : "Your guide to eco-friendly recycling & composting",
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: R.fs(context, 13),
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: sp * 1.5),
                // Search Input Field
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    textAlign: _showUrdu ? TextAlign.right : TextAlign.left,
                    textDirection: _showUrdu ? TextDirection.rtl : TextDirection.ltr,
                    decoration: InputDecoration(
                      hintText: _showUrdu ? "یہاں تلاش کریں..." : "Search guidance...",
                      hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
                      prefixIcon: const Icon(Icons.search, color: Colors.grey),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, color: Colors.grey),
                              onPressed: () => _searchController.clear(),
                            )
                          : null,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Tab Bar ───────────────────────────────────────────────
          TabBar(
            controller: _tabController,
            indicatorColor: const Color(0xFF2196F3),
            labelColor: const Color(0xFF2196F3),
            unselectedLabelColor: Colors.grey,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            tabs: [
              Tab(text: _showUrdu ? "اکثر پوچھے گئے سوالات" : "FAQs"),
              Tab(text: _showUrdu ? "ماحولیاتی وسائل" : "Resources"),
            ],
          ),

          // ── Tab Contents ──────────────────────────────────────────
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF2196F3)))
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildFAQList(isDarkMode),
                      _buildResourceList(isDarkMode),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFAQList(bool isDarkMode) {
    final filtered = _filteredFAQs;
    if (filtered.isEmpty) {
      return Center(
        child: Text(
          _showUrdu ? "کوئی سوال نہیں ملا۔" : "No FAQs match your search query.",
          style: const TextStyle(color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final faq = filtered[index];
        final question = _showUrdu ? faq['question_ur'] : faq['question_en'];
        final answer = _showUrdu ? faq['answer_ur'] : faq['answer_en'];
        final category = faq['category'] ?? 'general';

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(color: Colors.grey.withOpacity(0.1)),
          ),
          child: Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              title: Text(
                question,
                textDirection: _showUrdu ? TextDirection.rtl : TextDirection.ltr,
                style: TextStyle(
                  fontSize: R.fs(context, 14),
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
              leading: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFF2196F3).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(Icons.help_outline, color: Color(0xFF2196F3), size: 18),
                ),
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Divider(height: 1, thickness: 1, color: Color(0xFFEEEEEE)),
                      const SizedBox(height: 12),
                      Text(
                        answer,
                        textDirection: _showUrdu ? TextDirection.rtl : TextDirection.ltr,
                        style: TextStyle(
                          fontSize: R.fs(context, 13),
                          color: isDarkMode ? Colors.white70 : Colors.black54,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Align(
                        alignment: _showUrdu ? Alignment.centerLeft : Alignment.centerRight,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.grey.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            category.toUpperCase(),
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey),
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
      },
    );
  }

  Widget _buildResourceList(bool isDarkMode) {
    final filtered = _filteredResources;
    if (filtered.isEmpty) {
      return Center(
        child: Text(
          _showUrdu ? "کوئی وسائل نہیں ملے۔" : "No resources match your search query.",
          style: const TextStyle(color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final res = filtered[index];
        final title = res['title'] ?? 'Eco Resource';
        final url = res['url'] ?? '';
        final category = res['category'] ?? 'Education';
        final icon = res['icon'] ?? '🔗';
        final description = res['description'] ?? '';

        return GestureDetector(
          onTap: () => _launchURL(url),
          child: Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
              border: Border.all(color: Colors.grey.withOpacity(0.1)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon Box
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(icon, style: const TextStyle(fontSize: 22)),
                  ),
                ),
                const SizedBox(width: 14),
                // Text details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.between,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2196F3).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              category.toUpperCase(),
                              style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF2196F3)),
                            ),
                          ),
                          const Icon(Icons.open_in_new, size: 14, color: Colors.grey),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: R.fs(context, 14),
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? Colors.white : Colors.black87,
                        ),
                      ),
                      if (description.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: R.fs(context, 12),
                            color: isDarkMode ? Colors.white54 : Colors.grey[600],
                            height: 1.4,
                          ),
                        ),
                      ],
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
