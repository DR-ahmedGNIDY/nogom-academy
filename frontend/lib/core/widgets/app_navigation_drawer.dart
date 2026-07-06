import 'package:basketball_academy/core/constants/app_colors.dart';
import 'package:basketball_academy/core/constants/app_strings.dart';
import 'package:basketball_academy/core/router/app_router.dart';
import 'package:basketball_academy/features/auth/presentation/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

/// Shared primary navigation, rendered as a [Drawer] on mobile/tablet and as
/// a persistent panel inside [ResponsiveScaffold] on desktop widths.
///
/// يظهر لكل من يصل إلى الشاشات الرئيسية — أي super_admin / supervisor /
/// academy_admin فقط (الدور المحدود admin يُعاد توجيهه بعيداً عن هذه الشاشات
/// قبل أن تُرسم، لذا لا حاجة لفحص دور إضافي هنا).
class AppNavigationDrawer extends ConsumerWidget {
  final String userName;
  final bool isSuperAdmin;

  /// When true, this renders as a persistent side panel (no [Drawer] chrome,
  /// no auto-close-on-tap). When false, it renders as a real [Drawer] that
  /// closes itself before navigating.
  final bool isSidebar;

  const AppNavigationDrawer({
    super.key,
    required this.userName,
    required this.isSuperAdmin,
    this.isSidebar = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final content = SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.secondary, AppColors.secondaryLight],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(6.r),
                  decoration: const BoxDecoration(
                    color: AppColors.white,
                    shape: BoxShape.circle,
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      'assets/images/logo.png',
                      width: 34.r,
                      height: 34.r,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Icon(
                        Icons.person_outline,
                        color: AppColors.primary,
                        size: 26.r,
                      ),
                    ),
                  ),
                ),
                Gap(12.w),
                Expanded(
                  child: Text(
                    userName,
                    style: TextStyle(
                      color: AppColors.white,
                      fontSize: 15.sp,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          Gap(8.h),
          _NavItem(
            icon: Icons.dashboard_outlined,
            label: AppStrings.dashboard,
            isSidebar: isSidebar,
            onTap: () => context.go(AppRoutes.home),
          ),
          // التقارير — متاحة لـ super_admin / supervisor / academy_admin
          _NavItem(
            icon: Icons.bar_chart_outlined,
            label: AppStrings.reports,
            isSidebar: isSidebar,
            onTap: () => context.push(AppRoutes.reports),
          ),
          if (isSuperAdmin)
            _NavItem(
              icon: Icons.list_alt_outlined,
              label: AppStrings.academies,
              isSidebar: isSidebar,
              onTap: () => context.go(AppRoutes.academyList),
            ),
          _NavItem(
            icon: Icons.notifications_outlined,
            label: AppStrings.notifications,
            isSidebar: isSidebar,
            onTap: () => context.push(AppRoutes.notifications),
          ),
          _NavItem(
            icon: Icons.manage_accounts_outlined,
            label: 'إعدادات الحساب',
            isSidebar: isSidebar,
            onTap: () => context.push(AppRoutes.accountSettings),
          ),
          const Spacer(),
          const Divider(height: 1),
          _NavItem(
            icon: Icons.logout_outlined,
            label: AppStrings.logout,
            color: AppColors.error,
            isSidebar: isSidebar,
            onTap: () async {
              await ref.read(authStateProvider.notifier).logout();
              if (context.mounted) context.go(AppRoutes.login);
            },
          ),
          Gap(8.h),
        ],
      ),
    );

    if (isSidebar) {
      return Container(
        color: AppColors.surface,
        child: content,
      );
    }

    return Drawer(backgroundColor: AppColors.surface, child: content);
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;
  final bool isSidebar;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.isSidebar,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: color ?? AppColors.grey700),
      title: Text(
        label,
        style: TextStyle(
          fontSize: 14.sp,
          fontWeight: FontWeight.w600,
          color: color ?? AppColors.grey900,
        ),
      ),
      onTap: () {
        // On a real Drawer, close it before navigating. As a persistent
        // sidebar there's nothing to close — popping would incorrectly pop
        // the current page route instead.
        if (!isSidebar) Navigator.pop(context);
        onTap();
      },
    );
  }
}
