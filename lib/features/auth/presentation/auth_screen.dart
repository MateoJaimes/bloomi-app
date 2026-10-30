import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/network/api_client.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({
    required this.onAuthenticated,
    this.initiallyRegistering = true,
    super.key,
  });

  final Future<void> Function(BuildContext context, bool isRegistering, String email, String password, String document, String documentType) onAuthenticated;
  final bool initiallyRegistering;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _document = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  String _documentType = 'cc';
  late bool _isRegistering;
  bool _hidePassword = true;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _isRegistering = widget.initiallyRegistering;
  }

  @override
  void dispose() {
    _document.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
            children: [
              Container(
                width: 58,
                height: 58,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: AppColors.softRose,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.local_florist,
                  color: AppColors.primary,
                  size: 30,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                _isRegistering ? 'Únete a Bloomi' : 'Qué bueno verte',
                style: const TextStyle(
                  color: AppColors.ink,
                  fontSize: 27,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                _isRegistering
                    ? 'Crea tu cuenta para comenzar tu camino como donante.'
                    : 'Inicia sesión para continuar tu camino como donante.',
                style: const TextStyle(color: AppColors.muted, height: 1.45),
              ),
              const SizedBox(height: 26),
              if (_isRegistering) ...[
              DropdownButtonFormField<String>(
                initialValue: _documentType,
                decoration: const InputDecoration(labelText: 'Tipo de documento'),
                items: const [DropdownMenuItem(value: 'cc', child: Text('Cédula de ciudadanía')), DropdownMenuItem(value: 'ce', child: Text('Cédula de extranjería')), DropdownMenuItem(value: 'passport', child: Text('Pasaporte')), DropdownMenuItem(value: 'other', child: Text('Otro'))],
                onChanged: (value) { if (value != null) setState(() => _documentType = value); },
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _document,
                keyboardType: TextInputType.text,
                validator: (value) => value == null || value.trim().length < 5
                    ? 'Ingresa un documento válido'
                    : null,
                decoration: const InputDecoration(
                  labelText: 'Número de documento',
                  hintText: 'Ej. 1234567890',
                  prefixIcon: Icon(Icons.badge_outlined),
                ),
              ),
              ],
              const SizedBox(height: 16),
              TextFormField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                validator: _validateEmail,
                decoration: const InputDecoration(labelText: 'Correo electrónico', hintText: 'nombre@correo.com', prefixIcon: Icon(Icons.mail_outline)),
              ),
              if (_isRegistering) ...[
                const SizedBox(height: 0),
              ],
              const SizedBox(height: 16),
              TextFormField(
                controller: _password,
                obscureText: _hidePassword,
                validator: (value) => value == null || value.length < (_isRegistering ? 10 : 1)
                    ? (_isRegistering ? 'Usa al menos 10 caracteres' : 'Ingresa tu contraseña')
                    : null,
                decoration: InputDecoration(
                  labelText: 'Contraseña',
                  hintText: _isRegistering ? 'Mínimo 10 caracteres' : 'Tu contraseña',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    onPressed: () =>
                        setState(() => _hidePassword = !_hidePassword),
                    icon: Icon(
                      _hidePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 52,
                child: FilledButton(
                  onPressed: _submitting ? null : _submit,
                  child: _submitting ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : Text(
                    _isRegistering ? 'Crear cuenta' : 'Iniciar sesión',
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () =>
                    setState(() => _isRegistering = !_isRegistering),
                child: Text(
                  _isRegistering
                      ? '¿Ya tienes cuenta? Inicia sesión'
                      : '¿Aún no tienes cuenta? Regístrate',
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Tu cuenta y tus datos se guardan de forma segura en Bloomi.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.muted,
                  fontSize: 12,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String? _validateEmail(String? value) {
    if (value == null ||
        !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value.trim())) {
      return 'Ingresa un correo válido';
    }
    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    try {
      await widget.onAuthenticated(context, _isRegistering, _email.text.trim(), _password.text, _document.text.trim(), _documentType);
    } on ApiException catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.message)));
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No se pudo conectar. Verifica que la API esté encendida.')));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }
}
