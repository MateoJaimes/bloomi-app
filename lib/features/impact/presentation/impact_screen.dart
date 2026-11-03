import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/bloomi_ui.dart';
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
  @override
  Widget build(BuildContext context) => BloomiPage(
    children: [
      const BloomiTitle(
        'Tu impacto',
        'El registro de tus donaciones y tu participación en Bloomi.',
      ),
      const SizedBox(height: 24),
      FutureBuilder<List<dynamic>>(
        future: _activity,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return BloomiSurface(
              child: Column(
                children: [
                  const Text(
                    'No pudimos cargar tu actividad. Intenta de nuevo.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: () => setState(() {
                      _activity = _loadActivity();
                    }),
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            );
          }
          final donations = (snapshot.data![0] as List)
              .where((row) => row['donated_at'] != null)
              .toList();
          final points =
              parseApiInt(
                (snapshot.data![1] as Map<String, dynamic>)['balance'],
              ) ??
              0;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              BloomiMetrics(
                donations: donations.length,
                points: points,
                showIcons: true,
              ),
              const SizedBox(height: 24),
              const BloomiNotice(
                title: 'Donaciones confirmadas',
                color: AppColors.mint,
                detail: 'Cada donación queda registrada tras la confirmación de la institución donde donaste.',
              ),
              const SizedBox(height: 24),
              BloomiSurface(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Historial reciente',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (donations.isEmpty)
                      const Text(
                        'Tu historia empieza con tu primera donación. Aquí verás las donaciones que confirme la institución.',
                        style: TextStyle(
                          color: AppColors.muted,
                          fontSize: 14,
                          height: 1.6,
                        ),
                      )
                    else
                      for (var i = 0; i < donations.take(5).length; i++) ...[
                        if (i > 0)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: Divider(),
                          ),
                        Text(
                          donations[i]['center_name']?.toString() ??
                              'Centro de donación',
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          [
                            donations[i]['center_city']?.toString() ?? '',
                            _date(context, donations[i]['donated_at']),
                          ].where((s) => s.isNotEmpty).join(' · '),
                          style: const TextStyle(
                            color: AppColors.muted,
                            fontSize: 14,
                          ),
                        ),
                      ],
                  ],
                ),
              ),
            ],
          );
        },
      ),
    ],
  );
  String _date(BuildContext context, dynamic value) {
    final date = DateTime.tryParse(value.toString());
    return date == null
        ? ''
        : '${date.toLocal().day}/${date.toLocal().month}/${date.toLocal().year}';
  }
}
