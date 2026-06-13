import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/api_service.dart';
import '../utils/responsive.dart';
import 'start_with_photo_screen.dart';
import 'impact_story_detail_screen.dart';

class ImpactStoriesScreen extends StatefulWidget {
  const ImpactStoriesScreen({super.key});

  @override
  State<ImpactStoriesScreen> createState() => _ImpactStoriesScreenState();
}

class _ImpactStoriesScreenState extends State<ImpactStoriesScreen> {
  late Future<List<dynamic>> _storiesFuture;

  @override
  void initState() {
    super.initState();
    _storiesFuture = ApiService.instance.getImpactStories();
  }

  Future<void> _launchUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not open page: $urlString')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Invalid link or unsupported scheme: $urlString')),
        );
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
        actions: [
          TextButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const StartWithPhotoScreen()),
            ),
            child: Text(
              'Next',
              style: TextStyle(
                color: const Color(0xFFFF4081),
                fontWeight: FontWeight.bold,
                fontSize: R.fs(context, 15),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: R.pagePadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: sp * 0.5),

            RichText(
              text: TextSpan(
                style: TextStyle(
                  color: Colors.black,
                  fontSize: R.fs(context, 26),
                  fontWeight: FontWeight.w400,
                ),
                children: const [
                  TextSpan(text: 'Impact your '),
                  TextSpan(
                    text: 'world',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),

            SizedBox(height: sp * 1.5),

            Text(
              'Overall Global Pickup',
              style: TextStyle(
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
                fontSize: R.fs(context, 14),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '24,291,447',
              style: TextStyle(
                color: const Color(0xFF2196F3),
                fontWeight: FontWeight.w500,
                fontSize: R.fs(context, 34),
              ),
            ),

            SizedBox(height: sp * 1.5),

            // Map Placeholder
            Container(
              height: R.h(context, 22),
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(20),
                image: const DecorationImage(
                  image: NetworkImage(
                      'https://upload.wikimedia.org/wikipedia/commons/thumb/8/80/World_map_-_low_resolution.svg/1200px-World_map_-_low_resolution.svg.png'),
                  fit: BoxFit.contain,
                  opacity: 0.6,
                ),
              ),
              child: Center(
                child: Icon(
                  Icons.public,
                  size: R.icon(context, 60),
                  color: const Color(0xFF2196F3).withOpacity(0.3),
                ),
              ),
            ),

            SizedBox(height: sp * 2),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Stories of\nImpact',
                  style: TextStyle(
                    fontSize: R.fs(context, 22),
                    fontWeight: FontWeight.bold,
                    height: 1.1,
                  ),
                ),
                TextButton(
                  onPressed: () {},
                  child: Text(
                    'View All',
                    style: TextStyle(
                      color: const Color(0xFFFF4081),
                      fontWeight: FontWeight.bold,
                      fontSize: R.fs(context, 14),
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: sp),

            FutureBuilder<List<dynamic>>(
              future: _storiesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return SizedBox(
                    height: R.h(context, 20),
                    child: const Center(child: CircularProgressIndicator()),
                  );
                } else if (snapshot.hasError) {
                  return SizedBox(
                    height: R.h(context, 20),
                    child: Center(
                      child: Text(
                        'Failed to load stories.',
                        style: TextStyle(color: Colors.red, fontSize: R.fs(context, 13)),
                      ),
                    ),
                  );
                }

                final stories = snapshot.data ?? [];
                if (stories.isEmpty) {
                  return SizedBox(
                    height: R.h(context, 20),
                    child: Center(
                      child: Text(
                        'No stories found.',
                        style: TextStyle(color: Colors.grey, fontSize: R.fs(context, 13)),
                      ),
                    ),
                  );
                }

                return SizedBox(
                  height: R.h(context, 20),
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: stories.length,
                    itemBuilder: (context, index) {
                      final item = stories[index];
                      final title = item['title'] ?? '';
                      final imageUrl = item['image_url'] ?? '';
                      final videoUrl = item['video_url'] ?? '';

                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ImpactStoryDetailScreen(story: item),
                            ),
                          );
                        },
                        child: Container(
                          width: R.w(context, 50),
                          margin: EdgeInsets.only(right: sp),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            color: Colors.grey[200],
                            image: imageUrl.isNotEmpty
                                ? DecorationImage(
                                    image: NetworkImage(imageUrl),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                          ),
                          child: Stack(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.transparent,
                                      Colors.black.withOpacity(0.7),
                                    ],
                                  ),
                                ),
                              ),
                              if (videoUrl.isNotEmpty)
                                Center(
                                  child: Icon(
                                    Icons.play_circle_fill,
                                    color: Colors.white,
                                    size: R.icon(context, 40),
                                  ),
                                ),
                              Positioned(
                                bottom: sp * 0.75,
                                left: sp * 0.75,
                                right: sp * 0.75,
                                child: Text(
                                  title,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: R.fs(context, 13),
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
            SizedBox(height: sp * 1.5),
          ],
        ),
      ),
    );
  }
}