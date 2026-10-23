import 'dart:io';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/contact.dart';
import '../services/phone_numbers.dart';
import '../theme/app_theme.dart';
import 'conversation_screen.dart';

class ContactActionScreen extends StatelessWidget {
  final Contact contact;
  const ContactActionScreen({super.key, required this.contact});

  Future<void> _open(BuildContext context, Uri uri, String error) async {
    try {
      if (await launchUrl(uri, mode: LaunchMode.externalApplication)) return;
    } catch (_) {
      // L'appareil peut ne pas proposer d'application adaptée.
    }
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
  }

  Future<void> _call(BuildContext context) => _open(
    context,
    Uri(scheme: 'tel', path: contact.phone),
    'Impossible d’appeler',
  );

  Future<void> _whatsapp(BuildContext context) => _open(
    context,
    Uri.parse('https://wa.me/${whatsappNumber(contact.phone)}'),
    'Impossible d’ouvrir WhatsApp',
  );

  void _message(BuildContext ctx) => Navigator.push(
    ctx,
    MaterialPageRoute(builder: (_) => ConversationScreen(contact: contact)),
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppTheme.surface,
    appBar: AppBar(
      title: Text(contact.name),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, size: AppTheme.iconMd),
        onPressed: () => Navigator.pop(context),
      ),
    ),
    body: SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 12),
            _avatar(),
            const SizedBox(height: 16),
            Text(
              contact.name,
              style: const TextStyle(
                fontSize: AppTheme.fs30,
                fontWeight: FontWeight.w800,
                color: AppTheme.textDark,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              contact.displayPhone,
              style: const TextStyle(
                fontSize: AppTheme.fs20,
                color: AppTheme.textLight,
              ),
            ),
            if (contact.isEmergency) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.sosRed.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.emergency, color: AppTheme.sosRed, size: 18),
                    SizedBox(width: 6),
                    Text(
                      'Contact d\'urgence',
                      style: TextStyle(
                        fontSize: AppTheme.fs16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.sosRed,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 28),
            _bigBtn(
              Icons.phone,
              'APPELER',
              AppTheme.callGreen,
              () => _call(context),
            ),
            const SizedBox(height: 10),
            _bigBtn(
              Icons.message_outlined,
              'MESSAGE',
              AppTheme.messageBlue,
              () => _message(context),
            ),
            const SizedBox(height: 10),
            _bigBtnOutline(
              Icons.chat_outlined,
              'WHATSAPP',
              AppTheme.whatsappGreen,
              () => _whatsapp(context),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    ),
  );

  Widget _bigBtn(IconData ic, String l, Color c, VoidCallback t) => SizedBox(
    height: 76,
    width: double.infinity,
    child: ElevatedButton.icon(
      onPressed: t,
      icon: Icon(ic, size: AppTheme.iconLg),
      label: Text(
        l,
        style: const TextStyle(
          fontSize: AppTheme.fs26,
          fontWeight: FontWeight.w800,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: c,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        ),
      ),
    ),
  );

  Widget _bigBtnOutline(IconData ic, String l, Color c, VoidCallback t) =>
      SizedBox(
        height: 76,
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: t,
          icon: Icon(ic, size: AppTheme.iconLg, color: c),
          label: Text(
            l,
            style: TextStyle(
              fontSize: AppTheme.fs26,
              fontWeight: FontWeight.w800,
              color: c,
            ),
          ),
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: c, width: 2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            ),
          ),
        ),
      );

  Widget _avatar() {
    const double r = 52;
    if (contact.photoPath != null) {
      final f = File(contact.photoPath!);
      if (f.existsSync()) {
        return CircleAvatar(radius: r, backgroundImage: FileImage(f));
      }
    }
    return CircleAvatar(
      radius: r,
      backgroundColor: AppTheme.primaryLight,
      child: Text(
        contact.initials,
        style: const TextStyle(
          fontSize: 40,
          fontWeight: FontWeight.w800,
          color: AppTheme.primary,
        ),
      ),
    );
  }
}
