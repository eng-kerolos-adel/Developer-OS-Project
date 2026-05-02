import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/constants/route_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/animated_background.dart';
import '../../../../shared/widgets/glass_widgets.dart';
import '../../providers/auth_provider.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    final controller = ref.read(authControllerProvider.notifier);
    final success = await controller.registerWithEmail(
      _emailController.text,
      _passwordController.text,
      _nameController.text,
    );
    if (success && mounted) {
      context.go(RouteConstants.home);
    }
  }

  Future<void> _signInWithGoogle() async {
    final controller = ref.read(authControllerProvider.notifier);
    final success = await controller.signInWithGoogle();
    if (success && mounted) {
      context.go(RouteConstants.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isLoading = authState.status == AuthStatus.loading;

    return Scaffold(
      body: AnimatedBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Back button
                  IconButton(
                    onPressed: () => context.go(RouteConstants.login),
                    icon: Icon(
                      Icons.arrow_back_ios,
                      color: isDark ? AppTheme.white : AppTheme.black,
                      size: 18,
                    ),
                  ),

                  const SizedBox(height: 24),

                  Text(
                    '// new developer',
                    style: TextStyle(
                      fontFamily: 'JetBrainsMono',
                      fontSize: 12,
                      color: isDark ? AppTheme.gray : AppTheme.lightGray,
                    ),
                  ).animate().fadeIn(delay: 100.ms),

                  const SizedBox(height: 8),

                  Text(
                    'Create\nAccount',
                    style: TextStyle(
                      fontFamily: 'Syne',
                      fontSize: 40,
                      fontWeight: FontWeight.w800,
                      color: isDark ? AppTheme.white : AppTheme.black,
                      letterSpacing: -1,
                      height: 1.1,
                    ),
                  ).animate().fadeIn(delay: 200.ms).slideX(begin: -0.1, end: 0),

                  const SizedBox(height: 40),

                  if (authState.errorMessage != null)
                    GlassContainer(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 16),
                      color: Colors.red,
                      opacity: 0.1,
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: Colors.red, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              authState.errorMessage!,
                              style: const TextStyle(
                                fontFamily: 'JetBrainsMono',
                                fontSize: 12,
                                color: Colors.red,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ).animate().fadeIn().shakeX(),

                  GlassTextField(
                    controller: _nameController,
                    labelText: 'Full Name',
                    hintText: 'John Doe',
                    textInputAction: TextInputAction.next,
                    prefixIcon: Icon(
                      Icons.person_outline,
                      size: 18,
                      color: isDark ? AppTheme.gray : AppTheme.lightGray,
                    ),
                    validator: (val) =>
                        val == null || val.isEmpty ? 'Name is required' : null,
                  ).animate().fadeIn(delay: 300.ms),

                  const SizedBox(height: 14),

                  GlassTextField(
                    controller: _emailController,
                    labelText: 'Email',
                    hintText: 'dev@example.com',
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    prefixIcon: Icon(
                      Icons.alternate_email,
                      size: 18,
                      color: isDark ? AppTheme.gray : AppTheme.lightGray,
                    ),
                    validator: (val) {
                      if (val == null || val.isEmpty) return 'Email is required';
                      if (!RegExp(r'\S+@\S+\.\S+').hasMatch(val)) {
                        return 'Enter a valid email';
                      }
                      return null;
                    },
                  ).animate().fadeIn(delay: 350.ms),

                  const SizedBox(height: 14),

                  GlassTextField(
                    controller: _passwordController,
                    labelText: 'Password',
                    hintText: '••••••••',
                    obscureText: _obscurePassword,
                    textInputAction: TextInputAction.next,
                    prefixIcon: Icon(
                      Icons.lock_outline,
                      size: 18,
                      color: isDark ? AppTheme.gray : AppTheme.lightGray,
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        size: 18,
                        color: isDark ? AppTheme.gray : AppTheme.lightGray,
                      ),
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                    validator: (val) {
                      if (val == null || val.isEmpty) return 'Password is required';
                      if (val.length < 6) return 'Minimum 6 characters';
                      return null;
                    },
                  ).animate().fadeIn(delay: 400.ms),

                  const SizedBox(height: 14),

                  GlassTextField(
                    controller: _confirmPasswordController,
                    labelText: 'Confirm Password',
                    hintText: '••••••••',
                    obscureText: _obscureConfirm,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _register(),
                    prefixIcon: Icon(
                      Icons.lock_outline,
                      size: 18,
                      color: isDark ? AppTheme.gray : AppTheme.lightGray,
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirm
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        size: 18,
                        color: isDark ? AppTheme.gray : AppTheme.lightGray,
                      ),
                      onPressed: () =>
                          setState(() => _obscureConfirm = !_obscureConfirm),
                    ),
                    validator: (val) {
                      if (val == null || val.isEmpty) {
                        return 'Please confirm your password';
                      }
                      if (val != _passwordController.text) {
                        return 'Passwords do not match';
                      }
                      return null;
                    },
                  ).animate().fadeIn(delay: 450.ms),

                  const SizedBox(height: 32),

                  GlassButton(
                    label: 'Create Account',
                    onPressed: _register,
                    isLoading: isLoading,
                    isPrimary: true,
                  ).animate().fadeIn(delay: 500.ms),

                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: Divider(
                          color: (isDark ? AppTheme.white : AppTheme.black).withOpacity(0.1),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'OR',
                          style: TextStyle(
                            fontFamily: 'JetBrainsMono',
                            fontSize: 11,
                            letterSpacing: 2,
                            color: isDark ? AppTheme.gray : AppTheme.lightGray,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Divider(
                          color: (isDark ? AppTheme.white : AppTheme.black).withOpacity(0.1),
                        ),
                      ),
                    ],
                  ).animate().fadeIn(delay: 550.ms),

                  const SizedBox(height: 16),

                  GlassButton(
                    label: 'Continue with Google',
                    onPressed: _signInWithGoogle,
                    isLoading: false,
                    isPrimary: false,
                    icon: Image.asset(
                      'assets/icons/google.png',
                      width: 18,
                      height: 18,
                      errorBuilder: (_, __, ___) => Icon(
                        Icons.g_mobiledata,
                        color: isDark ? AppTheme.white : AppTheme.black,
                        size: 20,
                      ),
                    ),
                  ).animate().fadeIn(delay: 600.ms),

                  const SizedBox(height: 32),

                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Already have an account? ',
                          style: TextStyle(
                            fontFamily: 'JetBrainsMono',
                            fontSize: 13,
                            color: isDark ? AppTheme.gray : AppTheme.lightGray,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => context.go(RouteConstants.login),
                          child: Text(
                            'Sign In',
                            style: TextStyle(
                              fontFamily: 'JetBrainsMono',
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: isDark ? AppTheme.white : AppTheme.black,
                              decoration: TextDecoration.underline,
                              decorationColor:
                                  isDark ? AppTheme.white : AppTheme.black,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: 650.ms),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
