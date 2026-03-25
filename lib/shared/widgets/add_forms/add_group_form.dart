import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../l10n/app_localizations.dart';
import '../../services/group_task_service.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// Public API
// ═══════════════════════════════════════════════════════════════════════════════

enum GroupOverlayStep { selection, create, join }

class GroupActionsOverlay {
  static OverlayEntry? _overlayEntry;

  static void show(BuildContext context,
      {GroupOverlayStep initialStep = GroupOverlayStep.selection}) {
    if (_overlayEntry != null) return;

    final overlay = Overlay.of(context);

    _overlayEntry = OverlayEntry(
      builder: (ctx) => _OverlayWidget(
        onHide: hide,
        initialStep: initialStep,
      ),
    );

    overlay.insert(_overlayEntry!);
  }

  static void hide() {
    if (_overlayEntry == null) return;
    _overlayEntry?.remove();
    _overlayEntry = null;
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Overlay wrapper
// ═══════════════════════════════════════════════════════════════════════════════

class _OverlayWidget extends StatefulWidget {
  final VoidCallback onHide;
  final GroupOverlayStep initialStep;

  const _OverlayWidget({
    required this.onHide,
    required this.initialStep,
  });

  @override
  State<_OverlayWidget> createState() => _OverlayWidgetState();
}

class _OverlayWidgetState extends State<_OverlayWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));
    _opacityAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _slideAnim =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
            CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _controller.forward();
  }

  Future<void> _safeHide() async {
    await _controller.reverse();
    widget.onHide();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final double bottomPadding = keyboardHeight > 0 ? keyboardHeight + 20 : 90;

    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          GestureDetector(
            onTap: _safeHide,
            child: FadeTransition(
              opacity: _opacityAnim,
              child: Container(color: Colors.black.withValues(alpha: 0.5)),
            ),
          ),
          AnimatedPadding(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
            padding: EdgeInsets.only(bottom: bottomPadding),
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: FadeTransition(
                  opacity: _opacityAnim,
                  child: SlideTransition(
                    position: _slideAnim,
                    child: _GroupActionsPanel(initialStep: widget.initialStep),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Step router
// ═══════════════════════════════════════════════════════════════════════════════

class _GroupActionsPanel extends StatefulWidget {
  final GroupOverlayStep initialStep;
  const _GroupActionsPanel({required this.initialStep});

  @override
  State<_GroupActionsPanel> createState() => _GroupActionsPanelState();
}

class _GroupActionsPanelState extends State<_GroupActionsPanel> {
  late GroupOverlayStep _step;
  String? _scannedId;

  @override
  void initState() {
    super.initState();
    _step = widget.initialStep;
  }

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 450),
      child: Card(
        elevation: 24,
        shadowColor: Colors.black54,
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
        clipBehavior: Clip.antiAlias,
        child: AnimatedSize(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            transitionBuilder: (child, anim) => FadeTransition(
              opacity: anim,
              child: ScaleTransition(
                scale: Tween(begin: 0.95, end: 1.0).animate(anim),
                child: child,
              ),
            ),
            child: _buildStep(),
          ),
        ),
      ),
    );
  }

  Widget _buildStep() {
    switch (_step) {
      case GroupOverlayStep.selection:
        return _SelectionView(
          key: const ValueKey('selection'),
          onCreate: () => setState(() => _step = GroupOverlayStep.create),
          onJoin: () => setState(() => _step = GroupOverlayStep.join),
        );
      case GroupOverlayStep.create:
        return _CreateView(
          key: const ValueKey('create'),
          onBack: () => setState(() => _step = GroupOverlayStep.selection),
        );
      case GroupOverlayStep.join:
        return _JoinView(
          key: ValueKey('join-$_scannedId'),
          prefillId: _scannedId,
          onBack: () => setState(() {
            _step = GroupOverlayStep.selection;
            _scannedId = null;
          }),
          onScanRequest: () async {
            final id = await Navigator.of(context).push<String>(
              MaterialPageRoute(
                  builder: (_) => const GroupQrScannerPage()),
            );
            if (id != null && mounted) {
              setState(() {
                _scannedId = id;
                _step = GroupOverlayStep.join;
              });
            }
          },
        );
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// View 1 — Selection
// ═══════════════════════════════════════════════════════════════════════════════

class _SelectionView extends StatelessWidget {
  final VoidCallback onCreate;
  final VoidCallback onJoin;

  const _SelectionView(
      {super.key, required this.onCreate, required this.onJoin});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(height: 24),
          Text(
            t?.manageGroup ?? 'Manage Group',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _MenuTile(
                  icon: Icons.group_add_rounded,
                  label: t?.create ?? 'Create',
                  color: Theme.of(context).colorScheme.primaryContainer,
                  onTap: onCreate,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _MenuTile(
                  icon: Icons.qr_code_scanner_rounded,
                  label: t?.joinAction ?? 'Join',
                  color: Theme.of(context).colorScheme.secondaryContainer,
                  onTap: onJoin,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// View 2 — Create group
// ═══════════════════════════════════════════════════════════════════════════════

class _CreateView extends StatefulWidget {
  final VoidCallback onBack;
  const _CreateView({super.key, required this.onBack});

  @override
  State<_CreateView> createState() => _CreateViewState();
}

class _CreateViewState extends State<_CreateView> {
  final _nameCtrl = TextEditingController();
  String? _nameError;
  Color _selectedColor = Colors.blueAccent;

  static const List<Color> _palette = [
    Colors.blueAccent, Colors.lightBlue, Colors.teal, Colors.green,
    Colors.lightGreen, Colors.amber, Colors.orange, Colors.deepOrange,
    Colors.red, Colors.pink, Colors.purple, Colors.deepPurple,
    Colors.indigo, Colors.brown, Colors.blueGrey,
  ];

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  void _create() {
    final t = AppLocalizations.of(context);
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      setState(() => _nameError = t?.titleCannotBeEmpty ?? 'Name cannot be empty');
      return;
    }

    GroupActionsOverlay.hide();
    groupTaskService.createGroup(name, _selectedColor.toARGB32());
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _StepHeader(
            title: t?.newGroup ?? 'New Group',
            onBack: widget.onBack,
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _nameCtrl,
            autofocus: true,
            onChanged: (_) {
              if (_nameError != null) setState(() => _nameError = null);
            },
            onSubmitted: (_) => _create(),
            decoration: InputDecoration(
              labelText: t?.groupName ?? 'Group name',
              errorText: _nameError,
              prefixIcon: const Icon(Icons.drive_file_rename_outline_rounded),
              border:
              OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: _selectedColor, width: 2),
              ),
              filled: true,
              fillColor: Colors.grey.withValues(alpha: 0.05),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            t?.groupColor ?? 'Group color',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _palette.map((c) {
              final selected = c == _selectedColor;
              return GestureDetector(
                onTap: () => setState(() => _selectedColor = c),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: c,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: selected ? Colors.white : Colors.transparent,
                      width: 3,
                    ),
                    boxShadow: selected
                        ? [
                      BoxShadow(
                          color: c.withValues(alpha: 0.6),
                          blurRadius: 8,
                          spreadRadius: 2)
                    ]
                        : [],
                  ),
                  child: selected
                      ? const Icon(Icons.check, color: Colors.white, size: 20)
                      : null,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          // Live preview chip
          Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: _selectedColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: ValueListenableBuilder(
                valueListenable: _nameCtrl,
                builder: (_, _, _) => Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.group, color: Colors.white, size: 16),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        _nameCtrl.text.isEmpty
                            ? (t?.preview ?? 'Preview')
                            : _nameCtrl.text,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          _ActionButton(
            label: t?.createGroup ?? 'Create Group',
            icon: Icons.check_circle_outline_rounded,
            color: _selectedColor,
            onPressed: _create,
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// View 3 — Join group
// ═══════════════════════════════════════════════════════════════════════════════

class _JoinView extends StatefulWidget {
  final VoidCallback onBack;
  final VoidCallback onScanRequest;
  final String? prefillId;

  const _JoinView({
    super.key,
    required this.onBack,
    required this.onScanRequest,
    this.prefillId,
  });

  @override
  State<_JoinView> createState() => _JoinViewState();
}

class _JoinViewState extends State<_JoinView> {
  late final TextEditingController _codeCtrl;
  bool _joining = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _codeCtrl = TextEditingController(text: widget.prefillId ?? '');
    if (widget.prefillId != null && widget.prefillId!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _join());
    }
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  Future<void> _join() async {
    final t = AppLocalizations.of(context);
    final id = _codeCtrl.text.trim();
    if (id.isEmpty) return;

    setState(() {
      _joining = true;
      _error = null;
    });

    try {
      final ok = await groupTaskService.joinGroup(id);
      if (!mounted) return;
      if (ok) {
        GroupActionsOverlay.hide();
      } else {
        setState(() {
          _joining = false;
          _error = t?.error ?? 'Group not found. Check the code and try again.';
        });
      }
    } on FirebaseException catch (e) {
      if (!mounted) return;
      setState(() {
        _joining = false;
        _error = e.code == 'permission-denied'
            ? (t?.error ?? 'Permission denied. Update Firestore rules.')
            : '${t?.error ?? "Error"}: ${e.code}';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _joining = false;
        _error = t?.error ?? 'Unknown error. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StepHeader(
            title: t?.joinGroup ?? 'Join Group',
            onBack: widget.onBack,
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _codeCtrl,
            autofocus: widget.prefillId == null,
            textAlign: TextAlign.center,
            style: const TextStyle(
                letterSpacing: 4, fontSize: 22, fontWeight: FontWeight.bold),
            onChanged: (_) {
              if (_error != null) setState(() => _error = null);
            },
            onSubmitted: (_) => _join(),
            decoration: InputDecoration(
              hintText: 'KOD-123',
              helperText: t?.groupCode ?? 'Enter the unique group code',
              errorText: _error,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16)),
              filled: true,
              fillColor: Colors.grey.withValues(alpha: 0.05),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _joining ? null : widget.onScanRequest,
              icon: const Icon(Icons.qr_code_scanner_rounded),
              label: Text(t?.scanQRCode ?? 'Scan QR code'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _ActionButton(
            label: t?.joinGroup ?? 'Join Now',
            icon: Icons.send_rounded,
            loading: _joining,
            onPressed: _join,
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// QR scanner page
// ═══════════════════════════════════════════════════════════════════════════════

class GroupQrScannerPage extends StatefulWidget {
  const GroupQrScannerPage({super.key});

  @override
  State<GroupQrScannerPage> createState() => _GroupQrScannerPageState();
}

class _GroupQrScannerPageState extends State<GroupQrScannerPage> {
  final MobileScannerController _scanner = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    facing: CameraFacing.back,
    torchEnabled: false,
  );
  bool _hasScanned = false;

  void _onDetect(BarcodeCapture capture) {
    if (_hasScanned) return;
    final value = capture.barcodes.firstOrNull?.rawValue;
    if (value == null || value.isEmpty) return;
    _hasScanned = true;
    _scanner.stop();
    Navigator.of(context).pop(value);
  }

  @override
  void dispose() {
    _scanner.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(t?.scanQRCode ?? 'Scan group QR code'),
        actions: [
          ValueListenableBuilder(
            valueListenable: _scanner,
            builder: (_, value, _) {
              final isOn = value.torchState == TorchState.on;
              return IconButton(
                icon: Icon(isOn ? Icons.flash_on : Icons.flash_off),
                onPressed: _scanner.toggleTorch,
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(controller: _scanner, onDetect: _onDetect),
          _QrScanOverlay(),
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  t?.scanOrShare ?? 'Point at the group QR code',
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QrScanOverlay extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    const cutout = 260.0;
    final top = (size.height - cutout) / 2 - 40;
    final left = (size.width - cutout) / 2;

    return Stack(
      children: [
        ColorFiltered(
          colorFilter:
          const ColorFilter.mode(Colors.black54, BlendMode.srcOut),
          child: Stack(
            children: [
              Container(
                decoration: const BoxDecoration(
                  color: Colors.black,
                  backgroundBlendMode: BlendMode.dstOut,
                ),
              ),
              Positioned(
                top: top,
                left: left,
                child: Container(
                  width: cutout,
                  height: cutout,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
        Positioned(
          top: top,
          left: left,
          child: SizedBox(
            width: cutout,
            height: cutout,
            child: CustomPaint(painter: _QrBracketPainter()),
          ),
        ),
      ],
    );
  }
}

class _QrBracketPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blueAccent
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const arm = 28.0;
    const r = 8.0;
    final w = size.width;
    final h = size.height;

    final corners = [
      [Offset(0, arm), Offset(0, r), Offset(r, 0), Offset(arm, 0)],
      [Offset(w - arm, 0), Offset(w - r, 0), Offset(w, r), Offset(w, arm)],
      [Offset(w, h - arm), Offset(w, h - r), Offset(w - r, h), Offset(w - arm, h)],
      [Offset(arm, h), Offset(r, h), Offset(0, h - r), Offset(0, h - arm)],
    ];

    for (final pts in corners) {
      canvas.drawPath(
        Path()
          ..moveTo(pts[0].dx, pts[0].dy)
          ..lineTo(pts[1].dx, pts[1].dy)
          ..quadraticBezierTo(
              pts[2].dx, pts[2].dy, pts[3].dx, pts[3].dy),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_) => false;
}

// ═══════════════════════════════════════════════════════════════════════════════
// Shared UI components
// ═══════════════════════════════════════════════════════════════════════════════

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _MenuTile(
      {required this.icon,
        required this.label,
        required this.color,
        required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 28),
        decoration: BoxDecoration(
            color: color, borderRadius: BorderRadius.circular(24)),
        child: Column(
          children: [
            Icon(icon, size: 36, color: Colors.black87),
            const SizedBox(height: 12),
            Text(label,
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: Colors.black87)),
          ],
        ),
      ),
    );
  }
}

class _StepHeader extends StatelessWidget {
  final String title;
  final VoidCallback onBack;

  const _StepHeader({required this.title, required this.onBack});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Row(
      children: [
        IconButton.filledTonal(
          onPressed: onBack,
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
        ),
        const SizedBox(width: 16),
        Text(title,
            style:
            const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const Spacer(),
        IconButton(
          onPressed: GroupActionsOverlay.hide,
          icon: const Icon(Icons.close_rounded, color: Colors.grey),
          tooltip: t?.cancel ?? 'Close',
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final bool loading;
  final Color? color;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.loading = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: FilledButton.icon(
        onPressed: loading ? null : onPressed,
        icon: loading
            ? const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
                strokeWidth: 2, color: Colors.white))
            : Icon(icon),
        label: Text(label,
            style: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.bold)),
        style: FilledButton.styleFrom(
          backgroundColor: color,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }
}