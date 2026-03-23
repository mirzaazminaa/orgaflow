import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/skill_data.dart';
import '../../data/onboarding_data.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  int currentStep = 0;
  final PageController _pageController = PageController();

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
  void nextStep() {
    if (currentStep < 3) {
      setState(() => currentStep++);
      _pageController.animateToPage(currentStep, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    }
  }

  void previousStep() {
    if (currentStep > 0) {
      setState(() => currentStep--);
      _pageController.animateToPage(currentStep, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    }
  }

  void handleComplete() {
    Navigator.pushReplacementNamed(context, '/dashboard');
  }

  bool isStepValid() {
    switch (currentStep) {
      case 0:
        return namaLengkapController.text.isNotEmpty && nimController.text.isNotEmpty && selectedProdi != null && selectedJabatan != null && selectedDivisi != null;
      case 1:
        return selectedSkills.isNotEmpty;
      case 2:
        return true;
      case 3:
        return bioController.text.isNotEmpty;
      default:
        return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
        child: Column(
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
      ),
    );
  }

  Widget _buildStickyHeader(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2))],
      ),
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
                    gradient: LinearGradient(colors: [theme.colorScheme.primary, theme.colorScheme.secondary]),
                  ),
                  child: const Icon(Icons.person, size: 20, color: Colors.white),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Profiling Anggota', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      Text('Lengkapi data diri Anda', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ),
                Text('${currentStep + 1}/4', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: theme.colorScheme.primary)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: List.generate(4, (index) {
                final isActive = index == currentStep;
                final isCompleted = index < currentStep;
                return Expanded(
                  child: Container(
                    height: 4,
                    margin: EdgeInsets.only(right: index < 3 ? 8 : 0),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(2),
                      color: isCompleted || isActive ? theme.colorScheme.primary : Colors.grey[300],
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -2))],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            if (currentStep > 0)
              Expanded(
                child: OutlinedButton(
                  onPressed: previousStep,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Kembali'),
                ),
              ),
            if (currentStep > 0) const SizedBox(width: 12),
            Expanded(
              flex: currentStep == 0 ? 1 : 1,
              child: ElevatedButton(
                onPressed: isStepValid() ? (currentStep == 3 ? handleComplete : nextStep) : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  disabledBackgroundColor: Colors.grey[300],
                ),
                child: Text(currentStep == 3 ? 'Selesai' : 'Lanjut'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep1(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Step 1: Data Identitas', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('Informasi dasar tentang diri Anda', style: TextStyle(fontSize: 14, color: Colors.grey[600])),
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
                      border: Border.all(color: theme.colorScheme.primary, width: 2),
                    ),
                    child: profileImage != null
                        ? ClipOval(child: Image.file(profileImage!, fit: BoxFit.cover))
                        : Icon(Icons.add_a_photo, size: 40, color: theme.colorScheme.primary),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Center(child: Text('Upload Foto Profil', style: TextStyle(fontSize: 12, color: Colors.grey[600]))),
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
                items: OnboardingData.prodiList,
                onChanged: (value) => setState(() => selectedProdi = value),
                icon: Icons.school,
                theme: theme,
                required: true,
              ),
              const SizedBox(height: 20),
              _buildDropdown(
                label: 'Jabatan',
                value: selectedJabatan,
                items: OnboardingData.jabatanList,
                onChanged: (value) => setState(() => selectedJabatan = value),
                icon: Icons.work,
                theme: theme,
                required: true,
              ),
              const SizedBox(height: 20),
              _buildDropdown(
                label: 'Divisi',
                value: selectedDivisi,
                items: OnboardingData.divisiList,
                onChanged: (value) => setState(() => selectedDivisi = value),
                icon: Icons.group,
                theme: theme,
                required: true,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep2(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Step 2: Skill Inventory', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('Pilih skill yang Anda kuasai dan tentukan tingkat kemahiran', style: TextStyle(fontSize: 14, color: Colors.grey[600])),
              const SizedBox(height: 32),
              ...OnboardingData.skillCategories.entries.map((category) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.category, size: 18, color: theme.colorScheme.primary),
                        const SizedBox(width: 8),
                        Text(category.key, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: theme.colorScheme.primary)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final skills = category.value;
                        return Column(
                          children: [
                            for (int i = 0; i < skills.length; i += 2)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: _buildSkillItem(theme, category.key, skills[i]),
                                    ),
                                    if (i + 1 < skills.length) ...[
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: _buildSkillItem(theme, category.key, skills[i + 1]),
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
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: selectedSkills.entries.expand((categoryEntry) {
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
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: proficiencyColor,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                '${skillEntry.key} • $proficiencyLabel',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.white),
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
                color: isSelected ? theme.colorScheme.primary : Colors.grey[300]!,
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
                      fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                    ),
                  ),
                ),
                if (isSelected)
                  Icon(Icons.check_circle, size: 16, color: theme.colorScheme.primary),
              ],
            ),
          ),
        ),
        if (isSelected) ...[
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(child: _buildProficiencyButton(theme, categoryKey, skill, proficiency, 'beginner', 'Beginner')),
              const SizedBox(width: 4),
              Expanded(child: _buildProficiencyButton(theme, categoryKey, skill, proficiency, 'intermediate', 'Intermediate')),
              const SizedBox(width: 4),
              Expanded(child: _buildProficiencyButton(theme, categoryKey, skill, proficiency, 'expert', 'Expert')),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildProficiencyButton(ThemeData theme, String categoryKey, String skillName, String currentProficiency, String value, String label) {
    final isSelected = currentProficiency == value;
    Color buttonColor;
    switch (value) {
      case 'beginner':
        buttonColor = Colors.orange;
        break;
      case 'intermediate':
        buttonColor = Colors.teal;
        break;
      case 'expert':
        buttonColor = Colors.green;
        break;
      default:
        buttonColor = Colors.grey;
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
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected ? buttonColor : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: buttonColor, width: 2),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : buttonColor,
          ),
        ),
      ),
    );
  }

  Widget _buildStep3(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Step 3: Capacity & Commitment', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('Berapa banyak waktu yang bisa Anda dedikasikan?', style: TextStyle(fontSize: 14, color: Colors.grey[600])),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: theme.dividerColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Flexible(child: Text('Kapasitas Mingguan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600))),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text('${weeklyCapacity.toInt()} jam/minggu', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: theme.colorScheme.primary,
                        inactiveTrackColor: Colors.grey[300],
                        thumbColor: theme.colorScheme.primary,
                        overlayColor: theme.colorScheme.primary.withOpacity(0.2),
                        trackHeight: 4,
                      ),
                      child: Slider(
                        value: weeklyCapacity,
                        min: 0,
                        max: 40,
                        divisions: 8,
                        onChanged: (value) => setState(() => weeklyCapacity = value),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('0 jam', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                        Text('40 jam', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: theme.dividerColor),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Status Ketersediaan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 4),
                          Text(isAvailable ? 'Tersedia untuk tugas baru' : 'Sedang tidak tersedia', style: TextStyle(fontSize: 14, color: Colors.grey[600])),
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
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Step 4: Portfolio & Bio', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('Tunjukkan karya dan ceritakan tentang diri Anda', style: TextStyle(fontSize: 14, color: Colors.grey[600])),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Link Portfolio', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
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
                    child: Text('Belum ada link portfolio. Klik "Tambah Link" untuk menambahkan.', style: TextStyle(color: Colors.grey[600]), textAlign: TextAlign.center),
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
                                fillColor: theme.scaffoldBackgroundColor,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: theme.dividerColor),
                                ),
                              ),
                              items: OnboardingData.platformList.map((platform) {
                                return DropdownMenuItem(value: platform, child: Text(platform));
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
                                      fillColor: theme.scaffoldBackgroundColor,
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(color: theme.dividerColor),
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
                                fillColor: theme.scaffoldBackgroundColor,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: theme.dividerColor),
                                ),
                              ),
                              items: OnboardingData.platformList.map((platform) {
                                return DropdownMenuItem(value: platform, child: Text(platform));
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
                                fillColor: theme.scaffoldBackgroundColor,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: theme.dividerColor),
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
              const Text('Bio Singkat', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              const Row(
                children: [
                  Text('Ceritakan tentang diri Anda', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  Text(' *', style: TextStyle(color: Colors.red)),
                ],
              ),
              const SizedBox(height: 8),
              TextField(
                controller: bioController,
                maxLines: 5,
                decoration: InputDecoration(
                  hintText: 'Saya adalah mahasiswa yang passionate di bidang...',
                  filled: true,
                  fillColor: theme.scaffoldBackgroundColor,
                  contentPadding: const EdgeInsets.all(16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: theme.dividerColor),
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
                  border: Border.all(color: theme.colorScheme.primary.withOpacity(0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.summarize, color: theme.colorScheme.primary),
                        const SizedBox(width: 12),
                        const Text('Ringkasan Profil', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildSummaryItem('Nama', namaLengkapController.text.isEmpty ? '-' : namaLengkapController.text),
                    _buildSummaryItem('NIM', nimController.text.isEmpty ? '-' : nimController.text),
                    _buildSummaryItem('Prodi', selectedProdi ?? '-'),
                    _buildSummaryItem('Jabatan', selectedJabatan ?? '-'),
                    _buildSummaryItem('Divisi', selectedDivisi ?? '-'),
                    _buildSummaryItem('Total Skill', selectedSkills.values.fold(0, (sum, skills) => sum + skills.length).toString()),
                    _buildSummaryItem('Kapasitas', '${weeklyCapacity.toInt()} jam/minggu'),
                    _buildSummaryItem('Status', isAvailable ? 'Tersedia' : 'Tidak Tersedia'),
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
          Expanded(flex: 2, child: Text(label, style: const TextStyle(fontSize: 14, color: Colors.grey))),
          Expanded(flex: 3, child: Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500))),
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
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
          onChanged: (value) => setState(() {}),
        ),
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
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
          items: items.map((item) {
            return DropdownMenuItem(value: item, child: Text(item));
          }).toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }
}
