class WebSession {
  const WebSession({
    required this.id,
    required this.name,
    this.isDefault = false,
    this.isActive = false,
  });

  factory WebSession.fromMap(Map<Object?, Object?> map) => WebSession(
    id: map['id'] as String,
    name: map['name'] as String,
    isDefault: map['isDefault'] as bool? ?? false,
    isActive: map['isActive'] as bool? ?? false,
  );

  final String id;
  final String name;
  final bool isDefault;
  final bool isActive;
}
