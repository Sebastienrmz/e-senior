import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';
import '../models/contact.dart';
import '../services/phone_numbers.dart';
import '../models/message.dart';
import '../services/database_service.dart';
import '../theme/app_theme.dart';

/// Conversation avec un contact – EF3 : Messagerie Simplifiée
///
/// • Grandes bulles, texte ≥ 18 pt
/// • Messages rapides prédéfinis
/// • Préparation de messages dans l'application SMS et historique local
/// • Critère d'acceptation : envoi en < 45 secondes
class ConversationScreen extends StatefulWidget {
  final Contact contact;

  const ConversationScreen({super.key, required this.contact});

  @override
  State<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends State<ConversationScreen> {
  final _db = DatabaseService.instance;
  final _input = TextEditingController();
  final _scroll = ScrollController();
  List<Message> _messages = [];
  bool _loading = true;

  /// Messages rapides prédéfinis pour gagner du temps.
  static const _quickMessages = [
    'Bonjour !',
    'Comment ça va ?',
    'Je t\'appelle bientôt',
    'Merci beaucoup',
    'À bientôt !',
    'Je t\'embrasse',
    'Oui',
    'Non',
    'D\'accord',
    'Je suis bien arrivé(e)',
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final msgs = await _db.getMessages(widget.contact.id);
      await _db.markRead(widget.contact.id);
      if (!mounted) return;
      setState(() {
        _messages = msgs;
        _loading = false;
      });
      _scrollEnd();
    } catch (e) {
      debugPrint('Erreur chargement conversation: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  void _scrollEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ─── Envoi ────────────────────────────────────────────────────────

  bool _sending = false;

  Future<void> _send(String text, {bool whatsapp = false}) async {
    final content = text.trim();
    if (content.isEmpty || _sending) return;
    _sending = true;
    try {
      final msg = Message(
        id: const Uuid().v4(),
        contactId: widget.contact.id,
        content: content,
        isFromMe: true,
        timestamp: DateTime.now(),
        isRead: true,
      );
      await _db.insertMessage(msg);
      if (!mounted) return;
      _input.clear();
      await _load();
      if (!mounted) return;
      if (whatsapp) {
        await _openWhatsApp(content);
      } else {
        await _openSms(content);
      }
    } catch (e) {
      _launchError('Impossible de préparer le message');
    } finally {
      _sending = false;
    }
  }

  void _launchError(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _openSms(String body) async {
    final uri = Uri(
      scheme: 'sms',
      path: widget.contact.phone,
      query: 'body=${Uri.encodeComponent(body)}',
    );
    try {
      if (!await launchUrl(uri)) {
        _launchError('Application SMS indisponible. Brouillon conservé.');
      }
    } catch (_) {
      _launchError('Application SMS indisponible. Brouillon conservé.');
    }
  }

  Future<void> _openWhatsApp(String body) async {
    final number = whatsappNumber(widget.contact.phone);
    final uri = Uri.parse(
      'https://wa.me/$number?text=${Uri.encodeComponent(body)}',
    );
    try {
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        _launchError('Impossible d’ouvrir WhatsApp. Brouillon conservé.');
      }
    } catch (_) {
      _launchError('Impossible d’ouvrir WhatsApp. Brouillon conservé.');
    }
  }

  Future<void> _call() async {
    final uri = Uri(scheme: 'tel', path: widget.contact.phone);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  // ─── Messages rapides ─────────────────────────────────────────────

  void _showQuickMessages() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Messages rapides',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: AppTheme.fs26,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: _quickMessages.map((m) {
                  return InkWell(
                    onTap: () {
                      Navigator.pop(context);
                      _send(m);
                    },
                    borderRadius: BorderRadius.circular(24),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryLight.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: AppTheme.primary.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        m,
                        style: const TextStyle(
                          fontSize: AppTheme.fs22,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.primaryDark,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Choix mode d'envoi ───────────────────────────────────────────

  void _showSendOptions(String text) {
    if (text.trim().isEmpty) return;
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Envoyer par…',
                style: TextStyle(
                  fontSize: AppTheme.fs26,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(
                  Icons.sms,
                  size: AppTheme.iconMd,
                  color: AppTheme.primary,
                ),
                title: const Text(
                  'SMS',
                  style: TextStyle(fontSize: AppTheme.fs22),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _send(text);
                },
                minVerticalPadding: 14,
              ),
              ListTile(
                leading: const Icon(
                  Icons.chat,
                  size: AppTheme.iconMd,
                  color: Color(0xFF25D366),
                ),
                title: const Text(
                  'WhatsApp',
                  style: TextStyle(fontSize: AppTheme.fs22),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _send(text, whatsapp: true);
                },
                minVerticalPadding: 14,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Build ────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.contact.name),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, size: AppTheme.iconMd),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.phone, size: AppTheme.iconMd),
            onPressed: _call,
            tooltip: 'Appeler',
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _messages.isEmpty
                  ? _emptyChat()
                  : _chatList(),
            ),
            _inputBar(),
          ],
        ),
      ),
    );
  }

  Widget _emptyChat() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 72,
            color: AppTheme.primary.withValues(alpha: 0.25),
          ),
          const SizedBox(height: 16),
          const Text(
            'Aucun message',
            style: TextStyle(
              fontSize: AppTheme.fs22,
              color: AppTheme.textMedium,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Envoyez un premier message !',
            style: TextStyle(
              fontSize: AppTheme.fs20,
              color: AppTheme.textLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _chatList() {
    return ListView.builder(
      controller: _scroll,
      padding: const EdgeInsets.all(14),
      itemCount: _messages.length,
      itemBuilder: (_, i) {
        final m = _messages[i];
        final showDate =
            i == 0 || !_sameDay(_messages[i - 1].timestamp, m.timestamp);
        return Column(
          children: [if (showDate) _dateDivider(m.timestamp), _bubble(m)],
        );
      },
    );
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  Widget _dateDivider(DateTime dt) {
    final now = DateTime.now();
    String label;
    if (_sameDay(dt, now)) {
      label = "Aujourd'hui";
    } else if (_sameDay(dt, now.subtract(const Duration(days: 1)))) {
      label = 'Hier';
    } else {
      label = DateFormat('EEEE d MMMM', 'fr').format(dt);
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: AppTheme.divider.withValues(alpha: 0.25),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            label,
            style: const TextStyle(fontSize: 16, color: AppTheme.textLight),
          ),
        ),
      ),
    );
  }

  Widget _bubble(Message m) {
    final me = m.isFromMe;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: me ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.78,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              color: me ? AppTheme.primary : Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(20),
                topRight: const Radius.circular(20),
                bottomLeft: Radius.circular(me ? 20 : 4),
                bottomRight: Radius.circular(me ? 4 : 20),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Texte ≥ 18 pt (ENF3)
                Text(
                  m.content,
                  style: TextStyle(
                    fontSize: AppTheme.fs22,
                    color: me ? Colors.white : AppTheme.textDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('HH:mm').format(m.timestamp),
                  style: TextStyle(
                    fontSize: 14,
                    color: me ? Colors.white70 : AppTheme.textLight,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _inputBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
      decoration: BoxDecoration(
        color: AppTheme.card,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 4,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: Row(
        children: [
          // Messages rapides
          IconButton(
            onPressed: _showQuickMessages,
            icon: const Icon(
              Icons.flash_on,
              size: AppTheme.iconMd,
              color: AppTheme.primary,
            ),
            tooltip: 'Messages rapides',
            constraints: const BoxConstraints(
              minWidth: AppTheme.touchMin,
              minHeight: AppTheme.touchMin,
            ),
          ),
          const SizedBox(width: 6),
          // Champ texte
          Expanded(
            child: TextField(
              controller: _input,
              style: const TextStyle(fontSize: AppTheme.fs22),
              decoration: InputDecoration(
                hintText: 'Votre message…',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
              ),
              textCapitalization: TextCapitalization.sentences,
              maxLines: 3,
              minLines: 1,
            ),
          ),
          const SizedBox(width: 6),
          // Envoyer
          Container(
            decoration: const BoxDecoration(
              color: AppTheme.primary,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              onPressed: () => _showSendOptions(_input.text),
              icon: const Icon(Icons.send, color: Colors.white, size: 28),
              constraints: const BoxConstraints(
                minWidth: AppTheme.touchMin,
                minHeight: AppTheme.touchMin,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
