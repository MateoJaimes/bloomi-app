import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/bloomi_design.dart';
import '../../../core/widgets/bloomi_ui.dart';
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
    child: BloomiFormLayout(
      title: 'Ficha médica',
      showBack: !widget.isRequiredFlow,
      emblem: Icons.medical_information_outlined,
      step: widget.isRequiredFlow ? 'Paso 2 de 2' : null,
      children: [
        const Center(
          child: BloomiPill(
            'Información privada',
            color: AppColors.mint,
            foreground: AppColors.mintInk,
            icon: Icons.lock_outline,
          ),
        ),
        const SizedBox(height: 20),
        _area(
          _meds,
          'Medicamentos',
          'Nombre, dosis y frecuencia, o “Ninguno”.',
          Icons.medication_outlined,
          AppColors.blush,
          AppColors.primaryDark,
        ),
        const SizedBox(height: 16),
        _area(
          _conditions,
          'Condiciones',
          'Condiciones importantes, o “Ninguna”.',
          Icons.monitor_heart_outlined,
          AppColors.butter,
          AppColors.butterInk,
        ),
        const SizedBox(height: 16),
        _area(
          _allergies,
          'Alergias',
          'Alergias conocidas, o “Ninguna”.',
          Icons.spa_outlined,
          AppColors.lavender,
          AppColors.lavenderInk,
        ),
        const SizedBox(height: 12),
        CheckboxListTile(
          value: _reviewed,
          onChanged: (v) => setState(() => _reviewed = v ?? false),
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          title: const Text(
            'Revisé la ficha médica y completé lo que aplica.',
            style: TextStyle(fontSize: 14),
          ),
        ),
        const SizedBox(height: 18),
        FilledButton(
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
        const SizedBox(height: 16),
        const BloomiSurface(
          color: AppColors.blush,
          padding: EdgeInsets.all(14),
          child: Text(
            'La aptitud para donar la determina el personal médico del centro.',
            style: TextStyle(
              color: AppColors.primaryDark,
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ),
      ],
    ),
  );
  Widget _area(
    TextEditingController controller,
    String title,
    String hint,
    IconData icon,
    Color color,
    Color foreground,
  ) => BloomiSurface(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            BloomiEmblem(
              icon,
              size: 42,
              background: color,
              foreground: foreground,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        TextFormField(
          controller: controller,
          minLines: 1,
          maxLines: 3,
          maxLength: 4000,
          decoration: InputDecoration(
            labelText: title,
            hintText: hint,
            counterText: '',
          ),
        ),
      ],
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
