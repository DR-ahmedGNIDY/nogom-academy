import 'package:basketball_academy/core/constants/app_colors.dart';
import 'package:basketball_academy/features/auth/presentation/providers/auth_provider.dart';
import 'package:basketball_academy/features/matches/domain/entities/match_entity.dart';
import 'package:basketball_academy/features/matches/presentation/providers/matches_provider.dart';
import 'package:basketball_academy/features/matches/presentation/screens/select_match_players_screen.dart';
import 'package:basketball_academy/features/whatsapp/utils/whatsapp_utils.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';

class MatchDetailScreen extends ConsumerStatefulWidget {
  final String matchId;
  final String academyId;

  const MatchDetailScreen({
    super.key,
    required this.matchId,
    required this.academyId,
  });

  @override
  ConsumerState<MatchDetailScreen> createState() => _MatchDetailScreenState();
}

class _MatchDetailScreenState extends ConsumerState<MatchDetailScreen> {
  bool _sendingAll = false;

  String _reminderMessage(MatchEntity match, MatchPlayerEntity player) {
    return 'السلام عليكم ورحمة الله وبركاته\n\n'
        'ولي أمر اللاعب:\n'
        '${player.fullName}\n\n'
        'نود تذكيركم بأن ابنكم مشارك معنا في مباراة:\n'
        '${match.name}\n\n'
        'المقامة في:\n'
        '${match.location}\n\n'
        'وذلك بتاريخ:\n'
        '${match.date}\n\n'
        'في تمام الساعة:\n'
        '${match.time}\n\n'
        'نتمنى التوفيق للاعبنا العزيز.\n\n'
        'إدارة أكاديمية نجوم المستقبل';
  }

  Future<void> _sendReminder(MatchEntity match, MatchPlayerEntity player) async {
    final message = _reminderMessage(match, player);
    final opened = await WhatsAppUtils.open(player.parentPhone, message: message);
    if (opened) {
      await ref.read(matchesNotifierProvider.notifier).logReminder(
            matchId: match.id,
            playerId: player.id,
          );
      ref.invalidate(matchDetailProvider(match.id));
    }
  }

  Future<void> _sendToAll(MatchEntity match, List<MatchPlayerEntity> players) async {
    setState(() => _sendingAll = true);
    for (final player in players) {
      await _sendReminder(match, player);
    }
    if (mounted) setState(() => _sendingAll = false);
  }

  @override
  Widget build(BuildContext context) {
    final detailAsync = ref.watch(matchDetailProvider(widget.matchId));
    final canManage =
        ref.watch(authStateProvider).valueOrNull?.user?.canManageOperations ??
            false;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('تفاصيل المباراة'), centerTitle: true),
      body: detailAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text(err.toString())),
        data: (data) {
          final match = data.match;
          final players = data.players;
          return RefreshIndicator(
            onRefresh: () async =>
                ref.invalidate(matchDetailProvider(widget.matchId)),
            child: ListView(
              padding: EdgeInsets.all(16.r),
              children: [
                _MatchInfoCard(match: match, playersCount: players.length),
                Gap(16.h),
                if (canManage)
                  ElevatedButton.icon(
                    onPressed: () async {
                      final added = await Navigator.of(context).push<bool>(
                        MaterialPageRoute(
                          builder: (_) => SelectMatchPlayersScreen(
                            matchId: match.id,
                            academyId: widget.academyId,
                            alreadyAdded: match.playerIds.toSet(),
                          ),
                        ),
                      );
                      if (added == true) {
                        ref.invalidate(matchDetailProvider(widget.matchId));
                      }
                    },
                    icon: const Icon(Icons.group_add_outlined),
                    label: const Text('إضافة لاعبين للمباراة'),
                  ),
                Gap(20.h),
                if (players.isNotEmpty) ...[
                  Row(
                    children: [
                      Text('قائمة اللاعبين (${players.length})',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700)),
                      const Spacer(),
                      if (canManage)
                        TextButton.icon(
                          onPressed: _sendingAll
                              ? null
                              : () => _sendToAll(match, players),
                          icon: const Icon(Icons.campaign_outlined),
                          label: Text(
                              _sendingAll ? 'جارٍ الإرسال...' : 'إرسال للجميع'),
                        ),
                    ],
                  ),
                  Gap(8.h),
                  ...players.map(
                    (player) => Padding(
                      padding: EdgeInsets.only(bottom: 10.h),
                      child: _MatchPlayerCard(
                        player: player,
                        onRemind: canManage
                            ? () => _sendReminder(match, player)
                            : null,
                      ),
                    ),
                  ),
                ] else
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 40.h),
                    child: Center(
                      child: Text('لا يوجد لاعبون في هذه المباراة بعد',
                          style: TextStyle(color: AppColors.grey500)),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _MatchInfoCard extends StatelessWidget {
  final MatchEntity match;
  final int playersCount;

  const _MatchInfoCard({required this.match, required this.playersCount});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      child: Padding(
        padding: EdgeInsets.all(18.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.sports_soccer, color: AppColors.primary, size: 24.sp),
                Gap(8.w),
                Expanded(
                  child: Text(match.name,
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.w800)),
                ),
              ],
            ),
            if (match.sport != null) ...[
              Gap(4.h),
              Text(match.sport!, style: TextStyle(color: AppColors.grey500)),
            ],
            Gap(14.h),
            _InfoRow(icon: Icons.location_on_outlined, label: match.location),
            Gap(8.h),
            _InfoRow(icon: Icons.calendar_today_outlined, label: match.date),
            Gap(8.h),
            _InfoRow(icon: Icons.access_time_outlined, label: match.time),
            Gap(8.h),
            _InfoRow(
              icon: Icons.groups_outlined,
              label: '$playersCount لاعب مشارك',
            ),
            if (match.notes != null && match.notes!.isNotEmpty) ...[
              Gap(8.h),
              _InfoRow(icon: Icons.notes_outlined, label: match.notes!),
            ],
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoRow({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18.sp, color: AppColors.grey400),
        Gap(8.w),
        Expanded(child: Text(label, style: TextStyle(color: AppColors.grey700))),
      ],
    );
  }
}

class _MatchPlayerCard extends StatelessWidget {
  final MatchPlayerEntity player;
  final VoidCallback? onRemind;

  const _MatchPlayerCard({required this.player, required this.onRemind});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
        leading: CircleAvatar(
          backgroundColor: AppColors.primaryContainer,
          backgroundImage: (player.imageUrl != null && player.imageUrl!.isNotEmpty)
              ? CachedNetworkImageProvider(player.imageUrl!)
              : null,
          child: (player.imageUrl == null || player.imageUrl!.isEmpty)
              ? Icon(Icons.person, color: AppColors.primary)
              : null,
        ),
        title: Text(player.fullName,
            style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(
          '${player.playerCode} • ${player.parentPhone}',
          style: TextStyle(fontSize: 12.sp, color: AppColors.grey500),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.notifications_active_outlined),
          color: AppColors.primary,
          tooltip: 'تذكير بالمباراة',
          onPressed: onRemind,
        ),
      ),
    );
  }
}
