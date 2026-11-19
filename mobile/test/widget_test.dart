import 'package:flutter_test/flutter_test.dart';
import 'package:rollercoaster_mobile/main.dart';
import 'package:rollercoaster_mobile/providers/app_state.dart';
import 'package:rollercoaster_mobile/services/storage_service.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('App renders main navigation shell', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final storage = StorageService();
    await storage.init();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AppState(storage: storage)),
        ],
        child: const RollercoasterApp(),
      ),
    );

    expect(find.text('Rollercoaster'), findsOneWidget);
    expect(find.text('Overview'), findsOneWidget);
    expect(find.text('Watchlist'), findsOneWidget);
    expect(find.text('Quick Report'), findsOneWidget);
  });
}
