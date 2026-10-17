enum CoachRole { user, assistant, system }

enum Mood { calm, restless, tired, scattered }

class CoachMessage {
  const CoachMessage({
    required this.id,
    required this.role,
    required this.body,
    required this.at,
  });

  final String id;
  final CoachRole role;
  final String body;
  final DateTime at;

  CoachMessage copyWith({String? body}) => CoachMessage(
        id: id,
        role: role,
        body: body ?? this.body,
        at: at,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'role': role.name,
        'body': body,
        'at': at.toIso8601String(),
      };

  factory CoachMessage.fromJson(Map<String, dynamic> json) {
    return CoachMessage(
      id: json['id'] as String? ?? '',
      role: CoachRole.values.firstWhere(
        (e) => e.name == json['role'],
        orElse: () => CoachRole.assistant,
      ),
      body: json['body'] as String? ?? '',
      at: DateTime.tryParse(json['at'] as String? ?? '') ?? DateTime.now(),
    );
  }
}