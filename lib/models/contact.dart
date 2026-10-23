/// Contact enregistré dans la base locale.
///
/// Un contact peut avoir une photo et être affiché parmi les favoris.
/// Un seul contact peut être désigné pour le bouton SOS.
class Contact {
  final String id;
  String name;
  String phone;
  String? photoPath;
  bool isFavorite;
  bool isEmergency;
  int sortOrder;
  DateTime createdAt;
  DateTime updatedAt;

  Contact({
    required this.id,
    required this.name,
    required this.phone,
    this.photoPath,
    this.isFavorite = true,
    this.isEmergency = false,
    this.sortOrder = 0,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  /// Initiales pour l'avatar par défaut.
  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    final trimmed = name.trim();
    return trimmed.isNotEmpty ? trimmed[0].toUpperCase() : '?';
  }

  /// Numéro formaté pour affichage.
  String get displayPhone {
    final digits = phone.replaceAll(RegExp(r'[^\d+]'), '');
    if (digits.length == 10) {
      return '${digits.substring(0, 2)} ${digits.substring(2, 4)} '
          '${digits.substring(4, 6)} ${digits.substring(6, 8)} ${digits.substring(8)}';
    }
    return phone;
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'phone': phone,
    'photoPath': photoPath,
    'isFavorite': isFavorite ? 1 : 0,
    'isEmergency': isEmergency ? 1 : 0,
    'sortOrder': sortOrder,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory Contact.fromMap(Map<String, dynamic> m) => Contact(
    id: m['id'] as String,
    name: m['name'] as String,
    phone: m['phone'] as String,
    photoPath: m['photoPath'] as String?,
    isFavorite: (m['isFavorite'] as int) == 1,
    isEmergency: (m['isEmergency'] as int) == 1,
    sortOrder: (m['sortOrder'] as int?) ?? 0,
    createdAt: DateTime.parse(m['createdAt'] as String),
    updatedAt: DateTime.parse(m['updatedAt'] as String),
  );

  Contact copyWith({
    String? name,
    String? phone,
    String? photoPath,
    bool? isFavorite,
    bool? isEmergency,
    int? sortOrder,
    bool clearPhoto = false,
  }) => Contact(
    id: id,
    name: name ?? this.name,
    phone: phone ?? this.phone,
    photoPath: clearPhoto ? null : (photoPath ?? this.photoPath),
    isFavorite: isFavorite ?? this.isFavorite,
    isEmergency: isEmergency ?? this.isEmergency,
    sortOrder: sortOrder ?? this.sortOrder,
    createdAt: createdAt,
    updatedAt: DateTime.now(),
  );
}
