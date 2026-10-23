import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/contact.dart';
import '../models/message.dart';
import '../services/database_service.dart';
import '../theme/app_theme.dart';
import 'conversation_screen.dart';

/// Liste des conversations – EF3 : Messagerie Simplifiée
///
/// Affiche tous les contacts favoris avec aperçu du dernier message
/// et badge de messages non lus.
class MessagingListScreen extends StatefulWidget {
  const MessagingListScreen({super.key});

  @override
  State<MessagingListScreen> createState() => _MessagingListScreenState();
}

class _MessagingListScreenState extends State<MessagingListScreen> {
  final _db = DatabaseService.instance;
  List<Contact> _contacts = [];
  final Map<String, Message?> _lastMsgs = {};
  final Map<String, int> _unreads = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final contacts = await _db.getFavorites();
      for (final c in contacts) {
        _lastMsgs[c.id] = await _db.lastMessage(c.id);
        _unreads[c.id] = await _db.unreadCount(c.id);
      }
      if (!mounted) return;
      setState(() {
        _contacts = contacts;
        _loading = false;
      });
    } catch (e) {
      debugPrint('Erreur chargement messages: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  String _time(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inDays == 0) return DateFormat('HH:mm').format(dt);
    if (diff.inDays == 1) return 'Hier';
    if (diff.inDays < 7) return DateFormat('EEEE', 'fr').format(dt);
    return DateFormat('dd/MM/yy').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, size: AppTheme.iconMd),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _contacts.isEmpty
          ? _empty()
          : ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: _contacts.length,
              separatorBuilder: (_, __) => const Divider(height: 1, indent: 88),
              itemBuilder: (_, i) => _row(_contacts[i]),
            ),
    );
  }

  Widget _empty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.message_outlined,
            size: 80,
            color: AppTheme.primary.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 20),
          const Text(
            'Aucun message',
            style: TextStyle(
              fontSize: AppTheme.fs26,
              color: AppTheme.textMedium,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Sélectionnez un contact\npour envoyer un message',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: AppTheme.fs20,
              color: AppTheme.textLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(Contact c) {
    final last = _lastMsgs[c.id];
    final unread = _unreads[c.id] ?? 0;
    final bold = unread > 0;

    return InkWell(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ConversationScreen(contact: c)),
        );
        _load();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            _avatar(c),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nom + heure
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          c.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: AppTheme.fs22,
                            fontWeight: bold
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: AppTheme.textDark,
                          ),
                        ),
                      ),
                      if (last != null)
                        Text(
                          _time(last.timestamp),
                          style: TextStyle(
                            fontSize: 16,
                            color: bold ? AppTheme.primary : AppTheme.textLight,
                            fontWeight: bold
                                ? FontWeight.w700
                                : FontWeight.w400,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Dernier message + badge
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          last != null
                              ? (last.isFromMe
                                    ? 'Vous : ${last.content}'
                                    : last.content)
                              : 'Aucun message',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: AppTheme.fs18,
                            color: bold
                                ? AppTheme.textDark
                                : AppTheme.textLight,
                            fontWeight: bold
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                        ),
                      ),
                      if (unread > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.primary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '$unread',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _avatar(Contact c) {
    const double r = 30;
    if (c.photoPath != null) {
      final f = File(c.photoPath!);
      if (f.existsSync()) {
        return CircleAvatar(radius: r, backgroundImage: FileImage(f));
      }
    }
    return CircleAvatar(
      radius: r,
      backgroundColor: AppTheme.primary,
      child: Text(
        c.initials,
        style: const TextStyle(
          fontSize: AppTheme.fs20,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }
}
