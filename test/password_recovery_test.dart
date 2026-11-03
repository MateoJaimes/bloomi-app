import 'package:bloomi_app/core/network/api_client.dart';
import 'package:bloomi_app/features/auth/presentation/password_recovery_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class RecoveryApi extends ApiClient {
  final emails = <String>[];
  bool fail = false;
  @override
  Future<void> forgotPassword(String email) async {
    if (fail) throw const ApiException('No fue posible enviar el enlace.');
    emails.add(email);
  }
}

void main() {
  testWidgets(
    'requests a link, shows email confirmation and enforces resend cooldown',
    (tester) async {
      final api = RecoveryApi();
      await tester.binding.setSurfaceSize(const Size(800, 1400));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        MaterialApp(home: PasswordRecoveryScreen(api: api)),
      );
      await tester.tap(find.text('Enviar enlace'));
      await tester.pumpAndSettle();
      expect(find.text('Ingresa un correo válido'), findsOneWidget);
      expect(api.emails, isEmpty);

      await tester.enterText(find.byType(TextFormField), 'donor@example.com');
      await tester.tap(find.text('Enviar enlace'));
      await tester.pumpAndSettle();
      expect(api.emails, ['donor@example.com']);
      expect(find.text('Revisa tu correo'), findsOneWidget);
      expect(find.text('donor@example.com'), findsOneWidget);
      expect(find.byType(TextFormField), findsNothing);
      expect(
        tester
            .widget<TextButton>(
              find.widgetWithText(TextButton, 'Reenviar enlace en 60s'),
            )
            .onPressed,
        isNull,
      );

      await tester.pump(const Duration(seconds: 60));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Reenviar enlace'));
      await tester.pumpAndSettle();
      expect(api.emails, hasLength(2));
      expect(
        find.text('Solicitud enviada. Usa el enlace del correo más reciente.'),
        findsOneWidget,
      );
      await tester.tap(find.text('Cambiar correo electrónico'));
      await tester.pumpAndSettle();
      expect(find.byType(TextFormField), findsOneWidget);
      expect(find.text('donor@example.com'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets('delivery errors keep email editable for retry', (tester) async {
    final api = RecoveryApi()..fail = true;
    await tester.pumpWidget(
      MaterialApp(
        home: PasswordRecoveryScreen(
          api: api,
          initialEmail: 'donor@example.com',
        ),
      ),
    );
    await tester.tap(find.text('Enviar enlace'));
    await tester.pumpAndSettle();
    expect(find.text('No fue posible enviar el enlace.'), findsOneWidget);
    expect(find.byType(TextFormField), findsOneWidget);
    expect(find.text('Revisa tu correo'), findsNothing);
  });
}
