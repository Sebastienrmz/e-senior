import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:flutter/material.dart';
import '../services/app_preferences.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/contact.dart';
import '../services/database_service.dart';
import '../theme/app_theme.dart';
import 'add_contact_screen.dart';

/// Réglages locaux, gestion des contacts et effacement des données.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _db = DatabaseService.instance;
  List<Contact> _contacts = [];
  Contact? _emergency;
  bool _loading = true;

  // Paramètres utilisateur
  String _userName = '';
  double _fontScale = 1.0;
  bool _vibrationOn = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final contacts = await _db.getAllContacts();
      final emergency = await _db.getEmergencyContact();

      final prefs = await SharedPreferences.getInstance();
      if (!mounted) return;
      setState(() {
        _contacts = contacts;
        _emergency = emergency;
        _userName = prefs.getString('userName') ?? '';
        _fontScale = prefs.getDouble('fontScale') ?? 1.0;
        _vibrationOn = prefs.getBool('vibrationOn') ?? true;
        _loading = false;
      });
    } catch (e) {
      debugPrint('Erreur chargement paramètres: $e');
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _savePref(String key, dynamic val) async {
    final prefs = await SharedPreferences.getInstance();
    if (val is double) await prefs.setDouble(key, val);
    if (val is bool) await prefs.setBool(key, val);
    if (val is String) await prefs.setString(key, val);
    if (key == 'fontScale') AppPreferences.textScale.value = val as double;
    if (key == 'vibrationOn') AppPreferences.vibration = val as bool;
  }

  // ─── Actions ──────────────────────────────────────────────────────

  void _editName() {
    final ctrl = TextEditingController(text: _userName);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Votre nom'),
        content: TextField(
          controller: ctrl,
          style: const TextStyle(fontSize: AppTheme.fs22),
          decoration: const InputDecoration(hintText: 'Prénom et Nom'),
          textCapitalization: TextCapitalization.words,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Annuler',
              style: TextStyle(fontSize: AppTheme.fs20),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              final v = ctrl.text.trim();
              setState(() => _userName = v);
              _savePref('userName', v);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(100, AppTheme.touchMin),
            ),
            child: const Text('OK', style: TextStyle(fontSize: AppTheme.fs20)),
          ),
        ],
      ),
    );
  }

  void _addContact() async {
    final count = _contacts.where((c) => c.isFavorite).length;
    if (count >= 12) {
      _snack('Maximum de 12 contacts atteint');
      return;
    }
    final ok = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const AddContactScreen()),
    );
    if (ok == true) _load();
  }

  void _editContact(Contact c) async {
    final ok = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => AddContactScreen(existing: c)),
    );
    if (ok == true) _load();
  }

  void _deleteContact(Contact c) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Supprimer ?'),
        content: Text('Supprimer ${c.name} et tous ses messages ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Annuler',
              style: TextStyle(fontSize: AppTheme.fs20),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              await _db.deleteContact(c.id);
              if (!mounted) return;
              Navigator.pop(context);
              _load();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.sosRed,
              minimumSize: const Size(100, AppTheme.touchMin),
            ),
            child: const Text(
              'Supprimer',
              style: TextStyle(fontSize: AppTheme.fs20),
            ),
          ),
        ],
      ),
    );
  }

  void _showRemoteConfig() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Piste d’évolution'),
        content: const Text(
          'La configuration par un proche à distance était prévue dans le projet. '
          'Elle n’est pas implémentée : les réglages se font sur cet appareil.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  // Effacement des données locales
  void _eraseAll() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber, color: AppTheme.sosRed, size: 28),
            SizedBox(width: 10),
            Text('Tout supprimer ?'),
          ],
        ),
        content: const Text(
          'Toutes vos données seront supprimées définitivement :\n\n'
          '• Contacts\n• Messages\n• Photos importées dans E-Senior\n• Paramètres\n\n'
          'Cette action est irréversible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Annuler',
              style: TextStyle(fontSize: AppTheme.fs20),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              await _db.eraseAll();
              final prefs = await SharedPreferences.getInstance();
              await prefs.clear();
              await AppPreferences.load();
              final dir = await getApplicationDocumentsDirectory();
              await for (final entry in dir.list(followLinks: false)) {
                final name = p.basename(entry.path);
                if (entry is File &&
                    (name.startsWith('contact_') ||
                        name.startsWith('photo_'))) {
                  await entry.delete();
                }
              }
              if (mounted) {
                Navigator.pop(context);
                _load();
                _snack('Données supprimées');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.sosRed,
              minimumSize: const Size(120, AppTheme.touchMin),
            ),
            child: const Text(
              'Tout supprimer',
              style: TextStyle(fontSize: AppTheme.fs20),
            ),
          ),
        ],
      ),
    );
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  // ─── Build ────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Paramètres')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final favCount = _contacts.where((c) => c.isFavorite).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Paramètres'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, size: AppTheme.iconMd),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppTheme.pad),
        children: [
          // ═══ PROFIL ═══
          _section('Profil'),
          _settingCard(
            Icons.person,
            'Mon nom',
            subtitle: _userName.isNotEmpty ? _userName : 'Non défini',
            onTap: _editName,
          ),

          const SizedBox(height: 24),

          // Contacts
          _section('Mes contacts ($favCount / 12)'),
          ..._contacts.map(_contactCard),
          if (favCount < 12)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: OutlinedButton.icon(
                onPressed: _addContact,
                icon: const Icon(Icons.person_add, size: 28),
                label: const Text('Ajouter un contact'),
              ),
            ),

          const SizedBox(height: 24),

          // Contact SOS
          _section('Contact d\'urgence (SOS)'),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.sosRed.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(AppTheme.radius),
              border: Border.all(color: AppTheme.sosRed.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                const Icon(Icons.emergency, color: AppTheme.sosRed, size: 32),
                const SizedBox(width: 14),
                Expanded(
                  child: _emergency != null
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _emergency!.name,
                              style: const TextStyle(
                                fontSize: AppTheme.fs22,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              _emergency!.displayPhone,
                              style: const TextStyle(
                                fontSize: AppTheme.fs18,
                                color: AppTheme.textMedium,
                              ),
                            ),
                          ],
                        )
                      : const Text(
                          'Aucun contact d\'urgence défini.\n'
                          'Modifiez un contact et activez l\'option SOS.',
                          style: TextStyle(
                            fontSize: AppTheme.fs18,
                            color: AppTheme.textMedium,
                          ),
                        ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Affichage
          _section('Affichage'),
          _settingCard(
            Icons.text_fields,
            'Taille du texte : ${_fontLabel()}',
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: _fontScale > 0.8
                      ? () {
                          setState(
                            () => _fontScale =
                                ((_fontScale * 10).round() - 1).clamp(8, 14) /
                                10,
                          );
                          _savePref('fontScale', _fontScale);
                        }
                      : null,
                  icon: const Icon(Icons.remove_circle_outline, size: 32),
                  constraints: const BoxConstraints(
                    minWidth: AppTheme.touchMin,
                    minHeight: AppTheme.touchMin,
                  ),
                ),
                IconButton(
                  onPressed: _fontScale < 1.4
                      ? () {
                          setState(
                            () => _fontScale =
                                ((_fontScale * 10).round() + 1).clamp(8, 14) /
                                10,
                          );
                          _savePref('fontScale', _fontScale);
                        }
                      : null,
                  icon: const Icon(Icons.add_circle_outline, size: 32),
                  constraints: const BoxConstraints(
                    minWidth: AppTheme.touchMin,
                    minHeight: AppTheme.touchMin,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _section('Retour haptique'),
          _switchCard(
            Icons.vibration,
            'Vibrations',
            'Retour haptique',
            _vibrationOn,
            (v) {
              setState(() => _vibrationOn = v);
              _savePref('vibrationOn', v);
            },
          ),

          const SizedBox(height: 24),

          // Présentation de la fonction envisagée
          _section('Configuration à distance'),
          _settingCard(
            Icons.cloud_sync,
            'Gestion par un proche',
            subtitle: 'Fonction prévue, non implémentée',
            onTap: _showRemoteConfig,
          ),

          const SizedBox(height: 24),

          // Données et confidentialité
          _section('Données et confidentialité'),
          _settingCard(
            Icons.security,
            'Stockage local',
            subtitle: 'Base SQLite sur cet appareil, sans chiffrement ajouté',
          ),
          _settingCard(
            Icons.privacy_tip,
            'Données personnelles',
            subtitle: 'Aucun compte ni synchronisation serveur',
          ),
          _settingCard(
            Icons.info_outline,
            'À propos',
            subtitle: 'E-Senior v1.0.0 – Projet étudiant',
          ),

          const SizedBox(height: 16),

          // Effacement local
          ElevatedButton.icon(
            onPressed: _eraseAll,
            icon: const Icon(Icons.delete_forever, size: 28),
            label: const Text('SUPPRIMER TOUTES MES DONNÉES'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.sosRed,
              minimumSize: const Size(double.infinity, AppTheme.buttonH),
            ),
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // ─── Composants ───────────────────────────────────────────────────

  String _fontLabel() {
    if (_fontScale <= 0.8) return 'Petit';
    if (_fontScale <= 1.0) return 'Normal';
    if (_fontScale <= 1.2) return 'Grand';
    return 'Très grand';
  }

  Widget _section(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, top: 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: AppTheme.fs22,
          fontWeight: FontWeight.w700,
          color: AppTheme.primaryDark,
        ),
      ),
    );
  }

  Widget _settingCard(
    IconData icon,
    String title, {
    String? subtitle,
    VoidCallback? onTap,
    Widget? trailing,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, size: AppTheme.iconMd, color: AppTheme.primary),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: AppTheme.fs20,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: subtitle != null
            ? Text(subtitle, style: const TextStyle(fontSize: 16))
            : null,
        trailing:
            trailing ??
            (onTap != null ? const Icon(Icons.chevron_right, size: 28) : null),
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        minVerticalPadding: 10,
      ),
    );
  }

  Widget _switchCard(
    IconData icon,
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: SwitchListTile(
        secondary: Icon(icon, size: AppTheme.iconMd, color: AppTheme.primary),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: AppTheme.fs20,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 16)),
        value: value,
        onChanged: onChanged,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
    );
  }

  Widget _contactCard(Contact c) {
    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      child: ListTile(
        leading: CircleAvatar(
          radius: 22,
          backgroundColor: AppTheme.primary,
          child: Text(
            c.initials,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
        title: Text(
          c.name,
          style: const TextStyle(
            fontSize: AppTheme.fs20,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(c.displayPhone, style: const TextStyle(fontSize: 16)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (c.isEmergency)
              const Padding(
                padding: EdgeInsets.only(right: 4),
                child: Icon(Icons.emergency, color: AppTheme.sosRed, size: 22),
              ),
            IconButton(
              icon: const Icon(Icons.edit, size: 26),
              onPressed: () => _editContact(c),
              constraints: const BoxConstraints(
                minWidth: AppTheme.touchMin,
                minHeight: AppTheme.touchMin,
              ),
            ),
            IconButton(
              icon: const Icon(
                Icons.delete_outline,
                size: 26,
                color: AppTheme.sosRed,
              ),
              onPressed: () => _deleteContact(c),
              constraints: const BoxConstraints(
                minWidth: AppTheme.touchMin,
                minHeight: AppTheme.touchMin,
              ),
            ),
          ],
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      ),
    );
  }
}
