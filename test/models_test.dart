import 'package:flutter_test/flutter_test.dart';
import 'package:e_senior/models/contact.dart';
import 'package:e_senior/services/phone_numbers.dart';

void main() {
  test('initiales avec espaces et nom vide', () {
    Contact c(String name) => Contact(id: 'a', name: name, phone: '');
    expect(c('  Marie  ').initials, 'M');
    expect(c(' Marie Dupont ').initials, 'MD');
    expect(c('   ').initials, '?');
  });
  test('aller-retour SQLite et suppression de photo', () {
    final c = Contact(
      id: 'a',
      name: 'Marie',
      phone: '0600000000',
      photoPath: '/photo.png',
    );
    expect(Contact.fromMap(c.toMap()).toMap(), c.toMap());
    expect(c.copyWith(clearPhoto: true).photoPath, isNull);
    expect(c.displayPhone, '06 00 00 00 00');
  });
  test('numéros WhatsApp français et internationaux', () {
    expect(whatsappNumber('06 00 00 00 00'), '33600000000');
    expect(whatsappNumber('+33 6 00 00 00 00'), '33600000000');
    expect(whatsappNumber('0033 6 00 00 00 00'), '33600000000');
    expect(whatsappNumber('+351 912345678'), '351912345678');
  });
}
