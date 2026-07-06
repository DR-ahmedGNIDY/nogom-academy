import 'package:basketball_academy/core/constants/app_colors.dart';
import 'package:basketball_academy/core/di/injection_container.dart';
import 'package:basketball_academy/core/errors/failures.dart';
import 'package:basketball_academy/features/auth/presentation/providers/auth_provider.dart';
import 'package:basketball_academy/features/groups/domain/entities/group_entity.dart';
import 'package:basketball_academy/features/groups/domain/usecases/get_group_usecase.dart';
import 'package:basketball_academy/features/groups/presentation/providers/groups_provider.dart';
import 'package:basketball_academy/features/groups/presentation/screens/edit_group_screen.dart';
import 'package:basketball_academy/features/player/domain/entities/player_entity.dart';
import 'package:basketball_academy/features/player/presentation/screens/player_detail_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';

final _groupDetailProvider = FutureProvider.autoDispose
    .family<({GroupEntity group, List<PlayerEntity> players}), String>(
        (ref, groupId) async {
  final usecase = sl<GetGroupUsecase>();
  final result = await usecase(groupId);
  return result.fold(
    // Throw the Failure itself (not just its message) so the UI can tell a
    // 404 (group deleted/never existed) apart from a real network/server error.
    (failure) => throw failure,
    (data) => data,
  );
});

class GroupDetailScreen extends ConsumerWidget {
  final String academyId;
  final String groupId;

  const GroupDetailScreen({
    super.key,
    required this.academyId,
    required this.groupId,
  });

  Color _occupationColor(double? rate) {
    if (rate == null) return AppColors.grey400;
    if (rate >= 90) return AppColors.error;
    if (rate >= 70) return AppColors.warning;
    return AppColors.success;
  }

