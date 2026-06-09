import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../constants/app_colors.dart';
import '../../models/blood_bank_model.dart';
import '../../services/api_service.dart';
import '../../services/blood_bank_service.dart';
import '../../widgets/cards/blood_bank_card.dart';
import '../../widgets/common/app_loader.dart';

final bloodBankServiceProvider =
    Provider<BloodBankService>((ref) => BloodBankService(ref.watch(apiServiceProvider)));

final bloodBanksListProvider = FutureProvider.autoDispose<List<BloodBankModel>>((ref) {
  return ref.watch(bloodBankServiceProvider).fetchAll();
});

/// Blood banks only — no labs tab.
class BloodBanksListScreen extends ConsumerWidget {
  const BloodBanksListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(bloodBanksListProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Blood Banks',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1E293B),
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1E293B),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: async.when(
        loading: () => const AppLoader(),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(e.toString(), textAlign: TextAlign.center),
          ),
        ),
        data: (list) {
          if (list.isEmpty) {
            return Center(
              child: Text(
                'No blood banks found',
                style: GoogleFonts.poppins(color: AppColors.textSecondary),
              ),
            );
          }
          return RefreshIndicator(
            color: AppColors.logoTeal,
            onRefresh: () async => ref.invalidate(bloodBanksListProvider),
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              itemCount: list.length,
              itemBuilder: (_, i) => BloodBankCard(bank: list[i]),
            ),
          );
        },
      ),
    );
  }
}
