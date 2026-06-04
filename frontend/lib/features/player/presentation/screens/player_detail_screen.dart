import 'package:basketball_academy/core/constants/app_colors.dart';
import 'package:basketball_academy/core/constants/app_strings.dart';
import 'package:basketball_academy/features/auth/presentation/providers/auth_provider.dart';
import 'package:basketball_academy/features/player/domain/entities/player_entity.dart';
import 'package:basketball_academy/features/player/presentation/providers/player_provider.dart';
import 'package:basketball_academy/features/player/presentation/screens/edit_player_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';

class PlayerDetailScreen extends ConsumerWidget {
  final String playerId;
  final String academyId;

  const PlayerDetailScreen({
    super.key,
    required this.playerId,
    required this.academyId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playersAsync = ref.watch(playersProvider);

    return playersAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(title: const Text(AppStrings.playerDetails)),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (err, _) => Scaffold(
        appBar: AppBar(title: const Text(AppStrings.playerDetails)),
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(24.r),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64.sp, color: AppColors.error),
                Gap(16.h),
                Text(err.toString(),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium),
                Gap(16.h),
                ElevatedButton.icon(
                  onPressed: () => ref.read(playersProvider.notifier).refresh(),
                  icon: const Icon(Icons.refresh),
                  label: const Text(AppStrings.retry),
                ),
              ],
            ),
          ),
        ),
      ),
      data: (state) {
        PlayerEntity? player;
        try {
          player = state.players.firstWhere((p) => p.id == playerId);
        } catch (_) {
          player = null;
        }

        if (player == null) {
          return Scaffold(
            appBar: AppBar(title: const Text(AppStrings.playerDetails)),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.person_off_outlined,
                      size: 80.sp, color: AppColors.grey300),
                  Gap(16.h),
                  Text(
                    'اللاعب غير موجود',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(color: AppColors.grey500),
                  ),
                ],
              ),
            ),
          );
        }

        return _PlayerDetailContent(
          player: player,
          academyId: academyId,
        );
      },
    );
  }
}

class _PlayerDetailContent extends ConsumerWidget {
  final PlayerEntity player;
  final String academyId;

  const _PlayerDetailContent({
    required this.player,
    required this.academyId,
  });

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        title: const Text('حذف اللاعب'),
        content: const Text(AppStrings.deletePlayerConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text(AppStrings.cancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: AppColors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(AppStrings.delete),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    if (!context.mounted) return;

    final error =
        await ref.read(playersProvider.notifier).deletePlayer(player.id);

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
          content: Text(AppStrings.playerDeleted),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
      if (context.mounted) Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final authState = ref.watch(authStateProvider).valueOrNull;
    final isSuperAdmin = authState?.user?.isSuperAdmin ?? false;
    final isAcademyAdminSame =
        !isSuperAdmin && authState?.user?.academyId == academyId;
    final canEdit = isSuperAdmin || isAcademyAdminSame;

    final dateFormat = DateFormat('dd/MM/yyyy', 'ar');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(AppStrings.playerDetails),
        centerTitle: true,
        actions: [
          if (canEdit) ...[
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: AppStrings.edit,
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => EditPlayerScreen(
                      player: player,
                      academyId: academyId,
                    ),
                  ),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: AppColors.error),
              tooltip: AppStrings.delete,
              onPressed: () => _confirmDelete(context, ref),
            ),
          ],
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Container(
              color: AppColors.primaryContainer,
              padding: EdgeInsets.symmetric(vertical: 32.h),
              child: Column(
                children: [
                  // Player photo
                  Container(
                    width: 120.w,
                    height: 120.w,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: player.imageUrl != null &&
                              player.imageUrl!.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: player.imageUrl!,
                              fit: BoxFit.cover,
                              placeholder: (_, __) => const Center(
                                  child: CircularProgressIndicator()),
                              errorWidget: (_, __, ___) => Icon(
                                Icons.person,
                                color: AppColors.primary,
                                size: 64.sp,
                              ),
                            )
                          : Icon(
                              Icons.person,
                              color: AppColors.primary,
                              size: 64.sp,
                            ),
                    ),
                  ),
                  Gap(16.h),
                  // Player code chip
                  Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(20.r),
                    ),
                    child: Text(
                      player.playerCode,
                      style: TextStyle(
                        fontSize: 13.sp,
                        color: AppColors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Gap(10.h),
                  Text(
                    player.fullName,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.secondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            Padding(
              padding: EdgeInsets.all(20.r),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Player info card
                  Text(
                    AppStrings.playerInfo,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.grey800,
                    ),
                  ),
                  Gap(12.h),
                  _InfoCard(
                    children: [
                      _InfoRow(
                        icon: Icons.cake_outlined,
                        label: AppStrings.birthDate,
                        value: dateFormat.format(player.birthDate),
                      ),
                      _RowDivider(),
                      _InfoRow(
                        icon: Icons.person_outline,
                        label: AppStrings.age,
                        value: '${player.age} ${AppStrings.yearsOld}',
                      ),
                      if (isSuperAdmin) ...[
                        _RowDivider(),
                        _InfoRow(
                          icon: Icons.business_outlined,
                          label: 'معرّف الأكاديمية',
                          value: player.academyId,
                        ),
                      ],
                    ],
                  ),

                  Gap(24.h),

                  // Parent info card
                  Text(
                    AppStrings.parentInfo,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.grey800,
                    ),
                  ),
                  Gap(12.h),
                  _InfoCard(
                    children: [
                      _InfoRow(
                        icon: Icons.person_outline,
                        label: AppStrings.parentName,
                        value: player.parentName,
                      ),
                      _RowDivider(),
                      _InfoRow(
                        icon: Icons.family_restroom_outlined,
                        label: AppStrings.parentRelationship,
                        value: player.parentRelationship,
                      ),
                      if (player.parentJob != null &&
                          player.parentJob!.isNotEmpty) ...[
                        _RowDivider(),
                        _InfoRow(
                          icon: Icons.work_outline,
                          label: AppStrings.parentJob,
                          value: player.parentJob!,
                        ),
                      ],
                      _RowDivider(),
                      _InfoRow(
                        icon: Icons.phone_outlined,
                        label: AppStrings.parentPhone,
                        value: player.parentPhone,
                      ),
                    ],
                  ),

                  // Notes
                  if (player.notes != null && player.notes!.isNotEmpty) ...[
                    Gap(24.h),
                    Text(
                      AppStrings.notes,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.grey800,
                      ),
                    ),
                    Gap(12.h),
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(16.r),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(16.r),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        player.notes!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppColors.grey700,
                          height: 1.6,
                        ),
                      ),
                    ),
                  ],

                  Gap(80.h),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Info card / row helpers
// ---------------------------------------------------------------------------

class _InfoCard extends StatelessWidget {
  final List<Widget> children;
  const _InfoCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16.r),
        child: Column(children: children),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      child: Row(
        children: [
          Container(
            width: 40.w,
            height: 40.w,
            decoration: BoxDecoration(
              color: AppColors.primaryContainer,
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Icon(icon, color: AppColors.primary, size: 20.sp),
          ),
          Gap(12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.labelSmall
                      ?.copyWith(color: AppColors.grey500),
                ),
                Gap(2.h),
                Text(
                  value,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.grey800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RowDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      indent: 68.w,
      endIndent: 16.w,
      color: AppColors.grey100,
    );
  }
}
