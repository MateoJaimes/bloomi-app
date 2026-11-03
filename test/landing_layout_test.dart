import 'package:bloomi_app/core/theme/app_theme.dart';
import 'package:bloomi_app/features/home/presentation/public_landing_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final width in [320.0, 768.0, 1440.0]) {
    testWidgets('Welcome fits $width and keeps both account actions', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(Size(width, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      var registered = false;
      var loggedIn = false;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: PublicLandingScreen(
            onLogin: () => loggedIn = true,
            onRegister: () => registered = true,
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('Registrarme'));
      expect(registered, isTrue);
      await tester.ensureVisible(find.text('Ya tengo una cuenta'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ya tengo una cuenta'));
      expect(loggedIn, isTrue);
      expect(tester.takeException(), isNull);
    });
  }
}
