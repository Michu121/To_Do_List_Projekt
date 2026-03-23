import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../app_settings.dart';
import '../shared/widgets/app_bars/upper_app_bar.dart';
import '../shared/services/auth_service.dart';
import '../shared/widgets/in_app_notification.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final AppSettings _s = AppSettings.instance;

  bool get _isGoogleUser {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;
    return user.providerData.any((p) => p.providerId == 'google.com');
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _s,
      builder: (context, _) {
        final theme = Theme.of(context);

        return Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          appBar: const MyAppBar(title: 'Settings'),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
              children: [
                // ── Appearance ──────────────────────────────────────
                _Label('Appearance', Icons.palette_outlined),
                const SizedBox(height: 8),
                _Card(children: [
                  _Tile(
                    icon: Icons.dark_mode_outlined,
                    iconColor: Colors.indigo,
                    title: 'Theme',
                    trailing: _ThemeToggle(s: _s),
                  ),
                  _Div(),
                  _AccentRow(s: _s),
                ]),

                const SizedBox(height: 22),

                // ── Notifications ───────────────────────────────────
                _Label('Notifications', Icons.notifications_outlined),
                const SizedBox(height: 8),
                _Card(children: [
                  _Tile(
                    icon: Icons.notifications_active_outlined,
                    iconColor: Colors.orange,
                    title: 'Enable notifications',
                    trailing: Switch.adaptive(
                      value: _s.notificationsEnabled,
                      activeColor: theme.colorScheme.primary,
                      onChanged: _s.setNotificationsEnabled,
                    ),
                  ),
                  _Div(),
                  _Tile(
                    icon: Icons.alarm_outlined,
                    iconColor:
                    _s.notificationsEnabled ? Colors.amber : Colors.grey,
                    title: 'Task reminders',
                    trailing: Switch.adaptive(
                      value: _s.taskReminders,
                      activeColor: theme.colorScheme.primary,
                      onChanged: _s.notificationsEnabled
                          ? _s.setTaskReminders
                          : null,
                    ),
                  ),
                  _Div(),
                  _Tile(
                    icon: Icons.schedule_outlined,
                    iconColor: _s.notificationsEnabled
                        ? theme.colorScheme.primary
                        : Colors.grey,
                    title: 'Remind me',
                    subtitle: _s.notificationsEnabled
                        ? null
                        : 'Enable notifications first',
                    trailing: _s.notificationsEnabled
                        ? _TimingDrop(s: _s)
                        : null,
                  ),
                  _Div(),
                  _Tile(
                    icon: Icons.person_add_outlined,
                    iconColor: _s.notificationsEnabled
                        ? Colors.blueAccent
                        : Colors.grey,
                    title: 'Friend invitations',
                    trailing: Switch.adaptive(
                      value: _s.invitations,
                      activeColor: theme.colorScheme.primary,
                      onChanged:
                      _s.notificationsEnabled ? _s.setInvitations : null,
                    ),
                  ),
                  _Div(),
                  _Tile(
                    icon: Icons.group_add_outlined,
                    iconColor: _s.notificationsEnabled
                        ? Colors.purple
                        : Colors.grey,
                    title: 'Group invitations',
                    trailing: Switch.adaptive(
                      value: _s.groupInvitations,
                      activeColor: theme.colorScheme.primary,
                      onChanged: _s.notificationsEnabled
                          ? _s.setGroupInvitations
                          : null,
                    ),
                  ),
                ]),

                const SizedBox(height: 22),

                // ── Account ─────────────────────────────────────────
                _Label('Account', Icons.manage_accounts_outlined),
                const SizedBox(height: 8),
                _Card(children: [
                  if (!_isGoogleUser) ...[
                    _Tile(
                      icon: Icons.lock_outline,
                      iconColor: Colors.green,
                      title: 'Change password',
                      showArrow: true,
                      onTap: () => _showChangePwd(context),
                    ),
                    _Div(),
                  ],
                  _Tile(
                    icon: Icons.security_outlined,
                    iconColor: Colors.blue,
                    title: 'Privacy and security',
                    showArrow: true,
                    onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) => const PrivacySecurityPage())),
                  ),
                  _Div(),
                  _Tile(
                    icon: Icons.logout_rounded,
                    iconColor: Colors.red,
                    title: 'Log out',
                    titleColor: Colors.red,
                    onTap: () => _showLogout(context),
                  ),
                ]),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showChangePwd(BuildContext context) async {
    final formKey = GlobalKey<FormState>();
    final curCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confCtrl = TextEditingController();

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Change password'),
        content: Form(
          key: formKey,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            _PwdField(ctrl: curCtrl, label: 'Current password'),
            const SizedBox(height: 10),
            _PwdField(
                ctrl: newCtrl,
                label: 'New password',
                validator: (v) =>
                (v?.length ?? 0) < 8 ? 'Min 8 characters' : null),
            const SizedBox(height: 10),
            _PwdField(
                ctrl: confCtrl,
                label: 'Confirm password',
                validator: (v) =>
                v != newCtrl.text ? 'Passwords do not match' : null),
          ]),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(ctx);
                InAppNotification.success(context, 'Password changed');
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    curCtrl.dispose();
    newCtrl.dispose();
    confCtrl.dispose();
  }

  Future<void> _showLogout(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Log out'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Log out'),
          ),
        ],
      ),
    );
    if (ok == true) {
      try {
        await authService.logout();
      } catch (e) {
        if (!mounted) return;
        InAppNotification.error(context, 'Failed to log out: $e');
      }
    }
  }
}

