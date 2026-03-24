import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../app_settings.dart';
import '../l10n/app_localizations.dart';
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
    final t = AppLocalizations.of(context);
    return AnimatedBuilder(
      animation: _s,
      builder: (context, _) {
        final theme = Theme.of(context);

        return Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          appBar: MyAppBar(title: t?.settings ?? 'Settings'),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
              children: [
                // ── Appearance ──────────────────────────────────────
                _Label(t?.appearance ?? 'Appearance', Icons.palette_outlined),
                const SizedBox(height: 8),
                _Card(children: [
                  _Tile(
                    icon: Icons.dark_mode_outlined,
                    iconColor: Colors.indigo,
                    title: t?.theme ?? 'Theme',
                    trailing: _ThemePillSelector(s: _s),
                  ),
                  _Div(),
                  _AccentRow(s: _s, t: t),
                ]),

                const SizedBox(height: 22),
                _Label(t?.language ?? 'Language', Icons.language_outlined),
                const SizedBox(height: 8),
                _Card(children: [
                  _Tile(
                    icon: Icons.language_outlined,
                    iconColor: Colors.teal,
                    title: t?.language ?? 'Language',
                    trailing: SizedBox(
                        width: 140,
                        child: _LanguageDropdown(s: _s)
                    ),
                  ),
                ]),
                const SizedBox(height: 22),

                // ── Notifications ───────────────────────────────────
                _Label(t?.notifications ?? 'Notifications', Icons.notifications_outlined),
                const SizedBox(height: 8),
                _Card(children: [
                  _Tile(
                    icon: Icons.notifications_active_outlined,
                    iconColor: Colors.orange,
                    title: t?.enableNotifications ?? 'Enable notifications',
                    trailing: Switch.adaptive(
                      value: _s.notificationsEnabled,
                      activeThumbColor: theme.colorScheme.primary,
                      onChanged: _s.setNotificationsEnabled,
                    ),
                  ),
                  _Div(),
                  _Tile(
                    icon: Icons.alarm_outlined,
                    iconColor:
                    _s.notificationsEnabled ? Colors.amber : Colors.grey,
                    title: t?.taskReminders ?? 'Task reminders',
                    trailing: Switch.adaptive(
                      value: _s.taskReminders,
                      activeThumbColor: theme.colorScheme.primary,
                      onChanged: _s.notificationsEnabled
                          ? _s.setTaskReminders
                          : null,
                    ),
                  ),
                  if (_s.taskReminders) ...[
                    _Div(),
                    _Tile(
                      icon: Icons.schedule_outlined,
                      iconColor: theme.colorScheme.primary,
                      title: t?.remindMe ?? 'Remind me',
                      trailing: _s.notificationsEnabled
                          ? _TimingDrop(s: _s)
                          : null,
                    ),
                  ],
                ]),

                const SizedBox(height: 22),

                // ── Account ─────────────────────────────────────────
                _Label(t?.account ?? 'Account', Icons.manage_accounts_outlined),
                const SizedBox(height: 8),
                _Card(children: [
                  if (!_isGoogleUser) ...[
                    _Tile(
                      icon: Icons.lock_outline,
                      iconColor: Colors.green,
                      title: t?.changePassword ?? 'Change password',
                      showArrow: true,
                      onTap: () => _showChangePwd(context),
                    ),
                    _Div(),
                  ],
                  _Tile(
                    icon: Icons.security_outlined,
                    iconColor: Colors.blue,
                    title: t?.privacySecurity ?? 'Privacy and security',
                    showArrow: true,
                    onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) => const PrivacySecurityPage())),
                  ),
                  _Div(),
                  _Tile(
                    icon: Icons.logout_rounded,
                    iconColor: Colors.red,
                    title: t?.logOut ?? 'Log out',
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

  // ... (reszta metod _showChangePwd i _showLogout pozostaje bez zmian)
  Future<void> _showChangePwd(BuildContext context) async {
    final t = AppLocalizations.of(context);
    final formKey = GlobalKey<FormState>();
    final curCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confCtrl = TextEditingController();

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(t?.changePasswordTitle ?? 'Change password'),
        content: Form(
          key: formKey,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            _PwdField(ctrl: curCtrl, label: t?.currentPassword ?? 'Current password'),
            const SizedBox(height: 10),
            _PwdField(
                ctrl: newCtrl,
                label: t?.newPassword ?? 'New password',
                validator: (v) =>
                (v?.length ?? 0) < 8 ? (t?.minCharacters ?? 'Min 8 characters') : null),
            const SizedBox(height: 10),
            _PwdField(
                ctrl: confCtrl,
                label: t?.confirmPassword ?? 'Confirm password',
                validator: (v) =>
                v != newCtrl.text ? (t?.passwordsDoNotMatch ?? 'Passwords do not match') : null),
          ]),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(t?.cancel ?? 'Cancel')),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(ctx);
                InAppNotification.success(context, t?.passwordChanged ?? 'Password changed');
              }
            },
            child: Text(t?.save ?? 'Save'),
          ),
        ],
      ),
    );
    curCtrl.dispose();
    newCtrl.dispose();
    confCtrl.dispose();
  }

  Future<void> _showLogout(BuildContext context) async {
    final t = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(t?.logOutTitle ?? 'Log out'),
        content: Text(t?.areYouSureLogOut ?? 'Are you sure you want to log out?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(t?.cancel ?? 'Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(t?.logOut ?? 'Log out'),
          ),
        ],
      ),
    );
    if (ok == true) {
      try {
        await authService.logout();
      } catch (e) {
        if (!mounted) return;
        InAppNotification.error(context, '${t?.failedToLogOut ?? "Failed to log out"}: $e');
      }
    }
  }
}

