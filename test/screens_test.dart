import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:e_senior/models/contact.dart';
import 'package:e_senior/models/message.dart';
import 'package:e_senior/screens/home_screen.dart';
import 'package:e_senior/screens/add_contact_screen.dart';
import 'package:e_senior/screens/contact_action_screen.dart';
import 'package:e_senior/screens/conversation_screen.dart';
import 'package:e_senior/screens/settings_screen.dart';
import 'package:e_senior/services/database_service.dart';
import 'package:e_senior/theme/app_theme.dart';
import 'package:e_senior/widgets/sos_button.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final db = DatabaseService.instance;
  late Directory temp;
  final launched = <String>[];
  final contact = Contact(
    id: 'demo',
    name: 'Contact démonstration',
    phone: '+33600000000',
  );

  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfiNoIsolate;
    temp = await Directory.systemTemp.createTemp('esenior-test-');
    await databaseFactory.setDatabasesPath(temp.path);
    await initializeDateFormatting('fr');
  });
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    launched.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/url_launcher'),
          (call) async {
            if (call.method == 'canLaunch') return true;
            if (call.method == 'launch') {
              launched.add((call.arguments as Map)['url'] as String);
              return true;
            }
            return null;
          },
        );
    await db.eraseAll();
  });
  tearDownAll(() async {
    await db.close();
    await temp.delete(recursive: true);
  });

  Future<void> show(
    WidgetTester tester,
    Widget screen, {
    double scale = 1,
  }) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.runAsync(() async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(scale)),
            child: child!,
          ),
          home: screen,
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 150));
    });
    await tester.pumpAndSettle();
  }

  testWidgets('accueil vide utilisable avec grand texte', (tester) async {
    await show(tester, const HomeScreen(), scale: 1.4);
    expect(find.text('Aucun contact'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('contact et paramètres sans débordement', (tester) async {
    await tester.runAsync(
      () => db.insertContact(contact.copyWith(isEmergency: true)),
    );
    await show(tester, ContactActionScreen(contact: contact), scale: 1.4);
    expect(tester.takeException(), isNull);
    await show(tester, const SettingsScreen());
    expect(find.text('Mes contacts (1 / 12)'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('validation du formulaire sans écriture vide', (tester) async {
    await show(tester, const AddContactScreen());
    final buttons = find.byType(ElevatedButton);
    await tester.ensureVisible(buttons.last);
    await tester.tap(buttons.last);
    await tester.pumpAndSettle();
    expect(await tester.runAsync(db.favoriteCount), 0);
    expect(find.text('Entrez un nom'), findsOneWidget);
  });
  testWidgets('dates françaises et WhatsApp sans ouverture SMS', (
    tester,
  ) async {
    await tester.runAsync(() => db.insertContact(contact));
    await tester.runAsync(
      () => db.insertMessage(
        Message(
          id: 'old',
          contactId: contact.id,
          content: 'Ancien brouillon',
          isFromMe: true,
          timestamp: DateTime(2020, 1, 2),
        ),
      ),
    );
    await show(tester, ConversationScreen(contact: contact));
    expect(find.text('Ancien brouillon'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.enterText(find.byType(TextField), 'Bonjour avec des espaces');
    await tester.tap(find.byIcon(Icons.send));
    await tester.pumpAndSettle();
    await tester.runAsync(() async {
      await tester.tap(find.text('WhatsApp'));
      await Future<void>.delayed(const Duration(milliseconds: 150));
    });
    await tester.pumpAndSettle();
    expect(launched, hasLength(1));
    expect(launched.single, startsWith('https://wa.me/33600000000?text='));
    expect(launched.single, contains('Bonjour%20avec%20des%20espaces'));
    expect(
      (await tester.runAsync(() => db.getMessages(contact.id)))!,
      hasLength(2),
    );
  });
  testWidgets('SOS : appui bref annulé, maintien deux secondes requis', (
    tester,
  ) async {
    var activations = 0;
    await show(
      tester,
      Scaffold(body: SOSButton(onActivated: () => activations++)),
    );
    await tester.tap(find.byType(SOSButton));
    await tester.pumpAndSettle();
    expect(activations, 0);
    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(SOSButton)),
    );
    await tester.pump(const Duration(milliseconds: 150));
    expect(find.text('MAINTENEZ...'), findsOneWidget);
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    await tester.pump(const Duration(milliseconds: 20));
    expect(activations, 1);
    await gesture.up();
  });
}
