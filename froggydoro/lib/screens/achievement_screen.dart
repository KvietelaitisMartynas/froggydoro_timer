import 'package:flutter/material.dart';
import 'package:froggydoro/services/database_service.dart';

class AchievementsScreen extends StatefulWidget {
  const AchievementsScreen({super.key});

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen> {
  final DatabaseService _databaseService = DatabaseService.instance;
  List<Map<String, dynamic>> _achievements = [];
  List<Map<String, dynamic>> _unlockedAchievements = [];

  @override
  void initState() {
    super.initState();
    _loadAchievements();
  }

  Future<void> _loadAchievements() async {
    final achievements = await _databaseService.getAllAchievements();
    final unlockedAchievements = await _databaseService.getUnlockedAchievements();
    
    if (mounted) {
      setState(() {
        _achievements = achievements;
        _unlockedAchievements = unlockedAchievements;
      });
    }
  }

  bool _isAchievementUnlocked(int achievementId) {
    return _unlockedAchievements.any((achievement) => 
      achievement['achievement_id'] == achievementId
    );
  }

  void _showAchievementDetails(BuildContext context, Map<String, dynamic> achievement, bool isUnlocked) {
    final name = achievement['name'] as String;
    final description = achievement['description'] as String;
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isUnlocked ? Icons.emoji_events : Icons.lock_outline,
                size: 56,
                color: isUnlocked ? Colors.amber : Colors.grey,
              ),
              const SizedBox(height: 16),
              Text(
                name,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: isUnlocked ? Colors.amber[700] : Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                description,
                style: TextStyle(
                  fontSize: 16,
                  color: isUnlocked ? Theme.of(context).colorScheme.onSurface : Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFFE4E8DD),
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.all(8.0),
          child: GridView.builder(
            itemCount: _achievements.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.80,
            ),
            itemBuilder: (context, index) {
              final achievement = _achievements[index];
              final isUnlocked = _isAchievementUnlocked(achievement['achievement_id']);
              final name = achievement['name'] as String;
              final parts = name.split(' ');

              return InkWell(
                onTap: () => _showAchievementDetails(context, achievement, isUnlocked),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isUnlocked ? Icons.emoji_events : Icons.lock_outline,
                        size: 46,
                        color: isUnlocked ? Colors.amber : Colors.grey,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        parts[0],
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: isUnlocked ? Colors.amber[700] : Colors.grey,
                        ),
                      ),
                      if (parts.length > 1)
                        Text(
                          parts[1],
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: isUnlocked ? Colors.amber[700] : Colors.grey,
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
