import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';
import '../models/contact.dart';
import '../services/database_service.dart';
import '../theme/app_theme.dart';

class AddContactScreen extends StatefulWidget {
  final Contact? existing;
  const AddContactScreen({super.key, this.existing});
  @override
  State<AddContactScreen> createState() => _AddContactScreenState();
}

class _AddContactScreenState extends State<AddContactScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  late final DatabaseService _db;
  final _picker = ImagePicker();
  String? _photoPath;
  bool _isEmergency = false;
  bool _saving = false;
  bool _dbReady = false;
  bool get _editing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    _db = DatabaseService.instance;
    _initDb();
    if (_editing) {
      _name.text = widget.existing!.name;
      _phone.text = widget.existing!.phone;
      _photoPath = widget.existing!.photoPath;
      _isEmergency = widget.existing!.isEmergency;
    }
  }

  Future<void> _initDb() async {
    try {
      await _db.database;
      if (mounted) setState(() => _dbReady = true);
    } catch (e) {
      debugPrint('DB init error: $e');
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto(ImageSource source) async {
    try {
      final xfile = await _picker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );
      if (xfile == null) return;
      final dir = await getApplicationDocumentsDirectory();
      final ext = p.extension(xfile.path);
      final dest = '${dir.path}/contact_${const Uuid().v4()}$ext';
      await File(xfile.path).copy(dest);
      if (mounted) setState(() => _photoPath = dest);
    } catch (e) {
      _snack('Erreur photo : $e');
    }
  }

  void _showPhotoOptions() {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Choisir une photo',
                style: TextStyle(
                  fontSize: AppTheme.fs24,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(
                  Icons.camera_alt_outlined,
                  size: AppTheme.iconMd,
                  color: AppTheme.primary,
                ),
                title: const Text(
                  'Prendre une photo',
                  style: TextStyle(fontSize: AppTheme.fs22),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _pickPhoto(ImageSource.camera);
                },
                minVerticalPadding: 14,
              ),
              ListTile(
                leading: const Icon(
                  Icons.photo_library_outlined,
                  size: AppTheme.iconMd,
                  color: AppTheme.primary,
                ),
                title: const Text(
                  'Depuis la galerie',
                  style: TextStyle(fontSize: AppTheme.fs22),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _pickPhoto(ImageSource.gallery);
                },
                minVerticalPadding: 14,
              ),
              if (_photoPath != null)
                ListTile(
                  leading: const Icon(
                    Icons.delete_outline,
                    size: AppTheme.iconMd,
                    color: AppTheme.sosRed,
                  ),
                  title: const Text(
                    'Supprimer la photo',
                    style: TextStyle(
                      fontSize: AppTheme.fs22,
                      color: AppTheme.sosRed,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    setState(() => _photoPath = null);
                  },
                  minVerticalPadding: 14,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (_form.currentState == null || !_form.currentState!.validate()) return;
    if (!_dbReady) {
      _snack('Chargement...');
      await _initDb();
      if (!_dbReady) return;
    }
    if (_saving) return;
    setState(() => _saving = true);
    try {
      final now = DateTime.now();
      final contact = Contact(
        id: _editing ? widget.existing!.id : const Uuid().v4(),
        name: _name.text.trim(),
        phone: _phone.text.trim(),
        photoPath: _photoPath,
        isFavorite: true,
        isEmergency: _isEmergency,
        sortOrder: _editing ? widget.existing!.sortOrder : 0,
        createdAt: _editing ? widget.existing!.createdAt : now,
        updatedAt: now,
      );
      if (_editing) {
        await _db.updateContact(contact);
      } else {
        await _db.insertContact(contact);
      }
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      debugPrint('Save error: $e');
      if (mounted) {
        _snack('Erreur : $e');
        setState(() => _saving = false);
      }
    }
  }

  void _snack(String m) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppTheme.surface,
    appBar: AppBar(
      title: Text(_editing ? 'Modifier' : 'Nouveau contact'),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, size: AppTheme.iconMd),
        onPressed: () => Navigator.pop(context),
      ),
    ),
    body: SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.pad),
        child: Form(
          key: _form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 12),
              Center(
                child: GestureDetector(
                  onTap: _showPhotoOptions,
                  child: Stack(
                    children: [
                      _avatarPreview(),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.primary,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 6),
              const Center(
                child: Text(
                  'Ajouter une photo',
                  style: TextStyle(
                    fontSize: AppTheme.fs16,
                    color: AppTheme.textLight,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Prénom et Nom',
                style: TextStyle(
                  fontSize: AppTheme.fs20,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textDark,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _name,
                style: const TextStyle(fontSize: AppTheme.fs22),
                decoration: const InputDecoration(
                  hintText: 'Ex : Marie Dupont',
                  prefixIcon: Icon(Icons.person_outline, size: AppTheme.iconMd),
                ),
                textCapitalization: TextCapitalization.words,
                autofocus: !_editing,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Entrez un nom' : null,
              ),
              const SizedBox(height: 20),
              const Text(
                'Numéro de téléphone',
                style: TextStyle(
                  fontSize: AppTheme.fs20,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textDark,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _phone,
                style: const TextStyle(fontSize: AppTheme.fs22),
                decoration: const InputDecoration(
                  hintText: 'Ex : 06 12 34 56 78',
                  prefixIcon: Icon(Icons.phone_outlined, size: AppTheme.iconMd),
                ),
                keyboardType: TextInputType.phone,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Entrez un numéro' : null,
              ),
              const SizedBox(height: 20),
              Material(
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radius),
                  side: const BorderSide(color: AppTheme.border),
                ),
                child: SwitchListTile(
                  title: const Text(
                    'Contact d\'urgence (SOS)',
                    style: TextStyle(
                      fontSize: AppTheme.fs20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: const Text(
                    'Sera appelé avec le bouton SOS',
                    style: TextStyle(fontSize: AppTheme.fs18),
                  ),
                  value: _isEmergency,
                  onChanged: (v) => setState(() => _isEmergency = v),
                  secondary: Icon(
                    Icons.emergency,
                    size: AppTheme.iconMd,
                    color: _isEmergency ? AppTheme.sosRed : AppTheme.border,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 72),
                ),
                child: _saving
                    ? const SizedBox(
                        width: 28,
                        height: 28,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 3,
                        ),
                      )
                    : Text(
                        _editing ? 'ENREGISTRER' : 'AJOUTER CE CONTACT',
                        style: const TextStyle(
                          fontSize: AppTheme.fs22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    ),
  );

  Widget _avatarPreview() {
    const double r = 48;
    if (_photoPath != null && File(_photoPath!).existsSync()) {
      return CircleAvatar(
        radius: r,
        backgroundImage: FileImage(File(_photoPath!)),
      );
    }
    return CircleAvatar(
      radius: r,
      backgroundColor: AppTheme.primaryLight,
      child: Icon(
        Icons.person,
        size: 48,
        color: AppTheme.primary.withValues(alpha: 0.35),
      ),
    );
  }
}
