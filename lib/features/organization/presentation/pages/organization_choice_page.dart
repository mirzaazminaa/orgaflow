import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class OrganizationChoicePage extends StatefulWidget {
  const OrganizationChoicePage({super.key});

  @override
  State<OrganizationChoicePage> createState() => _OrganizationChoicePageState();
}

class _OrganizationChoicePageState extends State<OrganizationChoicePage> with TickerProviderStateMixin {
  String? mode; // null, 'create', 'join'
  final organizationNameController = TextEditingController();
  String? selectedOrgType;
  final organizationCodeController = TextEditingController();
  String generatedCode = '';
  bool copied = false;
  String errorMessage = '';

  late AnimationController _orb1Controller;
  late AnimationController _orb2Controller;
  late AnimationController _orb3Controller;
  late AnimationController _orb4Controller;
  late AnimationController _orb5Controller;

  final List<String> orgTypes = [
    'Himpunan Mahasiswa',
    'Unit Kegiatan Mahasiswa',
    'Badan Eksekutif Mahasiswa',
    'Senat Mahasiswa',
    'Komunitas',
    'Lainnya',
  ];

  @override
  void initState() {
    super.initState();
    _orb1Controller = AnimationController(vsync: this, duration: const Duration(seconds: 9))..repeat(reverse: true);
    _orb2Controller = AnimationController(vsync: this, duration: const Duration(seconds: 11))..repeat(reverse: true);
    _orb3Controller = AnimationController(vsync: this, duration: const Duration(seconds: 25))..repeat();
    _orb4Controller = AnimationController(vsync: this, duration: const Duration(seconds: 8))..repeat(reverse: true);
    _orb5Controller = AnimationController(vsync: this, duration: const Duration(seconds: 10))..repeat(reverse: true);
  }

  @override
  void dispose() {
    organizationNameController.dispose();
    organizationCodeController.dispose();
    _orb1Controller.dispose();
    _orb2Controller.dispose();
    _orb3Controller.dispose();
    _orb4Controller.dispose();
    _orb5Controller.dispose();
    super.dispose();
  }

  String generateOrgCode(String orgName) {
    final prefix = orgName.split(' ').map((word) => word.isNotEmpty ? word[0] : '').join('').toUpperCase();
    final prefixTrimmed = prefix.length > 4 ? prefix.substring(0, 4) : prefix;
    final random = (math.Random().nextDouble() * 10000).toInt().toString().padLeft(4, '0');
    final year = DateTime.now().year;
    return '$prefixTrimmed-$year-$random';
  }

  void handleCreateOrganization() {
    if (organizationNameController.text.trim().isEmpty || selectedOrgType == null) {
      setState(() => errorMessage = 'Mohon lengkapi semua field');
      return;
    }
    final code = generateOrgCode(organizationNameController.text);
    setState(() {
      generatedCode = code;
      errorMessage = '';
    });
  }

  void handleJoinOrganization() {
    if (organizationCodeController.text.trim().isEmpty) {
      setState(() => errorMessage = 'Mohon masukkan kode organisasi');
      return;
    }
    final codePattern = RegExp(r'^[A-Z0-9]+-\d{4}-[A-Z0-9]+$');
    if (!codePattern.hasMatch(organizationCodeController.text.toUpperCase())) {
      setState(() => errorMessage = 'Format kode tidak valid. Contoh: HMTI-2026-ABC1');
      return;
    }
    Navigator.pushReplacementNamed(context, '/onboarding');
  }

