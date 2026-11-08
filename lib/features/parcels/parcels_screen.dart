import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/constants/colors.dart';
import '../../core/constants/dimensions.dart';
import '../../data/models.dart';
import '../../data/repository_provider.dart';
import '../../shared/widgets/cas_mascot_view.dart';
import '../../shared/widgets/casama_button.dart';
import '../../shared/widgets/status_chip.dart';

class ParcelsScreen extends ConsumerStatefulWidget {
  final bool initialOpenAddModal;

  const ParcelsScreen({super.key, this.initialOpenAddModal = false});

  @override
  ConsumerState<ParcelsScreen> createState() => _ParcelsScreenState();
}

class _ParcelsScreenState extends ConsumerState<ParcelsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    if (widget.initialOpenAddModal) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _showAddParcelModal(context);
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final repo = ref.watch(repositoryProvider);
    final upcomingParcels = repo.parcels
        .where((p) => p.status == ParcelStatus.expected)
        .toList();
    final historyParcels = repo.parcels
        .where((p) => p.status == ParcelStatus.received)
        .toList();

    return Scaffold(
      backgroundColor: context.scaffoldBg,
      appBar: AppBar(
        title: const Text('Parcels'),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.add,
              color: CasamaColors.primaryCoral,
              size: 28,
            ),
            onPressed: () => _showAddParcelModal(context),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
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
                Tab(text: 'Upcoming'),
                Tab(text: 'History'),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildParcelList(upcomingParcels, isHistory: false),
          _buildParcelList(historyParcels, isHistory: true),
        ],
      ),
    );
  }

  Widget _buildParcelList(List<ParcelItem> parcels, {required bool isHistory}) {
    if (parcels.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CasMascotView(
              pose: CasPose.deliveries,
              width: 140,
              height: 140,
            ),
            const SizedBox(height: 16),
            Text(
              isHistory ? 'No past parcels' : 'No upcoming deliveries!',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: context.textColor,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Add a delivery when expecting a package.',
              style: TextStyle(color: context.textSecondaryColor),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(CasamaSpacing.lg),
      itemCount: parcels.length,
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final parcel = parcels[index];
        return _ParcelCard(parcel: parcel, isHistory: isHistory);
      },
    );
  }

  void _showAddParcelModal(BuildContext context) {
    String courier = 'Shopee';
    DateTime selectedDate = DateTime.now();
    TimeOfDay selectedTime = const TimeOfDay(hour: 16, minute: 0);
    ParcelPaymentType paymentType = ParcelPaymentType.cod;
    final codController = TextEditingController(text: '350');
    final notesController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Add Expected Parcel',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: context.textColor,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Courier Dropdown
                    DropdownButtonFormField<String>(
                      initialValue: courier,
                      decoration: const InputDecoration(labelText: 'Courier'),
                      items:
                          ['Shopee', 'Lazada', 'TikTok Shop', 'FedEx', 'Other']
                              .map(
                                (c) =>
                                    DropdownMenuItem(value: c, child: Text(c)),
                              )
                              .toList(),
                      onChanged: (val) {
                        if (val != null) setModalState(() => courier = val);
                      },
                    ),
                    const SizedBox(height: 14),

                    // Date & Time Row
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.calendar_today, size: 16),
                            label: Text(
                              DateFormat('MMM dd').format(selectedDate),
                            ),
                            onPressed: () async {
                              final d = await showDatePicker(
                                context: context,
                                initialDate: selectedDate,
                                firstDate: DateTime.now(),
                                lastDate: DateTime.now().add(
                                  const Duration(days: 60),
                                ),
                              );
                              if (d != null) {
                                setModalState(() => selectedDate = d);
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.access_time, size: 16),
                            label: Text(selectedTime.format(context)),
                            onPressed: () async {
                              final t = await showTimePicker(
                                context: context,
                                initialTime: selectedTime,
                              );
                              if (t != null) {
                                setModalState(() => selectedTime = t);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Payment Type
                    Row(
                      children: [
                        Expanded(
                          child: ChoiceChip(
                            label: const Text('Cash on Delivery (COD)'),
                            selected: paymentType == ParcelPaymentType.cod,
                            onSelected: (_) => setModalState(
                              () => paymentType = ParcelPaymentType.cod,
                            ),
                            selectedColor: CasamaColors.tileParcels,
                            labelStyle: TextStyle(
                              color: paymentType == ParcelPaymentType.cod
                                  ? CasamaColors.primaryCoral
                                  : CasamaColors.ink,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ChoiceChip(
                            label: const Text('Paid Online'),
                            selected: paymentType == ParcelPaymentType.paid,
                            onSelected: (_) => setModalState(
                              () => paymentType = ParcelPaymentType.paid,
                            ),
                            selectedColor: CasamaColors.homeBg,
                            labelStyle: TextStyle(
                              color: paymentType == ParcelPaymentType.paid
                                  ? CasamaColors.homeGreen
                                  : CasamaColors.ink,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),

                    if (paymentType == ParcelPaymentType.cod) ...[
                      const SizedBox(height: 14),
                      TextField(
                        controller: codController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'COD Amount (₱)',
                          prefixText: '₱ ',
                        ),
                      ),
                    ],

                    const SizedBox(height: 14),
                    TextField(
                      controller: notesController,
                      decoration: const InputDecoration(
                        labelText: 'Instructions / Notes',
                        hintText:
                            'e.g., Fragile, Leave at guard, Call on arrival',
                      ),
                    ),

                    const SizedBox(height: 20),
                    CasamaButton(
                      label: 'Save Parcel',
                      onPressed: () {
                        final arrival = DateTime(
                          selectedDate.year,
                          selectedDate.month,
                          selectedDate.day,
                          selectedTime.hour,
                          selectedTime.minute,
                        );
                        final cod = paymentType == ParcelPaymentType.cod
                            ? double.tryParse(codController.text) ?? 0.0
                            : null;

                        ref
                            .read(repositoryProvider)
                            .addParcel(
                              courier: courier,
                              arrival: arrival,
                              paymentType: paymentType,
                              codAmount: cod,
                              notes: notesController.text.trim(),
                            );
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Added expected delivery from $courier!',
                            ),
                            backgroundColor: CasamaColors.midnightNavy,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _ParcelCard extends ConsumerWidget {
  final ParcelItem parcel;
  final bool isHistory;

  const _ParcelCard({required this.parcel, required this.isHistory});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isShopee = parcel.courier.toLowerCase().contains('shopee');
    final isLazada = parcel.courier.toLowerCase().contains('lazada');

    final courierBg = isShopee
        ? const Color(0xFFFFF0EE)
        : (isLazada ? const Color(0xFFF0EFFF) : CasamaColors.softNeutral);
    final courierColor = isShopee
        ? const Color(0xFFEE4D2D)
        : (isLazada ? const Color(0xFF0F156D) : CasamaColors.ink);

    final isCod = parcel.paymentType == ParcelPaymentType.cod;
    final paymentText = isCod
        ? 'COD • ₱${parcel.codAmount?.toStringAsFixed(0) ?? '0'}'
        : 'Paid';

    return Container(
      padding: const EdgeInsets.all(CasamaSpacing.md),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: CasamaSpacing.roundedLg,
        border: Border.all(color: context.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Courier Icon / Badge
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: context.isDark
                      ? courierBg.withValues(alpha: 0.25)
                      : courierBg,
                  borderRadius: CasamaSpacing.roundedMd,
                ),
                alignment: Alignment.center,
                child: Text(
                  parcel.courier.isNotEmpty ? parcel.courier[0] : 'P',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: courierColor,
                  ),
                ),
              ),
              const SizedBox(width: 14),

              // Courier Name & Expected arrival
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      parcel.courier,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: courierColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Expected ${_formatArrival(parcel.expectedArrival)}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: context.textColor,
                      ),
                    ),
                  ],
                ),
              ),

              // Payment Status Chip
              StatusChip(
                label: paymentText,
                variant: isCod ? ChipVariant.cod : ChipVariant.paid,
              ),
            ],
          ),

          if (parcel.notes != null && parcel.notes!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              parcel.notes!,
              style: TextStyle(fontSize: 13, color: context.textSecondaryColor),
            ),
          ],

          const SizedBox(height: 14),
          Divider(height: 1, color: context.borderColor),
          const SizedBox(height: 12),

          // Bottom Row: Availability avatars & Action Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Roommate Avatars Row
              Row(
                children: [
                  ...parcel.availableMemberNames
                      .take(3)
                      .map(
                        (name) => Container(
                          margin: const EdgeInsets.only(right: 4),
                          width: 26,
                          height: 26,
                          decoration: const BoxDecoration(
                            color: CasamaColors.dustyBlue,
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            name.isNotEmpty ? name[0] : '?',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  if (parcel.availableMemberNames.length > 3)
                    Text(
                      '+${parcel.availableMemberNames.length - 3}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: CasamaColors.textSecondary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                ],
              ),

              // Action button (Matching Mockup Screen 3)
              if (!isHistory) ...[
                if (isShopee)
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: CasamaColors.primaryCoral,
                      foregroundColor: Colors.white,
                      shape: const StadiumBorder(),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      minimumSize: Size.zero,
                    ),
                    onPressed: () {
                      ref.read(repositoryProvider).receiveParcel(parcel.id);
                      _showPointsCelebrationDialog(
                        context,
                        5,
                        'Parcel Received!',
                      );
                    },
                    child: const Text(
                      'I Got It',
                      style: TextStyle(fontSize: 13),
                    ),
                  )
                else
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: CasamaColors.ink,
                      shape: const StadiumBorder(),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      minimumSize: Size.zero,
                    ),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Marked as unavailable for this delivery',
                          ),
                        ),
                      );
                    },
                    child: const Text(
                      'Mark Unavailable',
                      style: TextStyle(fontSize: 13),
                    ),
                  ),
              ] else
                const StatusChip(
                  label: 'Received',
                  variant: ChipVariant.returned,
                ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatArrival(DateTime dt) {
    final now = DateTime.now();
    if (dt.day == now.day && dt.month == now.month && dt.year == now.year) {
      return 'Today ${DateFormat('h:mm a').format(dt)}';
    }
    return DateFormat('MMM dd h:mm a').format(dt);
  }

  void _showPointsCelebrationDialog(
    BuildContext context,
    int points,
    String reason,
  ) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: CasamaSpacing.roundedXl),
          backgroundColor: CasamaColors.white,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CasMascotView(
                pose: CasPose.jumping,
                width: 120,
                height: 120,
              ),
              const SizedBox(height: 12),
              Text(
                '+$points Good Kasama Points! 🎉',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: CasamaColors.ink,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Thank you for receiving the delivery: $reason',
                style: const TextStyle(
                  color: CasamaColors.textSecondary,
                  fontSize: 13,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              CasamaButton(
                label: 'Awesome!',
                onPressed: () => Navigator.pop(ctx),
                height: 44,
              ),
            ],
          ),
        );
      },
    );
  }
}
