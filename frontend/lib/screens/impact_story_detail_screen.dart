import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../utils/responsive.dart';

class ImpactStoryDetailScreen extends StatelessWidget {
  final Map<String, dynamic> story;

  const ImpactStoryDetailScreen({super.key, required this.story});

  Future<void> _launchUrl(BuildContext context, String urlString) async {
    final Uri url = Uri.parse(urlString);
    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not open page: $urlString')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Invalid link or unsupported scheme: $urlString')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final sp = R.sp(context);
    final title = story['title'] ?? 'Story';
    final imageUrl = story['image_url'] ?? '';
    final videoUrl = story['video_url'] ?? '';
    final description = story['description'] ?? 'No description provided.';

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: R.h(context, 35),
                pinned: true,
                backgroundColor: const Color(0xFF2E7D32),
                iconTheme: const IconThemeData(color: Colors.white),
                flexibleSpace: FlexibleSpaceBar(
                  background: imageUrl.isNotEmpty
                      ? Stack(
                          fit: StackFit.expand,
                          children: [
                            imageUrl.startsWith('http')
                                ? Image.network(imageUrl, fit: BoxFit.cover)
                                : Image.asset(imageUrl, fit: BoxFit.cover),
                            Container(
                              color: Colors.black.withOpacity(0.35),
                            ),
                          ],
                        )
                      : Container(color: Colors.grey[350]),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: sp * 1.25, vertical: sp * 1.5),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: R.fs(context, 24),
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                          height: 1.2,
                        ),
                      ),
                      SizedBox(height: sp),
                      Divider(color: Colors.grey[200]),
                      SizedBox(height: sp * 0.5),
                      Text(
                        description,
                        style: TextStyle(
                          fontSize: R.fs(context, 15),
                          color: Colors.grey[800],
                          height: 1.5,
                        ),
                      ),
                      if (videoUrl.isNotEmpty) ...[
                        SizedBox(height: sp * 2),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2E7D32),
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(vertical: sp * 0.9),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 0,
                            ),
                            icon: const Icon(Icons.play_circle_fill, size: 20),
                            label: Text(
                              'Watch Video / Read Full Story',
                              style: TextStyle(
                                fontSize: R.fs(context, 14),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            onPressed: () => _launchUrl(context, videoUrl),
                          ),
                        ),
                      ],
                      SizedBox(height: R.h(context, 10)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
