import 'package:flutter/material.dart';
import '../utils/responsive.dart';
import 'impact_stories_screen.dart';

class GoalSelectionScreen extends StatelessWidget {
  const GoalSelectionScreen({super.key});

  final List<Map<String, dynamic>> goals = const [
    {'icon': Icons.lightbulb_outline_rounded, 'title': 'Inspire Cleanups'},
    {'icon': Icons.trending_up_rounded, 'title': 'Improve Data Quality'},
    {'icon': Icons.handshake_outlined, 'title': 'Join a Cleanup'},
    {'icon': Icons.saved_search_rounded, 'title': 'Track My Impact'},
    {'icon': Icons.gavel_rounded, 'title': 'Change Policy'},
    {'icon': Icons.help_outline_rounded, 'title': 'Not Sure'},
  ];

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
        child: Padding(
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
                    TextSpan(text: 'What is your '),
                    TextSpan(
                      text: 'goal',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    TextSpan(text: '?'),
                  ],
                ),
              ),
              SizedBox(height: sp * 2),
              Expanded(
                child: GridView.builder(
                  itemCount: goals.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: R.isLarge(context) ? 3 : 2,
                    crossAxisSpacing: sp,
                    mainAxisSpacing: sp,
                    childAspectRatio: R.isSmall(context) ? 1.0 : 0.85,
                  ),
                  itemBuilder: (context, index) =>
                      _buildGoalCard(context, goals[index]),
                ),
              ),
              SizedBox(height: sp),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGoalCard(BuildContext context, Map<String, dynamic> goal) {
    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const ImpactStoriesScreen()),
      ),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              goal['icon'],
              size: R.icon(context, 44),
              color: const Color(0xFF2196F3),
            ),
            SizedBox(height: R.sp(context)),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: R.sp(context) * 0.75),
              child: Text(
                goal['title'],
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: R.fs(context, 14),
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}