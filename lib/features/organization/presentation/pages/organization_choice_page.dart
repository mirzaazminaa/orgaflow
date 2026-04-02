import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/utils/invite_code_utils.dart';
import '../../../onboarding/domain/models/master_option.dart';
import '../../domain/models/create_organization_input.dart';
import '../../domain/models/join_organization_input.dart';
import '../presenters/organization_presenter.dart';

class OrganizationChoicePage extends StatefulWidget {
  const OrganizationChoicePage({super.key});

  @override
  State<OrganizationChoicePage> createState() => _OrganizationChoicePageState();
}

class _HoverCard extends StatefulWidget {
  final Widget child;
  final Color color;

  const _HoverCard({required this.child, required this.color});

  @override
  State<_HoverCard> createState() => _HoverCardState();
}

class _HoverCardState extends State<_HoverCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        transform: Matrix4.identity()
          ..translate(0.0, _isHovered ? -8.0 : 0.0),
        decoration: BoxDecoration(
          color: theme.cardColor.withOpacity(0.8),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: _isHovered
                ? widget.color.withOpacity(0.5)
                : widget.color.withOpacity(0.2),
            width: _isHovered ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: widget.color.withOpacity(_isHovered ? 0.3 : 0.15),
              blurRadius: _isHovered ? 40 : 30,
              spreadRadius: _isHovered ? 2 : 0,
              offset: Offset(0, _isHovered ? 12 : 8),
            ),
          ],
        ),
        child: widget.child,
      ),
    );
  }
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

class _GradientIconButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final IconData icon;

  const _GradientIconButton({
    required this.onPressed,
    required this.icon,
  });

  @override
  State<_GradientIconButton> createState() => _GradientIconButtonState();
}

class _GradientIconButtonState extends State<_GradientIconButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    const purpleColor = Color(0xFF8B5CF6);
    const tealColor = Color(0xFF14B8A6);
    const hoverPurple = Color(0xFFA78BFA);
    const hoverTeal = Color(0xFF2DD4BF);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: _isHovered
                ? [hoverPurple, hoverTeal]
                : [purpleColor, tealColor],
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: _isHovered
              ? [
                  BoxShadow(
                    color: purpleColor.withOpacity(0.4),
                    blurRadius: 15,
                    offset: const Offset(0, 4),
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
              child: Icon(widget.icon, color: Colors.white, size: 20),
            ),
          ),
        ),
      ),
    );
  }
}

