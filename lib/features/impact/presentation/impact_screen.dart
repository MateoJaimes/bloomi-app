import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/section_page.dart';
import '../../../core/network/api_client.dart';

class ImpactScreen extends StatefulWidget {
  const ImpactScreen({required this.api, super.key});
  final ApiClient api;

  @override
  State<ImpactScreen> createState() => _ImpactScreenState();
}

class _ImpactScreenState extends State<ImpactScreen> {
  late Future<List<dynamic>> _activity;

  @override
  void initState() {
    super.initState();
    _activity = _loadActivity();
  }

  Future<List<dynamic>> _loadActivity() => Future.wait([
    widget.api.get('/me/donations'),
    widget.api.get('/me/points'),
  ]);

  void _retry() => setState(() => _activity = _loadActivity());

  @override
  Widget build(BuildContext context) {
    return SectionPage(
      title: 'Tu impacto',
      subtitle: 'Cada gesto cuenta. Tu historia empieza aquí.',
      icon: Icons.favorite_border,
      child: FutureBuilder<List<dynamic>>(
        future: _activity,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError) return Column(mainAxisSize: MainAxisSize.min, children: [
            Text('No pudimos cargar tu actividad. ${snapshot.error}', textAlign: TextAlign.center, style: const TextStyle(color: AppColors.muted)),
            const SizedBox(height: 10),
            OutlinedButton.icon(onPressed: _retry, icon: const Icon(Icons.refresh_rounded), label: const Text('Reintentar')),
          ]);
          final donations = (snapshot.data![0] as List).where((row) => (row as Map<String, dynamic>)['donated_at'] != null).length;
          final points = parseApiInt((snapshot.data![1] as Map<String, dynamic>)['balance']) ?? 0;
          return Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(color: AppColors.softRose, borderRadius: BorderRadius.circular(20)),
            child: Column(children: [
              const Icon(Icons.volunteer_activism, color: AppColors.primary, size: 40),
              const SizedBox(height: 12),
              Text(donations == 0 ? 'Tu primera donación está por venir' : 'Tu historia de impacto', textAlign: TextAlign.center, style: const TextStyle(color: AppColors.ink, fontWeight: FontWeight.w700, fontSize: 18)),
              const SizedBox(height: 8),
              Text('$donations donaciones · $points puntos disponibles', textAlign: TextAlign.center, style: const TextStyle(color: AppColors.muted, height: 1.4)),
              const SizedBox(height: 5),
              const Text('El equipo de la institución confirma las donaciones registradas.', textAlign: TextAlign.center, style: TextStyle(color: AppColors.muted, height: 1.4)),
            ]),
          );
        },
      ),
    );
  }
}
