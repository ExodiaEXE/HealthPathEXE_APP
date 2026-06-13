import 'package:flutter/material.dart';

/// Disables Material 3 stretch overscroll — it can call setState during sliver
/// cache collection and trigger debugNeedsLayout / wrong build scope errors.
class HpScrollBehavior extends MaterialScrollBehavior {
  const HpScrollBehavior();

  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    return child;
  }
}
