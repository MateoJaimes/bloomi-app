import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/bloomi_design.dart';

class PasswordRecoveryScreen extends StatefulWidget {
  const PasswordRecoveryScreen({this.initialEmail = '', this.api, super.key});
  final String initialEmail;
  final ApiClient? api;
  @override
  State<PasswordRecoveryScreen> createState() => _PasswordRecoveryScreenState();
}

class _PasswordRecoveryScreenState extends State<PasswordRecoveryScreen> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _email;
  late final ApiClient _api;
  Timer? _resendTimer;
  int _resendSeconds = 0;
  bool _sent = false;
  bool _busy = false;
  String? _error;
  String? _notice;

  @override
  void initState() {
    super.initState();
    _email = TextEditingController(text: widget.initialEmail);
    _api = widget.api ?? ApiClient();
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    _email.dispose();
    super.dispose();
  }

  void _startResendTimer() {
    _resendTimer?.cancel();
    _resendSeconds = 60;
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() => _resendSeconds--);
      if (_resendSeconds == 0) timer.cancel();
    });
  }

  Future<void> _sendEmail() async {
    if (_busy || _resendSeconds > 0) return;
    if (!_sent && !_form.currentState!.validate()) return;
    final resending = _sent;
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
      _notice = null;
    });
    try {
      await _api.forgotPassword(_email.text.trim());
      if (!mounted) return;
      setState(() {
        _sent = true;
        _notice = resending
            ? 'Solicitud enviada. Usa el enlace del correo más reciente.'
            : null;
        _startResendTimer();
      });
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) {
        setState(
          () => _error =
              'No pudimos conectar. Revisa tu conexión e inténtalo de nuevo.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BloomiFormLayout(
      title: 'Bloomi',
      formKey: _form,
      emblem: _sent
          ? Icons.mark_email_read_outlined
          : Icons.lock_reset_outlined,
      children: [
        Text(
          _sent ? 'Revisa tu correo' : '¿Olvidaste tu contraseña?',
          style: const TextStyle(
            fontSize: 27,
            fontWeight: FontWeight.w800,
            color: AppColors.ink,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          _sent
              ? 'Si hay una cuenta asociada a este correo, recibirás un enlace para crear una contraseña nueva.'
              : 'Escribe el correo de tu cuenta. Te enviaremos un enlace para crear una contraseña nueva.',
          style: const TextStyle(color: AppColors.muted, height: 1.5),
        ),
        const SizedBox(height: 24),
        if (!_sent) ...[
          TextFormField(
            controller: _email,
            readOnly: _busy,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.email],
            autocorrect: false,
            maxLength: 254,
            onFieldSubmitted: (_) => _sendEmail(),
            decoration: const InputDecoration(
              labelText: 'Correo electrónico',
              hintText: 'nombre@correo.com',
              counterText: '',
              prefixIcon: Icon(Icons.mail_outline),
            ),
            validator: (value) =>
                RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                    .hasMatch(value?.trim() ?? '')
                ? null
                : 'Ingresa un correo válido',
          ),
        ] else ...[
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.softRose,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              _email.text.trim(),
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.ink,
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Abre el enlace del correo y elige tu nueva contraseña. Después, vuelve a Bloomi para iniciar sesión.',
            style: TextStyle(color: AppColors.ink, height: 1.5),
          ),
          const SizedBox(height: 12),
          const Text(
            '¿No lo encuentras? Revisa spam o correo no deseado. El enlace es de un solo uso; abre siempre el más reciente.',
            style: TextStyle(color: AppColors.muted, height: 1.5),
          ),
        ],
        if (_error != null || _notice != null) ...[
          const SizedBox(height: 16),
          Semantics(liveRegion: true, child: Text(_error ?? _notice!)),
        ],
        const SizedBox(height: 28),
        SizedBox(
          height: 52,
          child: FilledButton(
            onPressed: _busy
                ? null
                : (_sent
                      ? () => Navigator.pop(context)
                      : (_resendSeconds > 0 ? null : _sendEmail)),
            child: _busy
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    _sent
                        ? 'Volver a iniciar sesión'
                        : (_resendSeconds > 0
                              ? 'Enviar enlace en ${_resendSeconds}s'
                              : 'Enviar enlace'),
                  ),
          ),
        ),
        if (_sent) ...[
          const SizedBox(height: 8),
          TextButton(
            onPressed: _busy || _resendSeconds > 0 ? null : _sendEmail,
            child: Text(
              _resendSeconds > 0
                  ? 'Reenviar enlace en ${_resendSeconds}s'
                  : 'Reenviar enlace',
            ),
          ),
          TextButton(
            onPressed: _busy
                ? null
                : () => setState(() {
                    _sent = false;
                    _error = null;
                    _notice = null;
                  }),
            child: const Text('Cambiar correo electrónico'),
          ),
        ] else ...[
          const SizedBox(height: 8),
          TextButton(
            onPressed: _busy ? null : () => Navigator.pop(context),
            child: const Text('Volver a iniciar sesión'),
          ),
        ],
      ],
    );
  }
}
