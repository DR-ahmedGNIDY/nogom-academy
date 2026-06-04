import 'package:basketball_academy/features/subscription/domain/entities/subscription_entity.dart';
import 'package:json_annotation/json_annotation.dart';

part 'subscription_model.g.dart';

@JsonSerializable()
class SubscriptionModel {
  @JsonKey(name: '_id')
  final String id;
  final String academyId;
  final String playerId;
  final String type; // 'NEW_SUBSCRIPTION' | 'RENEWAL'
  final double amount;
  final DateTime startDate;
  final DateTime endDate;
  final String? notes;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime? updatedAt;

  const SubscriptionModel({
    required this.id,
    required this.academyId,
    required this.playerId,
    required this.type,
    required this.amount,
    required this.startDate,
    required this.endDate,
    this.notes,
    required this.createdAt,
    this.updatedAt,
  });

  factory SubscriptionModel.fromJson(Map<String, dynamic> json) =>
      _$SubscriptionModelFromJson(json);

  Map<String, dynamic> toJson() => _$SubscriptionModelToJson(this);

  SubscriptionEntity toEntity() => SubscriptionEntity(
        id: id,
        academyId: academyId,
        playerId: playerId,
        type: type == 'NEW_SUBSCRIPTION'
            ? SubscriptionType.newSubscription
            : SubscriptionType.renewal,
        amount: amount,
        startDate: startDate,
        endDate: endDate,
        notes: notes,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
}
