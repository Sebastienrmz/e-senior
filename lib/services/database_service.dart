import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/contact.dart';
import '../models/message.dart';

/// Stockage SQLite local des contacts et des brouillons de messages.
class DatabaseService {
  static final DatabaseService instance = DatabaseService();
  final DatabaseFactory? factory;
  final String? path;
  Future<Database>? _opening;

  // La fabrique et le chemin sont injectables pour tester sur une base isolée.
  DatabaseService({this.factory, this.path});

  Future<Database> get database =>
      _opening ??= _open().catchError((Object error) {
        _opening = null;
        throw error;
      });

  Future<Database> _open() async {
    final dbFactory = factory ?? databaseFactory;
    final dbPath =
        path ?? join(await dbFactory.getDatabasesPath(), 'e_senior_v1.db');
    return dbFactory.openDatabase(
      dbPath,
      options: OpenDatabaseOptions(
        version: 1,
        onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
        onCreate: _create,
      ),
    );
  }

  Future<void> close() async {
    final opening = _opening;
    if (opening != null) await (await opening).close();
    _opening = null;
  }

  Future<void> _create(Database db, int version) async {
    // Table contacts
    await db.execute('''
      CREATE TABLE contacts (
        id          TEXT PRIMARY KEY,
        name        TEXT NOT NULL,
        phone       TEXT NOT NULL,
        photoPath   TEXT,
        isFavorite  INTEGER NOT NULL DEFAULT 1,
        isEmergency INTEGER NOT NULL DEFAULT 0,
        sortOrder   INTEGER NOT NULL DEFAULT 0,
        createdAt   TEXT NOT NULL,
        updatedAt   TEXT NOT NULL
      )
    ''');

    // Table messages
    await db.execute('''
      CREATE TABLE messages (
        id        TEXT PRIMARY KEY,
        contactId TEXT NOT NULL,
        content   TEXT NOT NULL,
        isFromMe  INTEGER NOT NULL,
        timestamp TEXT NOT NULL,
        isRead    INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (contactId) REFERENCES contacts(id) ON DELETE CASCADE
      )
    ''');

    // Table paramètres clé/valeur
    await db.execute('''
      CREATE TABLE settings (
        key   TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');

    // Index pour accélérer les requêtes fréquentes
    await db.execute('CREATE INDEX idx_msg_contact ON messages(contactId)');
    await db.execute('CREATE INDEX idx_msg_time ON messages(timestamp DESC)');
    await db.execute('CREATE INDEX idx_contact_fav ON contacts(isFavorite)');
    await db.execute('CREATE INDEX idx_contact_sos ON contacts(isEmergency)');
  }

  // ═══════════════════════════════════════════════════════════════════
  //  CONTACTS
  // ═══════════════════════════════════════════════════════════════════

  /// Contacts favoris triés pour l’accueil.
  Future<List<Contact>> getFavorites() async {
    final db = await database;
    final rows = await db.query(
      'contacts',
      where: 'isFavorite = 1',
      orderBy: 'sortOrder ASC, name COLLATE NOCASE ASC',
    );
    return rows.map(Contact.fromMap).toList();
  }

  /// Tous les contacts.
  Future<List<Contact>> getAllContacts() async {
    final db = await database;
    final rows = await db.query(
      'contacts',
      orderBy: 'sortOrder ASC, name COLLATE NOCASE ASC',
    );
    return rows.map(Contact.fromMap).toList();
  }

  /// Contact choisi pour le bouton SOS.
  Future<Contact?> getEmergencyContact() async {
    final db = await database;
    final rows = await db.query('contacts', where: 'isEmergency = 1', limit: 1);
    return rows.isEmpty ? null : Contact.fromMap(rows.first);
  }

  /// Un contact par ID.
  Future<Contact?> getContact(String id) async {
    final db = await database;
    final rows = await db.query('contacts', where: 'id = ?', whereArgs: [id]);
    return rows.isEmpty ? null : Contact.fromMap(rows.first);
  }

  /// Nombre de contacts favoris, limité à douze.
  Future<int> favoriteCount() async {
    final db = await database;
    final r = await db.rawQuery(
      'SELECT COUNT(*) AS c FROM contacts WHERE isFavorite = 1',
    );
    return (r.first['c'] as int?) ?? 0;
  }

  Future<void> _checkFavoriteLimit(Transaction txn, Contact contact) async {
    if (!contact.isFavorite) return;
    final rows = await txn.rawQuery(
      'SELECT COUNT(*) AS c FROM contacts WHERE isFavorite = 1 AND id != ?',
      [contact.id],
    );
    if ((rows.first['c'] as int) >= 12) {
      throw StateError('Maximum de 12 contacts favoris atteint');
    }
  }

  /// Le changement du contact SOS et l'écriture réussissent ensemble.
  Future<void> insertContact(Contact contact) async {
    final db = await database;
    await db.transaction((txn) async {
      await _checkFavoriteLimit(txn, contact);
      if (contact.isEmergency) {
        await txn.update('contacts', {
          'isEmergency': 0,
        }, where: 'isEmergency = 1');
      }
      await txn.insert('contacts', contact.toMap());
    });
  }

  Future<void> updateContact(Contact contact) async {
    final db = await database;
    await db.transaction((txn) async {
      await _checkFavoriteLimit(txn, contact);
      if (contact.isEmergency) {
        await txn.update(
          'contacts',
          {'isEmergency': 0},
          where: 'isEmergency = 1 AND id != ?',
          whereArgs: [contact.id],
        );
      }
      final count = await txn.update(
        'contacts',
        contact.toMap(),
        where: 'id = ?',
        whereArgs: [contact.id],
      );
      if (count != 1) throw StateError('Contact introuvable');
    });
  }

  /// Les messages sont supprimés par la clé étrangère ON DELETE CASCADE.
  Future<void> deleteContact(String id) async {
    final db = await database;
    await db.delete('contacts', where: 'id = ?', whereArgs: [id]);
  }

  // ═══════════════════════════════════════════════════════════════════
  //  MESSAGES
  // ═══════════════════════════════════════════════════════════════════

  /// Messages d'une conversation, triés chronologiquement.
  Future<List<Message>> getMessages(String contactId) async {
    final db = await database;
    final rows = await db.query(
      'messages',
      where: 'contactId = ?',
      whereArgs: [contactId],
      orderBy: 'timestamp ASC',
    );
    return rows.map(Message.fromMap).toList();
  }

  /// Dernier message d'un contact (pour la liste des conversations).
  Future<Message?> lastMessage(String contactId) async {
    final db = await database;
    final rows = await db.query(
      'messages',
      where: 'contactId = ?',
      whereArgs: [contactId],
      orderBy: 'timestamp DESC',
      limit: 1,
    );
    return rows.isEmpty ? null : Message.fromMap(rows.first);
  }

  /// Nombre de messages non lus pour un contact.
  Future<int> unreadCount(String contactId) async {
    final db = await database;
    final r = await db.rawQuery(
      'SELECT COUNT(*) AS c FROM messages WHERE contactId = ? AND isFromMe = 0 AND isRead = 0',
      [contactId],
    );
    return (r.first['c'] as int?) ?? 0;
  }

  /// Nombre total de messages non lus.
  Future<int> totalUnread() async {
    final db = await database;
    final r = await db.rawQuery(
      'SELECT COUNT(*) AS c FROM messages WHERE isFromMe = 0 AND isRead = 0',
    );
    return (r.first['c'] as int?) ?? 0;
  }

  /// Insérer un message.
  Future<void> insertMessage(Message m) async {
    final db = await database;
    await db.insert('messages', m.toMap());
  }

  /// Marquer tous les messages d'un contact comme lus.
  Future<void> markRead(String contactId) async {
    final db = await database;
    await db.update(
      'messages',
      {'isRead': 1},
      where: 'contactId = ? AND isFromMe = 0 AND isRead = 0',
      whereArgs: [contactId],
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  //  PARAMÈTRES
  // ═══════════════════════════════════════════════════════════════════

  Future<String?> getSetting(String key) async {
    final db = await database;
    final rows = await db.query('settings', where: 'key = ?', whereArgs: [key]);
    return rows.isEmpty ? null : rows.first['value'] as String;
  }

  Future<void> setSetting(String key, String value) async {
    final db = await database;
    await db.insert('settings', {
      'key': key,
      'value': value,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // ═══════════════════════════════════════════════════════════════════
  //  EFFACEMENT LOCAL
  // ═══════════════════════════════════════════════════════════════════

  /// Efface les tables de la base locale dans une transaction.
  Future<void> eraseAll() async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('messages');
      await txn.delete('contacts');
      await txn.delete('settings');
    });
  }
}
