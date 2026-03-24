import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../shared/services/auth_service.dart';
import '../shared/services/fire_store_service.dart';
import '../shared/services/group_task_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  final _auth = AuthService();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isLogin = true;
  bool _loading = false;
  bool _obscurePassword = true;
  String? _error;

  late final AnimationController _animController;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnim =
        CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _animController.dispose();
    super.dispose();
  }

  void _toggleMode() {
    setState(() {
      _isLogin = !_isLogin;
      _error = null;
    });
    _animController.reset();
    _animController.forward();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      UserCredential cred;
      if (_isLogin) {
        cred = await _auth.loginEmail(
          _emailController.text.trim(),
          _passwordController.text,
        );
      } else {
        cred = await _auth.registerEmail(
          _emailController.text.trim(),
          _passwordController.text,
        );
        await cred.user!.updateDisplayName(_nameController.text.trim());
      }
      await FirestoreService().afterLogin(cred.user!);
      groupTaskService.init();
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        setState(() {
          _error = _friendlyError(e.code);
          _loading = false;
        });
      }
    }
  }

  Future<void> _googleSignIn() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final cred = await _auth.signInGoogle();
      if (cred != null) {
        await FirestoreService().afterLogin(cred.user!);
        groupTaskService.init();
      } else {
        if (mounted) setState(() => _loading = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Google sign-in failed. Try again.';
          _loading = false;
        });
      }
    }
  }

  String _friendlyError(String code) => switch (code) {
    'user-not-found' => 'No account found for this email.',
    'wrong-password' => 'Incorrect password.',
    'email-already-in-use' => 'This email is already registered.',
    'weak-password' => 'Password must be at least 6 characters.',
    'invalid-email' => 'Enter a valid email address.',
    _ => 'Something went wrong. Please try again.',
  };

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.center,
                colors: [
                  accent.withValues(alpha: isDark ? 0.4 : 0.15),
                  theme.scaffoldBackgroundColor,
                ],
              ),
            ),
          ),

          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                child: FadeTransition(
                  opacity: _fadeAnim,
                  child: SlideTransition(
                    position: _slideAnim,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // ── Logo ──────────────────────────────────
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [accent, accent.withValues(alpha: 0.7)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(22),
                            boxShadow: [
                              BoxShadow(
                                  color: accent.withValues(alpha: 0.4),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8))
                            ],
                          ),
                          child: const Icon(Icons.checklist_rounded,
                              size: 44, color: Colors.white),
                        ),
                        const SizedBox(height: 24),

                        Text(
                          _isLogin ? (t?.welcomeBack ?? 'Welcome back') : (t?.createAccount ?? 'Create account'),
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _isLogin
                              ? 'Sign in to your account'
                              : 'Join and start organising',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.55),
                          ),
                        ),
                        const SizedBox(height: 32),

                        // ── Form card ─────────────────────────────
                        Container(
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surface,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                  color: Colors.black.withAlpha(isDark ? 40 : 12),
                                  blurRadius: 24,
                                  offset: const Offset(0, 8))
                            ],
                          ),
                          padding: const EdgeInsets.all(24),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              children: [
                                if (!_isLogin) ...[
                                  _Field(
                                    controller: _nameController,
                                    label: t?.username ?? 'Full name',
                                    icon: Icons.person_outline,
                                    accent: accent,
                                    action: TextInputAction.next,
                                    validator: (v) => (v?.trim().isEmpty ?? true)
                                        ? (t?.fieldRequired ?? 'Enter your name')
                                        : null,
                                  ),
                                  const SizedBox(height: 14),
                                ],
                                _Field(
                                  controller: _emailController,
                                  label: t?.email ?? 'Email',
                                  icon: Icons.email_outlined,
                                  accent: accent,
                                  keyboard: TextInputType.emailAddress,
                                  action: TextInputAction.next,
                                  validator: (v) =>
                                  (v?.contains('@') ?? false)
                                      ? null
                                      : (t?.invalidEmail ?? 'Enter a valid email'),
                                ),
                                const SizedBox(height: 14),
                                _Field(
                                  controller: _passwordController,
                                  label: t?.password ?? 'Password',
                                  icon: Icons.lock_outline,
                                  accent: accent,
                                  obscure: _obscurePassword,
                                  action: TextInputAction.done,
                                  suffix: IconButton(
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility_off
                                          : Icons.visibility,
                                      size: 20,
                                    ),
                                    onPressed: () => setState(
                                            () => _obscurePassword =
                                        !_obscurePassword),
                                  ),
                                  validator: (v) =>
                                  (v?.length ?? 0) >= 6
                                      ? null
                                      : (t?.minCharacters ?? 'At least 6 characters'),
                                  onFieldSubmitted: (_) => _submit(),
                                ),

                                // Error message
                                if (_error != null) ...[
                                  const SizedBox(height: 14),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 14, vertical: 10),
                                    decoration: BoxDecoration(
                                      color: Colors.red.shade50,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                          color: Colors.red.shade200),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(Icons.error_outline,
                                            size: 16,
                                            color: Colors.red.shade700),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            _error!,
                                            style: TextStyle(
                                                color: Colors.red.shade700,
                                                fontSize: 13),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],

                                const SizedBox(height: 20),

                                // Submit button
                                SizedBox(
                                  width: double.infinity,
                                  height: 52,
                                  child: FilledButton(
                                    style: FilledButton.styleFrom(
                                      backgroundColor: accent,
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                          BorderRadius.circular(14)),
                                    ),
                                    onPressed: _loading ? null : _submit,
                                    child: _loading
                                        ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          color: Colors.white),
                                    )
                                        : Text(
                                      _isLogin
                                          ? (t?.signIn ?? 'Sign In')
                                          : (t?.signUp ?? 'Create Account'),
                                      style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // ── Or divider ────────────────────────────
                        Row(
                          children: [
                            Expanded(
                                child: Divider(
                                    color: theme.dividerColor)),
                            Padding(
                              padding:
                              const EdgeInsets.symmetric(horizontal: 12),
                              child: Text('or',
                                  style: TextStyle(
                                      color: theme.colorScheme.onSurface
                                          .withValues(alpha: 0.4),
                                      fontSize: 13)),
                            ),
                            Expanded(
                                child: Divider(
                                    color: theme.dividerColor)),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // ── Google button ─────────────────────────
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14)),
                              side: BorderSide(
                                  color: theme.dividerColor, width: 1.5),
                            ),
                            onPressed: _loading ? null : _googleSignIn,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'G',
                                  style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: accent),
                                ),
                                const SizedBox(width: 10),
                                const Text('Continue with Google',
                                    style: TextStyle(fontSize: 15)),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // ── Toggle mode ───────────────────────────
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _isLogin
                                  ? (t?.noAccount ?? "Don't have an account? ")
                                  : (t?.haveAccount ?? 'Already have an account? '),
                              style: TextStyle(
                                  color: theme.colorScheme.onSurface
                                      .withValues(alpha: 0.55),
                                  fontSize: 14),
                            ),
                            const SizedBox(width: 4),
                            GestureDetector(
                              onTap: _toggleMode,
                              child: Text(
                                _isLogin ? (t?.signUp ?? 'Register') : (t?.signIn ?? 'Sign In'),
                                style: TextStyle(
                                    color: accent,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
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

// ── Reusable field ────────────────────────────────────────────────────────────

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.label,
    required this.icon,
    required this.accent,
    this.keyboard,
    this.action = TextInputAction.next,
    this.obscure = false,
    this.suffix,
    this.validator,
    this.onFieldSubmitted,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final Color accent;
  final TextInputType? keyboard;
  final TextInputAction action;
  final bool obscure;
  final Widget? suffix;
  final String? Function(String?)? validator;
  final void Function(String)? onFieldSubmitted;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboard,
      textInputAction: action,
      obscureText: obscure,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        suffixIcon: suffix,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
              color: Theme.of(context).dividerColor.withAlpha(100)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: accent, width: 1.5),
        ),
      ),
      validator: validator,
      onFieldSubmitted: onFieldSubmitted,
    );
  }
}