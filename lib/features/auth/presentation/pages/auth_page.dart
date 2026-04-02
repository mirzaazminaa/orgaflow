import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/session/session_context.dart';
import 'register_page.dart';
import '../presenters/auth_presenter.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _GradientButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final String text;
  final double height;
  final bool isLoading;

  const _GradientButton({
    required this.onPressed,
    required this.text,
    this.height = 56,
    this.isLoading = false,
  });

  @override
  State<_GradientButton> createState() => _GradientButtonState();
}

class _GradientButtonState extends State<_GradientButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    const purpleColor = Color(0xFF8B5CF6);
    const tealColor = Color(0xFF14B8A6);
    const hoverPurple = Color(0xFFA78BFA);
    const hoverTeal = Color(0xFF2DD4BF);

    return MouseRegion(
      cursor: widget.onPressed != null ? SystemMouseCursors.click : SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        height: widget.height,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: _isHovered && widget.onPressed != null
                ? [hoverPurple, hoverTeal]
                : [purpleColor, tealColor],
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: _isHovered && widget.onPressed != null
              ? [
                  BoxShadow(
                    color: purpleColor.withOpacity(0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ]
              : [],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onPressed,
            borderRadius: BorderRadius.circular(12),
            child: Center(
              child: widget.isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      widget.text,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AuthPageState extends State<AuthPage> with TickerProviderStateMixin {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  AuthPresenter? _presenter;

  bool showPassword = false;
  bool rememberMe = false;
  bool isLoading = false;

  late AnimationController _orb1Controller;
  late AnimationController _orb2Controller;
  late AnimationController _orb3Controller;
  late AnimationController _orb4Controller;
  late AnimationController _orb5Controller;

  @override
  void initState() {
    super.initState();
    _orb1Controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);

    _orb2Controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat(reverse: true);

    _orb3Controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat(reverse: true);

    _orb4Controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 9),
    )..repeat(reverse: true);

    _orb5Controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 11),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    _orb1Controller.dispose();
    _orb2Controller.dispose();
    _orb3Controller.dispose();
    _orb4Controller.dispose();
    _orb5Controller.dispose();
    super.dispose();
  }

  Future<void> handleSubmit() async {
    final identifier = emailController.text.trim();
    final password = passwordController.text.trim();

    if (identifier.isEmpty || password.isEmpty) {
      showMessage('Email dan password wajib diisi');
      return;
    }

    try {
      setState(() {
        isLoading = true;
      });

      final result = await (_presenter ??= AuthPresenter()).signIn(
        email: identifier,
        password: password,
      );

      if (!mounted) return;

      if (result.isFailure) {
        showMessage(result.error!.message);
        return;
      }

      showMessage('Login berhasil');

      Navigator.pushReplacementNamed(
        context,
        result.data?.routeName ?? AppRouteTarget.dashboard.routeName,
      );
    } catch (_) {
      showMessage('Terjadi kesalahan saat login.');
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> handleForgotPassword() async {
    final result = await (_presenter ??= AuthPresenter()).requestPasswordReset(
      email: emailController.text,
    );

    if (!mounted) return;

    if (result.isFailure) {
      showMessage(result.error!.message);
      return;
    }

    showMessage(
      'Jika email terdaftar, tautan reset password akan dikirim ke inbox Anda.',
    );
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const purpleColor = Color(0xFF8B5CF6);
    const tealColor = Color(0xFF14B8A6);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              purpleColor.withOpacity(0.15),
              theme.scaffoldBackgroundColor,
              tealColor.withOpacity(0.15),
            ],
          ),
        ),
        child: Stack(
          children: [
            // Animated background orbs
            _buildAnimatedOrbs(),

            // Main content
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 448),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildHeader(),
                        const SizedBox(height: 32),
                        _buildLoginCard(theme),
                        const SizedBox(height: 24),
                        _buildSignUpLink(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedOrbs() {
    const purpleColor = Color(0xFF8B5CF6);
    const tealColor = Color(0xFF14B8A6);
    return Positioned.fill(
      child: Stack(
        children: [
          // Orb 1 - Top left, large
          AnimatedBuilder(
            animation: _orb1Controller,
            builder: (context, child) {
              final scale = 1.0 + (_orb1Controller.value * 0.2);
              final opacity = 0.4 + (_orb1Controller.value * 0.2);
              return Positioned(
                top: -160,
                left: -160,
                child: Transform.scale(
                  scale: scale,
                  child: Container(
                    width: 384,
                    height: 384,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          purpleColor.withOpacity(opacity * 0.3),
                          purpleColor.withOpacity(opacity * 0.1),
                        ],
                      ),
                    ),
                  ).animate(onPlay: (controller) => controller.repeat()).blur(
                      begin: const Offset(0, 0),
                      end: const Offset(80, 80),
                      duration: 1.ms),
                ),
              );
            },
          ),

          // Orb 2 - Top right, medium
          AnimatedBuilder(
            animation: _orb2Controller,
            builder: (context, child) {
              final scale = 1.0 + (_orb2Controller.value * 0.3);
              final opacity = 0.3 + (_orb2Controller.value * 0.3);
              return Positioned(
                top: -100,
                right: -100,
                child: Transform.scale(
                  scale: scale,
                  child: Container(
                    width: 256,
                    height: 256,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          tealColor.withOpacity(opacity * 0.4),
                          tealColor.withOpacity(opacity * 0.1),
                        ],
                      ),
                    ),
                  ).animate(onPlay: (controller) => controller.repeat()).blur(
                      begin: const Offset(0, 0),
                      end: const Offset(60, 60),
                      duration: 1.ms),
                ),
              );
            },
          ),

          // Orb 3 - Bottom left, small
          AnimatedBuilder(
            animation: _orb3Controller,
            builder: (context, child) {
              final scale = 1.0 + (_orb3Controller.value * 0.25);
              final opacity = 0.35 + (_orb3Controller.value * 0.25);
              final rotation = _orb3Controller.value * 2 * math.pi;
              return Positioned(
                bottom: -80,
                left: -80,
                child: Transform.rotate(
                  angle: rotation,
                  child: Transform.scale(
                    scale: scale,
                    child: Container(
                      width: 192,
                      height: 192,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            purpleColor.withOpacity(opacity * 0.35),
                            purpleColor.withOpacity(opacity * 0.1),
                          ],
                        ),
                      ),
                    ).animate(onPlay: (controller) => controller.repeat()).blur(
                        begin: const Offset(0, 0),
                        end: const Offset(50, 50),
                        duration: 1.ms),
                  ),
                ),
              );
            },
          ),

          // Orb 4 - Bottom right, medium
          AnimatedBuilder(
            animation: _orb4Controller,
            builder: (context, child) {
              final scale = 1.0 + (_orb4Controller.value * 0.28);
              final opacity = 0.32 + (_orb4Controller.value * 0.28);
              return Positioned(
                bottom: -120,
                right: -120,
                child: Transform.scale(
                  scale: scale,
                  child: Container(
                    width: 288,
                    height: 288,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          tealColor.withOpacity(opacity * 0.38),
                          tealColor.withOpacity(opacity * 0.1),
                        ],
                      ),
                    ),
                  ).animate(onPlay: (controller) => controller.repeat()).blur(
                      begin: const Offset(0, 0),
                      end: const Offset(70, 70),
                      duration: 1.ms),
                ),
              );
            },
          ),

          // Orb 5 - Center floating, small
          AnimatedBuilder(
            animation: _orb5Controller,
            builder: (context, child) {
              final scale = 1.0 + (_orb5Controller.value * 0.35);
              final opacity = 0.25 + (_orb5Controller.value * 0.35);
              final offsetY = _orb5Controller.value * 100 - 50;
              return Positioned(
                top: MediaQuery.of(context).size.height * 0.3 + offsetY,
                right: 50,
                child: Transform.scale(
                  scale: scale,
                  child: Container(
                    width: 160,
                    height: 160,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          purpleColor.withOpacity(opacity * 0.3),
                          purpleColor.withOpacity(opacity * 0.05),
                        ],
                      ),
                    ),
                  ).animate(onPlay: (controller) => controller.repeat()).blur(
                      begin: const Offset(0, 0),
                      end: const Offset(45, 45),
                      duration: 1.ms),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    const purpleColor = Color(0xFF8B5CF6);
    const tealColor = Color(0xFF14B8A6);
    return Column(
      children: [
        // Logo with hover effect (using GestureDetector for tap scale)
        GestureDetector(
          onTapDown: (_) => setState(() {}),
          onTapUp: (_) => setState(() {}),
          child: Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: const LinearGradient(
                colors: [purpleColor, tealColor],
              ),
            ),
            child: const Icon(
              Icons.auto_awesome,
              size: 32,
              color: Colors.white,
            ),
          ),
        )
            .animate()
            .fadeIn(duration: 600.ms, delay: 200.ms)
            .slideY(begin: -0.2, end: 0, duration: 600.ms, delay: 200.ms)
            .scale(begin: const Offset(0.8, 0.8), delay: 200.ms),

        const SizedBox(height: 16),

        // Title with gradient
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [purpleColor, tealColor],
          ).createShader(bounds),
          child: const Text(
            'Selamat datang di OrgaFlow!',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
        )
            .animate()
            .fadeIn(duration: 600.ms, delay: 200.ms)
            .slideY(begin: -0.2, end: 0, duration: 600.ms, delay: 200.ms),

        const SizedBox(height: 8),

        Text(
          'Yuk, buat distribusi kerja ormawamu jadi lebih adil.',
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
          ),
          textAlign: TextAlign.center,
        )
            .animate()
            .fadeIn(duration: 600.ms, delay: 300.ms)
            .slideY(begin: -0.2, end: 0, duration: 600.ms, delay: 300.ms),
      ],
    );
  }

  Widget _buildLoginCard(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor.withOpacity(0.9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.dividerColor.withOpacity(0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withOpacity(0.05),
            blurRadius: 40,
            spreadRadius: 0,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildIdentifierField(theme),
                const SizedBox(height: 16),
                _buildPasswordField(theme),
                const SizedBox(height: 16),
                _buildRememberMeAndForgot(theme),
                const SizedBox(height: 24),
                _buildSubmitButton(theme),
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn(duration: 600.ms, delay: 300.ms).scale(
        begin: const Offset(0.95, 0.95), delay: 300.ms, duration: 600.ms);
  }

  Widget _buildIdentifierField(ThemeData theme) {
    return TextField(
      controller: emailController,
      decoration: InputDecoration(
        labelText: 'Email atau NIM',
        hintText: 'you@example.com atau 12345678',
        prefixIcon: Icon(
          Icons.mail_outline,
          color: theme.colorScheme.primary,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: theme.dividerColor.withOpacity(0.3),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: theme.colorScheme.primary,
            width: 2,
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordField(ThemeData theme) {
    return TextField(
      controller: passwordController,
      obscureText: !showPassword,
      decoration: InputDecoration(
        labelText: 'Password',
        prefixIcon: Icon(
          Icons.lock_outline,
          color: theme.colorScheme.primary,
        ),
        suffixIcon: IconButton(
          icon: Icon(
            showPassword ? Icons.visibility_off : Icons.visibility,
            color: theme.colorScheme.primary.withOpacity(0.6),
          ),
          onPressed: () => setState(() => showPassword = !showPassword),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: theme.dividerColor.withOpacity(0.3),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: theme.colorScheme.primary,
            width: 2,
          ),
        ),
      ),
    );
  }

  Widget _buildRememberMeAndForgot(ThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: Row(
            children: [
              SizedBox(
                width: 24,
                height: 24,
                child: Checkbox(
                  value: rememberMe,
                  onChanged: (value) =>
                      setState(() => rememberMe = value ?? false),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Ingat saya',
                style: TextStyle(
                  fontSize: 14,
                  color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
        TextButton(
          onPressed: () => Navigator.pushNamed(context, '/forgot-password'),
          child: Text(
            'Lupa password?',
            style: TextStyle(
              fontSize: 14,
              color: theme.colorScheme.primary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton(ThemeData theme) {
    return _GradientButton(
      onPressed: isLoading ? null : handleSubmit,
      text: 'Sign In',
      height: 48,
      isLoading: isLoading,
    );
  }

  Widget _buildSignUpLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Belum punya akun? ',
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
          ),
        ),
        TextButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const RegisterPage(),
              ),
            );
          },
          child: Text(
            'Daftar sekarang',
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    )
        .animate()
        .fadeIn(duration: 600.ms, delay: 400.ms)
        .slideY(begin: 0.2, end: 0, duration: 600.ms, delay: 400.ms);
  }
}
