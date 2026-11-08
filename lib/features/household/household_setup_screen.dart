import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/colors.dart';
import '../../core/constants/dimensions.dart';
import '../../shared/widgets/cas_mascot_view.dart';
import '../../shared/widgets/casama_button.dart';
import '../../shared/widgets/casama_text_field.dart';

class HouseholdSetupScreen extends StatefulWidget {
  const HouseholdSetupScreen({super.key});

  @override
  State<HouseholdSetupScreen> createState() => _HouseholdSetupScreenState();
}

class _HouseholdSetupScreenState extends State<HouseholdSetupScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _createNameController = TextEditingController();
  final _joinCodeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _createNameController.dispose();
    _joinCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.scaffoldBg,
      appBar: AppBar(
        title: const Text('Household Setup'),
        automaticallyImplyLeading: false,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            child: TabBar(
              controller: _tabController,
              indicatorColor: CasamaColors.primaryCoral,
              indicatorWeight: 3,
              labelColor: CasamaColors.primaryCoral,
              unselectedLabelColor: context.textSecondaryColor,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
              tabs: const [
                Tab(text: 'Join Household'),
                Tab(text: 'Create New'),
              ],
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: TabBarView(
          controller: _tabController,
          children: [_buildJoinTab(context), _buildCreateTab(context)],
        ),
      ),
    );
  }

  Widget _buildJoinTab(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(CasamaSpacing.xl),
      child: Column(
        children: [
          const SizedBox(height: CasamaSpacing.md),
          const CasMascotView(pose: CasPose.waving, width: 130, height: 130),
          const SizedBox(height: 16),
          Text(
            'Got an Invite Code?',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: context.textColor,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Ask your roommate or household owner for the 6-character code (e.g. CASA204).',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: context.textSecondaryColor),
          ),
          const SizedBox(height: CasamaSpacing.xl),

          CasamaTextField(
            controller: _joinCodeController,
            label: 'Household Invite Code',
            hint: 'CASA204',
            prefixIcon: Icons.vpn_key_outlined,
          ),
          const SizedBox(height: CasamaSpacing.xl),

          CasamaButton(
            label: 'Join Household',
            isPill: true,
            height: 52,
            onPressed: () {
              final code = _joinCodeController.text.trim().toUpperCase();
              if (code.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter an invite code')),
                );
                return;
              }
              context.go('/dashboard');
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Joined household with code $code!')),
              );
            },
          ),
          const SizedBox(height: CasamaSpacing.md),
          TextButton(
            onPressed: () {
              _joinCodeController.text = 'CASA204';
            },
            child: const Text('Fill Demo Code: CASA204'),
          ),
        ],
      ),
    );
  }

  Widget _buildCreateTab(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(CasamaSpacing.xl),
      child: Column(
        children: [
          const SizedBox(height: CasamaSpacing.md),
          const CasMascotView(pose: CasPose.hero, width: 130, height: 130),
          const SizedBox(height: 16),
          Text(
            'Start a New Household',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: context.textColor,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Give your shared living space a name to generate an invite code for your housemates.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: context.textSecondaryColor),
          ),
          const SizedBox(height: CasamaSpacing.xl),

          CasamaTextField(
            controller: _createNameController,
            label: 'Household Name',
            hint: 'e.g., Casa 204, Apartment 4B, The Loft',
            prefixIcon: Icons.home_work_outlined,
          ),
          const SizedBox(height: CasamaSpacing.xl),

          CasamaButton(
            label: 'Create Household',
            style: CasamaButtonStyle.navy,
            isPill: true,
            height: 52,
            onPressed: () {
              final name = _createNameController.text.trim();
              if (name.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter a household name'),
                  ),
                );
                return;
              }
              context.go('/dashboard');
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Created household "$name"!')),
              );
            },
          ),
        ],
      ),
    );
  }
}