class PrivacySecurityPage extends StatelessWidget {
  const PrivacySecurityPage({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final s = AppSettings.instance;
    return AnimatedBuilder(
      animation: s,
      builder: (context, _) {
        final theme = Theme.of(context);
        return Scaffold(
          appBar: AppBar(
            title: Text(t?.privacyAndSecurity ?? 'Privacy & Security'),
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
                  title: t?.biometricLock ?? 'Biometric lock',
                  subtitle: t?.fingerprintFaceId ?? 'Fingerprint / Face ID',
                  trailing: Switch.adaptive(
                      value: s.biometricLock,
                      activeThumbColor: theme.colorScheme.primary,
                      onChanged: s.setBiometricLock),
                ),
                _Div(),
                _Tile(
                  icon: Icons.phonelink_lock_outlined,
                  iconColor: Colors.orange,
                  title: t?.lockWhenMinimised ?? 'Lock when minimised',
                  trailing: Switch.adaptive(
                      value: s.lockWhenBackgrounded,
                      activeThumbColor: theme.colorScheme.primary,
                      onChanged: s.setLockWhenBackgrounded),
                ),
                _Div(),
                _Tile(
                  icon: Icons.visibility_off_outlined,
                  iconColor: Colors.blueGrey,
                  title: t?.hideNotificationContent ?? 'Hide notification content',
                  trailing: Switch.adaptive(
                      value: s.hideNotificationContent,
                      activeThumbColor: theme.colorScheme.primary,
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
            if (trailing != null) trailing!, // POPRAWIONA SKŁADNIA
            if (showArrow && trailing == null)
              Icon(Icons.chevron_right_rounded,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.3)),
          ],
        ),
      ),
    );
  }
}

class _ThemePillSelector extends StatelessWidget {
  const _ThemePillSelector({required this.s});
  final AppSettings s;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Obliczamy wyrównanie (Alignment) dla suwaka na podstawie wybranego trybu
    Alignment indicatorAlignment;
    switch (s.themeMode) {
      case AppThemeMode.light:
        indicatorAlignment = Alignment.centerLeft;
        break;
      case AppThemeMode.system:
        indicatorAlignment = Alignment.center;
        break;
      case AppThemeMode.dark:
        indicatorAlignment = Alignment.centerRight;
        break;
    }

    return Container(
      height: 44,
      width: 135, // Zwiększona lekko szerokość, by 3 ikony miały więcej miejsca
      padding: const EdgeInsets.all(4), // Padding dla "toru", po którym porusza się suwak
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Stack(
        children: [
          // Warstwa spodnia: Animowany suwak (pill)
          AnimatedAlign(
            alignment: indicatorAlignment,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            child: FractionallySizedBox(
              widthFactor: 1 / 3, // Suwak zajmuje 1/3 szerokości
              child: Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: theme.colorScheme.primary.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Warstwa wierzchnia: Ikony
          Row(
            children: [
              _buildThemeOption(context, AppThemeMode.light, Icons.light_mode_rounded),
              _buildThemeOption(context, AppThemeMode.system, Icons.settings_brightness_rounded),
              _buildThemeOption(context, AppThemeMode.dark, Icons.dark_mode_rounded),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildThemeOption(BuildContext context, AppThemeMode mode, IconData icon) {
    final isSelected = s.themeMode == mode;
    final theme = Theme.of(context);

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque, // Zapewnia responsywność na całej powierzchni Expanded
        onTap: () => s.setThemeMode(mode),
        child: Center(
          child: AnimatedScale(
            duration: const Duration(milliseconds: 200),
            scale: isSelected ? 1.1 : 1.0,
            child: Icon(
              icon,
              size: 20,
              color: isSelected
                  ? theme.colorScheme.onPrimary
                  : theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}

class _LanguageDropdown extends StatelessWidget {
  const _LanguageDropdown({required this.s});
  final AppSettings s;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final String currentLabel = s.locale.languageCode == 'pl' ? '🇵🇱 Polish' : '🇺🇸 English';

    return MenuAnchor(
      alignmentOffset: const Offset(0,-45),
      style: MenuStyle(
        padding: WidgetStateProperty.all(EdgeInsets.zero),
        shape: WidgetStateProperty.all(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        backgroundColor: WidgetStateProperty.all(theme.colorScheme.surfaceContainerHighest),
      ),
      menuChildren: [
        _buildMenuItem(context, 'pl', '🇵🇱 Polish'),
        _buildMenuItem(context, 'en', '🇺🇸 English'),
      ],
      builder: (context, controller, child) {
        return GestureDetector(
          onTap: () => controller.isOpen ? controller.close() : controller.open(),
          child: Container(

            width: 140,
            height: 45,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  currentLabel,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
                Icon(Icons.keyboard_arrow_down_rounded, color: s.accentColor, size: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMenuItem(BuildContext context, String code, String label) {
    final isSelected = s.locale.languageCode == code;

    return MenuItemButton(
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.all(isSelected?null:s.accentColor.withValues(alpha: 0.01)),
      ),
      // MenuAnchor automatycznie dopasowuje szerokość przycisków do najszerszego elementu
      onPressed: () => s.setLocale(code),
      child: Container(
        width: 115, // Szerokość dopasowana do wnętrza kontenera
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
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
  const _AccentRow({required this.s, this.t});
  final AppSettings s;
  final AppLocalizations? t;

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
              Text(t?.accentColor ?? 'Accent color',
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
    final t = AppLocalizations.of(context);
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
              (v) => (v?.trim().isEmpty ?? true) ? (t?.fieldRequired ?? 'Required') : null,
    );
  }
}