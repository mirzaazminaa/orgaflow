import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/utils/message_helper.dart';
import '../../domain/models/onboarding_initial_data.dart';
import '../../domain/models/portfolio_link_input.dart';
import '../../models/skill_data.dart';
import '../presenters/onboarding_presenter.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _GradientButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final String text;
  final double height;
  final bool isLoading;
  final IconData? icon;

  const _GradientButton({
    required this.onPressed,
    required this.text,
    this.height = 56,
    this.isLoading = false,
    this.icon,
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
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.text,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        if (widget.icon != null) ...[
                          const SizedBox(width: 8),
                          Icon(widget.icon, size: 18, color: Colors.white),
                        ],
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OnboardingPageState extends State<OnboardingPage> {
  int currentStep = 0;
  final PageController _pageController = PageController();
  final OnboardingPresenter _presenter = OnboardingPresenter();

  // Step 1: Data Identitas
  File? profileImage;
  final namaLengkapController = TextEditingController();
  final nimController = TextEditingController();
  String? selectedProdi;
  String? selectedJabatan;
  String? selectedDivisi;

  // Step 2: Skill Inventory
  Map<String, Map<String, String>> selectedSkills = {};

  // Step 3: Capacity & Commitment
  double weeklyCapacity = 10;
  bool isAvailable = true;

  // Step 4: Portfolio & Bio
  List<PortfolioLink> portfolioLinks = [];
  final bioController = TextEditingController();
  OnboardingInitialData? _initialData;
  bool isLoadingInitialData = true;
  bool isSubmitting = false;
  String? loadError;

  bool get isOwnerLocked {
    final initialData = _initialData;
    return initialData != null && _presenter.isOwnerLocked(initialData);
  }

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _pageController.dispose();
    namaLengkapController.dispose();
    nimController.dispose();
    bioController.dispose();
    for (var link in portfolioLinks) {
      link.dispose();
    }
    super.dispose();
  }

  Future<void> pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => profileImage = File(pickedFile.path));
    }
  }

  Future<void> _loadInitialData() async {
    final result = await _presenter.loadInitialData();

    if (!mounted) {
      return;
    }

    if (result.isFailure) {
      setState(() {
        isLoadingInitialData = false;
        loadError = result.error!.message;
      });
      MessageHelper.showSnackBar(context, result.error!.message);
      return;
    }

    final initialData = result.data!;
    _applyInitialData(initialData);

    setState(() {
      _initialData = initialData;
      isLoadingInitialData = false;
      loadError = null;
    });
  }

  void _applyInitialData(OnboardingInitialData initialData) {
    namaLengkapController.text = initialData.profile?.fullName ?? '';
    nimController.text = initialData.profile?.nim ?? '';
    bioController.text = initialData.profile?.bio ?? '';
    selectedProdi = _presenter.labelForCode(
      initialData.masterData.studyPrograms,
      initialData.profile?.studyProgramCode,
    );
    selectedJabatan = _presenter.labelForCode(
          initialData.masterData.positions,
          initialData.member.positionCode,
        ) ??
        (initialData.member.isOwner ? 'Ketua Umum' : null);
    selectedDivisi = _presenter.labelForCode(
      initialData.masterData.divisions,
      initialData.member.divisionCode,
    );
    selectedSkills = _presenter.buildSelectedSkills(initialData);
    weeklyCapacity =
        initialData.member.weeklyCapacityHours.clamp(0, 40).toDouble();
    isAvailable = initialData.member.availabilityStatus != 'unavailable';

    for (final link in portfolioLinks) {
      link.dispose();
    }

    portfolioLinks = initialData.portfolioLinks.map((item) {
      final draft = PortfolioLink(
        platform: _presenter.labelForCode(
          initialData.masterData.portfolioPlatforms,
          item.platformCode,
        ),
      );
      draft.urlController.text = item.url;
      return draft;
    }).toList();
  }

  void nextStep() {
    if (currentStep < 3) {
      setState(() => currentStep++);
      _pageController.animateToPage(currentStep,
          duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    }
  }

  void previousStep() {
    if (currentStep > 0) {
      setState(() => currentStep--);
      _pageController.animateToPage(currentStep,
          duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    }
  }

  Future<void> handleComplete() async {
    final initialData = _initialData;
    if (initialData == null) {
      return;
    }

    setState(() {
      isSubmitting = true;
    });

    final portfolioDrafts = <PortfolioLinkInput>[];
    for (var index = 0; index < portfolioLinks.length; index++) {
      final link = portfolioLinks[index];
      final url = link.urlController.text.trim();
      final platform = link.platform?.trim();

      if ((platform == null || platform.isEmpty) && url.isEmpty) {
        continue;
      }

      portfolioDrafts.add(
        PortfolioLinkInput(
          platformCode: platform ?? '',
          url: url,
          sortOrder: index,
        ),
      );
    }

    final result = await _presenter.submit(
      initialData: initialData,
      fullName: namaLengkapController.text,
      nim: nimController.text,
      studyProgramLabel: selectedProdi,
      positionLabel: selectedJabatan,
      divisionLabel: selectedDivisi,
      weeklyCapacityHours: weeklyCapacity.toInt(),
      isAvailable: isAvailable,
      bio: bioController.text,
      portfolioLinks: portfolioDrafts,
      selectedSkills: selectedSkills,
      avatarPath: initialData.profile?.avatarPath,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      isSubmitting = false;
    });

    if (result.isFailure) {
      MessageHelper.showSnackBar(context, result.error!.message);
      return;
    }

    Navigator.pushReplacementNamed(context, '/dashboard');
  }

  bool isStepValid() {
    if (isLoadingInitialData || _initialData == null) {
      return false;
    }

    switch (currentStep) {
      case 0:
        return namaLengkapController.text.isNotEmpty &&
            nimController.text.isNotEmpty &&
            selectedProdi != null &&
            (isOwnerLocked || selectedJabatan != null) &&
            (isOwnerLocked || selectedDivisi != null);
      case 1:
        return selectedSkills.isNotEmpty;
      case 2:
        return true;
      case 3:
        return true; // Step 4 is now optional
      default:
        return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const purpleColor = Color(0xFF8B5CF6);
    const tealColor = Color(0xFF14B8A6);

    if (isLoadingInitialData) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF8B5CF6)),
        ),
      );
    }

    if (_initialData == null) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  loadError ?? 'Gagal memuat data onboarding',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.black87),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      isLoadingInitialData = true;
                      loadError = null;
                    });
                    _loadInitialData();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: purpleColor,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Coba Lagi'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          _buildStickyHeader(theme),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildStep1(theme),
                _buildStep2(theme),
                _buildStep3(theme),
                _buildStep4(theme),
              ],
            ),
          ),
          _buildFooter(theme),
        ],
      ),
    );
  }

  Widget _buildStickyHeader(ThemeData theme) {
    const purpleColor = Color(0xFF8B5CF6);
    const tealColor = Color(0xFF14B8A6);
    final progress = (currentStep + 1) / 4;
    final percentage = ((currentStep + 1) * 25).toInt();
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    gradient: const LinearGradient(
                      colors: [purpleColor, tealColor],
                    ),
                  ),
                  child: const Icon(Icons.person, size: 20, color: Colors.white),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Complete Your Profile',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      Text('Langkah 1 dari 4',
                          style: TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ),
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [purpleColor, tealColor],
                  ).createShader(bounds),
                  child: Text(
                    '$percentage%',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                height: 8,
                child: Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeInOut,
                      width: MediaQuery.of(context).size.width * progress,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [purpleColor, tealColor],
                        ),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(10),
                          bottomLeft: Radius.circular(10),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (currentStep > 0)
              TextButton(
                onPressed: previousStep,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Kembali', style: TextStyle(fontSize: 14)),
              )
            else
              const SizedBox.shrink(),
            SizedBox(
              width: currentStep == 3 ? 240 : 160,
              child: _GradientButton(
                onPressed: (isStepValid() && !isSubmitting)
                    ? (currentStep == 3 ? handleComplete : nextStep)
                    : null,
                text: currentStep == 3 && isSubmitting
                    ? 'Menyimpan...'
                    : currentStep == 3
                        ? 'Selesai & Masuk Dashboard'
                        : 'Lanjut',
                height: 48,
                isLoading: currentStep == 3 && isSubmitting,
                icon: currentStep == 3 ? Icons.check_circle : Icons.arrow_forward,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep1(ThemeData theme) {
    const purpleColor = Color(0xFF8B5CF6);
    const tealColor = Color(0xFF14B8A6);
    
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: const LinearGradient(
                      colors: [purpleColor, tealColor],
                    ),
                  ),
                  child: const Icon(Icons.person, size: 40, color: Colors.white),
                ),
              ),
              const SizedBox(height: 24),
              const Center(
                child: Text('Step 1: Data Identitas',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text('Informasi dasar tentang diri Anda',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600])),
              ),
              const SizedBox(height: 32),
              Center(
                child: GestureDetector(
                  onTap: pickImage,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: theme.colorScheme.primary.withOpacity(0.1),
                      border: Border.all(
                          color: theme.colorScheme.primary, width: 2),
                    ),
                    child: profileImage != null
                        ? ClipOval(
                            child: Image.file(profileImage!, fit: BoxFit.cover))
                        : Icon(Icons.add_a_photo,
                            size: 40, color: theme.colorScheme.primary),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                  child: Text('Upload Foto Profil',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]))),
              const SizedBox(height: 32),
              _buildTextField(
                controller: namaLengkapController,
                label: 'Nama Lengkap',
                hint: 'John Doe',
                icon: Icons.person,
                theme: theme,
                required: true,
              ),
              const SizedBox(height: 20),
              _buildTextField(
                controller: nimController,
                label: 'NIM',
                hint: '123456789',
                icon: Icons.badge,
                theme: theme,
                required: true,
              ),
              const SizedBox(height: 20),
              _buildDropdown(
                label: 'Program Studi',
                value: selectedProdi,
                items: _initialData!.masterData.studyPrograms
                    .map((item) => item.label)
                    .toList(),
                onChanged: (value) => setState(() => selectedProdi = value),
                icon: Icons.school,
                theme: theme,
                required: true,
              ),
              const SizedBox(height: 20),
              _buildDropdown(
                label: 'Jabatan',
                value: selectedJabatan,
                items: _initialData!.masterData.positions
                    .where((item) => isOwnerLocked || item.label != 'Ketua Umum')
                    .map((item) => item.label)
                    .toList(),
                onChanged: isOwnerLocked
                    ? null
                    : (value) => setState(() => selectedJabatan = value),
                icon: Icons.work,
                theme: theme,
                required: true,
                enabled: !isOwnerLocked,
              ),
              const SizedBox(height: 20),
              _buildDropdown(
                label: 'Divisi',
                value: selectedDivisi,
                items: _initialData!.masterData.divisions
                    .map((item) => item.label)
                    .toList(),
                onChanged: isOwnerLocked
                    ? null
                    : (value) => setState(() => selectedDivisi = value),
                icon: Icons.group,
                theme: theme,
                required: true,
                enabled: !isOwnerLocked,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep2(ThemeData theme) {
    const purpleColor = Color(0xFF8B5CF6);
    const tealColor = Color(0xFF14B8A6);
    
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: const LinearGradient(
                      colors: [purpleColor, tealColor],
                    ),
                  ),
                  child: const Icon(Icons.bolt, size: 40, color: Colors.white),
                ),
              ),
              const SizedBox(height: 24),
              const Center(
                child: Text('Step 2: Skill Inventory',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                    'Pilih skill yang Anda kuasai dan tentukan tingkat kemahiran',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600])),
              ),
              const SizedBox(height: 32),
              ..._initialData!.masterData.skillCategories.map((category) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.category,
                            size: 18, color: theme.colorScheme.primary),
                        const SizedBox(width: 8),
                        Text(category.label,
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: theme.colorScheme.primary)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final skills = category.skills;
                        return Column(
                          children: [
                            for (int i = 0; i < skills.length; i += 2)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: _buildSkillItem(
                                        theme,
                                        category.label,
                                        skills[i].name,
                                      ),
                                    ),
                                    if (i + 1 < skills.length) ...[
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: _buildSkillItem(
                                          theme,
                                          category.label,
                                          skills[i + 1].name,
                                        ),
                                      ),
                                    ] else
                                      const Expanded(child: SizedBox()),
                                  ],
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                  ],
                );
              }),
              if (selectedSkills.isNotEmpty) ...[
                const Divider(height: 32),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Skills Terpilih (${selectedSkills.values.fold(0, (sum, skills) => sum + skills.length)}):',
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children:
                            selectedSkills.entries.expand((categoryEntry) {
                          return categoryEntry.value.entries.map((skillEntry) {
                            Color proficiencyColor;
                            String proficiencyLabel;
                            switch (skillEntry.value) {
                              case 'beginner':
                                proficiencyColor = Colors.orange;
                                proficiencyLabel = 'Beginner';
                                break;
                              case 'intermediate':
                                proficiencyColor = Colors.teal;
                                proficiencyLabel = 'Intermediate';
                                break;
                              case 'expert':
                                proficiencyColor = Colors.green;
                                proficiencyLabel = 'Expert';
                                break;
                              default:
                                proficiencyColor = Colors.grey;
                                proficiencyLabel = 'Unknown';
                            }
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: proficiencyColor,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                '${skillEntry.key} • $proficiencyLabel',
                                style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white),
                              ),
                            );
                          });
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSkillItem(ThemeData theme, String categoryKey, String skill) {
    final isSelected = selectedSkills[categoryKey]?.containsKey(skill) ?? false;
    final proficiency = selectedSkills[categoryKey]?[skill] ?? 'beginner';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () {
            setState(() {
              if (!selectedSkills.containsKey(categoryKey)) {
                selectedSkills[categoryKey] = {};
              }
              if (isSelected) {
                selectedSkills[categoryKey]!.remove(skill);
                if (selectedSkills[categoryKey]!.isEmpty) {
                  selectedSkills.remove(categoryKey);
                }
              } else {
                selectedSkills[categoryKey]![skill] = 'beginner';
              }
            });
          },
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color:
                    isSelected ? theme.colorScheme.primary : Colors.grey[300]!,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    skill,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.black87,
                      fontWeight:
                          isSelected ? FontWeight.w500 : FontWeight.normal,
                    ),
                  ),
                ),
                if (isSelected)
                  Icon(Icons.check_circle,
                      size: 16, color: theme.colorScheme.primary),
              ],
            ),
          ),
        ),
        if (isSelected) ...[
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                  child: _buildProficiencyButton(theme, categoryKey, skill,
                      proficiency, 'beginner', 'Beginner')),
              const SizedBox(width: 4),
              Expanded(
                  child: _buildProficiencyButton(theme, categoryKey, skill,
                      proficiency, 'intermediate', 'Intermediate')),
              const SizedBox(width: 4),
              Expanded(
                  child: _buildProficiencyButton(theme, categoryKey, skill,
                      proficiency, 'expert', 'Expert')),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildProficiencyButton(ThemeData theme, String categoryKey,
      String skillName, String currentProficiency, String value, String label) {
    final isSelected = currentProficiency == value;
    Color buttonColor;
    Color lightColor;
    switch (value) {
      case 'beginner':
        buttonColor = Colors.orange;
        lightColor = Colors.orange.withOpacity(0.2);
        break;
      case 'intermediate':
        buttonColor = Colors.teal;
        lightColor = Colors.teal.withOpacity(0.2);
        break;
      case 'expert':
        buttonColor = Colors.green;
        lightColor = Colors.green.withOpacity(0.2);
        break;
      default:
        buttonColor = Colors.grey;
        lightColor = Colors.grey.withOpacity(0.2);
    }

    return InkWell(
      onTap: () {
        setState(() {
          if (selectedSkills[categoryKey]?.containsKey(skillName) ?? false) {
            selectedSkills[categoryKey]![skillName] = value;
          }
        });
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected ? buttonColor : lightColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : buttonColor,
          ),
        ),
      ),
    );
  }

  Widget _buildStep3(ThemeData theme) {
    const purpleColor = Color(0xFF8B5CF6);
    const tealColor = Color(0xFF14B8A6);
    
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: const LinearGradient(
                      colors: [purpleColor, tealColor],
                    ),
                  ),
                  child: const Icon(Icons.schedule, size: 40, color: Colors.white),
                ),
              ),
              const SizedBox(height: 24),
              const Center(
                child: Text('Step 3: Capacity & Commitment',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text('Berapa banyak waktu yang bisa Anda dedikasikan?',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600])),
              ),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.access_time, size: 18, color: Colors.grey),
                        const SizedBox(width: 8),
                        const Text('Weekly Capacity (Jam/Minggu)',
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500)),
                        const Text(' *', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Center(
                      child: ShaderMask(
                        shaderCallback: (bounds) => const LinearGradient(
                          colors: [purpleColor, tealColor],
                        ).createShader(bounds),
                        child: Text(
                          '${weeklyCapacity.toInt()}',
                          style: const TextStyle(
                            fontSize: 64,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    Center(
                      child: Text(
                        'jam / minggu',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                    ),
                    const SizedBox(height: 32),
                    Column(
                      children: [
                        // Slider
                        SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            activeTrackColor: Colors.transparent,
                            inactiveTrackColor: Colors.transparent,
                            thumbColor: purpleColor,
                            overlayColor: purpleColor.withOpacity(0.1),
                            trackHeight: 4,
                            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
                          ),
                          child: Slider(
                            value: weeklyCapacity,
                            min: 0,
                            max: 40,
                            divisions: 8,
                            onChanged: (value) =>
                                setState(() => weeklyCapacity = value),
                          ),
                        ),
                        const SizedBox(height: 4),
                        // Tick marks (vertical lines) and numbers
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  for (int i = 0; i <= 8; i++)
                                    Container(
                                      width: 2,
                                      height: 12,
                                      color: Colors.grey[400],
                                    ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  for (int i = 0; i <= 8; i++)
                                    SizedBox(
                                      width: 20,
                                      child: Text(
                                        '${i * 5}',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: weeklyCapacity.toInt() == i * 5
                                              ? purpleColor
                                              : Colors.grey[500],
                                          fontWeight: weeklyCapacity.toInt() == i * 5
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Ringan',
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey[600])),
                        Text('Full-time',
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey[600])),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: Text(
                        'Berapa jam kamu sanggup bekerja untuk organisasi di tengah kesibukan kuliah',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Status Ketersediaan',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 4),
                          Text(
                              isAvailable
                                  ? 'Tersedia untuk tugas baru'
                                  : 'Sedang tidak tersedia',
                              style: TextStyle(
                                  fontSize: 14, color: Colors.grey[600])),
                        ],
                      ),
                    ),
                    Switch(
                      value: isAvailable,
                      onChanged: (value) => setState(() => isAvailable = value),
                      activeColor: theme.colorScheme.primary,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep4(ThemeData theme) {
    const purpleColor = Color(0xFF8B5CF6);
    const tealColor = Color(0xFF14B8A6);
    
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: const LinearGradient(
                      colors: [purpleColor, tealColor],
                    ),
                  ),
                  child: const Icon(Icons.work, size: 40, color: Colors.white),
                ),
              ),
              const SizedBox(height: 24),
              const Center(
                child: Text('Portfolio & Social Link',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text('Proof of Work - Link ke karya dan profile kamu',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600])),
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Link Tautan (opsional)',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        portfolioLinks.add(PortfolioLink());
                      });
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Tambah Link'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (portfolioLinks.isEmpty)
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Center(
                    child: Text(
                        'Belum ada link portfolio. Klik "Tambah Link" untuk menambahkan.',
                        style: TextStyle(color: Colors.grey[600]),
                        textAlign: TextAlign.center),
                  ),
                ),
              ...portfolioLinks.asMap().entries.map((entry) {
                final index = entry.key;
                final link = entry.value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      if (constraints.maxWidth < 600) {
                        return Column(
                          children: [
                            DropdownButtonFormField<String>(
                              value: link.platform,
                              decoration: InputDecoration(
                                hintText: 'Platform',
                                filled: true,
                                fillColor: Colors.white,
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 12),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Colors.grey[300]!),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Colors.grey[300]!),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: Color(0xFF8B5CF6), width: 2),
                                ),
                              ),
                              items: _initialData!.masterData.portfolioPlatforms
                                  .map((platform) {
                                return DropdownMenuItem(
                                    value: platform.label,
                                    child: Text(platform.label));
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  link.platform = value;
                                });
                              },
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: link.urlController,
                                    decoration: InputDecoration(
                                      hintText: 'https://...',
                                      filled: true,
                                      fillColor: Colors.white,
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                              horizontal: 16, vertical: 12),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(color: Colors.grey[300]!),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(color: Colors.grey[300]!),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: const BorderSide(color: Color(0xFF8B5CF6), width: 2),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  onPressed: () {
                                    setState(() {
                                      link.dispose();
                                      portfolioLinks.removeAt(index);
                                    });
                                  },
                                  icon: const Icon(Icons.delete,
                                      color: Colors.red),
                                ),
                              ],
                            ),
                          ],
                        );
                      }
                      return Row(
                        children: [
                          Expanded(
                            flex: 1,
                            child: DropdownButtonFormField<String>(
                              value: link.platform,
                              decoration: InputDecoration(
                                hintText: 'Platform',
                                filled: true,
                                fillColor: Colors.white,
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 12),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Colors.grey[300]!),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Colors.grey[300]!),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: Color(0xFF8B5CF6), width: 2),
                                ),
                              ),
                              items: _initialData!.masterData.portfolioPlatforms
                                  .map((platform) {
                                return DropdownMenuItem(
                                    value: platform.label,
                                    child: Text(platform.label));
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  link.platform = value;
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 2,
                            child: TextField(
                              controller: link.urlController,
                              decoration: InputDecoration(
                                hintText: 'https://...',
                                filled: true,
                                fillColor: Colors.white,
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 12),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Colors.grey[300]!),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Colors.grey[300]!),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: Color(0xFF8B5CF6), width: 2),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            onPressed: () {
                              setState(() {
                                link.dispose();
                                portfolioLinks.removeAt(index);
                              });
                            },
                            icon: const Icon(Icons.delete, color: Colors.red),
                          ),
                        ],
                      );
                    },
                  ),
                );
              }),
              const SizedBox(height: 24),
              Row(
                children: [
                  const Text('Bio Singkat (opsional)',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ],
              ),
              const SizedBox(height: 4),
              const Text('Ceritakan tentang diri Anda',
                  style: TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 8),
              TextField(
                controller: bioController,
                maxLines: 5,
                decoration: InputDecoration(
                  hintText:
                      'Saya adalah mahasiswa yang passionate di bidang...',
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.all(16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF8B5CF6), width: 2),
                  ),
                ),
                onChanged: (value) => setState(() {}),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: theme.colorScheme.primary.withOpacity(0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.summarize, color: theme.colorScheme.primary),
                        const SizedBox(width: 12),
                        const Text('Ringkasan Profil',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w600)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildSummaryItem(
                        'Nama',
                        namaLengkapController.text.isEmpty
                            ? '-'
                            : namaLengkapController.text),
                    _buildSummaryItem('NIM',
                        nimController.text.isEmpty ? '-' : nimController.text),
                    _buildSummaryItem('Prodi', selectedProdi ?? '-'),
                    _buildSummaryItem('Jabatan', selectedJabatan ?? '-'),
                    _buildSummaryItem('Divisi', selectedDivisi ?? '-'),
                    _buildSummaryItem(
                        'Total Skill',
                        selectedSkills.values
                            .fold(0, (sum, skills) => sum + skills.length)
                            .toString()),
                    _buildSummaryItem(
                        'Kapasitas', '${weeklyCapacity.toInt()} jam/minggu'),
                    _buildSummaryItem(
                        'Status', isAvailable ? 'Tersedia' : 'Tidak Tersedia'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
              flex: 2,
              child: Text(label,
                  style: const TextStyle(fontSize: 14, color: Colors.grey))),
          Expanded(
              flex: 3,
              child: Text(value,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w500))),
        ],
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
            Icon(icon, size: 16, color: Colors.grey[700]),
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
            fillColor: Colors.white,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: Color(0xFF8B5CF6), width: 2),
            ),
          ),
          onChanged: (value) => setState(() {}),
        ),
      ],
    );
  }

  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<String> items,
    ValueChanged<String?>? onChanged,
    required IconData icon,
    required ThemeData theme,
    bool required = false,
    bool enabled = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: Colors.grey[700]),
            const SizedBox(width: 8),
            Text(label,
                style:
                    const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
            if (required) const Text(' *', style: TextStyle(color: Colors.red)),
          ],
        ),
        const SizedBox(height: 8),
        IgnorePointer(
          ignoring: !enabled,
          child: DropdownButtonFormField<String>(
            value: value,
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: Color(0xFF8B5CF6), width: 2),
              ),
            ),
            items: items.map((item) {
              return DropdownMenuItem(value: item, child: Text(item));
            }).toList(),
            onChanged: onChanged ?? (_) {},
          ),
        ),
      ],
    );
  }
}
