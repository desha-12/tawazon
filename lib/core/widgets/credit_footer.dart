import 'package:flutter/material.dart';

import '../constants/credits.dart';
import '../theme/app_colors.dart';

class CreditFooter extends StatelessWidget {
  const CreditFooter({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          AppCredits.developedBy,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.frost.withValues(alpha: 0.85),
            fontSize: compact ? 12 : 13,
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          AppCredits.faculty,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.mint,
            fontSize: compact ? 12 : 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
