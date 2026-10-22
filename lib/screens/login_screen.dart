import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';

import '../services/auth_service.dart';
import '../theme/app_colors.dart';

/// Email/password sign-in and sign-up, toggled by [_isSignUp]. Shown before
/// [RootTabs] when no Firebase user is signed in (see [main.dart]'s
/// StreamBuilder on [AuthService.authStateChanges]).
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isSignUp = false;
  bool _submitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    if (email.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = 'メールアドレスとパスワードを入力してください。');
      return;
    }

    setState(() {
      _submitting = true;
      _errorMessage = null;
    });
    try {
      if (_isSignUp) {
        await AuthService.instance.signUp(email: email, password: password);
      } else {
        await AuthService.instance.signIn(email: email, password: password);
      }
      // On success, main.dart's auth-state StreamBuilder swaps to RootTabs
      // automatically — nothing further to do here.
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = e.message ?? 'エラーが発生しました。もう一度お試しください。');
    } catch (_) {
      if (!mounted) return;
      setState(() => _errorMessage = '通信エラーが発生しました。ネットワーク環境を確認してください。');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'K帳',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.w700,
                    color: AppColors.hankoRed,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _isSignUp ? '新規登録' : 'ログイン',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 18, color: AppColors.inkSecondary),
                ),
                const SizedBox(height: 32),
                _FieldBox(
                  controller: _emailController,
                  placeholder: 'メールアドレス',
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 12),
                _FieldBox(
                  controller: _passwordController,
                  placeholder: 'パスワード（6文字以上）',
                  obscureText: true,
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _errorMessage!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.errorRed, fontSize: 14),
                  ),
                ],
                const SizedBox(height: 20),
                CupertinoButton.filled(
                  onPressed: _submitting ? null : _submit,
                  child: _submitting
                      ? const CupertinoActivityIndicator(color: CupertinoColors.white)
                      : Text(_isSignUp ? '登録する' : 'ログイン'),
                ),
                const SizedBox(height: 12),
                CupertinoButton(
                  onPressed: _submitting
                      ? null
                      : () => setState(() {
                            _isSignUp = !_isSignUp;
                            _errorMessage = null;
                          }),
                  child: Text(
                    _isSignUp ? 'すでにアカウントをお持ちの方はこちら' : 'アカウントをお持ちでない方はこちら',
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FieldBox extends StatelessWidget {
  const _FieldBox({
    required this.controller,
    required this.placeholder,
    this.obscureText = false,
    this.keyboardType,
  });

  final TextEditingController controller;
  final String placeholder;
  final bool obscureText;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return CupertinoTextField(
      controller: controller,
      placeholder: placeholder,
      obscureText: obscureText,
      keyboardType: keyboardType,
      autocorrect: false,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      style: const TextStyle(color: AppColors.inkPrimary, fontSize: 16),
      placeholderStyle: const TextStyle(color: AppColors.inkSecondary),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.borderLine),
      ),
    );
  }
}
