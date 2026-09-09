class PatientReminder {
  final String id;
  final String title;
  final String? description;
  final String type;
  final DateTime scheduledTime;
  final String? repeat;
  final bool isVoicePromptEnabled;
  final String? voicePromptText;
  final String status;

  PatientReminder({
    required this.id,
    required this.title,
    this.description,
    required this.type,
    required this.scheduledTime,
    this.repeat,
    this.isVoicePromptEnabled = true,
    this.voicePromptText,
    required this.status,
  });

  bool get isAcknowledged => status == 'acknowledged';

  factory PatientReminder.fromJson(Map<String, dynamic> json) {
    DateTime parsedTime;
    try {
      parsedTime = json['scheduledTime'] != null
          ? DateTime.parse(json['scheduledTime'].toString())
          : DateTime.now();
    } catch (_) {
      parsedTime = DateTime.now();
    }

    return PatientReminder(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Reminder',
      description: json['description']?.toString(),
      type: json['type']?.toString() ?? 'custom',
      scheduledTime: parsedTime,
      repeat: json['repeat']?.toString() ?? 'daily',
      isVoicePromptEnabled: json['isVoicePromptEnabled'] == true,
      voicePromptText: json['voicePromptText']?.toString(),
      status: json['status']?.toString() ?? 'pending',
    );
  }

  Map<String, dynamic> toJson() => {
        '_id': id,
        'title': title,
        'description': description,
        'type': type,
        'scheduledTime': scheduledTime.toIso8601String(),
        'repeat': repeat,
        'isVoicePromptEnabled': isVoicePromptEnabled,
        'voicePromptText': voicePromptText,
        'status': status,
      };
}