  Future<void> _confirmDelete(
      BuildContext context, WidgetRef ref, String groupId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        title: const Text('حذف المجموعة'),
        content: const Text('هل أنت متأكد من حذف هذه المجموعة؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: AppColors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('حذف'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    if (!context.mounted) return;

    final error = await ref.read(groupsProvider.notifier).deleteGroup(groupId);

    if (!context.mounted) return;

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم حذف المجموعة بنجاح'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(_groupDetailProvider(groupId));
    final authState = ref.watch(authStateProvider).valueOrNull;
    final isSuperAdmin = authState?.user?.isSuperAdmin ?? false;
    final isAcademyLevelSame =
        !isSuperAdmin && authState?.user?.academyId == academyId;
    final canEdit = isSuperAdmin || isAcademyLevelSame;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('تفاصيل المجموعة'),
        centerTitle: true,
        actions: [
          detailAsync.whenOrNull(
                data: (data) => Row(
                  children: [
                    if (canEdit)
                      IconButton(
                        icon: const Icon(Icons.edit_outlined),
                        tooltip: 'تعديل',
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => EditGroupScreen(
                                academyId: academyId,
                                group: data.group,
                              ),
                            ),
                          );
                        },
                      ),
                    if (isSuperAdmin)
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: AppColors.error),
                        tooltip: 'حذف',
                        onPressed: () => _confirmDelete(context, ref, groupId),
                      ),
                  ],
                ),
              ) ??
              const SizedBox.shrink(),
        ],
      ),
      body: detailAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) {
          final isDeleted = err is NotFoundFailure;
          return Center(
            child: Padding(
              padding: EdgeInsets.all(24.r),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isDeleted ? Icons.groups_outlined : Icons.error_outline,
                    size: 64.sp,
                    color: isDeleted ? AppColors.grey400 : AppColors.error,
                  ),
                  Gap(16.h),
                  Text(
                    isDeleted ? 'تم حذف المجموعة' : (err as Failure).message,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  Gap(16.h),
                  if (isDeleted)
                    ElevatedButton.icon(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('العودة للقائمة'),
                    )
                  else
                    ElevatedButton.icon(
                      onPressed: () =>
                          ref.invalidate(_groupDetailProvider(groupId)),
                      icon: const Icon(Icons.refresh),
                      label: const Text('إعادة المحاولة'),
                    ),
                ],
              ),
            ),
          );
        },
        data: (data) {
          final group = data.group;
          final players = data.players;
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(_groupDetailProvider(groupId)),
            child: ListView(
              padding: EdgeInsets.all(16.r),
              children: [
                _GroupInfoCard(
                  group: group,
                  occupationColor: _occupationColor(group.occupationRate),
                ),
                Gap(20.h),
                Text(
                  'اللاعبون (${players.length})',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                Gap(8.h),
                if (players.isEmpty)
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 40.h),
                    child: const Center(
                      child: Text('لا يوجد لاعبون في هذه المجموعة بعد',
                          style: TextStyle(color: AppColors.grey500)),
                    ),
                  )
                else
                  ...players.map(
                    (player) => Padding(
                      padding: EdgeInsets.only(bottom: 10.h),
                      child: _GroupPlayerCard(
                        player: player,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => PlayerDetailScreen(
                              playerId: player.id,
                              academyId: academyId,
                            ),
                          ),
                        ),
                      ),
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

class _GroupInfoCard extends StatelessWidget {
  final GroupEntity group;
  final Color occupationColor;

  const _GroupInfoCard({required this.group, required this.occupationColor});

  @override
  Widget build(BuildContext context) {
    final occupationRate = group.occupationRate;
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
                Icon(Icons.groups_outlined, color: AppColors.primary, size: 24.sp),
                Gap(8.w),
                Expanded(
                  child: Text(group.name,
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.w800)),
                ),
              ],
            ),
            Gap(14.h),
            _InfoRow(
              icon: Icons.cake_outlined,
              label: group.ageGroup ?? 'بدون فئة عمرية',
            ),
            Gap(8.h),
            _InfoRow(
              icon: Icons.person_outline,
              label: 'المدرب: ${group.coachId ?? 'غير محدد'}',
            ),
            Gap(8.h),
            _InfoRow(
              icon: Icons.groups_outlined,
              label:
                  'اللاعبون: ${group.playersCount}${group.capacity != null ? ' / ${group.capacity}' : ''}',
            ),
            if (occupationRate != null) ...[
              Gap(12.h),
              Row(
                children: [
                  Text(
                    'نسبة الإشغال: ',
                    style: TextStyle(color: AppColors.grey700, fontSize: 13.sp),
                  ),
                  Text(
                    '${occupationRate.toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: occupationColor,
                      fontSize: 13.sp,
                    ),
                  ),
                ],
              ),
              Gap(6.h),
              ClipRRect(
                borderRadius: BorderRadius.circular(8.r),
                child: LinearProgressIndicator(
                  value: (occupationRate / 100).clamp(0.0, 1.0),
                  minHeight: 8.h,
                  backgroundColor: AppColors.grey200,
                  color: occupationColor,
                ),
              ),
            ],
            _InfoRow(
              icon: group.isActive ? Icons.check_circle_outline : Icons.cancel_outlined,
              label: group.isActive ? 'نشطة' : 'غير نشطة',
            ),
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
        Expanded(child: Text(label, style: const TextStyle(color: AppColors.grey700))),
      ],
    );
  }
}

class _GroupPlayerCard extends StatelessWidget {
  final PlayerEntity player;
  final VoidCallback onTap;

  const _GroupPlayerCard({required this.player, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
      child: ListTile(
        onTap: onTap,
        contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
        leading: CircleAvatar(
          backgroundColor: AppColors.primaryContainer,
          backgroundImage: (player.imageUrl != null && player.imageUrl!.isNotEmpty)
              ? CachedNetworkImageProvider(player.imageUrl!)
              : null,
          child: (player.imageUrl == null || player.imageUrl!.isEmpty)
              ? const Icon(Icons.person, color: AppColors.primary)
              : null,
        ),
        title: Text(player.fullName,
            style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(
          '${player.playerCode} • ${player.parentPhone}',
          style: TextStyle(fontSize: 12.sp, color: AppColors.grey500),
        ),
        trailing: const Icon(Icons.chevron_left, color: AppColors.grey300),
      ),
    );
  }
}
