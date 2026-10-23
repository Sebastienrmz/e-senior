/// Texte préparé pour un contact et conservé localement.
///
/// Cette entrée ne confirme pas l’envoi par SMS ou WhatsApp.
class Message {
  final String id;
  final String contactId;
  final String content;
  final bool isFromMe;
  final DateTime timestamp;
  bool isRead;

  Message({
    required this.id,
    required this.contactId,
    required this.content,
    required this.isFromMe,
    required this.timestamp,
    this.isRead = false,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'contactId': contactId,
    'content': content,
    'isFromMe': isFromMe ? 1 : 0,
    'timestamp': timestamp.toIso8601String(),
    'isRead': isRead ? 1 : 0,
  };

  factory Message.fromMap(Map<String, dynamic> m) => Message(
    id: m['id'] as String,
    contactId: m['contactId'] as String,
    content: m['content'] as String,
    isFromMe: (m['isFromMe'] as int) == 1,
    timestamp: DateTime.parse(m['timestamp'] as String),
    isRead: (m['isRead'] as int) == 1,
  );
}
