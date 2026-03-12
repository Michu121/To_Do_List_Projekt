import 'package:flutter/material.dart';
import 'package:todo_list/app_settings.dart';
import 'package:todo_list/assets/widgets.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final AppSettings settings = AppSettings.instance;

  final List<Color> accentColors = const [
    Color(0xFF5C6BC0), // Indigo
    Color(0xFF4CAF50), // Green
    Color(0xFFE91E63), // Pink
    Color(0xFFFF9800), // Orange
    Color(0xFFFFEB3B), // Yellow
    Color(0xFF00BCD4), // Cyan
    Color(0xFFF44336), // Red
  ];

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: settings,
      builder: (context, _) {
        final theme = Theme.of(context);

        return Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          appBar: const MyAppBar(title: 'Settings'),
          bottomNavigationBar: MyBottomAppBar(),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const _SectionTitle('Appearance'),
                _SettingsCard(
                  child: Column(
                    children: [
                      _buildThemePicker(context),
                      const Divider(height: 1),
                      _buildAccentColorPicker(context),
                      const Divider(height: 1),
                      _buildMenuPlacementPicker(context),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                const _SectionTitle('Language'),
                _SettingsCard(
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    title: const Text('App language'),
                    subtitle: Text(settings.language),
                    trailing: const Icon(Icons.check_circle_outline),
                  ),
                ),
                const SizedBox(height: 20),

                const _SectionTitle('Notifications'),
                _SettingsCard(
                  child: Column(
                    children: [
                      SwitchListTile.adaptive(
                        value: settings.notificationsEnabled,
                        onChanged: settings.setNotificationsEnabled,
                        title: const Text('Enable notifications'),
                        subtitle: const Text('Turn all notifications on or off'),
                      ),
                      const Divider(height: 1),
                      SwitchListTile.adaptive(
                        value: settings.taskReminders,
                        onChanged: settings.notificationsEnabled
                            ? settings.setTaskReminders
                            : null,
                        title: const Text('Task reminders'),
                      ),
                      const Divider(height: 1),
                      SwitchListTile.adaptive(
                        value: settings.friendInvitations,
                        onChanged: settings.notificationsEnabled
                            ? settings.setFriendInvitations
                            : null,
                        title: const Text('Friend invitations'),
                      ),
                      const Divider(height: 1),
                      SwitchListTile.adaptive(
                        value: settings.groupInvitations,
                        onChanged: settings.notificationsEnabled
                            ? settings.setGroupInvitations
                            : null,
                        title: const Text('Group invitations'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                const _SectionTitle('Account settings'),
                _SettingsCard(
                  child: Column(
                    children: [
                      ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        title: const Text('Change password'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => _showChangePasswordDialog(context),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        title: const Text('Privacy & security'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => _showPrivacyAndSecuritySheet(context),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildThemePicker(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Theme',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            children: [
              ChoiceChip(
                label: const Text('Light'),
                selected: settings.themeMode == ThemeMode.light,
                onSelected: (_) => settings.setThemeMode(ThemeMode.light),
              ),
              ChoiceChip(
                label: const Text('Dark'),
                selected: settings.themeMode == ThemeMode.dark,
                onSelected: (_) => settings.setThemeMode(ThemeMode.dark),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAccentColorPicker(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Accent color',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: accentColors.map((color) {
              final isSelected = settings.accentColor.value == color.value;

              return GestureDetector(
                onTap: () => settings.setAccentColor(color),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected
                          ? Theme.of(context).colorScheme.onSurface
                          : Colors.transparent,
                      width: 3,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.12),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuPlacementPicker(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Menu button placement',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            children: [
              ChoiceChip(
                label: const Text('Left'),
                selected: !settings.menuButtonOnRight,
                onSelected: (_) => settings.setMenuButtonPlacement(false),
              ),
              ChoiceChip(
                label: const Text('Right'),
                selected: settings.menuButtonOnRight,
                onSelected: (_) => settings.setMenuButtonPlacement(true),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog(BuildContext context) {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Change password'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: currentPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Current password',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: newPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'New password',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: confirmPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Confirm new password',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final currentPassword = currentPasswordController.text.trim();
                final newPassword = newPasswordController.text.trim();
                final confirmPassword = confirmPasswordController.text.trim();

                if (currentPassword.isEmpty ||
                    newPassword.isEmpty ||
                    confirmPassword.isEmpty) {
                  _showSnackBar('Please fill in all password fields.');
                  return;
                }

                if (newPassword.length < 6) {
                  _showSnackBar('New password must have at least 6 characters.');
                  return;
                }

                if (newPassword != confirmPassword) {
                  _showSnackBar('New passwords do not match.');
                  return;
                }

                Navigator.pop(dialogContext);
                _showSnackBar('Password changed successfully.');
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _showPrivacyAndSecuritySheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) {
        return AnimatedBuilder(
          animation: settings,
          builder: (context, _) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Privacy & Security',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    SwitchListTile.adaptive(
                      value: settings.privateProfile,
                      onChanged: settings.setPrivateProfile,
                      title: const Text('Private profile'),
                      subtitle: const Text(
                        'Only approved users can view profile details',
                      ),
                    ),
                    SwitchListTile.adaptive(
                      value: settings.twoFactorAuth,
                      onChanged: settings.setTwoFactorAuth,
                      title: const Text('Two-factor authentication'),
                    ),
                    SwitchListTile.adaptive(
                      value: settings.biometricLock,
                      onChanged: settings.setBiometricLock,
                      title: const Text('Biometric app lock'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final Widget child;

  const _SettingsCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1.5,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: child,
      ),
    );
  }
}