import 'package:basketball_academy/features/matches/domain/entities/match_entity.dart';

class MatchMapper {
  static MatchEntity fromJson(Map<String, dynamic> json) {
    final reminderLog = (json['reminderLog'] as List?) ?? const [];
    DateTime? lastReminderAt;
    for (final entry in reminderLog) {
      if (entry is Map && entry['sentAt'] != null) {
        final parsed = DateTime.tryParse(entry['sentAt'].toString());
        if (parsed != null &&
            (lastReminderAt == null || parsed.isAfter(lastReminderAt))) {
          lastReminderAt = parsed;
        }
      }
    }

    return MatchEntity(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      academyId: (json['academyId'] ?? '').toString(),
      sport: json['sport'] as String?,
      name: (json['name'] ?? '').toString(),
      location: (json['location'] ?? '').toString(),
      date: (json['date'] ?? '').toString(),
      time: (json['time'] ?? '').toString(),
      notes: json['notes'] as String?,
      playerIds: ((json['playerIds'] as List?) ?? const [])
          .map((e) => e.toString())
          .toList(),
      reminderCount: reminderLog.length,
      lastReminderAt: lastReminderAt,
      createdAt:
          DateTime.tryParse((json['createdAt'] ?? '').toString()) ??
              DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : null,
    );
  }
}

class MatchPlayerMapper {
  static MatchPlayerEntity fromJson(Map<String, dynamic> json) {
    return MatchPlayerEntity(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      fullName: (json['fullName'] ?? '').toString(),
      playerCode: (json['playerCode'] ?? '').toString(),
      imageUrl: json['image_url'] as String?,
      parentPhone: (json['parentPhone'] ?? '').toString(),
      parentName: (json['parentName'] ?? '').toString(),
    );
  }
}