// ── Privacy page ──────────────────────────────────────────────────────────────

class PrivacySecurityPage extends StatelessWidget {
  const PrivacySecurityPage({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppSettings.instance;
    return AnimatedBuilder(
      animation: s,
      builder: (context, _) {
        final theme = Theme.of(context);
        return Scaffold(
          appBar: AppBar(
            title: const Text('Privacy & Security'),
            backgroundColor: theme.appBarTheme.backgroundColor,
            foregroundColor: Colors.white,
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _Card(children: [
                _Tile(
                  icon: Icons.fingerprint,
                  iconColor: Colors.green,
                  title: 'Biometric lock',
                  subtitle: 'Fingerprint / Face ID',
                  trailing: Switch.adaptive(
                      value: s.biometricLock,
                      activeColor: theme.colorScheme.primary,
                      onChanged: s.setBiometricLock),
                ),
                _Div(),
                _Tile(
                  icon: Icons.phonelink_lock_outlined,
                  iconColor: Colors.orange,
                  title: 'Lock when minimised',
                  trailing: Switch.adaptive(
                      value: s.lockWhenBackgrounded,
                      activeColor: theme.colorScheme.primary,
                      onChanged: s.setLockWhenBackgrounded),
                ),
                _Div(),
                _Tile(
                  icon: Icons.visibility_off_outlined,
                  iconColor: Colors.blueGrey,
                  title: 'Hide notification content',
                  trailing: Switch.adaptive(
                      value: s.hideNotificationContent,
                      activeColor: theme.colorScheme.primary,
                      onChanged: s.setHideNotificationContent),
                ),
              ]),
            ],
          ),
        );
      },
    );
  }
}

// ── Shared widgets ────────────────────────────────────────────────────────────

class _Label extends StatelessWidget {
  const _Label(this.text, this.icon);
  final String text;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    return Row(
      children: [
        Icon(icon, size: 14, color: accent),
        const SizedBox(width: 6),
        Text(text.toUpperCase(),
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
                color: accent)),
      ],
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.dividerColor.withAlpha(60)),
        boxShadow: theme.brightness == Brightness.light
            ? [
          BoxShadow(
              color: Colors.black.withAlpha(8),
              blurRadius: 12,
              offset: const Offset(0, 4))
        ]
            : [],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
      ),
    );
  }
}

