import 'dart:async';
import 'package:flutter/material.dart';

enum NotifType { success, error, info, warning }

/// Drop-in replacement for SnackBar — shows a banner sliding from the top.
/// Usage:
///   InAppNotification.show(context, message: '...', type: NotifType.success);
class InAppNotification {
  static _ActiveNotif? _active;

  static void show(
      BuildContext context, {
        required String message,
        NotifType type = NotifType.info,
        IconData? icon,
        Duration duration = const Duration(seconds: 3),
      }) {
    // Dismiss current immediately before showing new one
    _active?.dismiss();

    OverlayState? overlay;
    try {
      overlay = Overlay.of(context, rootOverlay: true);
    } catch (_) {
      return;
    }

    final theme = Theme.of(context);

    final (Color bg, IconData defIcon) = switch (type) {
      NotifType.success => (Colors.green.shade600, Icons.check_circle_outline),
      NotifType.error => (Colors.red.shade700, Icons.error_outline),
      NotifType.warning => (Colors.orange.shade700, Icons.warning_amber_outlined),
      NotifType.info => (theme.colorScheme.primary, Icons.info_outline),
    };

    final fg = bg.computeLuminance() > 0.4 ? Colors.black87 : Colors.white;

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _NotifBanner(
        message: message,
        bg: bg,
        fg: fg,
        icon: icon ?? defIcon,
        onDismiss: () {
          entry.remove();
          _active = null;
        },
      ),
    );

    overlay.insert(entry);

    final timer = Timer(duration, () {
      try {
        entry.remove();
      } catch (_) {}
      _active = null;
    });

    _active = _ActiveNotif(entry: entry, timer: timer);
  }

  /// Convenience helpers
  static void success(BuildContext ctx, String msg) =>
      show(ctx, message: msg, type: NotifType.success);
  static void error(BuildContext ctx, String msg) =>
      show(ctx, message: msg, type: NotifType.error);
  static void warning(BuildContext ctx, String msg) =>
      show(ctx, message: msg, type: NotifType.warning);
  static void info(BuildContext ctx, String msg) =>
      show(ctx, message: msg, type: NotifType.info);
}

class _ActiveNotif {
  final OverlayEntry entry;
  final Timer timer;
  _ActiveNotif({required this.entry, required this.timer});

  void dismiss() {
    timer.cancel();
    try {
      entry.remove();
    } catch (_) {}
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _NotifBanner extends StatefulWidget {
  final String message;
  final Color bg;
  final Color fg;
  final IconData icon;
  final VoidCallback onDismiss;

  const _NotifBanner({
    required this.message,
    required this.bg,
    required this.fg,
    required this.icon,
    required this.onDismiss,
  });

  @override
  State<_NotifBanner> createState() => _NotifBannerState();
}

class _NotifBannerState extends State<_NotifBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<Offset> _slide;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );
    _slide = Tween<Offset>(
      begin: const Offset(0, -1.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SlideTransition(
        position: _slide,
        child: FadeTransition(
          opacity: _fade,
          child: GestureDetector(
            onTap: widget.onDismiss,
            behavior: HitTestBehavior.opaque,
            child: Container(
              margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
              decoration: BoxDecoration(
                color: widget.bg,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: widget.bg.withValues(alpha: 0.45),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(widget.icon, color: widget.fg, size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.message,
                      style: TextStyle(
                        color: widget.fg,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        height: 1.3,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.close_rounded,
                      color: widget.fg.withValues(alpha: 0.65), size: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}