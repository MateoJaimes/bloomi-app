import 'dart:io';
import 'dart:ui' as ui;

import 'package:bloomi_app/core/theme/app_theme.dart';
import 'package:bloomi_app/features/auth/presentation/auth_screen.dart';
import 'package:bloomi_app/features/auth/presentation/password_recovery_screen.dart';
import 'package:bloomi_app/features/home/presentation/public_landing_screen.dart';
import 'package:bloomi_app/features/profile/data/profile_repository.dart';
import 'package:bloomi_app/features/profile/data/medical_profile_repository.dart';
import 'package:bloomi_app/features/profile/presentation/personal_info_screen.dart';
import 'package:bloomi_app/features/profile/presentation/medical_profile_screen.dart';
import 'package:bloomi_app/features/questionnaire/data/health_questionnaire_repository.dart';
import 'package:bloomi_app/features/questionnaire/presentation/health_questionnaire_screen.dart';
import 'package:bloomi_app/features/rewards/data/rewards_repository.dart';
import 'package:bloomi_app/features/rewards/presentation/rewards_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'mobile_design_test.dart' show DesignApi;

class FormApi extends DesignApi {
  @override
  Future<dynamic> patch(String path, {Object? body}) async => {};
  @override
  Future<void> forgotPassword(String email) async {}
}

void main() {
  setUpAll(() async {
    await (FontLoader(
      'Nunito',
    )..addFont(rootBundle.load('assets/fonts/Nunito.ttf'))).load();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  });
  Future<void> mount(
    WidgetTester tester,
    Widget screen, {
    double width = 390,
  }) async {
    await tester.binding.setSurfaceSize(Size(width, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      RepaintBoundary(
        key: const ValueKey('preview'),
        child: MaterialApp(
          key: UniqueKey(),
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          home: Scaffold(body: screen),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> shot(WidgetTester tester, String name) async {
    if (!const bool.fromEnvironment('BLOOMI_CAPTURE_DESIGN')) return;
    await tester.runAsync(() async {
      final boundary = tester.renderObject<RenderRepaintBoundary>(
        find.byKey(const ValueKey('preview')),
      );
      final image = await boundary.toImage();
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      final directory = Directory('design/implementacion-v2');
      await directory.create(recursive: true);
      await File('${directory.path}/$name.png')
          .writeAsBytes(bytes!.buffer.asUint8List());
      image.dispose();
    });
  }

  testWidgets(
    'Access screens fit and preserve validation and recovery states',
    (tester) async {
      await mount(
        tester,
        PublicLandingScreen(onLogin: () {}, onRegister: () {}),
      );
      await shot(tester, '01-bienvenida');
      await mount(
        tester,
        AuthScreen(
          initiallyRegistering: false,
          onAuthenticated: (
            context,
            registering,
            email,
            password,
            document,
            type,
          ) async {},
        ),
      );
      await shot(tester, '02-login');
      await tester.ensureVisible(find.text('Iniciar sesión'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Iniciar sesión'));
      await tester.pumpAndSettle();
      expect(find.text('Ingresa un correo válido'), findsOneWidget);
      await mount(
        tester,
        AuthScreen(
          key: const ValueKey('register'),
          onAuthenticated: (
            context,
            registering,
            email,
            password,
            document,
            type,
          ) async {},
        ),
      );
      await shot(tester, '03-registro');
      await mount(
        tester,
        PasswordRecoveryScreen(
          api: FormApi(),
          initialEmail: 'donor@example.com',
        ),
      );
      await shot(tester, '04-recuperar');
      await tester.ensureVisible(find.text('Enviar enlace'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Enviar enlace'));
      await tester.pumpAndSettle();
      await shot(tester, '08-correo-enviado');
      expect(find.text('Revisa tu correo'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets(
    'Personal and medical forms save existing data with keyboard open',
    (tester) async {
      final api = FormApi();
      final profile = ApiProfileRepository(api);
      await profile.load();
      var saved = false;
      await mount(
        tester,
        PersonalInfoScreen(
          repository: profile,
          isRequiredFlow: true,
          onRequiredComplete: () => saved = true,
        ),
        width: 320,
      );
      await shot(tester, '05-datos-personales');
      // The editable form keeps its real profile values.
      expect(find.text('María'), findsOneWidget);
      tester.view.viewInsets = FakeViewPadding(
        bottom: 280 * tester.view.devicePixelRatio,
      );
      addTearDown(tester.view.resetViewInsets);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Guardar y continuar'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Guardar y continuar'));
      await tester.pump();
      expect(saved, isTrue);
      tester.view.resetViewInsets();
      final medical = ApiMedicalProfileRepository(api);
      await medical.load();
      saved = false;
      await mount(
        tester,
        MedicalProfileScreen(
          repository: medical,
          isRequiredFlow: true,
          onRequiredComplete: () => saved = true,
        ),
      );
      await shot(tester, '06-ficha-medica');
      await tester.ensureVisible(find.byType(CheckboxListTile));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(CheckboxListTile));
      await tester.ensureVisible(find.text('Guardar y terminar'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Guardar y terminar'));
      await tester.pump();
      expect(saved, isTrue);
      expect(medical.profile.allergies, 'Penicilina');
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'Questionnaire restores answers and render fits; redemption confirms real balance',
    (tester) async {
      final questionnaire = SessionHealthQuestionnaireRepository();
      await questionnaire.submitAnswers({
        questionnaire.questions.first.id: true,
      });
      await mount(tester, HealthQuestionnaireScreen(repository: questionnaire));
      await shot(tester, '07-cuestionario');
      expect(
        tester
            .widget<SegmentedButton<bool>>(
              find.byType(SegmentedButton<bool>).first,
            )
            .selected,
        {true},
      );
      final rewards = DemoRewardsRepository();
      await mount(tester, RewardsScreen(repository: rewards));
      await tester.tap(find.text('Canjear').first);
      await tester.pumpAndSettle();
      await shot(tester, '14-confirmar-canje');
      expect(find.text('Saldo después del canje: 400 puntos'), findsOneWidget);
      await tester.tap(find.text('Sí, canjear'));
      await tester.pumpAndSettle();
      expect(rewards.pointsBalance, 400);
      expect(find.text('Canjeado'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
