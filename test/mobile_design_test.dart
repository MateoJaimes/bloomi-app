import 'dart:io';
import 'dart:ui' as ui;

import 'package:bloomi_app/app/app_shell.dart';
import 'package:bloomi_app/core/network/api_client.dart';
import 'package:bloomi_app/core/theme/app_theme.dart';
import 'package:bloomi_app/core/widgets/bloomi_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

class DesignApi extends ApiClient {
  int centerRequests = 0;
  bool failCenters = false;
  bool empty = false;
  @override
  bool get hasSession => true;
  @override
  Future<void> restoreSession() async {}
  @override
  Future<dynamic> get(String path, {Map<String, String>? query}) async {
    switch (path) {
      case '/me':
        return {
          'first_name': 'María',
          'second_name': 'Isabel',
          'last_name': 'García',
          'second_last_name': 'López',
          'birth_date': '1995-06-12',
          'blood_type': 'O+',
          'gender': 'Femenino',
          'department': 'Cundinamarca',
          'city': 'Bogotá',
        };
      case '/me/medical':
        return {
          'medications': 'Ninguno',
          'conditions': 'Ninguna registrada',
          'allergies': 'Penicilina',
          'is_completed': true,
        };
      case '/me/questionnaire':
        return {'active': null};
      case '/me/points':
        return {'balance': 320};
      case '/me/redemptions':
        return [];
      case '/rewards':
        return empty
            ? []
            : [
                {
                  'id': 'coffee',
                  'name': 'Café para compartir',
                  'description': 'Disfruta una pausa en un lugar aliado.',
                  'points_cost': 150,
                },
                {
                  'id': 'wellness',
                  'name': 'Experiencia de bienestar',
                  'description': 'Un momento para cuidar también de ti.',
                  'points_cost': 400,
                },
              ];
      case '/me/donations':
        return empty
            ? []
            : [
                {
                  'donated_at': '2026-10-12T12:00:00Z',
                  'center_name': 'Hemocentro Distrital',
                  'center_city': 'Bogotá',
                },
                {
                  'donated_at': '2026-09-12T12:00:00Z',
                  'center_name': 'Banco de Sangre Medellín',
                  'center_city': 'Medellín',
                },
              ];
      case '/centers':
        centerRequests++;
        if (failCenters) throw const ApiException('offline');
        return empty
            ? []
            : [
                {
                  'name': 'Hemocentro Distrital',
                  'city': 'Bogotá',
                  'department': 'Cundinamarca',
                  'address': 'Carrera 7 # 32-12',
                },
                {
                  'name': 'Banco de Sangre Medellín',
                  'city': 'Medellín',
                  'department': 'Antioquia',
                  'address': 'Calle 50 # 40-20, edificio de atención al donante, piso 2',
                },
              ];
      default:
        return [];
    }
  }
}

