import 'package:basketball_academy/core/constants/app_colors.dart';
import 'package:basketball_academy/core/widgets/app_navigation_drawer.dart';
import 'package:basketball_academy/core/widgets/responsive_center.dart';
import 'package:basketball_academy/features/auth/presentation/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Drop-in replacement for [Scaffold] on primary/hub screens: renders the
/// shared [AppNavigationDrawer] as a real drawer below [kDesktopBreakpoint]
/// (tablet/mobile) and as a persistent sidebar at or above it (desktop),
/// matching every other [Scaffold] parameter 1:1 so call sites only need to
/// rename `Scaffold(` to `ResponsiveScaffold(`.
class ResponsiveScaffold extends ConsumerWidget {
  final PreferredSizeWidget? appBar;
  final Widget body;
  final Color? backgroundColor;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  final Widget? bottomNavigationBar;
  final bool extendBodyBehindAppBar;

  const ResponsiveScaffold({
    super.key,
    this.appBar,
    required this.body,
    this.backgroundColor,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.bottomNavigationBar,
    this.extendBodyBehindAppBar = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider).valueOrNull;
    final user = authState?.user;
    final isSuperAdmin = user?.isSuperAdmin ?? false;
    final isSecurity = user?.isSecurity ?? false;
    final isDesktop = WebLayoutScope.widthOf(context) >= kDesktopBreakpoint;

    if (!isDesktop) {
      return Scaffold(
        backgroundColor: backgroundColor,
        drawer: AppNavigationDrawer(
          userName: user?.name ?? '',
          isSuperAdmin: isSuperAdmin,
          isSecurity: isSecurity,
        ),
        appBar: appBar,
        body: body,
        floatingActionButton: floatingActionButton,
        floatingActionButtonLocation: floatingActionButtonLocation,
        bottomNavigationBar: bottomNavigationBar,
        extendBodyBehindAppBar: extendBodyBehindAppBar,
      );
    }

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Row(
        children: [
          SizedBox(
            width: 260,
            child: DecoratedBox(
              decoration: BoxDecoration(
                border: Border(left: BorderSide(color: AppColors.border)),
              ),
              child: AppNavigationDrawer(
                userName: user?.name ?? '',
                isSuperAdmin: isSuperAdmin,
                isSecurity: isSecurity,
                isSidebar: true,
              ),
            ),
          ),
          Expanded(
            child: Scaffold(
              backgroundColor: backgroundColor,
              appBar: appBar,
              body: body,
              floatingActionButton: floatingActionButton,
              floatingActionButtonLocation: floatingActionButtonLocation,
              bottomNavigationBar: bottomNavigationBar,
              extendBodyBehindAppBar: extendBodyBehindAppBar,
            ),
          ),
        ],
      ),
    );
  }
}
