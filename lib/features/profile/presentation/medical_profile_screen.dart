import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../data/medical_profile_repository.dart';
import '../domain/medical_profile.dart';

class MedicalProfileScreen extends StatefulWidget {
  const MedicalProfileScreen({
    required this.repository,
    this.isRequiredFlow = false,
    this.onRequiredComplete,
    super.key,
  });
  final ApiMedicalProfileRepository repository;
  final bool isRequiredFlow;
  final VoidCallback? onRequiredComplete;
  @override
  State<MedicalProfileScreen> createState() => _MedicalProfileScreenState();
}

class _MedicalProfileScreenState extends State<MedicalProfileScreen> {
  late final _meds = TextEditingController(
    text: widget.repository.profile.medications,
  );
  late final _conditions = TextEditingController(
    text: widget.repository.profile.conditions,
  );
  late final _allergies = TextEditingController(
    text: widget.repository.profile.allergies,
  );
  bool _reviewed = false, _saving = false;
  @override
  void dispose() {
    _meds.dispose();
    _conditions.dispose();
    _allergies.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !widget.isRequiredFlow,
    child: Scaffold(
      appBar: AppBar(title: const Text('Ficha médica')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(22),
          children: [
            const Text(
              'Tu información de salud',
              style: TextStyle(
                color: AppColors.ink,
                fontSize: 24,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Registra lo importante para que el equipo de salud tenga contexto. La aptitud para donar siempre la determina el personal médico.',
              style: TextStyle(color: AppColors.muted, height: 1.45),
            ),
            const SizedBox(height: 22),
            _area(
              _meds,
              'Medicamentos que tomas',
              'Nombre, dosis y frecuencia. Escribe “Ninguno” si no tomas.',
            ),
            const SizedBox(height: 14),
            _area(
              _conditions,
              'Enfermedades o condiciones',
              'Incluye condiciones importantes o escribe “Ninguna”.',
            ),
            const SizedBox(height: 14),
            _area(
              _allergies,
              'Alergias',
              'Medicamentos u otras alergias; escribe “Ninguna” si aplica.',
            ),
            const SizedBox(height: 10),
            CheckboxListTile(
              value: _reviewed,
              onChanged: (v) => setState(() => _reviewed = v ?? false),
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              title: const Text(
                'Revisé la ficha médica y completé lo que aplica.',
                style: TextStyle(fontSize: 13),
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              height: 50,
              child: FilledButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        widget.isRequiredFlow
                            ? 'Guardar y terminar'
                            : 'Guardar ficha médica',
                      ),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Tu información médica es privada y está vinculada a tu cuenta.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.muted, fontSize: 12),
            ),
          ],
        ),
      ),
    ),
  );
  Widget _area(TextEditingController c, String label, String hint) =>
      TextFormField(
        controller: c,
        maxLines: 3,
        maxLength: 4000,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          alignLabelWithHint: true,
        ),
      );
  Future<void> _save() async {
    if (!_reviewed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Confirma que revisaste y completaste la ficha médica.',
          ),
        ),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      await widget.repository.save(
        MedicalProfile(
          medications: _meds.text,
          conditions: _conditions.text,
          allergies: _allergies.text,
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo guardar la ficha médica. $e')),
        );
      }
      return;
    }
    if (!mounted) return;
    if (widget.isRequiredFlow) {
      widget.onRequiredComplete?.call();
    } else {
      Navigator.pop(context, true);
    }
  }
}
