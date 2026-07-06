import 'package:basketball_academy/core/constants/app_colors.dart';
import 'package:basketball_academy/core/widgets/responsive_center.dart';
import 'package:basketball_academy/core/widgets/responsive_scaffold.dart';
import 'package:basketball_academy/features/academy/presentation/providers/academy_provider.dart';
import 'package:basketball_academy/features/auth/presentation/providers/auth_provider.dart';
import 'package:basketball_academy/features/groups/domain/entities/group_entity.dart';
import 'package:basketball_academy/features/groups/presentation/providers/groups_provider.dart';
import 'package:basketball_academy/features/groups/presentation/screens/create_group_screen.dart';
import 'package:basketball_academy/features/groups/presentation/screens/group_details_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';

class GroupsListScreen extends ConsumerStatefulWidget {
  final String academyId;

  const GroupsListScreen({super.key, required this.academyId});

  @override
  ConsumerState<GroupsListScreen> createState() => _GroupsListScreenState();
}

class _GroupsListScreenState extends ConsumerState<GroupsListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(groupsProvider.notifier).filterByAcademy(widget.academyId);
    });
  }

  @override
  void didUpdateWidget(GroupsListScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.academyId != widget.academyId) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(groupsProvider.notifier).filterByAcademy(widget.academyId);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final groupsAsync = ref.watch(groupsProvider);
    final authState = ref.watch(authStateProvider).valueOrNull;
    final isSuperAdmin = authState?.user?.isSuperAdmin ?? false;

    final academy =
        ref.watch(academyByIdProvider(widget.academyId)).valueOrNull;
    final isMultiSport = academy?.isMultiSport ?? false;
    final academySports = academy?.sports ?? const <String>[];

    return ResponsiveScaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('المجموعات'),
        centerTitle: true,
      ),
      body: ResponsiveCenter(
        maxWidth: 900,
        child: Column(
          children: [
            if (isMultiSport)
              groupsAsync.whenOrNull(
                    data: (state) => _SportChipRow(
                      options: academySports,
                      selected: state.sportIdFilter,
                      onSelected: (sport) => ref
                          .read(groupsProvider.notifier)
                          .filterBySport(sport),
                    ),
                  ) ??
                  const SizedBox.shrink(),
            Expanded(
              child: groupsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) => _ErrorState(
                  message: err.toString(),
                  onRetry: () => ref.read(groupsProvider.notifier).refresh(),
                ),
                data: (state) {
                  if (state.groups.isEmpty) {
                    return _EmptyState(
                      showCreateButton: isSuperAdmin,
                      onCreate: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              CreateGroupScreen(academyId: widget.academyId),
                        ),
                      ),
                    );
                  }
                  return RefreshIndicator(
                    onRefresh: () => ref.read(groupsProvider.notifier).refresh(),
                    child: ListView.separated(
                      padding: EdgeInsets.symmetric(
                          horizontal: 16.w, vertical: 12.h),
                      itemCount: state.groups.length,
                      separatorBuilder: (_, __) => Gap(10.h),
                      itemBuilder: (context, index) {
                        final group = state.groups[index];
                        return _GroupCard(
                          group: group,
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => GroupDetailScreen(
                                academyId: widget.academyId,
                                groupId: group.id,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: isSuperAdmin
          ? FloatingActionButton.extended(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => CreateGroupScreen(academyId: widget.academyId),
                  ),
                );
              },
              icon: const Icon(Icons.group_add_outlined),
              label: const Text('إضافة مجموعة'),
            )
          : null,
    );
  }
}

class _SportChipRow extends StatelessWidget {
  final List<String> options;
  final String? selected;
  final ValueChanged<String?> onSelected;

  const _SportChipRow({
    required this.options,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48.h,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        itemCount: options.length + 1,
        separatorBuilder: (_, __) => Gap(8.w),
        itemBuilder: (context, index) {
          if (index == 0) {
            final isSelected = selected == null;
            return FilterChip(
              label: Text(
                'الكل',
                style: TextStyle(
                  fontSize: 12.sp,
                  color: isSelected ? AppColors.white : AppColors.grey700,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
              selected: isSelected,
              onSelected: (_) => onSelected(null),
              selectedColor: AppColors.primary,
              backgroundColor: AppColors.white,
              side: BorderSide(
                color: isSelected ? AppColors.primary : AppColors.grey200,
              ),
              checkmarkColor: AppColors.white,
            );
          }
          final option = options[index - 1];
          final isSelected = selected == option;
          return FilterChip(
            label: Text(
              option,
              style: TextStyle(
                fontSize: 12.sp,
                color: isSelected ? AppColors.white : AppColors.grey700,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
            selected: isSelected,
            onSelected: (_) => onSelected(isSelected ? null : option),
            selectedColor: AppColors.primary,
            backgroundColor: AppColors.white,
            side: BorderSide(
              color: isSelected ? AppColors.primary : AppColors.grey200,
            ),
            checkmarkColor: AppColors.white,
          );
        },
      ),
    );
  }
}

class _GroupCard extends StatelessWidget {
  final GroupEntity group;
  final VoidCallback onTap;

  const _GroupCard({required this.group, required this.onTap});

  Color _occupationColor(double? rate) {
    if (rate == null) return AppColors.grey400;
    if (rate >= 90) return AppColors.error;
    if (rate >= 70) return AppColors.warning;
    return AppColors.success;
  }

  @override
  Widget build(BuildContext context) {
    final occupationRate = group.occupationRate;
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16.r),
        child: Padding(
          padding: EdgeInsets.all(14.r),
          child: Row(
            children: [
              CircleAvatar(
                radius: 26.r,
                backgroundColor: AppColors.primaryContainer,
                child: const Icon(Icons.groups_outlined, color: AppColors.primary),
              ),
              Gap(12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      group.name,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Gap(4.h),
                    Text(
                      group.ageGroup ?? 'بدون فئة عمرية',
                      style: TextStyle(fontSize: 12.sp, color: AppColors.grey500),
                    ),
                    Gap(4.h),
                    Row(
                      children: [
                        Icon(Icons.person_outline,
                            size: 14.sp, color: AppColors.grey400),
                        Gap(4.w),
                        Text(
                          '${group.playersCount}${group.capacity != null ? '/${group.capacity}' : ''}',
                          style: TextStyle(fontSize: 12.sp, color: AppColors.grey500),
                        ),
                        if (occupationRate != null) ...[
                          Gap(8.w),
                          Text(
                            '${occupationRate.toStringAsFixed(0)}%',
                            style: TextStyle(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w700,
                              color: _occupationColor(occupationRate),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_left, color: AppColors.grey300),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool showCreateButton;
  final VoidCallback onCreate;

  const _EmptyState({required this.showCreateButton, required this.onCreate});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.r),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.groups_outlined, size: 80.sp, color: AppColors.grey300),
            Gap(16.h),
            Text(
              'لا توجد مجموعات حالياً',
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(color: AppColors.grey500),
            ),
            if (showCreateButton) ...[
              Gap(20.h),
              ElevatedButton.icon(
                onPressed: onCreate,
                icon: const Icon(Icons.group_add_outlined),
                label: const Text('إنشاء مجموعة'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.r),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64.sp, color: AppColors.error),
            Gap(16.h),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            Gap(16.h),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      ),
    );
  }
}
