import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/bloomi_ui.dart';
import '../../../core/widgets/bloomi_design.dart';
import '../../../core/network/api_client.dart';

class CentersScreen extends StatefulWidget {
  const CentersScreen({required this.api, super.key});
  final ApiClient api;
  @override
  State<CentersScreen> createState() => _CentersScreenState();
}

class _CentersScreenState extends State<CentersScreen> {
  late Future<dynamic> _centers;
  String _query = '';
  @override
  void initState() {
    super.initState();
    _centers = widget.api.get('/centers');
  }

  String _normalize(String text) {
    const accents = 'áéíóúüñ';
    const plain = 'aeiouun';
    var result = text.toLowerCase().trim();
    for (var i = 0; i < accents.length; i++) {
      result = result.replaceAll(accents[i], plain[i]);
    }
    return result;
  }

  @override
  Widget build(BuildContext context) => BloomiPage(
    quietHeader: true,
    children: [
      const BloomiTitle(
        'Centros de donación',
        'Encuentra instituciones donde puedes donar sangre.',
      ),
      const SizedBox(height: 24),
      TextField(
        onChanged: (value) => setState(() => _query = _normalize(value)),
        decoration: const InputDecoration(
          labelText: 'Buscar por ciudad o institución',
          prefixIcon: Padding(
            padding: EdgeInsets.all(14),
            child: BloomiIcon(
              'material-symbols:search-rounded',
              size: 20,
              color: AppColors.muted,
            ),
          ),
        ),
      ),
      const SizedBox(height: 24),
      FutureBuilder<dynamic>(
        future: _centers,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          if (snapshot.hasError) {
            return BloomiSurface(
              child: Column(
                children: [
                  const Text(
                    'No pudimos cargar los centros. Intenta de nuevo.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: () => setState(() {
                      _centers = widget.api.get('/centers');
                    }),
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            );
          }
          final centers = snapshot.data as List;
          final filtered = centers
              .where(
                (row) => _normalize(
                  '${row['name'] ?? ''} ${row['city'] ?? ''} ${row['department'] ?? ''}',
                ).contains(_query),
              )
              .toList();
          if (filtered.isEmpty) {
            return BloomiNotice(
              title: centers.isEmpty
                  ? 'Pronto habrá más lugares para donar'
                  : 'No encontramos coincidencias',
              detail: centers.isEmpty
                  ? 'Aún no hay centros publicados. Vuelve a consultar más adelante.'
                  : 'Prueba con otra ciudad o con el nombre de la institución.',
              icon: 'local-hospital-outline-rounded',
            );
          }
          return Column(
            children: [
              for (final row in filtered) ...[
                BloomiSurface(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const BloomiEmblem(
                        Icons.local_hospital_outlined,
                        size: 60,
                        background: AppColors.mint,
                        foreground: AppColors.mintInk,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              row['name']?.toString() ?? 'Centro de donación',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                height: 1.3,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              [row['city'], row['department']]
                                  .whereType<String>()
                                  .where((v) => v.isNotEmpty)
                                  .join(' · '),
                              style: const TextStyle(
                                color: AppColors.primaryDark,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              row['address']?.toString() ??
                                  'Dirección por confirmar',
                              style: const TextStyle(
                                color: AppColors.muted,
                                fontSize: 14,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ],
          );
        },
      ),
      const SizedBox(height: 16),
      const Text(
        'Confirma horarios y requisitos directamente con cada institución antes de acudir.',
        style: TextStyle(color: AppColors.muted, fontSize: 14, height: 1.6),
      ),
    ],
  );
}