void main() {
  setUpAll(() async {
    final font = FontLoader('Nunito')
      ..addFont(rootBundle.load('assets/fonts/Nunito.ttf'));
    await font.load();
    final material = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await material.load();
  });
  Future<void> mount(
    WidgetTester tester,
    DesignApi api,
    double width, {
    double scale = 1,
  }) async {
    await tester.binding.setSurfaceSize(Size(width, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(scale)),
          child: child!,
        ),
        home: RepaintBoundary(
          key: const ValueKey('capture'),
          child: AppShell(api: api),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> capture(WidgetTester tester, String name) async {
    if (!const bool.fromEnvironment('BLOOMI_CAPTURE_DESIGN')) return;
    final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(const ValueKey('capture')),
    );
    await tester.runAsync(() async {
      final shot = await boundary.toImage();
      final bytes = await shot.toByteData(format: ui.ImageByteFormat.png);
      await File('design/sleek/implemented-$name.png')
          .writeAsBytes(bytes!.buffer.asUint8List());
      shot.dispose();
    });
  }

  for (final width in [320.0, 390.0, 1024.0]) {
    testWidgets('Donor tabs fit $width with live data and center search', (
      tester,
    ) async {
      final api = DesignApi();
      await mount(tester, api, width);
      expect(find.text('Hola, María García'), findsOneWidget);
      expect(tester.takeException(), isNull);
      if (width == 390) await capture(tester, 'home');
      await tester.tap(find.text('Buscar centros'));
      await tester.pumpAndSettle();
      expect(find.text('Hemocentro Distrital'), findsOneWidget);
      if (width == 390) await capture(tester, 'centers');
      final requests = api.centerRequests;
      await tester.enterText(find.byType(TextField), 'medellin');
      await tester.pumpAndSettle();
      expect(find.text('Hemocentro Distrital'), findsNothing);
      expect(find.text('Banco de Sangre Medellín'), findsOneWidget);
      expect(api.centerRequests, requests);
      await tester.enterText(find.byType(TextField), 'no-existe');
      await tester.pumpAndSettle();
      expect(find.text('No encontramos coincidencias'), findsOneWidget);
      await tester.tap(find.byTooltip('Canjes'));
      await tester.pumpAndSettle();
      expect(find.text('320 pts'), findsOneWidget);
      expect(find.text('Faltan 80 pts'), findsOneWidget);
      if (width == 390) await capture(tester, 'rewards');
      await tester.tap(find.text('Canjear'));
      await tester.pumpAndSettle();
      expect(find.text('Confirmar canje'), findsOneWidget);
      await tester.tap(find.text('Ahora no'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Impacto'));
      await tester.pumpAndSettle();
      expect(find.text('Historial reciente'), findsOneWidget);
      if (width == 390) await capture(tester, 'impact');
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets('Large text remains usable at narrow width', (tester) async {
    await mount(tester, DesignApi(), 320, scale: 1.6);
    expect(tester.takeException(), isNull);
    for (final tab in ['Centros', 'Canjes', 'Impacto']) {
      await tester.tap(find.byTooltip(tab));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }
  });
  testWidgets('Center errors retry, empty content gives direction', (
    tester,
  ) async {
    final api = DesignApi()..failCenters = true;
    await mount(tester, api, 390);
    await tester.tap(find.byTooltip('Centros'));
    await tester.pumpAndSettle();
    expect(find.text('Reintentar'), findsOneWidget);
    api.failCenters = false;
    api.empty = true;
    await tester.tap(find.text('Reintentar'));
    await tester.pumpAndSettle();
    expect(find.text('Pronto habrá más lugares para donar'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'Floating navigation follows scrolling, keeps tabs, and header scrolls with content',
    (tester) async {
      final api = DesignApi();
      await mount(tester, api, 390);
      await tester.binding.setSurfaceSize(const Size(390, 760));
      await tester.pumpAndSettle();
      final nav = find.byKey(const ValueKey('floating-navigation'));
      final header = find.byKey(const ValueKey('home-header'));
      expect(find.byType(BloomiLogo), findsNothing);
      expect(find.byIcon(Icons.smart_toy_outlined), findsOneWidget);
      AnimatedContainer bar() => tester.widget<AnimatedContainer>(nav);
      expect(bar().constraints!.maxHeight, 68);
      expect((bar().margin! as EdgeInsets).bottom, 20);
      expect(find.byType(ProgressiveScrollBlur), findsOneWidget);
      expect(
        tester.getCenter(find.byTooltip('Datos personales')).dx,
        lessThan(tester.getCenter(find.text('Bloomi')).dx),
      );
      expect(
        tester.getCenter(find.byTooltip('Cerrar sesión')).dx,
        greaterThan(tester.getCenter(find.text('Bloomi')).dx),
      );
      final initialList = tester.widget<ListView>(find.byType(ListView).first);
      initialList.controller!.jumpTo(1);
      await tester.pumpAndSettle();
      expect(find.byType(ProgressiveScrollBlur), findsOneWidget);
      initialList.controller!.jumpTo(2);
      await tester.pumpAndSettle();
      expect(find.byType(ProgressiveScrollBlur), findsNWidgets(2));
      initialList.controller!.jumpTo(0);
      await tester.pumpAndSettle();
      await capture(tester, 'home-floating');
      expect(header, findsOneWidget);
      // Drag inside the fixed bottom blur, outside the floating capsule.
      await tester.dragFrom(const Offset(120, 640), const Offset(0, -230));
      await tester.pumpAndSettle();
      expect(bar().constraints!.maxHeight, 52);
      expect((bar().margin! as EdgeInsets).bottom, 28);
      expect(header.hitTestable(), findsNothing);
      expect(find.byType(ProgressiveScrollBlur), findsNWidgets(2));
      await capture(tester, 'home-collapsed');
      final list = tester.widget<ListView>(find.byType(ListView).first);
      final savedOffset = list.controller!.offset;
      expect(savedOffset, greaterThan(1));
      await tester.dragFrom(const Offset(120, 320), const Offset(0, 50));
      await tester.pumpAndSettle();
      expect(bar().constraints!.maxHeight, 68);
      await tester.dragFrom(const Offset(120, 500), const Offset(0, -60));
      await tester.pumpAndSettle();
      expect(bar().constraints!.maxHeight, 52);
      final retainedOffset = list.controller!.offset;
      await tester.tap(find.byTooltip('Chatbot'));
      await tester.pumpAndSettle();
      expect(bar().constraints!.maxHeight, 68);
      expect(header, findsNothing);
      expect(find.text('Asistente Bloomi'), findsOneWidget);
      await tester.tap(
        find.widgetWithText(ActionChip, '¿Cómo uso mis puntos?'),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('Elige una y confirma'), findsOneWidget);
      await capture(tester, 'chat');
      await tester.tap(find.byTooltip('Inicio'));
      await tester.pumpAndSettle();
      expect(header.hitTestable(), findsNothing);
      expect(
        tester.widget<ListView>(find.byType(ListView).first).controller!.offset,
        closeTo(retainedOffset, 1),
      );
      await tester.tap(find.byTooltip('Chatbot'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Elige una y confirma'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('Capsule margin adds to the bottom safe area', (tester) async {
    tester.view.padding = FakeViewPadding(
      bottom: 34 * tester.view.devicePixelRatio,
    );
    addTearDown(tester.view.resetPadding);
    await mount(tester, DesignApi(), 390);
    final bar = tester.widget<AnimatedContainer>(
      find.byKey(const ValueKey('floating-navigation')),
    );
    expect((bar.margin! as EdgeInsets).bottom, 54);
    expect((bar.margin! as EdgeInsets).left, 20);
    expect(tester.takeException(), isNull);
  });
}
