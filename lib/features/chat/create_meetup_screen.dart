import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/colors.dart';
import '../../core/constants/dimensions.dart';
import '../../data/repository_provider.dart';
import '../../shared/widgets/casama_avatar.dart';
import '../../shared/widgets/casama_button.dart';

class CreateMeetupScreen extends ConsumerStatefulWidget {
  const CreateMeetupScreen({super.key});

  @override
  ConsumerState<CreateMeetupScreen> createState() => _CreateMeetupScreenState();
}

class _CreateMeetupScreenState extends ConsumerState<CreateMeetupScreen> {
  final _activityController = TextEditingController(text: 'Study Session 🎓');
  final _locationController = TextEditingController(text: 'Dorm Common Area');
  final _timeController = TextEditingController(text: 'Today • 7:00 PM');

  @override
  void dispose() {
    _activityController.dispose();
    _locationController.dispose();
    _timeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final repo = ref.watch(repositoryProvider);

    return Scaffold(
      backgroundColor: context.scaffoldBg,
      appBar: AppBar(
        title: const Text('Create Meet-up'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            }
          },
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: CasamaSpacing.lg),
          child: Column(
            children: [
              const SizedBox(height: CasamaSpacing.sm),

              // Hero Illustration Container
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 20),
                decoration: BoxDecoration(
                  color: context.isDark
                      ? CasamaColors.darkTileParcels
                      : const Color(0xFFFFECE8),
                  borderRadius: CasamaSpacing.roundedXl,
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        'assets/images/cas/cas_together.png',
                        height: 110,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) =>
                            const Text(
                              '🙌 ☕ 🍕',
                              style: TextStyle(fontSize: 48),
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Bring the household together',
                        style: TextStyle(
                          color: context.textColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: CasamaSpacing.lg),

              // Form fields
              _buildFieldCard(
                icon: Icons.calendar_today_outlined,
                label: 'Activity',
                child: TextField(
                  controller: _activityController,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: context.textColor,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              _buildFieldCard(
                icon: Icons.location_on_outlined,
                label: 'Location',
                child: TextField(
                  controller: _locationController,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: context.textColor,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              _buildFieldCard(
                icon: Icons.access_time_rounded,
                label: 'Time',
                child: TextField(
                  controller: _timeController,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: context.textColor,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Invitees
              _buildFieldCard(
                icon: Icons.people_outline_rounded,
                label: 'Invitees',
                child: Row(
                  children: repo.members.map((m) {
                    return Container(
                      margin: const EdgeInsets.only(right: 8, top: 4),
                      child: CasamaAvatar(
                        radius: 16,
                        avatarUrl: m.profile.avatarUrl,
                        name: m.profile.displayName,
                      ),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: CasamaSpacing.xl),

              // Action button
              CasamaButton(
                label: 'Send Invitation',
                onPressed: () {
                  ref
                      .read(repositoryProvider)
                      .sendChatMessage(
                        '📢 Meet-up Invitation: ${_activityController.text.trim()} at ${_locationController.text.trim()} (${_timeController.text.trim()})',
                      );
                  if (Navigator.canPop(context)) {
                    Navigator.pop(context);
                  }
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Meet-up invitation sent to housemates!'),
                    ),
                  );
                },
                isPill: true,
                height: 52,
              ),

              const SizedBox(height: CasamaSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFieldCard({
    required IconData icon,
    required String label,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: CasamaSpacing.roundedLg,
        border: Border.all(color: context.borderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: context.textSecondaryColor, size: 22),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: context.textSecondaryColor,
                  ),
                ),
                const SizedBox(height: 2),
                child,
              ],
            ),
          ),
        ],
      ),
    );
  }
}
