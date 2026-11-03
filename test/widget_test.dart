import 'package:bloomi_app/app/bloomi_app.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

void main() {
  testWidgets('Bloomi opens its welcome screen', (tester) async {
    FlutterSecureStorage.setMockInitialValues({});
    await tester.pumpWidget(const BloomiApp());
    await tester.pumpAndSettle();
    expect(find.text('Bloomi'), findsOneWidget);
    expect(find.text('Registrarme'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
