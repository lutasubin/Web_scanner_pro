class HistoryMessage {
  const HistoryMessage({
    required this.id,
    required this.title,
    required this.body,
    required this.packageName,
    required this.receivedAt,
  });

  factory HistoryMessage.fromMap(Map<Object?, Object?> map) => HistoryMessage(
    id: map['id'] as String,
    title: map['title'] as String? ?? 'WhatsApp',
    body: map['body'] as String? ?? '',
    packageName: map['packageName'] as String? ?? '',
    receivedAt: (map['receivedAt'] as num?)?.toInt() ?? 0,
  );

  final String id;
  final String title;
  final String body;
  final String packageName;
  final int receivedAt;

  bool get isBusiness => packageName.endsWith('.w4b');

  String get source => isBusiness ? 'WhatsApp Business' : 'WhatsApp';

  String get formattedTime {
    if (receivedAt <= 0) return '';
    final dt = DateTime.fromMillisecondsSinceEpoch(receivedAt).toLocal();
    final now = DateTime.now();
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    final sameDay =
        dt.year == now.year && dt.month == now.month && dt.day == now.day;
    if (sameDay) return '$hh:$mm';
    final dd = dt.day.toString().padLeft(2, '0');
    final mo = dt.month.toString().padLeft(2, '0');
    return '$dd/$mo $hh:$mm';
  }
}

class HistoryConversation {
  const HistoryConversation({
    required this.title,
    required this.packageName,
    required this.messages,
  });

  final String title;
  final String packageName;
  final List<HistoryMessage> messages;

  String get key => '$packageName::$title';
  bool get isBusiness => packageName.endsWith('.w4b');
  String get source => isBusiness ? 'WA Business' : 'WhatsApp';
  HistoryMessage get latest => messages.first;
  int get count => messages.length;
}
