import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/credit_footer.dart';
import '../../../services/locale_controller.dart';

class AboutScreen extends ConsumerWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    return Scaffold(
      appBar: AppBar(title: Text(s.about)),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
        child: Column(
          children: [
            Image.asset(AppAssets.logo, height: 128),
            const SizedBox(height: 16),
            Text(s.appName, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 6),
            Text(s.tagline, style: const TextStyle(color: AppColors.mint, fontWeight: FontWeight.w600)),
            const SizedBox(height: 18),
            Text(s.aboutBody, textAlign: TextAlign.center, style: const TextStyle(height: 1.45, color: AppColors.muted)),
            const Spacer(),
            const CreditFooter(),
          ],
        ),
      ),
    );
  }
}
