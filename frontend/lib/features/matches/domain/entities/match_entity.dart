import 'package:equatable/equatable.dart';

class MatchEntity extends Equatable {
  final String id;
  final String academyId;
  final String? sport;
  final String name;
  final String location;
  final String date; // 'YYYY-MM-DD'
  final String time; // 'HH:mm'
  final String? notes;
  final List<String> playerIds;
  final int reminderCount;
  final DateTime? lastReminderAt;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const MatchEntity({
    required this.id,
    required this.academyId,
    this.sport,
    required this.name,
    required this.location,
    required this.date,
    required this.time,
    this.notes,
    this.playerIds = const [],
    this.reminderCount = 0,
    this.lastReminderAt,
    required this.createdAt,
    this.updatedAt,
  });

  int get playersCount => playerIds.length;

  @override
  List<Object?> get props => [
        id,
        academyId,
        sport,
        name,
        location,
        date,
        time,
        notes,
        playerIds,
        reminderCount,
        lastReminderAt,
        createdAt,
        updatedAt,
      ];
}

/// لاعب مشارك في مباراة — يجمع بين بيانات اللاعب الأساسية وحالة التذكير.
class MatchPlayerEntity extends Equatable {
  final String id;
  final String fullName;
  final String playerCode;
  final String? imageUrl;
  final String parentPhone;
  final String parentName;

  const MatchPlayerEntity({
    required this.id,
    required this.fullName,
    required this.playerCode,
    this.imageUrl,
    required this.parentPhone,
    required this.parentName,
  });

  @override
  List<Object?> get props =>
      [id, fullName, playerCode, imageUrl, parentPhone, parentName];
}
