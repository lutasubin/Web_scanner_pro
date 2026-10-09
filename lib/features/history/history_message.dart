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
  String get source =>
      packageName.endsWith('.w4b') ? 'WhatsApp Business' : 'WhatsApp';
}
