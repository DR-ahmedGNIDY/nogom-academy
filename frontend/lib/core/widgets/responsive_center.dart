import 'package:flutter/material.dart';

/// Screens narrower than this keep the exact mobile layout untouched.
const double kWebBreakpoint = 768;

/// Whether the app should render its web/desktop layout, based on the
/// *real* (pre-ScreenUtil-clamp) window width captured once at the app root.
///
/// Read this instead of comparing [MediaQuery] width directly inside screens:
/// the app root clamps the [MediaQuery] size that flutter_screenutil sees
/// (so `.w`/`.h`/`.sp`/`.r` keep mobile-like proportions on wide windows),
/// which means by the time a screen builds, `MediaQuery.sizeOf` no longer
/// reflects the real window width.
class WebLayoutScope extends InheritedWidget {
  final bool isWebLayout;

  const WebLayoutScope({
    super.key,
    required this.isWebLayout,
    required super.child,
  });

  static bool of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<WebLayoutScope>();
    return scope?.isWebLayout ?? false;
  }

  @override
  bool updateShouldNotify(WebLayoutScope oldWidget) =>
      isWebLayout != oldWidget.isWebLayout;
}

/// Centers [child] and caps its width once the viewport is wider than
/// [kWebBreakpoint] (i.e. on web/desktop), so content doesn't stretch across
/// the full browser window. Below the breakpoint it returns [child] as-is,
/// so mobile (and narrow web) rendering is unaffected.
class ResponsiveCenter extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry? webPadding;

  const ResponsiveCenter({
    super.key,
    required this.child,
    this.maxWidth = 480,
    this.webPadding,
  });

  @override
  Widget build(BuildContext context) {
    if (!WebLayoutScope.of(context)) return child;

    final content = ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: child,
    );

    return Center(
      child: webPadding != null ? Padding(padding: webPadding!, child: content) : content,
    );
  }
}