class _OrganizationChoicePageState extends State<OrganizationChoicePage>
    with TickerProviderStateMixin {
  String? mode; // null, 'create', 'join'
  final organizationNameController = TextEditingController();
  String? selectedOrgType;
  final customOrgTypeController = TextEditingController();
  final organizationCodeController = TextEditingController();
  final OrganizationPresenter _presenter = OrganizationPresenter();
  String generatedCode = '';
  bool copied = false;
  String errorMessage = '';
  bool isSubmitting = false;
  bool isLoadingOrgTypes = false;
  List<MasterOption> orgTypeOptions = [];

  late AnimationController _orb1Controller;
  late AnimationController _orb2Controller;
  late AnimationController _orb3Controller;
  late AnimationController _orb4Controller;
  late AnimationController _orb5Controller;

  @override
  void initState() {
    super.initState();
    _orb1Controller =
        AnimationController(vsync: this, duration: const Duration(seconds: 9))
          ..repeat(reverse: true);
    _orb2Controller =
        AnimationController(vsync: this, duration: const Duration(seconds: 11))
          ..repeat(reverse: true);
    _orb3Controller =
        AnimationController(vsync: this, duration: const Duration(seconds: 25))
          ..repeat();
    _orb4Controller =
        AnimationController(vsync: this, duration: const Duration(seconds: 8))
          ..repeat(reverse: true);
    _orb5Controller =
        AnimationController(vsync: this, duration: const Duration(seconds: 10))
          ..repeat(reverse: true);
    loadOrganizationTypes();
  }

  @override
  void dispose() {
    organizationNameController.dispose();
    customOrgTypeController.dispose();
    organizationCodeController.dispose();
    _orb1Controller.dispose();
    _orb2Controller.dispose();
    _orb3Controller.dispose();
    _orb4Controller.dispose();
    _orb5Controller.dispose();
    super.dispose();
  }

  List<String> get orgTypes {
    return orgTypeOptions.map((item) => item.label).toList();
  }

  Future<void> loadOrganizationTypes() async {
    setState(() {
      isLoadingOrgTypes = true;
    });

    final result = await _presenter.loadOrganizationTypes();

    if (!mounted) {
      return;
    }

    setState(() {
      isLoadingOrgTypes = false;
      if (result.isSuccess) {
        orgTypeOptions = result.data!;
      }
    });

    if (result.isFailure) {
      setState(() {
        errorMessage = result.error!.message;
      });
    }
  }

  MasterOption? get selectedOrgTypeOption {
    for (final option in orgTypeOptions) {
      if (option.label == selectedOrgType) {
        return option;
      }
    }
    return null;
  }

  Future<void> handleCreateOrganization() async {
    if (organizationNameController.text.trim().isEmpty ||
        selectedOrgType == null) {
      setState(() => errorMessage = 'Mohon lengkapi semua field');
      return;
    }

    // Jika pilih "Lainnya", validasi custom input
    if (selectedOrgType == 'Lainnya' && customOrgTypeController.text.trim().isEmpty) {
      setState(() => errorMessage = 'Mohon masukkan jenis organisasi');
      return;
    }

    final orgType = selectedOrgTypeOption;
    if (orgType == null) {
      setState(() => errorMessage = 'Jenis organisasi tidak valid');
      return;
    }

    setState(() {
      errorMessage = '';
      isSubmitting = true;
    });

    final result = await _presenter.createOrganization(
      CreateOrganizationInput(
        name: organizationNameController.text.trim(),
        typeCode: orgType.code,
      ),
    );

    if (!mounted) {
      return;
    }

    setState(() {
      isSubmitting = false;
    });

    if (result.isFailure) {
      setState(() {
        errorMessage = result.error!.message;
      });
      return;
    }

    setState(() {
      generatedCode = result.data?.inviteCode ?? '';
    });
  }

  Future<void> handleJoinOrganization() async {
    final normalizedInviteCode = InviteCodeUtils.normalize(
      organizationCodeController.text,
    );

    if (normalizedInviteCode.isEmpty) {
      setState(() => errorMessage = 'Mohon masukkan kode organisasi');
      return;
    }

    if (organizationCodeController.text != normalizedInviteCode) {
      organizationCodeController.value =
          organizationCodeController.value.copyWith(
        text: normalizedInviteCode,
        selection: TextSelection.collapsed(
          offset: normalizedInviteCode.length,
        ),
      );
    }

    if (!InviteCodeUtils.isValid(normalizedInviteCode)) {
      setState(() =>
          errorMessage = 'Format kode tidak valid. Contoh: HMTI-2026-ABC1');
      return;
    }

    setState(() {
      errorMessage = '';
      isSubmitting = true;
    });

    final result = await _presenter.joinOrganization(
      JoinOrganizationInput(
        inviteCode: normalizedInviteCode,
      ),
    );

    if (!mounted) {
      return;
    }

    setState(() {
      isSubmitting = false;
    });

    if (result.isFailure) {
      setState(() {
        errorMessage = result.error!.message;
      });
      return;
    }

    Navigator.pushReplacementNamed(context, '/onboarding');
  }

  Future<void> handleCopyCode() async {
    final inviteCode = generatedCode.trim();
    if (inviteCode.isEmpty) {
      return;
    }

    await Clipboard.setData(
      ClipboardData(text: inviteCode),
    );

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text('Kode disalin: $inviteCode'),
          duration: const Duration(seconds: 2)),
    );
    setState(() => copied = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => copied = false);
    });
  }

  void handleContinueAfterCreate() {
    Navigator.pushReplacementNamed(context, '/onboarding');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (mode == null) {
      return _buildChoiceScreen(theme);
    } else if (mode == 'create') {
      return _buildCreateScreen(theme);
    } else {
      return _buildJoinScreen(theme);
    }
  }

  Widget _buildChoiceScreen(ThemeData theme) {
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
            _buildAnimatedOrbs(theme),
            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    const SizedBox(height: 32),
                    _buildHeader(theme),
                    const SizedBox(height: 64),
                    _buildChoiceCards(theme),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    const tealColor = Color(0xFF14B8A6);
    const purpleColor = Color(0xFF8B5CF6);
    
    return Column(
      children: [
        Container(
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
          child: const Icon(Icons.business, size: 32, color: Colors.white),
        )
            .animate()
            .scale(begin: const Offset(0, 0), delay: 200.ms, duration: 600.ms),
        const SizedBox(height: 24),
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [purpleColor, tealColor],
          ).createShader(bounds),
          child: const Text(
            'Pilih "Rumah" Organisasi',
            style: TextStyle(
                fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
            textAlign: TextAlign.center,
          ),
        ).animate().fadeIn(delay: 200.ms),
        const SizedBox(height: 16),
        Text(
          'Sebelum mulai, Anda perlu punya organisasi untuk bekerja sama dengan tim',
          style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          textAlign: TextAlign.center,
        ).animate().fadeIn(delay: 300.ms),
      ],
    );
  }

  Widget _buildChoiceCards(ThemeData theme) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 800) {
          return IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: _buildCreateCard(theme)),
                const SizedBox(width: 32),
                Expanded(child: _buildJoinCard(theme)),
              ],
            ),
          );
        } else {
          return Column(
            children: [
              _buildCreateCard(theme),
              const SizedBox(height: 32),
              _buildJoinCard(theme),
            ],
          );
        }
      },
    );
  }

  Widget _buildCreateCard(ThemeData theme) {
    const purpleColor = Color(0xFF8B5CF6);
    return _HoverCard(
      color: purpleColor,
      child: Container(
        padding: const EdgeInsets.all(40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  colors: [
                    purpleColor.withOpacity(0.2),
                    purpleColor.withOpacity(0.1)
                  ],
                ),
              ),
              child: Icon(Icons.person_add,
                  size: 48, color: purpleColor),
            ),
            const SizedBox(height: 32),
            ShaderMask(
              shaderCallback: (bounds) => LinearGradient(
                colors: [
                  purpleColor,
                  purpleColor.withOpacity(0.8)
                ],
              ).createShader(bounds),
              child: const Text('Buat Organisasi Baru',
                  style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white)),
            ),
            const SizedBox(height: 16),
            Text(
                'Anda adalah Ketua atau Admin yang ingin memulai organisasi baru dari awal.',
                style: TextStyle(fontSize: 14, color: Colors.grey[600])),
            const SizedBox(height: 32),
            _buildFeatureItem(theme, 'Jadi Admin/Ketua secara otomatis',
                purpleColor),
            const SizedBox(height: 16),
            _buildFeatureItem(theme, 'Dapatkan kode organisasi unik',
                purpleColor),
            const SizedBox(height: 16),
            _buildFeatureItem(
                theme, 'Undang anggota dengan kode', purpleColor),
            const SizedBox(height: 40),
            _GradientButton(
              onPressed: () => setState(() => mode = 'create'),
              text: 'Mulai Buat Organisasi',
              height: 56,
            ),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(delay: 300.ms, duration: 600.ms)
        .slideY(begin: 0.2, end: 0);
  }

  Widget _buildJoinCard(ThemeData theme) {
    const tealColor = Color(0xFF14B8A6);
    return _HoverCard(
      color: tealColor,
      child: Container(
        padding: const EdgeInsets.all(40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  colors: [
                    tealColor.withOpacity(0.2),
                    tealColor.withOpacity(0.1)
                  ],
                ),
              ),
              child: Icon(Icons.confirmation_number,
                  size: 48, color: tealColor),
            ),
            const SizedBox(height: 32),
            ShaderMask(
              shaderCallback: (bounds) => LinearGradient(
                colors: [
                  tealColor,
                  tealColor.withOpacity(0.8)
                ],
              ).createShader(bounds),
              child: const Text('Gabung Organisasi',
                  style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white)),
            ),
            const SizedBox(height: 16),
            Text(
                'Anda adalah Anggota yang sudah mendapat kode undangan dari Ketua atau Admin.',
                style: TextStyle(fontSize: 14, color: Colors.grey[600])),
            const SizedBox(height: 32),
            _buildFeatureItem(
                theme, 'Masukkan kode organisasi', tealColor),
            const SizedBox(height: 16),
            _buildFeatureItem(
                theme, 'Bergabung sebagai Anggota', tealColor),
            const SizedBox(height: 16),
            _buildFeatureItem(
                theme, 'Langsung akses dashboard tim', tealColor),
            const SizedBox(height: 40),
            _GradientButton(
              onPressed: () => setState(() => mode = 'join'),
              text: 'Gabung dengan Kode',
              height: 56,
            ),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(delay: 400.ms, duration: 600.ms)
        .slideY(begin: 0.2, end: 0);
  }

  Widget _buildFeatureItem(ThemeData theme, String text, Color color) {
    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
                colors: [color.withOpacity(0.2), color.withOpacity(0.1)]),
          ),
          child: Icon(Icons.check_circle, size: 16, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 14))),
      ],
    );
  }

  Widget _buildCreateScreen(ThemeData theme) {
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
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Container(
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: theme.dividerColor),
                  ),
                  padding: const EdgeInsets.all(32),
                  child: generatedCode.isEmpty
                      ? _buildCreateForm(theme)
                      : _buildSuccessScreen(theme),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCreateForm(ThemeData theme) {
    return Column(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(colors: [
              theme.colorScheme.primary,
              theme.colorScheme.primary.withOpacity(0.8)
            ]),
          ),
          child: const Icon(Icons.add, size: 32, color: Colors.white),
        ),
        const SizedBox(height: 16),
        const Text('Buat Organisasi Baru',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text('Anda akan menjadi Admin/Ketua organisasi ini',
            style: TextStyle(fontSize: 14, color: Colors.grey[600])),
        const SizedBox(height: 32),
        if (isLoadingOrgTypes)
          const Padding(
            padding: EdgeInsets.only(bottom: 20),
            child: LinearProgressIndicator(),
          ),
        _buildTextField(
          controller: organizationNameController,
          label: 'Nama Organisasi',
          hint: 'Himpunan Mahasiswa Teknik Informatika',
          icon: Icons.business,
          theme: theme,
          required: true,
        ),
        const SizedBox(height: 20),
        _buildDropdown(
          label: 'Jenis Organisasi',
          value: selectedOrgType,
          items: orgTypes,
          onChanged: (value) => setState(() {
            selectedOrgType = value;
            errorMessage = '';
            if (value != 'Lainnya') {
              customOrgTypeController.clear();
            }
          }),
          icon: Icons.people,
          theme: theme,
          required: true,
        ),
        if (selectedOrgType == 'Lainnya') ...[
          const SizedBox(height: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.edit, size: 16, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  const Text('Jenis Organisasi Lainnya',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                  const Text(' *', style: TextStyle(color: Colors.red)),
                ],
              ),
              const SizedBox(height: 8),
              TextField(
                controller: customOrgTypeController,
                decoration: InputDecoration(
                  hintText: 'Masukkan jenis organisasi',
                  filled: true,
                  fillColor: theme.scaffoldBackgroundColor,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: theme.dividerColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: theme.dividerColor.withOpacity(0.3)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
                  ),
                ),
                onChanged: (_) => setState(() => errorMessage = ''),
              ),
            ],
          ),
        ],
        if (errorMessage.isNotEmpty) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red.withOpacity(0.3)),
            ),
            child: Text(errorMessage,
                style: const TextStyle(color: Colors.red, fontSize: 14)),
          ),
        ],
        const SizedBox(height: 32),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => setState(() => mode = null),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ).copyWith(
                  elevation: MaterialStateProperty.resolveWith<double>(
                    (Set<MaterialState> states) {
                      if (states.contains(MaterialState.hovered)) {
                        return 4;
                      }
                      return 0;
                    },
                  ),
                  backgroundColor: MaterialStateProperty.resolveWith<Color>(
                    (Set<MaterialState> states) {
                      if (states.contains(MaterialState.hovered)) {
                        return theme.colorScheme.primary.withOpacity(0.05);
                      }
                      return Colors.transparent;
                    },
                  ),
                ),
                child: const Text('Kembali'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _GradientButton(
                onPressed: (isSubmitting || isLoadingOrgTypes)
                    ? null
                    : handleCreateOrganization,
                text: isSubmitting ? 'Membuat...' : 'Buat Organisasi',
                height: 48,
                isLoading: isSubmitting,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSuccessScreen(ThemeData theme) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.green.withOpacity(0.3)),
          ),
          child: Column(
            children: [
              const Icon(Icons.check_circle, size: 48, color: Colors.green),
              const SizedBox(height: 12),
              const Text('Organisasi Berhasil Dibuat!',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.green)),
              const SizedBox(height: 8),
              Text(organizationNameController.text,
                  style: TextStyle(fontSize: 14, color: Colors.grey[600])),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: theme.colorScheme.primary.withOpacity(0.3), width: 2),
          ),
          child: Column(
            children: [
              const Text('Kode Organisasi Unik',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.scaffoldBackgroundColor,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: theme.colorScheme.primary, width: 2),
                      ),
                      child: Text(
                        generatedCode,
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'monospace',
                            color: theme.colorScheme.primary),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _GradientIconButton(
                    onPressed: handleCopyCode,
                    icon: copied ? Icons.check : Icons.copy,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text('Bagikan kode ini kepada anggota yang ingin bergabung',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  textAlign: TextAlign.center),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.orange.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              const Icon(Icons.key, size: 20, color: Colors.orange),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Simpan kode ini dengan aman!',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.orange)),
                    const SizedBox(height: 4),
                    Text(
                        'Kode organisasi dibutuhkan anggota untuk bergabung. Anda bisa melihatnya lagi di menu Settings.',
                        style:
                            TextStyle(fontSize: 11, color: Colors.grey[600])),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        _GradientButton(
          onPressed: handleContinueAfterCreate,
          text: 'Lanjut ke Profiling',
          height: 48,
        ),
      ],
    );
  }

  Widget _buildJoinScreen(ThemeData theme) {
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
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Container(
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: theme.dividerColor),
                  ),
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          gradient: LinearGradient(colors: [
                            theme.colorScheme.primary,
                            theme.colorScheme.primary.withOpacity(0.8)
                          ]),
                        ),
                        child: const Icon(Icons.login,
                            size: 32, color: Colors.white),
                      ),
                      const SizedBox(height: 16),
                      const Text('Gabung Organisasi',
                          style: TextStyle(
                              fontSize: 24, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text(
                          'Masukkan kode yang diberikan oleh Ketua/Admin organisasi',
                          style:
                              TextStyle(fontSize: 14, color: Colors.grey[600])),
                      const SizedBox(height: 32),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.key,
                                  size: 16, color: theme.colorScheme.primary),
                              const SizedBox(width: 8),
                              const Text('Kode Organisasi',
                                  style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500)),
                              const Text(' *',
                                  style: TextStyle(color: Colors.red)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: organizationCodeController,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                fontSize: 18,
                                fontFamily: 'monospace',
                                fontWeight: FontWeight.bold),
                            textCapitalization: TextCapitalization.characters,
                            decoration: InputDecoration(
                              hintText: 'HMTI-2026-ABC1',
                              filled: true,
                              fillColor: theme.scaffoldBackgroundColor,
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 16),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide:
                                    BorderSide(color: theme.dividerColor),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                    color: theme.dividerColor.withOpacity(0.3)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                    color: theme.colorScheme.primary, width: 2),
                              ),
                            ),
                            onChanged: (value) {
                              organizationCodeController.value =
                                  organizationCodeController.value.copyWith(
                                text: value.toUpperCase(),
                                selection: TextSelection.collapsed(
                                    offset: value.length),
                              );
                              setState(() => errorMessage = '');
                            },
                          ),
                          const SizedBox(height: 4),
                          Text('Format: XXXX-YYYY-ZZZZ (misal: HMTI-2026-ABC1)',
                              style: TextStyle(
                                  fontSize: 12, color: Colors.grey[600])),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color:
                                  theme.colorScheme.primary.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.key,
                                size: 20, color: theme.colorScheme.primary),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Belum punya kode?',
                                      style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: theme.colorScheme.primary)),
                                  const SizedBox(height: 4),
                                  Text(
                                      'Minta kode organisasi kepada Ketua/Admin yang telah membuat organisasi. Setiap organisasi punya kode unik.',
                                      style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey[600])),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (errorMessage.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border:
                                Border.all(color: Colors.red.withOpacity(0.3)),
                          ),
                          child: Text(errorMessage,
                              style: const TextStyle(
                                  color: Colors.red, fontSize: 14)),
                        ),
                      ],
                      const SizedBox(height: 32),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => setState(() => mode = null),
                              style: OutlinedButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                              ).copyWith(
                                elevation: MaterialStateProperty.resolveWith<double>(
                                  (Set<MaterialState> states) {
                                    if (states.contains(MaterialState.hovered)) {
                                      return 4;
                                    }
                                    return 0;
                                  },
                                ),
                                backgroundColor: MaterialStateProperty.resolveWith<Color>(
                                  (Set<MaterialState> states) {
                                    if (states.contains(MaterialState.hovered)) {
                                      return theme.colorScheme.primary.withOpacity(0.05);
                                    }
                                    return Colors.transparent;
                                  },
                                ),
                              ),
                              child: const Text('Kembali'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _GradientButton(
                              onPressed: isSubmitting ? null : handleJoinOrganization,
                              text: isSubmitting ? 'Memproses...' : 'Gabung Organisasi',
                              height: 48,
                              isLoading: isSubmitting,
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
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required ThemeData theme,
    bool required = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            Text(label,
                style:
                    const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
            if (required) const Text(' *', style: TextStyle(color: Colors.red)),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: theme.scaffoldBackgroundColor,
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
          onChanged: (_) => setState(() => errorMessage = ''),
        ),
        const SizedBox(height: 4),
        Text('Nama lengkap organisasi/himpunan Anda',
            style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<String> items,
    required Function(String?) onChanged,
    required IconData icon,
    required ThemeData theme,
    bool required = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            Text(label,
                style:
                    const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
            if (required) const Text(' *', style: TextStyle(color: Colors.red)),
          ],
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value,
          decoration: InputDecoration(
            filled: true,
            fillColor: theme.scaffoldBackgroundColor,
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
          hint: const Text('Pilih Jenis Organisasi'),
          items: items
              .map((item) => DropdownMenuItem(value: item, child: Text(item)))
              .toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildAnimatedOrbs(ThemeData theme) {
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
                          theme.colorScheme.secondary
                              .withOpacity(opacity * 0.3),
                          theme.colorScheme.secondary
                              .withOpacity(opacity * 0.1),
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
                          theme.colorScheme.primary.withOpacity(opacity * 0.3),
                          theme.colorScheme.primary.withOpacity(opacity * 0.1),
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
                  offset: const Offset(-325, -325),
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
                              theme.colorScheme.primary
                                  .withOpacity(opacity * 0.1),
                              theme.colorScheme.secondary
                                  .withOpacity(opacity * 0.1),
                              theme.colorScheme.primary
                                  .withOpacity(opacity * 0.1),
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
                        theme.colorScheme.primary.withOpacity(opacity * 0.2),
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
                        theme.colorScheme.secondary.withOpacity(opacity * 0.25),
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
}
