import 'package:flutter/material.dart';
import '../app_settings.dart';
import '../shared/widgets/app_bars/upper_app_bar.dart';
import 'package:todo_list/shared/services/auth_service.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final AppSettings settings = AppSettings.instance;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: settings,
      builder: (context, _) {
        final theme = Theme.of(context);

        return Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          appBar: const MyAppBar(title: 'Settings'),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              children: [
                const _SectionTitle(title: 'Appearance'),
                _SectionBox(
                  children: [
                    _ValueTile(
                      title: 'Theme',
                      value: settings.themeLabel,
                      onTap: () => _showThemePicker(context),
                    ),
                    const Divider(height: 1),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Accent color',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: AppSettings.availableAccentColors
                                .map((color) => _AccentColorCircle(
                              color: color,
                              isSelected:
                              settings.accentColor.toARGB32() ==
                                  color.toARGB32(),
                              onTap: () =>
                                  settings.setAccentColor(color),
                            ))
                                .toList(),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const _SectionTitle(title: 'Language'),
                _SectionBox(
                  children: [
                    _ValueTile(
                      title: 'Language',
                      value: settings.language,
                      onTap: () => _showLanguagePicker(context),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const _SectionTitle(title: 'Notifications'),
                _SectionBox(
                  children: [
                    SwitchListTile.adaptive(
                      value: settings.notificationsEnabled,
                      onChanged: settings.setNotificationsEnabled,
                      title: const Text('Enable notifications'),
                      contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    const Divider(height: 1),
                    SwitchListTile.adaptive(
                      value: settings.taskReminders,
                      onChanged: settings.notificationsEnabled
                          ? settings.setTaskReminders
                          : null,
                      title: const Text('Task reminders'),
                      contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    const Divider(height: 1),
                    SwitchListTile.adaptive(
                      value: settings.invitations,
                      onChanged: settings.notificationsEnabled
                          ? settings.setInvitations
                          : null,
                      title: const Text('Invitations'),
                      contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    const Divider(height: 1),
                    SwitchListTile.adaptive(
                      value: settings.groupInvitations,
                      onChanged: settings.notificationsEnabled
                          ? settings.setGroupInvitations
                          : null,
                      title: const Text('Group invitations'),
                      contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const _SectionTitle(title: 'Account'),
                _SectionBox(
                  children: [
                    _SimpleTile(
                      title: 'Change password',
                      onTap: () => _showChangePasswordDialog(context),
                    ),
                    const Divider(height: 1),
                    _SimpleTile(
                      title: 'Privacy and security',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) => const PrivacySecurityPage()),
                      ),
                    ),
                    const Divider(height: 1),
                    _SimpleTile(
                      title: 'Log out',
                      onTap: () => _showLogoutDialog(context),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Theme picker ─────────────────────────────────────────────────────────

  void _showThemePicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile<AppThemeMode>(
                value: AppThemeMode.light,
                groupValue: settings.themeMode,
                title: const Text('Light'),
                onChanged: (value) {
                  if (value != null) {
                    settings.setThemeMode(value);
                    Navigator.pop(context);
                  }
                },
              ),
              RadioListTile<AppThemeMode>(
                value: AppThemeMode.dark,
                groupValue: settings.themeMode,
                title: const Text('Dark'),
                onChanged: (value) {
                  if (value != null) {
                    settings.setThemeMode(value);
                    Navigator.pop(context);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Language picker ──────────────────────────────────────────────────────

  void _showLanguagePicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile<String>(
                value: 'English',
                groupValue: settings.language,
                title: const Text('English'),
                onChanged: (value) {
                  if (value != null) {
                    settings.setLanguage(value);
                    Navigator.pop(context);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Change password dialog ────────────────────────────────────────────────

  Future<void> _showChangePasswordDialog(BuildContext context) async {
    final formKey = GlobalKey<FormState>();
    final currentPasswordCtrl = TextEditingController();
    final newPasswordCtrl = TextEditingController();
    final confirmPasswordCtrl = TextEditingController();

    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Change password'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: currentPasswordCtrl,
                obscureText: true,
                decoration:
                const InputDecoration(labelText: 'Current password'),
                validator: (v) =>
                (v?.trim().isEmpty ?? true) ? 'Enter current password' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: newPasswordCtrl,
                obscureText: true,
                decoration:
                const InputDecoration(labelText: 'New password'),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Enter new password';
                  if (v.trim().length < 8) return 'At least 8 characters';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: confirmPasswordCtrl,
                obscureText: true,
                decoration:
                const InputDecoration(labelText: 'Confirm password'),
                validator: (v) {
                  if (v?.trim() != newPasswordCtrl.text.trim()) {
                    return 'Passwords do not match';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(dialogContext);
                // TODO: wire to auth service
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Password changed successfully')),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    currentPasswordCtrl.dispose();
    newPasswordCtrl.dispose();
    confirmPasswordCtrl.dispose();
  }
}

// ── Logout dialog (top-level helper) ─────────────────────────────────────────

Future<void> _showLogoutDialog(BuildContext context) async {
  final shouldLogout = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Log out'),
      content: const Text('Are you sure you want to log out?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          child: const Text('Log out'),
        ),
      ],
    ),
  );

  if (shouldLogout == true) {
    try {
      await authService.logout();
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to log out: $e')),
      );
    }
  }
}

// ── Privacy & Security page ───────────────────────────────────────────────────

class PrivacySecurityPage extends StatelessWidget {
  const PrivacySecurityPage({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = AppSettings.instance;

    return AnimatedBuilder(
      animation: settings,
      builder: (context, _) => Scaffold(
        appBar: AppBar(title: const Text('Privacy and security')),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _SectionBox(
              children: [
                SwitchListTile.adaptive(
                  value: settings.biometricLock,
                  onChanged: settings.setBiometricLock,
                  title: const Text('Use biometric lock'),
                  contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16),
                ),
                const Divider(height: 1),
                SwitchListTile.adaptive(
                  value: settings.lockWhenBackgrounded,
                  onChanged: settings.setLockWhenBackgrounded,
                  title: const Text('Lock app when minimised'),
                  contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16),
                ),
                const Divider(height: 1),
                SwitchListTile.adaptive(
                  value: settings.hideNotificationContent,
                  onChanged: settings.setHideNotificationContent,
                  title: const Text('Hide notification content'),
                  contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Shared sub-widgets ────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 10),
      child: Text(
        title,
        style: Theme.of(context)
            .textTheme
            .titleLarge
            ?.copyWith(fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _SectionBox extends StatelessWidget {
  const _SectionBox({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.dividerColor.withAlpha(80)),
        boxShadow: theme.brightness == Brightness.light
            ? [
          BoxShadow(
              color: Colors.black.withAlpha(12),
              blurRadius: 18,
              offset: const Offset(0, 6))
        ]
            : [],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(children: children),
      ),
    );
  }
}

class _ValueTile extends StatelessWidget {
  const _ValueTile(
      {required this.title, required this.value, required this.onTap});
  final String title;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(title,
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.w600)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(width: 6),
          const Icon(Icons.chevron_right_rounded),
        ],
      ),
      onTap: onTap,
    );
  }
}

class _SimpleTile extends StatelessWidget {
  const _SimpleTile({required this.title, required this.onTap});
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(title,
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.w600)),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: onTap,
    );
  }
}

class _AccentColorCircle extends StatelessWidget {
  const _AccentColorCircle(
      {required this.color, required this.isSelected, required this.onTap});
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final iconColor =
    ThemeData.estimateBrightnessForColor(color) == Brightness.dark
        ? Colors.white
        : Colors.black;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.onSurface
                : Colors.transparent,
            width: 2.4,
          ),
          boxShadow: [
            BoxShadow(
                color: color.withAlpha(90),
                blurRadius: 8,
                offset: const Offset(0, 3))
          ],
        ),
        child: isSelected
            ? Icon(Icons.check_rounded, size: 18, color: iconColor)
            : null,
      ),
    );
  }
}