import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../domain/models/register_input.dart';
import '../presenters/register_presenter.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
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

class _RegisterPageState extends State<RegisterPage>
    with TickerProviderStateMixin {
  final fullNameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  RegisterPresenter? _presenter;

  bool showPassword = false;
  bool showConfirmPassword = false;
  bool agreeToTerms = false;
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
      duration: const Duration(seconds: 9),
    )..repeat(reverse: true);

    _orb2Controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 11),
    )..repeat(reverse: true);

    _orb3Controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 25),
    )..repeat();

    _orb4Controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);

    _orb5Controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    fullNameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    _orb1Controller.dispose();
    _orb2Controller.dispose();
    _orb3Controller.dispose();
    _orb4Controller.dispose();
    _orb5Controller.dispose();
    super.dispose();
  }

  Map<String, dynamic> getPasswordStrength() {
    final password = passwordController.text;
    if (password.isEmpty) {
      return {'strength': 0, 'label': '', 'color': Colors.grey};
    }

    final hasMinLength = password.length >= 8;
    final hasLetter = RegExp(r'[a-zA-Z]').hasMatch(password);
    final hasNumber = RegExp(r'[0-9]').hasMatch(password);
    final hasSpecial = RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password);

    if (!hasMinLength) {
      return {'strength': 1, 'label': 'Lemah', 'color': Colors.red};
    }
    if (hasLetter && hasNumber && !hasSpecial && password.length < 10) {
      return {'strength': 2, 'label': 'Sedang', 'color': Colors.orange};
    }
    if (hasLetter && hasNumber && (hasSpecial || password.length >= 10)) {
      return {'strength': 3, 'label': 'Kuat', 'color': Colors.green};
    }
    return {'strength': 1, 'label': 'Lemah', 'color': Colors.red};
  }

  bool get passwordsMatch {
    return passwordController.text.isNotEmpty &&
        confirmPasswordController.text.isNotEmpty &&
        passwordController.text == confirmPasswordController.text;
  }

  Future<void> handleSubmit() async {
    if (fullNameController.text.trim().isEmpty ||
        emailController.text.trim().isEmpty ||
        passwordController.text.trim().isEmpty ||
        confirmPasswordController.text.trim().isEmpty) {
      showMessage('Semua field wajib diisi');
      return;
    }

    if (passwordController.text.trim().length < 8 ||
        !RegExp(r'[a-zA-Z]').hasMatch(passwordController.text.trim()) ||
        !RegExp(r'[0-9]').hasMatch(passwordController.text.trim())) {
      showMessage(
        'Password harus minimal 8 karakter dengan kombinasi huruf dan angka!',
      );
      return;
    }

    if (!passwordsMatch) {
      showMessage('Password tidak cocok!');
      return;
    }

    if (!agreeToTerms) {
      showMessage('Silakan setujui syarat dan ketentuan');
      return;
    }

    setState(() => isLoading = true);

    final result = await (_presenter ??= RegisterPresenter()).register(
      RegisterInput(
        fullName: fullNameController.text.trim(),
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      ),
    );

    if (!mounted) {
      return;
    }

    setState(() => isLoading = false);

    if (result.isFailure) {
      showMessage(result.error!.message);
      return;
    }

    final registerResult = result.data!;
    showMessage(registerResult.message ?? 'Akun berhasil dibuat');

    if (registerResult.hasSession) {
      Navigator.pushReplacementNamed(context, '/organization');
    }
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
            _buildAnimatedOrbs(),
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
                        _buildRegisterCard(theme),
                        const SizedBox(height: 24),
                        _buildSignInLink(),
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
          AnimatedBuilder(
            animation: _orb1Controller,
            builder: (context, child) {
              final scale = 1.0 + (_orb1Controller.value * 0.3);
              final opacity = 0.3 + (_orb1Controller.value * 0.2);
              return Positioned(
                top: -160,
                right: -160,
                child: Transform.scale(
                  scale: scale,
                  child: Container(
                    width: 500,
                    height: 500,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          tealColor.withOpacity(opacity * 0.3),
                          tealColor.withOpacity(opacity * 0.1),
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
          AnimatedBuilder(
            animation: _orb2Controller,
            builder: (context, child) {
              final scale = 1.2 - (_orb2Controller.value * 0.2);
              final opacity = 0.4 + (_orb2Controller.value * 0.2);
              return Positioned(
                bottom: -160,
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
          AnimatedBuilder(
            animation: _orb3Controller,
            builder: (context, child) {
              final rotation = _orb3Controller.value * 2 * math.pi;
              final scale =
                  1.0 + (math.sin(_orb3Controller.value * 2 * math.pi) * 0.15);
              final opacity =
                  0.2 + (math.sin(_orb3Controller.value * 2 * math.pi) * 0.15);
              return Positioned(
                top: MediaQuery.of(context).size.height * 0.5,
                left: MediaQuery.of(context).size.width * 0.5,
                child: Transform.translate(
                  offset: Offset(-325, -325),
                  child: Transform.rotate(
                    angle: rotation,
                    child: Transform.scale(
                      scale: scale,
                      child: Container(
                        width: 650,
                        height: 650,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              purpleColor.withOpacity(opacity * 0.1),
                              tealColor.withOpacity(opacity * 0.1),
                              purpleColor.withOpacity(opacity * 0.1),
                            ],
                          ),
                        ),
                      )
                          .animate(onPlay: (controller) => controller.repeat())
                          .blur(
                              begin: const Offset(0, 0),
                              end: const Offset(80, 80),
                              duration: 1.ms),
                    ),
                  ),
                ),
              );
            },
          ),
          AnimatedBuilder(
            animation: _orb4Controller,
            builder: (context, child) {
              final offsetY =
                  math.sin(_orb4Controller.value * 2 * math.pi) * 30;
              final offsetX =
                  math.sin(_orb4Controller.value * 2 * math.pi) * 15;
              final opacity =
                  0.2 + (math.sin(_orb4Controller.value * 2 * math.pi) * 0.2);
              return Positioned(
                top: MediaQuery.of(context).size.height * 0.25 + offsetY,
                left: 80 + offsetX,
                child: Container(
                  width: 320,
                  height: 320,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        tealColor.withOpacity(opacity * 0.2),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ).animate(onPlay: (controller) => controller.repeat()).blur(
                    begin: const Offset(0, 0),
                    end: const Offset(60, 60),
                    duration: 1.ms),
              );
            },
          ),
          AnimatedBuilder(
            animation: _orb5Controller,
            builder: (context, child) {
              final offsetY =
                  -math.sin(_orb5Controller.value * 2 * math.pi) * 25;
              final offsetX =
                  -math.sin(_orb5Controller.value * 2 * math.pi) * 12;
              final opacity =
                  0.2 + (math.sin(_orb5Controller.value * 2 * math.pi) * 0.15);
              return Positioned(
                bottom: MediaQuery.of(context).size.height * 0.33 + offsetY,
                right: 80 + offsetX,
                child: Container(
                  width: 288,
                  height: 288,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        purpleColor.withOpacity(opacity * 0.2),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ).animate(onPlay: (controller) => controller.repeat()).blur(
                    begin: const Offset(0, 0),
                    end: const Offset(60, 60),
                    duration: 1.ms),
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
        GestureDetector(
          child: Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
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
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [purpleColor, tealColor],
          ).createShader(bounds),
          child: const Text(
            'Join OrgaFlow',
            style: TextStyle(
              fontSize: 28,
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
          'Create your account and start organizing',
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
          ),
          textAlign: TextAlign.center,
        )
            .animate()
            .fadeIn(duration: 600.ms, delay: 200.ms)
            .slideY(begin: -0.2, end: 0, duration: 600.ms, delay: 200.ms),
      ],
    );
  }

  Widget _buildRegisterCard(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor.withOpacity(0.9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.dividerColor.withOpacity(0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.secondary.withOpacity(0.05),
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
                _buildTextField(
                  controller: fullNameController,
                  label: 'Nama Lengkap',
                  hint: 'John Doe',
                  icon: Icons.person_outline,
                  theme: theme,
                  delay: 400,
                ),
                const SizedBox(height: 20),
                _buildTextField(
                  controller: emailController,
                  label: 'Email Institusi/Mahasiswa',
                  hint: 'nama.mahasiswa@university.ac.id',
                  icon: Icons.mail_outline,
                  theme: theme,
                  delay: 500,
                ),
                const SizedBox(height: 20),
                _buildPasswordFieldWithStrength(theme),
                const SizedBox(height: 20),
                _buildConfirmPasswordField(theme),
                const SizedBox(height: 24),
                _buildTermsCheckbox(theme),
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required ThemeData theme,
    required int delay,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: theme.textTheme.bodyLarge?.color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: theme.inputDecorationTheme.fillColor ?? theme.cardColor,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: theme.dividerColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  BorderSide(color: theme.dividerColor.withOpacity(0.3)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  BorderSide(color: theme.colorScheme.primary, width: 2),
            ),
          ),
        ),
      ],
    )
        .animate()
        .fadeIn(duration: 500.ms, delay: delay.ms)
        .slideX(begin: -0.2, end: 0, duration: 500.ms, delay: delay.ms);
  }

  Widget _buildPasswordFieldWithStrength(ThemeData theme) {
    final passwordStrength = getPasswordStrength();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.lock_outline,
                size: 16, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              'Password',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: theme.textTheme.bodyLarge?.color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: passwordController,
          obscureText: !showPassword,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            hintText: '••••••••',
            filled: true,
            fillColor: theme.inputDecorationTheme.fillColor ?? theme.cardColor,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            suffixIcon: IconButton(
              icon: Icon(
                showPassword ? Icons.visibility_off : Icons.visibility,
                color: theme.colorScheme.primary.withOpacity(0.6),
              ),
              onPressed: () => setState(() => showPassword = !showPassword),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: theme.dividerColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  BorderSide(color: theme.dividerColor.withOpacity(0.3)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  BorderSide(color: theme.colorScheme.primary, width: 2),
            ),
          ),
        ),
        if (passwordController.text.isNotEmpty) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 4,
                  decoration: BoxDecoration(
                    color: passwordStrength['strength'] >= 1
                        ? passwordStrength['color']
                        : Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Container(
                  height: 4,
                  decoration: BoxDecoration(
                    color: passwordStrength['strength'] >= 2
                        ? passwordStrength['color']
                        : Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Container(
                  height: 4,
                  decoration: BoxDecoration(
                    color: passwordStrength['strength'] >= 3
                        ? passwordStrength['color']
                        : Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Password strength: ${passwordStrength['label']}',
            style: TextStyle(
              fontSize: 12,
              color: passwordStrength['strength'] >= 2
                  ? Colors.green
                  : Colors.orange,
            ),
          ),
        ],
      ],
    )
        .animate()
        .fadeIn(duration: 500.ms, delay: 550.ms)
        .slideX(begin: -0.2, end: 0, duration: 500.ms, delay: 550.ms);
  }

  Widget _buildConfirmPasswordField(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.lock_outline,
                size: 16, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              'Confirm Password',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: theme.textTheme.bodyLarge?.color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: confirmPasswordController,
          obscureText: !showConfirmPassword,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            hintText: '••••••••',
            filled: true,
            fillColor: theme.inputDecorationTheme.fillColor ?? theme.cardColor,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            suffixIcon: IconButton(
              icon: Icon(
                showConfirmPassword ? Icons.visibility_off : Icons.visibility,
                color: theme.colorScheme.primary.withOpacity(0.6),
              ),
              onPressed: () =>
                  setState(() => showConfirmPassword = !showConfirmPassword),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: theme.dividerColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  BorderSide(color: theme.dividerColor.withOpacity(0.3)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  BorderSide(color: theme.colorScheme.primary, width: 2),
            ),
          ),
        ),
        if (confirmPasswordController.text.isNotEmpty &&
            passwordController.text.isNotEmpty) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                passwordsMatch ? Icons.check_circle : Icons.cancel,
                size: 12,
                color: passwordsMatch ? Colors.green : Colors.red,
              ),
              const SizedBox(width: 4),
              Text(
                passwordsMatch ? 'Passwords match' : 'Passwords do not match',
                style: TextStyle(
                  fontSize: 12,
                  color: passwordsMatch ? Colors.green : Colors.red,
                ),
              ),
            ],
          ),
        ],
      ],
    )
        .animate()
        .fadeIn(duration: 500.ms, delay: 600.ms)
        .slideX(begin: -0.2, end: 0, duration: 500.ms, delay: 600.ms);
  }

  Widget _buildTermsCheckbox(ThemeData theme) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 20,
          height: 20,
          child: Checkbox(
            value: agreeToTerms,
            onChanged: (value) => setState(() => agreeToTerms = value ?? false),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
            activeColor: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Wrap(
            children: [
              Text(
                'I agree to the ',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              GestureDetector(
                onTap: () {
                  // TODO: Navigate to terms
                },
                child: Text(
                  'Terms of Service',
                  style: TextStyle(
                    fontSize: 14,
                    color: theme.colorScheme.primary,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
              Text(
                ' and ',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              GestureDetector(
                onTap: () {
                  // TODO: Navigate to privacy
                },
                child: Text(
                  'Privacy Policy',
                  style: TextStyle(
                    fontSize: 14,
                    color: theme.colorScheme.primary,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    ).animate().fadeIn(duration: 500.ms, delay: 700.ms);
  }

  Widget _buildSubmitButton(ThemeData theme) {
    return _GradientButton(
      onPressed: (isLoading || !agreeToTerms) ? null : handleSubmit,
      text: 'Create Account',
      height: 48,
      isLoading: isLoading,
    )
        .animate()
        .fadeIn(duration: 500.ms, delay: 800.ms)
        .slideY(begin: 0.2, end: 0, duration: 500.ms, delay: 800.ms);
  }

  Widget _buildSignInLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Already have an account? ',
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
          ),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'Sign in',
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    ).animate().fadeIn(duration: 500.ms, delay: 900.ms);
  }
}
