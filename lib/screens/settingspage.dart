import 'package:flutter/material.dart';
import 'package:todo_list/assets/widgets.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  String _selectedTheme = 'Light';
  String _selectedLanguage = 'English';
  bool _menuButtonOnRight = true;

  bool _notificationsEnabled = false;
  bool _taskReminders = false;
  bool _invites = false;
  bool _groupInvites = false;

  bool _privateAccount = true;
  bool _twoFactorAuth = false;
  bool _biometricLock = false;

  final List<Color> _accentColors = [
    Colors.indigo,
    Colors.green,
    Colors.pink,
    Colors.orange,
    Colors.yellow.shade700,
    Colors.cyan,
    Colors.red,
  ];

  int _selectedAccentIndex = 0;

  bool get _isDarkMode => _selectedTheme == 'Dark';
  Color get _accentColor => _accentColors[_selectedAccentIndex];
  Color get _pageBackground =>
      _isDarkMode ? const Color(0xFF121212) : const Color(0xFFF5F6FA);
  Color get _cardColor =>
      _isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;
  Color get _textColor => _isDarkMode ? Colors.white : Colors.black87;
  Color get _subtitleColor =>
      _isDarkMode ? Colors.white70 : Colors.black54;
  Color get _dividerColor =>
      _isDarkMode ? Colors.white12 : Colors.black12;

  void _openMenu() {
    if (_menuButtonOnRight) {
      _scaffoldKey.currentState?.openEndDrawer();
    } else {
      _scaffoldKey.currentState?.openDrawer();
    }
  }

  void _showThemeSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: _cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  title: Text(
                    'Light',
                    style: TextStyle(color: _textColor),
                  ),
                  trailing: _selectedTheme == 'Light'
                      ? Icon(Icons.check, color: _accentColor)
                      : null,
                  onTap: () {
                    setState(() => _selectedTheme = 'Light');
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  title: Text(
                    'Dark',
                    style: TextStyle(color: _textColor),
                  ),
                  trailing: _selectedTheme == 'Dark'
                      ? Icon(Icons.check, color: _accentColor)
                      : null,
                  onTap: () {
                    setState(() => _selectedTheme = 'Dark');
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showLanguageSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: _cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) {
        return SafeArea(
          child: ListTile(
            title: Text(
              'English',
              style: TextStyle(color: _textColor),
            ),
            trailing: Icon(Icons.check, color: _accentColor),
            onTap: () {
              setState(() => _selectedLanguage = 'English');
              Navigator.pop(context);
            },
          ),
        );
      },
    );
  }

  void _showChangePasswordDialog() {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: _cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'Change password',
            style: TextStyle(
              color: _textColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildPasswordField(
                controller: currentPasswordController,
                label: 'Current password',
              ),
              const SizedBox(height: 12),
              _buildPasswordField(
                controller: newPasswordController,
                label: 'New password',
              ),
              const SizedBox(height: 12),
              _buildPasswordField(
                controller: confirmPasswordController,
                label: 'Confirm new password',
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(
                'Cancel',
                style: TextStyle(color: _subtitleColor),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _accentColor,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                if (newPasswordController.text.isEmpty ||
                    confirmPasswordController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please fill in all password fields.'),
                    ),
                  );
                  return;
                }

                if (newPasswordController.text !=
                    confirmPasswordController.text) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('New passwords do not match.'),
                    ),
                  );
                  return;
                }

                Navigator.pop(dialogContext);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Password changed successfully.'),
                  ),
                );
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _showPrivacyDialog() {
    bool tempPrivateAccount = _privateAccount;
    bool tempTwoFactorAuth = _twoFactorAuth;
    bool tempBiometricLock = _biometricLock;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: _cardColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Text(
                'Privacy & security',
                style: TextStyle(
                  color: _textColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    activeThumbColor: _accentColor,
                    title: Text(
                      'Private account',
                      style: TextStyle(color: _textColor),
                    ),
                    value: tempPrivateAccount,
                    onChanged: (value) {
                      setDialogState(() => tempPrivateAccount = value);
                    },
                  ),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    activeThumbColor: _accentColor,
                    title: Text(
                      'Two-factor authentication',
                      style: TextStyle(color: _textColor),
                    ),
                    value: tempTwoFactorAuth,
                    onChanged: (value) {
                      setDialogState(() => tempTwoFactorAuth = value);
                    },
                  ),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    activeThumbColor: _accentColor,
                    title: Text(
                      'Biometric lock',
                      style: TextStyle(color: _textColor),
                    ),
                    value: tempBiometricLock,
                    onChanged: (value) {
                      setDialogState(() => tempBiometricLock = value);
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: Text(
                    'Cancel',
                    style: TextStyle(color: _subtitleColor),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _accentColor,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    setState(() {
                      _privateAccount = tempPrivateAccount;
                      _twoFactorAuth = tempTwoFactorAuth;
                      _biometricLock = tempBiometricLock;
                    });

                    Navigator.pop(dialogContext);

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Privacy settings updated.'),
                      ),
                    );
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
  }) {
    return TextField(
      controller: controller,
      obscureText: true,
      style: TextStyle(color: _textColor),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: _subtitleColor),
        filled: true,
        fillColor: _isDarkMode ? const Color(0xFF2A2A2A) : Colors.grey.shade100,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 10, top: 8),
      child: Text(
        title,
        style: TextStyle(
          color: _textColor,
          fontSize: 22,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildCard({required List<Widget> children}) {
    final List<Widget> content = [];

    for (int i = 0; i < children.length; i++) {
      content.add(children[i]);
      if (i != children.length - 1) {
        content.add(Divider(height: 1, color: _dividerColor));
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(_isDarkMode ? 0.25 : 0.06),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(children: content),
    );
  }

  Widget _buildTapTile({
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
      title: Text(
        title,
        style: TextStyle(
          color: _textColor,
          fontSize: 17,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(
          subtitle,
          style: TextStyle(
            color: _subtitleColor,
            fontSize: 14,
          ),
        ),
      ),
      trailing: Icon(Icons.chevron_right, color: _subtitleColor),
      onTap: onTap,
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: _cardColor,
      child: SafeArea(
        child: Column(
          children: [
            DrawerHeader(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.account_circle,
                    size: 72,
                    color: _accentColor,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Menu',
                    style: TextStyle(
                      color: _textColor,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: Icon(Icons.home_outlined, color: _textColor),
              title: Text('Home', style: TextStyle(color: _textColor)),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: Icon(Icons.check_circle_outline, color: _textColor),
              title: Text('Tasks', style: TextStyle(color: _textColor)),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: Icon(Icons.group_outlined, color: _textColor),
              title: Text('Groups', style: TextStyle(color: _textColor)),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: Icon(Icons.settings_outlined, color: _accentColor),
              title: Text(
                'Settings',
                style: TextStyle(
                  color: _accentColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: _pageBackground,
      drawer: _menuButtonOnRight ? null : _buildDrawer(),
      endDrawer: _menuButtonOnRight ? _buildDrawer() : null,
      appBar: AppBar(
        backgroundColor: _cardColor,
        elevation: 1,
        automaticallyImplyLeading: false,
        titleSpacing: 16,
        title: Row(
          children: [
            Icon(
              Icons.account_circle_outlined,
              size: 38,
              color: _accentColor,
            ),
            const SizedBox(width: 10),
            Text(
              'Settings',
              style: TextStyle(
                color: _textColor,
                fontWeight: FontWeight.w700,
                fontSize: 28,
              ),
            ),
          ],
        ),
        actions: _menuButtonOnRight
            ? [
          IconButton(
            onPressed: _openMenu,
            icon: Icon(Icons.menu, color: _textColor, size: 32),
          ),
        ]
            : null,
        leading: !_menuButtonOnRight
            ? IconButton(
          onPressed: _openMenu,
          icon: Icon(Icons.menu, color: _textColor, size: 32),
        )
            : null,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Appearance'),
            _buildCard(
              children: [
                _buildTapTile(
                  title: 'Theme',
                  subtitle: _selectedTheme,
                  onTap: _showThemeSheet,
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Accent color',
                        style: TextStyle(
                          color: _textColor,
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 12,
                        children: List.generate(_accentColors.length, (index) {
                          final isSelected = index == _selectedAccentIndex;

                          return GestureDetector(
                            onTap: () {
                              setState(() => _selectedAccentIndex = index);
                            },
                            child: Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _accentColors[index],
                                border: Border.all(
                                  color: isSelected
                                      ? (_isDarkMode
                                      ? Colors.white
                                      : Colors.black87)
                                      : Colors.transparent,
                                  width: 3,
                                ),
                              ),
                              child: isSelected
                                  ? const Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 18,
                              )
                                  : null,
                            ),
                          );
                        }),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Menu button placement',
                        style: TextStyle(
                          color: _textColor,
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          ChoiceChip(
                            label: const Text('Left'),
                            selected: !_menuButtonOnRight,
                            selectedColor: _accentColor.withOpacity(0.22),
                            labelStyle: TextStyle(
                              color: !_menuButtonOnRight
                                  ? _accentColor
                                  : _textColor,
                              fontWeight: FontWeight.w600,
                            ),
                            onSelected: (_) {
                              setState(() => _menuButtonOnRight = false);
                            },
                          ),
                          const SizedBox(width: 12),
                          ChoiceChip(
                            label: const Text('Right'),
                            selected: _menuButtonOnRight,
                            selectedColor: _accentColor.withOpacity(0.22),
                            labelStyle: TextStyle(
                              color: _menuButtonOnRight
                                  ? _accentColor
                                  : _textColor,
                              fontWeight: FontWeight.w600,
                            ),
                            onSelected: (_) {
                              setState(() => _menuButtonOnRight = true);
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            _buildSectionTitle('Language'),
            _buildCard(
              children: [
                _buildTapTile(
                  title: 'Language',
                  subtitle: _selectedLanguage,
                  onTap: _showLanguageSheet,
                ),
              ],
            ),
            const SizedBox(height: 18),
            _buildSectionTitle('Notifications'),
            _buildCard(
              children: [
                SwitchListTile.adaptive(
                  contentPadding:
                  const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
                  activeThumbColor: _accentColor,
                  title: Text(
                    'Enable notifications',
                    style: TextStyle(
                      color: _textColor,
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  value: _notificationsEnabled,
                  onChanged: (value) {
                    setState(() {
                      _notificationsEnabled = value;
                    });
                  },
                ),
                SwitchListTile.adaptive(
                  contentPadding:
                  const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
                  activeThumbColor: _accentColor,
                  title: Text(
                    'Task reminders',
                    style: TextStyle(
                      color: _notificationsEnabled
                          ? _textColor
                          : _subtitleColor,
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  value: _taskReminders,
                  onChanged: _notificationsEnabled
                      ? (value) {
                    setState(() => _taskReminders = value);
                  }
                      : null,
                ),
                SwitchListTile.adaptive(
                  contentPadding:
                  const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
                  activeThumbColor: _accentColor,
                  title: Text(
                    'Invites',
                    style: TextStyle(
                      color: _notificationsEnabled
                          ? _textColor
                          : _subtitleColor,
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  value: _invites,
                  onChanged: _notificationsEnabled
                      ? (value) {
                    setState(() => _invites = value);
                  }
                      : null,
                ),
                SwitchListTile.adaptive(
                  contentPadding:
                  const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
                  activeThumbColor: _accentColor,
                  title: Text(
                    'Group invites',
                    style: TextStyle(
                      color: _notificationsEnabled
                          ? _textColor
                          : _subtitleColor,
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  value: _groupInvites,
                  onChanged: _notificationsEnabled
                      ? (value) {
                    setState(() => _groupInvites = value);
                  }
                      : null,
                ),
              ],
            ),
            const SizedBox(height: 18),
            _buildSectionTitle('Account settings'),
            _buildCard(
              children: [
                _buildTapTile(
                  title: 'Change password',
                  subtitle: 'Update your account password',
                  onTap: _showChangePasswordDialog,
                ),
                _buildTapTile(
                  title: 'Privacy & security',
                  subtitle: 'Manage security preferences',
                  onTap: _showPrivacyDialog,
                ),
              ],
            ),
          ],
        ),
      ),
      bottomNavigationBar: MyBottomAppBar(),
    );
  }
}