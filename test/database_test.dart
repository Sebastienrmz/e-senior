import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:e_senior/services/database_service.dart';
import 'package:e_senior/models/contact.dart';
import 'package:e_senior/models/message.dart';

void main() {
  sqfliteFfiInit();
  late DatabaseService service;
  Contact contact(String id, {bool sos = false}) => Contact(
    id: id,
    name: 'Contact $id',
    phone: '+33600000000',
    isEmergency: sos,
  );
  Message message(String id, String contactId, {bool fromMe = false}) =>
      Message(
        id: id,
        contactId: contactId,
        content: 'Bonjour',
        isFromMe: fromMe,
        timestamp: DateTime(2026, 1, int.parse(id)),
      );

  setUp(() {
    service = DatabaseService(
      factory: databaseFactoryFfi,
      path: inMemoryDatabasePath,
    );
  });
  tearDown(() async {
    await service.close();
  });

  test('ouvertures concurrentes : même connexion', () async {
    final databases = await Future.wait(
      List.generate(10, (_) => service.database),
    );
    expect(databases.every((db) => identical(db, databases.first)), isTrue);
  });
  test('ajout, modification, lecture et suppression', () async {
    await service.insertContact(contact('a'));
    expect((await service.getContact('a'))!.name, 'Contact a');
    await service.updateContact(contact('a').copyWith(name: 'Marie'));
    expect((await service.getAllContacts()).single.name, 'Marie');
    await service.deleteContact('a');
    expect(await service.getContact('a'), isNull);
  });
  test('un seul SOS, y compris après changement', () async {
    await service.insertContact(contact('a', sos: true));
    await service.insertContact(contact('b', sos: true));
    expect((await service.getEmergencyContact())!.id, 'b');
    expect((await service.getContact('a'))!.isEmergency, isFalse);
    await service.updateContact(contact('a', sos: true));
    expect((await service.getEmergencyContact())!.id, 'a');
  });
  test('échec d’insertion : ancien SOS et messages conservés', () async {
    await service.insertContact(contact('a', sos: true));
    await service.insertContact(contact('b'));
    await service.insertMessage(message('1', 'b'));
    await expectLater(
      service.insertContact(contact('b', sos: true)),
      throwsA(isA<DatabaseException>()),
    );
    expect((await service.getEmergencyContact())!.id, 'a');
    expect(await service.getMessages('b'), hasLength(1));
  });
  test('modification inexistante : ancien SOS conservé', () async {
    await service.insertContact(contact('a', sos: true));
    await expectLater(
      service.updateContact(contact('missing', sos: true)),
      throwsStateError,
    );
    expect((await service.getEmergencyContact())!.id, 'a');
  });
  test('limite de douze favoris appliquée en base', () async {
    for (var i = 0; i < 12; i++) {
      await service.insertContact(contact('$i'));
    }
    await expectLater(service.insertContact(contact('13')), throwsStateError);
    await service.updateContact(contact('0').copyWith(name: 'Modifié'));
    expect(await service.favoriteCount(), 12);
  });
  test('clé étrangère et suppression en cascade', () async {
    await expectLater(
      service.insertMessage(message('1', 'absent')),
      throwsA(isA<DatabaseException>()),
    );
    await service.insertContact(contact('a'));
    await service.insertMessage(message('1', 'a'));
    await service.deleteContact('a');
    expect(await service.getMessages('a'), isEmpty);
  });
  test('ordre chronologique, dernier message et non lus', () async {
    await service.insertContact(contact('a'));
    await service.insertMessage(message('2', 'a'));
    await service.insertMessage(message('1', 'a'));
    await service.insertMessage(message('3', 'a', fromMe: true));
    expect((await service.getMessages('a')).map((m) => m.id), ['1', '2', '3']);
    expect((await service.lastMessage('a'))!.id, '3');
    expect(await service.unreadCount('a'), 2);
    await service.markRead('a');
    expect(await service.totalUnread(), 0);
  });
  test('effacement des trois tables', () async {
    await service.insertContact(contact('a'));
    await service.insertMessage(message('1', 'a'));
    await service.setSetting('test', 'value');
    await service.eraseAll();
    expect(await service.getAllContacts(), isEmpty);
    expect(await service.getMessages('a'), isEmpty);
    expect(await service.getSetting('test'), isNull);
  });
}
