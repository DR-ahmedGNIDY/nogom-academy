import 'package:basketball_academy/core/constants/app_colors.dart';
import 'package:basketball_academy/core/widgets/responsive_center.dart';
import 'package:basketball_academy/core/widgets/responsive_scaffold.dart';
import 'package:basketball_academy/features/auth/presentation/providers/auth_provider.dart';
import 'package:basketball_academy/features/matches/domain/entities/match_entity.dart';
import 'package:basketball_academy/features/matches/presentation/providers/matches_provider.dart';
import 'package:basketball_academy/features/matches/presentation/screens/create_match_screen.dart';
import 'package:basketball_academy/features/matches/presentation/screens/match_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';

class MatchesListScreen extends ConsumerWidget {
  final String academyId;

  const MatchesListScreen({super.key, required this.academyId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final matchesAsync = ref.watch(matchesListProvider(academyId));
    final canManage =
        ref.watch(authStateProvider).valueOrNull?.user?.canManageOperations ??
            false;

    return ResponsiveScaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('المباريات'), centerTitle: true),
      body: ResponsiveCenter(
        maxWidth: 900,
        child: matchesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text(err.toString())),
        data: (matches) {
          if (matches.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.sports_soccer_outlined,
                      size: 80.sp, color: AppColors.grey300),
                  Gap(16.h),
                  Text('لا توجد مباريات بعد',
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(color: AppColors.grey500)),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(matchesListProvider(academyId)),
            child: ListView.separated(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              itemCount: matches.length,
              separatorBuilder: (_, __) => Gap(10.h),
              itemBuilder: (context, index) {
                final match = matches[index];
                return _MatchCard(
                  match: match,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => MatchDetailScreen(
                        matchId: match.id,
                        academyId: academyId,
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
      floatingActionButton: canManage
          ? FloatingActionButton.extended(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => CreateMatchScreen(academyId: academyId),
                ),
              ),
              icon: const Icon(Icons.add),
              label: const Text('مباراة جديدة'),
            )
          : null,
    );
  }
}

class _MatchCard extends StatelessWidget {
  final MatchEntity match;
  final VoidCallback onTap;

  const _MatchCard({required this.match, required this.onTap});

  @override
  Widget build(BuildContext context) {
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
                child: Icon(Icons.sports_soccer, color: AppColors.primary),
              ),
              Gap(12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(match.name,
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                    Gap(4.h),
                    Text(
                      '${match.location} • ${match.date} ${match.time}',
                      style: TextStyle(fontSize: 12.sp, color: AppColors.grey500),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_left, color: AppColors.grey300),
            ],
          ),
        ),
      ),
    );
  }
}
