import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/section_page.dart';
import '../../../core/network/api_client.dart';

class CentersScreen extends StatelessWidget {
  const CentersScreen({required this.api, super.key});
  final ApiClient api;

  @override
  Widget build(BuildContext context) {
    return SectionPage(
      title: 'Centros de donación',
      subtitle: 'Encuentra dónde donar cerca de ti.',
      icon: Icons.location_on_outlined,
      child: FutureBuilder<dynamic>(
        future: api.get('/centers'),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) return const Padding(padding: EdgeInsets.all(32), child: Center(child: CircularProgressIndicator()));
          if (snapshot.hasError) return Text('No se pudieron cargar los centros. ${snapshot.error}', style: const TextStyle(color: AppColors.muted));
          final centers = snapshot.data as List;
          if (centers.isEmpty) return const Text('Aún no hay centros publicados en tu zona.', style: TextStyle(color: AppColors.muted));
          return Column(children: [
            for (final row in centers) ...[
              _CenterCard(name: row['name']?.toString() ?? 'Centro de donación', location: [row['city'], row['department']].whereType<String>().where((v) => v.isNotEmpty).join(' · '), distance: row['address']?.toString() ?? 'Consulta disponibilidad'),
              const SizedBox(height: 12),
            ],
          ]);
        },
      ),
    );
  }
}

class _CenterCard extends StatelessWidget {
  const _CenterCard({
    required this.name,
    required this.location,
    required this.distance,
  });

  final String name;
  final String location;
  final String distance;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: AppColors.softRose,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.local_hospital_outlined,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  location,
                  style: const TextStyle(color: AppColors.muted, fontSize: 12),
                ),
              ],
            ),
          ),
          Text(
            distance,
            style: const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