class _Div extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Divider(
        height: 1,
        thickness: 1,
        indent: 56,
        color: Theme.of(context).dividerColor.withAlpha(80));
  }
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.icon,
    required this.iconColor,
    required this.title,
    this.subtitle,
    this.titleColor,
    this.trailing,
    this.showArrow = false,
    this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final Color? titleColor;
  final Widget? trailing;
  final bool showArrow;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, size: 20, color: iconColor),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: titleColor)),
                  if (subtitle != null)
                    Text(subtitle!,
                        style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.5))),
                ],
              ),
            ),
            if (trailing != null) trailing!,
            if (showArrow && trailing == null)
              Icon(Icons.chevron_right_rounded,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.3)),
          ],
        ),
      ),
    );
  }
}

class _ThemeToggle extends StatelessWidget {
  const _ThemeToggle({required this.s});
  final AppSettings s;

  @override
  Widget build(BuildContext context) {
    final isDark = s.themeMode == AppThemeMode.dark;
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: () =>
          s.setThemeMode(isDark ? AppThemeMode.light : AppThemeMode.dark),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: 72,
        height: 34,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(17),
          color: isDark
              ? theme.colorScheme.primary
              : theme.colorScheme.surfaceContainerHighest,
        ),
        child: Stack(children: [
          AnimatedPositioned(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            left: isDark ? 40 : 4,
            top: 4,
            child: Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: Colors.black.withAlpha(30), blurRadius: 4)
                ],
              ),
              child: Icon(isDark ? Icons.dark_mode : Icons.light_mode,
                  size: 14,
                  color: isDark ? Colors.indigo : Colors.amber),
            ),
          ),
        ]),
      ),
    );
  }
}

class _TimingDrop extends StatelessWidget {
  const _TimingDrop({required this.s});
  final AppSettings s;

  @override
  Widget build(BuildContext context) {
    return DropdownButton<int>(
      value: s.notificationMinutesBefore,
      underline: const SizedBox.shrink(),
      style: TextStyle(
          fontSize: 13,
          color: Theme.of(context).colorScheme.onSurface,
          fontWeight: FontWeight.w600),
      items: AppSettings.notificationTimingOptions
          .map((m) => DropdownMenuItem(
          value: m, child: Text(AppSettings.timingLabel(m))))
          .toList(),
      onChanged: (v) {
        if (v != null) s.setNotificationMinutesBefore(v);
      },
    );
  }
}

class _AccentRow extends StatelessWidget {
  const _AccentRow({required this.s});
  final AppSettings s;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                    color: s.accentColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10)),
                child: Icon(Icons.color_lens_outlined,
                    size: 20, color: s.accentColor),
              ),
              const SizedBox(width: 14),
              Text('Accent color',
                  style: theme.textTheme.bodyLarge
                      ?.copyWith(fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: AppSettings.availableAccentColors
                .map((c) => _AccentDot(
              color: c,
              selected: s.accentColor.toARGB32() == c.toARGB32(),
              onTap: () => s.setAccentColor(c),
            ))
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _AccentDot extends StatelessWidget {
  const _AccentDot(
      {required this.color, required this.selected, required this.onTap});
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // Readable check icon regardless of accent luminance
    final fg = color.computeLuminance() > 0.4 ? Colors.black87 : Colors.white;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
          border: Border.all(
            color: selected
                ? Theme.of(context).colorScheme.onSurface
                : Colors.transparent,
            width: 2.5,
          ),
          boxShadow: [
            BoxShadow(
                color: color.withAlpha(selected ? 120 : 50),
                blurRadius: selected ? 10 : 4,
                offset: const Offset(0, 2))
          ],
        ),
        child: selected
            ? Icon(Icons.check_rounded, size: 20, color: fg)
            : null,
      ),
    );
  }
}

class _PwdField extends StatelessWidget {
  const _PwdField({required this.ctrl, required this.label, this.validator});
  final TextEditingController ctrl;
  final String label;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: ctrl,
      obscureText: true,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.lock_outline),
        border:
        OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      validator: validator ??
              (v) => (v?.trim().isEmpty ?? true) ? 'Required' : null,
    );
  }
}