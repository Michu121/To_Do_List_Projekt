import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../shared/services/auth_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLogin = true;
  bool _loading = false;
  bool _obscure = true;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      setState(() => _error = 'Please fill in all fields');
      return;
    }

    setState(() { _loading = true; _error = null; });

    try {
      if (_isLogin) {
        await authService.loginEmail(email, password);
      } else {
        await authService.registerEmail(email, password);
      }
    } catch (e) {
      setState(() => _error = _friendlyError(e.toString()));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _googleSignIn() async {
    setState(() { _loading = true; _error = null; });
    try {
      final result = await authService.signInGoogle();
      if (result == null && mounted) {
        setState(() => _loading = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = _friendlyGoogleError(e.toString());
          _loading = false;
        });
      }
    }
  }

  Future<void> _appleSignIn() async {
    setState(() { _loading = true; _error = null; });
    try {
      await authService.signInApple();
    } catch (e) {
      if (mounted) setState(() { _error = _friendlyError(e.toString()); _loading = false; });
    }
  }

  String _friendlyGoogleError(String raw) {
    if (raw.contains('sign_in_failed') || raw.contains('ApiException') || raw.contains('10:')) {
      return 'Google Sign-In failed.\n\nFix: Add your SHA-1 debug fingerprint to Firebase Console → Project Settings → Your Android App.\n\nRun: keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android';
    }
    if (raw.contains('network_error') || raw.contains('7:')) {
      return 'Network error. Check your internet connection.';
    }
    return _friendlyError(raw);
  }

  String _friendlyError(String raw) {
    if (raw.contains('wrong-password') || raw.contains('invalid-credential')) return 'Invalid email or password';
    if (raw.contains('user-not-found')) return 'No account found for this email';
    if (raw.contains('email-already-in-use')) return 'An account already exists for this email';
    if (raw.contains('weak-password')) return 'Password must be at least 6 characters';
    if (raw.contains('invalid-email')) return 'Please enter a valid email address';
    if (raw.contains('CONFIGURATION_NOT_FOUND')) return 'Email/Password sign-in is not enabled.\n\nFix: Firebase Console → Authentication → Sign-in method → Enable Email/Password.';
    if (raw.contains('network-request-failed')) return 'Network error. Check your internet connection.';
    return 'Something went wrong:\n$raw';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.blueAccent,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [BoxShadow(color: Colors.blueAccent.withOpacity(0.35), blurRadius: 20, offset: const Offset(0, 8))],
                  ),
                  child: const Icon(Icons.check_rounded, color: Colors.white, size: 48),
                ),
                const SizedBox(height: 20),
                Text(
                  'TaskFlow',
                  style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold, color: Colors.blueAccent, letterSpacing: -0.5),
                ),
                const SizedBox(height: 6),
                Text(
                  _isLogin ? 'Welcome back' : 'Create your account',
                  style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.55)),
                ),
                const SizedBox(height: 36),
                _buildTextField(controller: _emailController, label: 'Email', icon: Icons.email_outlined, keyboardType: TextInputType.emailAddress),
                const SizedBox(height: 14),
                _buildTextField(
                  controller: _passwordController,
                  label: 'Password',
                  icon: Icons.lock_outline,
                  obscure: _obscure,
                  suffixIcon: IconButton(
                    icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: Colors.grey),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(top: 2),
                          child: Icon(Icons.error_outline, color: Colors.red, size: 18),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 13)),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: _loading
                        ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                        : Text(_isLogin ? 'Sign In' : 'Create Account', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: Divider(color: theme.colorScheme.onSurface.withOpacity(0.15))),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text('or', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.45), fontSize: 13)),
                    ),
                    Expanded(child: Divider(color: theme.colorScheme.onSurface.withOpacity(0.15))),
                  ],
                ),
                const SizedBox(height: 16),
                _SocialButton(
                  label: 'Continue with Google',
                  icon: const Icon(Icons.g_mobiledata, size: 26, color: Colors.redAccent),
                  onTap: _loading ? null : _googleSignIn,
                  isDark: isDark,
                ),
                if (defaultTargetPlatform == TargetPlatform.iOS) ...[
                  const SizedBox(height: 10),
                  _SocialButton(
                    label: 'Continue with Apple',
                    icon: Icon(Icons.apple, color: isDark ? Colors.white : Colors.black, size: 22),
                    onTap: _loading ? null : _appleSignIn,
                    isDark: isDark,
                  ),
                ],
                const SizedBox(height: 28),
                GestureDetector(
                  onTap: () => setState(() { _isLogin = !_isLogin; _error = null; }),
                  child: RichText(
                    text: TextSpan(
                      style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6), fontSize: 14),
                      children: [
                        TextSpan(text: _isLogin ? "Don't have an account? " : 'Already have an account? '),
                        TextSpan(
                          text: _isLogin ? 'Sign Up' : 'Sign In',
                          style: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool obscure = false,
    Widget? suffixIcon,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscure,
      style: const TextStyle(fontSize: 15),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
        suffixIcon: suffixIcon,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.blueAccent, width: 1.5)),
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  final String label;
  final Widget icon;
  final VoidCallback? onTap;
  final bool isDark;

  const _SocialButton({required this.label, required this.icon, required this.onTap, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: Colors.grey.shade300),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          foregroundColor: isDark ? Colors.white : Colors.black87,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [icon, const SizedBox(width: 10), Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500))],
        ),
      ),
    );
  }
}