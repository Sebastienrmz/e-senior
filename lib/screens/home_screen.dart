import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/contact.dart';
import '../services/database_service.dart';
import '../theme/app_theme.dart';
import '../widgets/sos_button.dart';
import 'add_contact_screen.dart';
import 'contact_action_screen.dart';
import 'messaging_list_screen.dart';
import 'photo_gallery_screen.dart';
import 'settings_screen.dart';

/// Accueil : contacts favoris et accès aux fonctions du téléphone.
/// Grille contacts + grosses tuiles d'action + SOS
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  final _db = DatabaseService.instance;
  List<Contact> _contacts = [];
  Contact? _emergency;
  int _totalUnread = 0;
  bool _loading = true;
  String _userName = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState s) {
    if (s == AppLifecycleState.resumed) _load();
  }

  Future<void> _load() async {
    try {
      final c = await _db.getFavorites();
      final e = await _db.getEmergencyContact();
      final u = await _db.totalUnread();
      final prefs = await SharedPreferences.getInstance();
      final name = prefs.getString('userName') ?? '';
      if (!mounted) return;
      setState(() {
        _contacts = c;
        _emergency = e;
        _totalUnread = u;
        _userName = name;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _call(Contact c) async {
    final uri = Uri(scheme: 'tel', path: c.phone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      _snack('Impossible d\'appeler');
    }
  }

  void _onSOS() {
    if (_emergency == null) {
      _dialog(
        'Pas de contact SOS',
        'Ajoutez un contact d\'urgence dans les paramètres.',
        [
          _dlgBtn('Paramètres', () {
            Navigator.pop(context);
            _goSettings();
          }),
        ],
      );
      return;
    }
    _dialog('Appel d\'urgence', 'Appeler ${_emergency!.name} ?', [
      _dlgCancel(),
      _dlgBtn('APPELER', () {
        Navigator.pop(context);
        _call(_emergency!);
      }, color: AppTheme.sosRed),
    ]);
  }

  // Navigation
  void _goAddContact() async {
    try {
      if (await _db.favoriteCount() >= 12) {
        _snack('Maximum 12 contacts');
        return;
      }
    } catch (_) {}
    if (!mounted) return;
    final ok = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const AddContactScreen()),
    );
    if (ok == true) await _load();
  }

  void _goContact(Contact c) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ContactActionScreen(contact: c)),
    );
    _load();
  }

  void _goMessages() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const MessagingListScreen()),
    );
    _load();
  }

  void _goPhotos() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PhotoGalleryScreen()),
    );
  }

  void _goSettings() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SettingsScreen()),
    );
    _load();
  }

  void _goCamera() async {
    try {
      final picker = ImagePicker();
      final photo = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );
      if (photo == null) return;
      final dir = await getApplicationDocumentsDirectory();
      await File(photo.path).copy(
        p.join(
          dir.path,
          'photo_${DateTime.now().microsecondsSinceEpoch}${p.extension(photo.path)}',
        ),
      );
      _snack('Photo enregistrée dans Mes Photos');
    } catch (e) {
      _snack('Erreur appareil photo');
    }
  }

  /// Ouvrir l'app calendrier du téléphone
  Future<void> _openCalendar() async {
    try {
      // Android: content://com.android.calendar ou Google Calendar
      final androidCal = Uri.parse('content://com.android.calendar/time');
      final googleCal = Uri.parse('https://calendar.google.com');
      if (await canLaunchUrl(androidCal)) {
        await launchUrl(androidCal);
      } else {
        await launchUrl(googleCal, mode: LaunchMode.externalApplication);
      }
    } catch (_) {
      _snack('Impossible d\'ouvrir le calendrier');
    }
  }

  /// Ouvrir l'app météo
  Future<void> _openWeather() async {
    try {
      // Tenter d'ouvrir Samsung Weather, sinon Google Weather, sinon web
      final samsungWeather = Uri.parse('samsungweather://');
      final googleWeather = Uri.parse('https://weather.google.com');
      if (await canLaunchUrl(samsungWeather)) {
        await launchUrl(samsungWeather);
      } else {
        await launchUrl(googleWeather, mode: LaunchMode.externalApplication);
      }
    } catch (_) {
      _snack('Impossible d\'ouvrir la météo');
    }
  }

  // ─── BUILD ────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // En-tête et salutation
                    _header(),
                    // ─── Grille contacts ───
                    _contacts.isEmpty ? _emptyState() : _contactsGrid(),
                    // Actions principales
                    _actionTilesGrid(),
                    // ─── SOS ───
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 6, 14, 14),
                      child: SOSButton(onActivated: _onSOS),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  /// Header : salutation + 2 boutons Calendrier / Météo
  Widget _header() {
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Bonjour'
        : hour < 18
        ? 'Bon après-midi'
        : 'Bonsoir';
    final displayName = _userName.isNotEmpty ? _userName.split(' ').first : '';

    final now = DateTime.now();
    final dayNames = [
      'lundi',
      'mardi',
      'mercredi',
      'jeudi',
      'vendredi',
      'samedi',
      'dimanche',
    ];
    final monthNames = [
      'jan.',
      'fév.',
      'mars',
      'avr.',
      'mai',
      'juin',
      'juil.',
      'août',
      'sept.',
      'oct.',
      'nov.',
      'déc.',
    ];
    final dateStr =
        '${dayNames[now.weekday - 1]} ${now.day} ${monthNames[now.month - 1]}';

    // Icône et texte météo adaptatifs à l'heure
    final weatherIcon = hour < 7
        ? Icons.nightlight_round
        : hour < 12
        ? Icons.wb_sunny_rounded
        : hour < 18
        ? Icons.wb_sunny_rounded
        : hour < 21
        ? Icons.wb_twilight_rounded
        : Icons.nightlight_round;
    final weatherColor = hour < 7
        ? const Color(0xFF5C6BC0)
        : hour < 18
        ? const Color(0xFFFFA726)
        : hour < 21
        ? const Color(0xFFEF6C00)
        : const Color(0xFF5C6BC0);
    final weatherLabel = hour < 7
        ? 'Nuit'
        : hour < 12
        ? 'Matin'
        : hour < 18
        ? 'Après-midi'
        : hour < 21
        ? 'Soirée'
        : 'Nuit';

    return Container(
      margin: const EdgeInsets.fromLTRB(14, 8, 14, 6),
      padding: const EdgeInsets.fromLTRB(20, 16, 14, 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.primary, AppTheme.primary.withValues(alpha: 0.82)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── Ligne 1 : Salutation + Settings ───
          Row(
            children: [
              Expanded(
                child: Text(
                  displayName.isNotEmpty ? '$greeting, $displayName' : greeting,
                  style: const TextStyle(
                    fontSize: AppTheme.fs26,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
              GestureDetector(
                onTap: _goSettings,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.settings_outlined,
                    size: 22,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // ─── Ligne 2 : 2 boutons Calendrier + Météo ───
          Row(
            children: [
              // BOUTON CALENDRIER
              Expanded(
                child: GestureDetector(
                  onTap: _openCalendar,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.1),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.calendar_today_rounded,
                            size: 22,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                dateStr,
                                style: const TextStyle(
                                  fontSize: AppTheme.fs16,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Calendrier',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white.withValues(alpha: 0.6),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.chevron_right_rounded,
                          size: 20,
                          color: Colors.white.withValues(alpha: 0.4),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // BOUTON MÉTÉO
              GestureDetector(
                onTap: _openWeather,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(weatherIcon, size: 28, color: weatherColor),
                      const SizedBox(height: 4),
                      Text(
                        weatherLabel,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _emptyState() => SingleChildScrollView(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.people_outline,
            size: 72,
            color: AppTheme.textLight.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          const Text(
            'Aucun contact',
            style: TextStyle(
              fontSize: AppTheme.fs24,
              fontWeight: FontWeight.w600,
              color: AppTheme.textMedium,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Appuyez sur "Ajouter" ci-dessous',
            style: TextStyle(
              fontSize: AppTheme.fs18,
              color: AppTheme.textLight,
            ),
          ),
        ],
      ),
    ),
  );

  /// Contacts favoris sur trois colonnes.
  Widget _contactsGrid() => GridView.builder(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    padding: const EdgeInsets.fromLTRB(10, 6, 10, 6),
    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: 3,
      mainAxisExtent: 165,
      crossAxisSpacing: 4,
      mainAxisSpacing: 0,
    ),
    itemCount: _contacts.length,
    itemBuilder: (_, i) => _contactTile(_contacts[i]),
  );

  Widget _contactTile(Contact c) => GestureDetector(
    onTap: () => _goContact(c),
    onLongPress: () => _contextMenu(c),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: c.isEmergency
                  ? AppTheme.sosRed.withValues(alpha: 0.5)
                  : AppTheme.divider,
              width: c.isEmergency ? 3 : 1.5,
            ),
          ),
          child: _avatar(c, AppTheme.avatarR),
        ),
        const SizedBox(height: 6),
        Text(
          c.name,
          style: const TextStyle(
            fontSize: AppTheme.fs16,
            fontWeight: FontWeight.w600,
            color: AppTheme.textDark,
          ),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        if (c.isEmergency)
          Text(
            'SOS',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: AppTheme.sosRed.withValues(alpha: 0.7),
            ),
          ),
      ],
    ),
  );

  Widget _avatar(Contact c, double r) {
    if (c.photoPath != null) {
      final f = File(c.photoPath!);
      if (f.existsSync()) {
        return CircleAvatar(radius: r, backgroundImage: FileImage(f));
      }
    }
    return CircleAvatar(
      radius: r,
      backgroundColor: AppTheme.primaryLight,
      child: Text(
        c.initials,
        style: TextStyle(
          fontSize: r * 0.55,
          fontWeight: FontWeight.w700,
          color: AppTheme.primary,
        ),
      ),
    );
  }

  /// Accès à l’ajout de contact, aux messages, à la caméra et aux photos.
  Widget _actionTilesGrid() => Padding(
    padding: const EdgeInsets.fromLTRB(14, 4, 14, 4),
    child: Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _bigTile(
                Icons.person_add_rounded,
                'Ajouter',
                const Color(0xFFE8F5E9),
                AppTheme.callGreen,
                _goAddContact,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _bigTile(
                Icons.message_rounded,
                'Messages',
                const Color(0xFFE3F2FD),
                AppTheme.messageBlue,
                _goMessages,
                badge: _totalUnread > 0 ? _totalUnread : null,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _bigTile(
                Icons.camera_alt_rounded,
                'Appareil\nphoto',
                const Color(0xFFFFF3E0),
                const Color(0xFFE65100),
                _goCamera,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _bigTile(
                Icons.photo_library_rounded,
                'Photos',
                const Color(0xFFF3E5F5),
                const Color(0xFF7B1FA2),
                _goPhotos,
              ),
            ),
          ],
        ),
      ],
    ),
  );

  Widget _bigTile(
    IconData icon,
    String label,
    Color bg,
    Color fg,
    VoidCallback onTap, {
    int? badge,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 88,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(icon, size: 40, color: fg),
                if (badge != null)
                  Positioned(
                    right: -6,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.sosRed,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '$badge',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: AppTheme.fs20,
                  fontWeight: FontWeight.w700,
                  color: fg,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _contextMenu(Contact c) {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                c.name,
                style: const TextStyle(
                  fontSize: AppTheme.fs24,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 20),
              _sheetItem(Icons.phone, 'Appeler', () {
                Navigator.pop(context);
                _call(c);
              }),
              _sheetItem(Icons.edit_outlined, 'Modifier', () {
                Navigator.pop(context);
                _editContact(c);
              }),
              _sheetItem(Icons.delete_outline, 'Supprimer', () {
                Navigator.pop(context);
                _confirmDelete(c);
              }, color: AppTheme.sosRed),
            ],
          ),
        ),
      ),
    );
  }

  void _editContact(Contact c) async {
    final ok = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => AddContactScreen(existing: c)),
    );
    if (ok == true) _load();
  }

  void _confirmDelete(Contact c) =>
      _dialog('Supprimer ?', 'Supprimer ${c.name} et ses messages ?', [
        _dlgCancel(),
        _dlgBtn('Supprimer', () async {
          await _db.deleteContact(c.id);
          if (!mounted) return;
          Navigator.pop(context);
          _load();
        }, color: AppTheme.sosRed),
      ]);

  Widget _sheetItem(
    IconData icon,
    String label,
    VoidCallback onTap, {
    Color? color,
  }) => ListTile(
    leading: Icon(
      icon,
      size: AppTheme.iconMd,
      color: color ?? AppTheme.primary,
    ),
    title: Text(
      label,
      style: TextStyle(
        fontSize: AppTheme.fs22,
        color: color ?? AppTheme.textDark,
      ),
    ),
    onTap: onTap,
    minVerticalPadding: 14,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  );

  void _snack(String m) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  }

  void _dialog(String title, String content, List<Widget> actions) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: actions,
      ),
    );
  }

  Widget _dlgCancel() => TextButton(
    onPressed: () => Navigator.pop(context),
    child: const Text('Annuler', style: TextStyle(fontSize: AppTheme.fs20)),
  );
  Widget _dlgBtn(String l, VoidCallback onTap, {Color? color}) =>
      ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: color ?? AppTheme.primary,
          minimumSize: const Size(120, AppTheme.touchMin),
        ),
        child: Text(l, style: const TextStyle(fontSize: AppTheme.fs20)),
      );
}
