import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class SectionPage extends StatelessWidget {
  const SectionPage({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.child,
    super.key,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(22, 27, 22, 124),
      children: [
        Row(
          children: [
            Icon(icon, color: AppColors.primary, size: 25),
            const SizedBox(width: 9),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: AppColors.ink,
                  fontWeight: FontWeight.w800,
                  fontSize: 22,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(subtitle, style: const TextStyle(color: AppColors.muted)),
        const SizedBox(height: 23),
        child,
      ],
    );
  }
}
