import 'package:basketball_academy/core/constants/app_strings.dart';
import 'package:basketball_academy/core/di/injection_container.dart';
import 'package:basketball_academy/core/router/app_router.dart';
import 'package:basketball_academy/core/theme/app_theme.dart';
import 'package:basketball_academy/core/web/url_strategy.dart';
import 'package:basketball_academy/core/widgets/responsive_center.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Use clean path-based URLs on web (e.g. /players) instead of #/players.
  // No-op on non-web platforms.
  configureUrlStrategy();

  await initializeDateFormatting('ar', null);

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  await initDependencies();

  runApp(
    const ProviderScope(
      child: BasketballAcademyApp(),
    ),
  );
}

class BasketballAcademyApp extends ConsumerWidget {
  const BasketballAcademyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    // Captured here, above ScreenUtilInit, because ScreenUtilInit clamps the
    // MediaQuery size it hands to descendants (so `.w`/`.h`/`.sp` keep
    // mobile-like proportions on wide windows). This is the real window width.
    return LayoutBuilder(
      builder: (context, constraints) {
        final realWidth = constraints.maxWidth;

        return ScreenUtilInit(
          designSize: const Size(390, 844),
          minTextAdapt: true,
          splitScreenMode: true,
          builder: (context, child) {
            return MaterialApp.router(
              title: AppStrings.appNameEn,
              debugShowCheckedModeBanner: false,
              theme: AppTheme.lightTheme,
              routerConfig: router,
              builder: (context, widget) {
                return Directionality(
                  textDirection: TextDirection.rtl,
                  child: WebLayoutScope(
                    isWebLayout: realWidth >= kWebBreakpoint,
                    width: realWidth,
                    child: widget ?? const SizedBox.shrink(),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