  void handleCopyCode() {
    // In Flutter, we'll show a snackbar instead
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Kode disalin: $generatedCode'), duration: const Duration(seconds: 2)),
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
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.colorScheme.primary.withOpacity(0.2),
              theme.scaffoldBackgroundColor,
              theme.colorScheme.secondary.withOpacity(0.2),
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
                    _buildBackButton(theme),
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

  Widget _buildBackButton(ThemeData theme) {
    return Align(
      alignment: Alignment.centerLeft,
      child: ElevatedButton.icon(
        onPressed: () => Navigator.pop(context),
        icon: const Icon(Icons.arrow_back, size: 16),
        label: const Text('Kembali', style: TextStyle(fontWeight: FontWeight.w500)),
        style: ElevatedButton.styleFrom(
          backgroundColor: theme.cardColor.withOpacity(0.6),
          foregroundColor: theme.textTheme.bodyLarge?.color,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ).animate().fadeIn(duration: 600.ms, delay: 100.ms).slideX(begin: -0.2, end: 0),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Column(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [theme.colorScheme.primary, theme.colorScheme.secondary],
            ),
          ),
          child: const Icon(Icons.business, size: 32, color: Colors.white),
        ).animate().scale(begin: const Offset(0, 0), delay: 200.ms, duration: 600.ms),
        const SizedBox(height: 24),
        ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            colors: [theme.colorScheme.primary, theme.colorScheme.secondary],
          ).createShader(bounds),
          child: const Text(
            'Pilih "Rumah" Organisasi',
            style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
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
    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor.withOpacity(0.8),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.colorScheme.primary.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withOpacity(0.15),
            blurRadius: 30,
            spreadRadius: 0,
            offset: const Offset(0, 8),
          ),
        ],
      ),
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
                colors: [theme.colorScheme.primary.withOpacity(0.2), theme.colorScheme.secondary.withOpacity(0.1)],
              ),
            ),
            child: Icon(Icons.person_add, size: 48, color: theme.colorScheme.primary),
          ),
          const SizedBox(height: 32),
          ShaderMask(
            shaderCallback: (bounds) => LinearGradient(
              colors: [theme.colorScheme.primary, theme.colorScheme.primary.withOpacity(0.8)],
            ).createShader(bounds),
            child: const Text('Buat Organisasi Baru', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
          ),
          const SizedBox(height: 16),
          Text('Anda adalah Ketua atau Admin yang ingin memulai organisasi baru dari awal.', style: TextStyle(fontSize: 14, color: Colors.grey[600])),
          const SizedBox(height: 32),
          _buildFeatureItem(theme, 'Jadi Admin/Ketua secara otomatis', theme.colorScheme.primary),
          const SizedBox(height: 16),
          _buildFeatureItem(theme, 'Dapatkan kode organisasi unik', theme.colorScheme.primary),
          const SizedBox(height: 16),
          _buildFeatureItem(theme, 'Undang anggota dengan kode', theme.colorScheme.primary),
          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: () => setState(() => mode = 'create'),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Mulai Buat Organisasi', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 300.ms, duration: 600.ms).slideY(begin: 0.2, end: 0);
  }

  Widget _buildJoinCard(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor.withOpacity(0.8),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.colorScheme.primary.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withOpacity(0.15),
            blurRadius: 30,
            spreadRadius: 0,
            offset: const Offset(0, 8),
          ),
        ],
      ),
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
                colors: [theme.colorScheme.primary.withOpacity(0.2), theme.colorScheme.secondary.withOpacity(0.1)],
              ),
            ),
            child: Icon(Icons.confirmation_number, size: 48, color: theme.colorScheme.primary),
          ),
          const SizedBox(height: 32),
          ShaderMask(
            shaderCallback: (bounds) => LinearGradient(
              colors: [theme.colorScheme.primary, theme.colorScheme.primary.withOpacity(0.8)],
            ).createShader(bounds),
            child: const Text('Gabung Organisasi', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
          ),
          const SizedBox(height: 16),
          Text('Anda adalah Anggota yang sudah mendapat kode undangan dari Ketua atau Admin.', style: TextStyle(fontSize: 14, color: Colors.grey[600])),
          const SizedBox(height: 32),
          _buildFeatureItem(theme, 'Masukkan kode organisasi', theme.colorScheme.primary),
          const SizedBox(height: 16),
          _buildFeatureItem(theme, 'Bergabung sebagai Anggota', theme.colorScheme.primary),
          const SizedBox(height: 16),
          _buildFeatureItem(theme, 'Langsung akses dashboard tim', theme.colorScheme.primary),
          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: () => setState(() => mode = 'join'),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Gabung dengan Kode', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 400.ms, duration: 600.ms).slideY(begin: 0.2, end: 0);
  }

  Widget _buildFeatureItem(ThemeData theme, String text, Color color) {
    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(colors: [color.withOpacity(0.2), color.withOpacity(0.1)]),
          ),
          child: Icon(Icons.check_circle, size: 16, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 14))),
      ],
    );
  }

  Widget _buildCreateScreen(ThemeData theme) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.colorScheme.primary.withOpacity(0.05),
              theme.scaffoldBackgroundColor,
              theme.colorScheme.secondary.withOpacity(0.05),
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
                  child: generatedCode.isEmpty ? _buildCreateForm(theme) : _buildSuccessScreen(theme),
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
            gradient: LinearGradient(colors: [theme.colorScheme.primary, theme.colorScheme.primary.withOpacity(0.8)]),
          ),
          child: const Icon(Icons.add, size: 32, color: Colors.white),
        ),
        const SizedBox(height: 16),
        const Text('Buat Organisasi Baru', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text('Anda akan menjadi Admin/Ketua organisasi ini', style: TextStyle(fontSize: 14, color: Colors.grey[600])),
        const SizedBox(height: 32),
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
          }),
          icon: Icons.people,
          theme: theme,
          required: true,
        ),
        if (errorMessage.isNotEmpty) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red.withOpacity(0.3)),
            ),
            child: Text(errorMessage, style: const TextStyle(color: Colors.red, fontSize: 14)),
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
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Kembali'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: handleCreateOrganization,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Buat Organisasi'),
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
              const Text('Organisasi Berhasil Dibuat!', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.green)),
              const SizedBox(height: 8),
              Text(organizationNameController.text, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: theme.colorScheme.primary.withOpacity(0.3), width: 2),
          ),
          child: Column(
            children: [
              const Text('Kode Organisasi Unik', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.scaffoldBackgroundColor,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: theme.colorScheme.primary, width: 2),
                      ),
                      child: Text(
                        generatedCode,
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'monospace', color: theme.colorScheme.primary),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: handleCopyCode,
                    icon: Icon(copied ? Icons.check : Icons.copy, color: Colors.white),
                    style: IconButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.all(12),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text('Bagikan kode ini kepada anggota yang ingin bergabung', style: TextStyle(fontSize: 12, color: Colors.grey[600]), textAlign: TextAlign.center),
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
                    const Text('Simpan kode ini dengan aman!', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.orange)),
                    const SizedBox(height: 4),
                    Text('Kode organisasi dibutuhkan anggota untuk bergabung. Anda bisa melihatnya lagi di menu Settings.', style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton.icon(
            onPressed: handleContinueAfterCreate,
            icon: const Icon(Icons.arrow_forward),
            label: const Text('Lanjut ke Profiling'),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildJoinScreen(ThemeData theme) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.colorScheme.primary.withOpacity(0.05),
              theme.scaffoldBackgroundColor,
              theme.colorScheme.secondary.withOpacity(0.05),
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
                          gradient: LinearGradient(colors: [theme.colorScheme.primary, theme.colorScheme.primary.withOpacity(0.8)]),
                        ),
                        child: const Icon(Icons.login, size: 32, color: Colors.white),
                      ),
                      const SizedBox(height: 16),
                      const Text('Gabung Organisasi', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text('Masukkan kode yang diberikan oleh Ketua/Admin organisasi', style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                      const SizedBox(height: 32),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.key, size: 16, color: theme.colorScheme.primary),
                              const SizedBox(width: 8),
                              const Text('Kode Organisasi', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                              const Text(' *', style: TextStyle(color: Colors.red)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: organizationCodeController,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 18, fontFamily: 'monospace', fontWeight: FontWeight.bold),
                            textCapitalization: TextCapitalization.characters,
                            decoration: InputDecoration(
                              hintText: 'HMTI-2026-ABC1',
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
                            onChanged: (value) {
                              organizationCodeController.value = organizationCodeController.value.copyWith(
                                text: value.toUpperCase(),
                                selection: TextSelection.collapsed(offset: value.length),
                              );
                              setState(() => errorMessage = '');
                            },
                          ),
                          const SizedBox(height: 4),
                          Text('Format: XXXX-YYYY-ZZZZ (misal: HMTI-2026-ABC1)', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: theme.colorScheme.primary.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.key, size: 20, color: theme.colorScheme.primary),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Belum punya kode?', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: theme.colorScheme.primary)),
                                  const SizedBox(height: 4),
                                  Text('Minta kode organisasi kepada Ketua/Admin yang telah membuat organisasi. Setiap organisasi punya kode unik.', style: TextStyle(fontSize: 11, color: Colors.grey[600])),
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
                            border: Border.all(color: Colors.red.withOpacity(0.3)),
                          ),
                          child: Text(errorMessage, style: const TextStyle(color: Colors.red, fontSize: 14)),
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
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: const Text('Kembali'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: handleJoinOrganization,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: theme.colorScheme.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: const Text('Gabung Organisasi'),
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
            Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
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
        const SizedBox(height: 4),
        Text('Nama lengkap organisasi/himpunan Anda', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
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
            Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
            if (required) const Text(' *', style: TextStyle(color: Colors.red)),
          ],
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value,
          decoration: InputDecoration(
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
          hint: const Text('Pilih Jenis Organisasi'),
          items: items.map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(),
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
                          theme.colorScheme.secondary.withOpacity(opacity * 0.3),
                          theme.colorScheme.secondary.withOpacity(opacity * 0.1),
                        ],
                      ),
                    ),
                  ).animate(onPlay: (controller) => controller.repeat()).blur(begin: const Offset(0, 0), end: const Offset(80, 80), duration: 1.ms),
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
                  ).animate(onPlay: (controller) => controller.repeat()).blur(begin: const Offset(0, 0), end: const Offset(80, 80), duration: 1.ms),
                ),
              );
            },
          ),
          AnimatedBuilder(
            animation: _orb3Controller,
            builder: (context, child) {
              final rotation = _orb3Controller.value * 2 * math.pi;
              final scale = 1.0 + (math.sin(_orb3Controller.value * 2 * math.pi) * 0.15);
              final opacity = 0.2 + (math.sin(_orb3Controller.value * 2 * math.pi) * 0.15);
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
                              theme.colorScheme.primary.withOpacity(opacity * 0.1),
                              theme.colorScheme.secondary.withOpacity(opacity * 0.1),
                              theme.colorScheme.primary.withOpacity(opacity * 0.1),
                            ],
                          ),
                        ),
                      ).animate(onPlay: (controller) => controller.repeat()).blur(begin: const Offset(0, 0), end: const Offset(80, 80), duration: 1.ms),
                    ),
                  ),
                ),
              );
            },
          ),
          AnimatedBuilder(
            animation: _orb4Controller,
            builder: (context, child) {
              final offsetY = math.sin(_orb4Controller.value * 2 * math.pi) * 30;
              final offsetX = math.sin(_orb4Controller.value * 2 * math.pi) * 15;
              final opacity = 0.2 + (math.sin(_orb4Controller.value * 2 * math.pi) * 0.2);
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
                ).animate(onPlay: (controller) => controller.repeat()).blur(begin: const Offset(0, 0), end: const Offset(60, 60), duration: 1.ms),
              );
            },
          ),
          AnimatedBuilder(
            animation: _orb5Controller,
            builder: (context, child) {
              final offsetY = -math.sin(_orb5Controller.value * 2 * math.pi) * 25;
              final offsetX = -math.sin(_orb5Controller.value * 2 * math.pi) * 12;
              final opacity = 0.2 + (math.sin(_orb5Controller.value * 2 * math.pi) * 0.15);
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
                ).animate(onPlay: (controller) => controller.repeat()).blur(begin: const Offset(0, 0), end: const Offset(60, 60), duration: 1.ms),
              );
            },
          ),
        ],
      ),
    );
  }
}
