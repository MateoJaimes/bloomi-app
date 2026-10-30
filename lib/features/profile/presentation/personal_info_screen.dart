import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../data/profile_repository.dart';
import '../domain/user_profile.dart';

class PersonalInfoScreen extends StatefulWidget {
  const PersonalInfoScreen({
    required this.repository,
    this.isRequiredFlow = false,
    this.onRequiredComplete,
    super.key,
  });
  final ProfileRepository repository;
  final bool isRequiredFlow;
  final VoidCallback? onRequiredComplete;
  @override
  State<PersonalInfoScreen> createState() => _PersonalInfoScreenState();
}

class _PersonalInfoScreenState extends State<PersonalInfoScreen> {
  final _form = GlobalKey<FormState>();
  late final _first = TextEditingController(
    text: widget.repository.profile?.firstName ?? '',
  );
  late final _second = TextEditingController(
    text: widget.repository.profile?.secondName ?? '',
  );
  late final _last = TextEditingController(
    text: widget.repository.profile?.lastName ?? '',
  );
  late final _secondLast = TextEditingController(
    text: widget.repository.profile?.secondLastName ?? '',
  );
  late final _department = TextEditingController(
    text: widget.repository.profile?.department ?? '',
  );
  late final _city = TextEditingController(
    text: widget.repository.profile?.city ?? '',
  );
  late final _address = TextEditingController(
    text: widget.repository.profile?.address ?? '',
  );
  late final _phone = TextEditingController(
    text: widget.repository.profile?.phone ?? '',
  );
  DateTime? _birth;
  String? _blood;
  String? _gender;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final profile = widget.repository.profile;
    _birth = profile?.birthDate;
    _blood = profile?.bloodType;
    _gender = profile?.gender;
  }

  @override
  void dispose() {
    for (final c in [
      _first,
      _second,
      _last,
      _secondLast,
      _department,
      _city,
      _address,
      _phone,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !widget.isRequiredFlow,
    child: Scaffold(
      appBar: AppBar(title: const Text('Datos personales')),
      body: SafeArea(
        child: Form(
          key: _form,
          child: ListView(
            padding: const EdgeInsets.all(22),
            children: [
              const Text(
                'Cuéntanos sobre ti',
                style: TextStyle(
                  color: AppColors.ink,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Usaremos estos datos para personalizar tu experiencia en Bloomi.',
                style: TextStyle(color: AppColors.muted),
              ),
              const SizedBox(height: 22),
              _field(_first, 'Primer nombre'),
              const SizedBox(height: 12),
              _field(_second, 'Segundo nombre'),
              const SizedBox(height: 12),
              _field(_last, 'Primer apellido'),
              const SizedBox(height: 12),
              _field(_secondLast, 'Segundo apellido'),
              const SizedBox(height: 14),
              OutlinedButton.icon(
                onPressed: _pickDate,
                icon: const Icon(Icons.calendar_month),
                label: Text(
                  _birth == null
                      ? 'Fecha de nacimiento'
                      : '${_birth!.day}/${_birth!.month}/${_birth!.year}',
                ),
              ),
              const SizedBox(height: 12),
              _dropdown('Tipo de sangre', _blood, const [
                'A+',
                'A-',
                'B+',
                'B-',
                'AB+',
                'AB-',
                'O+',
                'O-',
                'No lo sé',
              ], (v) => setState(() => _blood = v)),
              const SizedBox(height: 12),
              _dropdown('Género', _gender, const [
                'Femenino',
                'Masculino',
                'Otro',
                'Prefiero no decirlo',
              ], (v) => setState(() => _gender = v)),
              const SizedBox(height: 12),
              _field(_department, 'Departamento'),
              const SizedBox(height: 12),
              _field(_city, 'Ciudad'),
              const SizedBox(height: 12),
              _field(_address, 'Dirección (opcional)', required: false),
              const SizedBox(height: 12),
              _field(_phone, 'Teléfono (opcional)', required: false),
              const SizedBox(height: 22),
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
                              ? 'Guardar y continuar'
                              : 'Guardar datos personales',
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  Widget _field(
    TextEditingController c,
    String label, {
    bool required = true,
  }) => TextFormField(
    controller: c,
    validator: required
        ? (v) => v == null || v.trim().isEmpty ? 'Completa este campo' : null
        : null,
    decoration: InputDecoration(labelText: label),
  );
  Widget _dropdown(
    String label,
    String? value,
    List<String> options,
    ValueChanged<String?> changed,
  ) => DropdownButtonFormField<String>(
    initialValue: options.contains(value) ? value : null,
    decoration: InputDecoration(labelText: label),
    items: options
        .map((v) => DropdownMenuItem(value: v, child: Text(v)))
        .toList(),
    onChanged: changed,
  );
  Future<void> _pickDate() async {
    final today = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _birth ?? DateTime(today.year - 18),
      firstDate: DateTime(1900),
      lastDate: today,
    );
    if (picked != null) setState(() => _birth = picked);
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate() ||
        _birth == null ||
        _blood == null ||
        _gender == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Completa los campos obligatorios, incluida tu fecha de nacimiento.',
          ),
        ),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      await widget.repository.save(
        UserProfile(
          firstName: _first.text.trim(),
          secondName: _second.text.trim(),
          lastName: _last.text.trim(),
          secondLastName: _secondLast.text.trim(),
          birthDate: _birth,
          bloodType: _blood!,
          gender: _gender!,
          department: _department.text.trim(),
          city: _city.text.trim(),
          address: _address.text.trim().isEmpty ? null : _address.text.trim(),
          phone: _phone.text.trim().isEmpty ? null : _phone.text.trim(),
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudieron guardar los datos. $e')),
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
