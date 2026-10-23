import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../theme/app_theme.dart';

/// Galerie Photos – EF4
///
/// • Consultation des 50 dernières photos avec zoom tactile (pinch)
/// • Navigation par swipe entre les photos
/// • Ajout de photos depuis la caméra ou la galerie
class PhotoGalleryScreen extends StatefulWidget {
  const PhotoGalleryScreen({super.key});

  @override
  State<PhotoGalleryScreen> createState() => _PhotoGalleryScreenState();
}

class _PhotoGalleryScreenState extends State<PhotoGalleryScreen> {
  List<File> _photos = [];
  bool _loading = true;

  static const _imageExts = {'.jpg', '.jpeg', '.png', '.gif', '.webp', '.bmp'};

  @override
  void initState() {
    super.initState();
    _scan();
  }

  Future<void> _scan() async {
    if (!mounted) return;
    setState(() => _loading = true);
    final files = <File>[];

    try {
      // Photos dans le dossier de l'application
      final appDir = await getApplicationDocumentsDirectory();
      await _collect(appDir, files);

      // Trier par date de modification (récentes en premier)
      files.sort((a, b) {
        try {
          return b.lastModifiedSync().compareTo(a.lastModifiedSync());
        } catch (_) {
          return 0;
        }
      });
    } catch (_) {}

    if (!mounted) return;
    // EF4 : afficher les 50 dernières photos
    setState(() {
      _photos = files.take(50).toList();
      _loading = false;
    });
  }

  Future<void> _collect(Directory dir, List<File> out) async {
    try {
      final entities = dir.listSync(followLinks: false);
      for (final e in entities) {
        if (e is File && _isImage(e.path)) {
          out.add(e);
        }
      }
    } catch (_) {}
  }

  bool _isImage(String path) {
    final lower = path.toLowerCase();
    return _imageExts.any(lower.endsWith);
  }

  Future<void> _addPhoto() async {
    // Proposer caméra ou galerie
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Ajouter une photo',
                style: TextStyle(
                  fontSize: AppTheme.fs26,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(
                  Icons.camera_alt,
                  size: AppTheme.iconMd,
                  color: AppTheme.primary,
                ),
                title: const Text(
                  'Prendre une photo',
                  style: TextStyle(fontSize: AppTheme.fs22),
                ),
                onTap: () => Navigator.pop(context, ImageSource.camera),
                minVerticalPadding: 14,
              ),
              ListTile(
                leading: const Icon(
                  Icons.photo_library,
                  size: AppTheme.iconMd,
                  color: AppTheme.primary,
                ),
                title: const Text(
                  'Depuis la galerie',
                  style: TextStyle(fontSize: AppTheme.fs22),
                ),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
                minVerticalPadding: 14,
              ),
            ],
          ),
        ),
      ),
    );

    if (source == null) return;

    try {
      final picker = ImagePicker();
      final xfile = await picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );
      if (xfile == null) return;

      final appDir = await getApplicationDocumentsDirectory();
      final name =
          'photo_${DateTime.now().microsecondsSinceEpoch}${p.extension(xfile.path)}';
      await File(xfile.path).copy('${appDir.path}/$name');
      _scan();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erreur : $e')));
      }
    }
  }

  void _openViewer(int index) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _PhotoViewer(photos: _photos, initial: index),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes Photos'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, size: AppTheme.iconMd),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_photo_alternate, size: AppTheme.iconMd),
            onPressed: _addPhoto,
            tooltip: 'Ajouter',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _photos.isEmpty
          ? _empty()
          : _grid(),
    );
  }

  Widget _empty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.photo_library_outlined,
            size: 80,
            color: AppTheme.primary.withValues(alpha: 0.25),
          ),
          const SizedBox(height: 20),
          const Text(
            'Aucune photo',
            style: TextStyle(
              fontSize: AppTheme.fs26,
              color: AppTheme.textMedium,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Vos photos apparaîtront ici',
            style: TextStyle(
              fontSize: AppTheme.fs20,
              color: AppTheme.textLight,
            ),
          ),
          const SizedBox(height: 28),
          ElevatedButton.icon(
            onPressed: _addPhoto,
            icon: const Icon(Icons.add_photo_alternate, size: AppTheme.iconMd),
            label: const Text('Ajouter une photo'),
          ),
        ],
      ),
    );
  }

  Widget _grid() {
    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: _photos.length,
      itemBuilder: (_, i) => GestureDetector(
        onTap: () => _openViewer(i),
        child: Hero(
          tag: 'photo_$i',
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            child: Image.file(
              _photos[i],
              fit: BoxFit.cover,
              cacheWidth: 400,
              errorBuilder: (_, __, ___) => Container(
                color: AppTheme.divider.withValues(alpha: 0.2),
                child: const Icon(
                  Icons.broken_image,
                  size: AppTheme.iconLg,
                  color: AppTheme.textLight,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════
//  VISIONNEUSE – zoom pinch-to-zoom (EF4)
// ═════════════════════════════════════════════════════════════════════

class _PhotoViewer extends StatefulWidget {
  final List<File> photos;
  final int initial;

  const _PhotoViewer({required this.photos, required this.initial});

  @override
  State<_PhotoViewer> createState() => _PhotoViewerState();
}

class _PhotoViewerState extends State<_PhotoViewer> {
  late final PageController _page;
  late int _current;

  @override
  void initState() {
    super.initState();
    _current = widget.initial;
    _page = PageController(initialPage: _current);
  }

  @override
  void dispose() {
    _page.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(
          '${_current + 1} / ${widget.photos.length}',
          style: const TextStyle(fontSize: AppTheme.fs22),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close, size: AppTheme.iconMd),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: PageView.builder(
        controller: _page,
        itemCount: widget.photos.length,
        onPageChanged: (i) => setState(() => _current = i),
        itemBuilder: (_, i) => Center(
          child: Hero(
            tag: 'photo_$i',
            // EF4 : zoom tactile (pinch) avec InteractiveViewer
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 5.0,
              child: Image.file(
                widget.photos[i],
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.broken_image,
                  size: 64,
                  color: Colors.white38,
                ),
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: Container(
        color: Colors.black,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: SafeArea(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Précédent
              IconButton(
                onPressed: _current > 0
                    ? () => _page.previousPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      )
                    : null,
                icon: Icon(
                  Icons.arrow_back_ios,
                  size: AppTheme.iconLg,
                  color: _current > 0 ? Colors.white : Colors.white24,
                ),
                constraints: const BoxConstraints(
                  minWidth: AppTheme.touchMin,
                  minHeight: AppTheme.touchMin,
                ),
              ),
              // Indication zoom
              Text(
                'Pincez pour zoomer',
                style: TextStyle(
                  fontSize: AppTheme.fs18,
                  color: Colors.white.withValues(alpha: 0.5),
                ),
              ),
              // Suivant
              IconButton(
                onPressed: _current < widget.photos.length - 1
                    ? () => _page.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      )
                    : null,
                icon: Icon(
                  Icons.arrow_forward_ios,
                  size: AppTheme.iconLg,
                  color: _current < widget.photos.length - 1
                      ? Colors.white
                      : Colors.white24,
                ),
                constraints: const BoxConstraints(
                  minWidth: AppTheme.touchMin,
                  minHeight: AppTheme.touchMin,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
