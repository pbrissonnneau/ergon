import 'package:flutter/material.dart';

import '../../app/app_services.dart';

/// App bar button (desktop): brings the overlay back on top of other
/// windows, starting it if it was closed.
class OverlayButton extends StatelessWidget {
  const OverlayButton({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    if (!s.platform.supportsOverlay) return const SizedBox.shrink();
    return IconButton(
      tooltip: 'Show the overlay on top',
      icon: const Icon(Icons.picture_in_picture_alt_outlined),
      onPressed: () {
        s.settings.overlayEnabled = true;
        s.platform.setOverlayVisible(true);
      },
    );
  }
}
