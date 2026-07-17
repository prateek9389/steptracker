import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:convert';
import 'dart:io';
import '../../theme/app_colors.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/glass_card.dart';
import '../../providers/profile_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/user_profile.dart';

class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  late final TextEditingController _nameController;
  String _selectedGender = 'Male';
  int _age = 26;
  double _height = 178.0;
  double _weight = 74.0;
  double _dailyGoal = 10000.0;
  double _stepLength = 72.0;
  String? _customAvatarUrl;
  bool _isUploadingAvatar = false;

  @override
  void initState() {
    super.initState();
    final profile = ref.read(profileStreamProvider).value;
    if (profile != null) {
      _nameController = TextEditingController(text: profile.name);
      _selectedGender = profile.gender;
      _age = profile.age;
      _height = profile.height;
      _weight = profile.weight;
      _dailyGoal = profile.dailyGoal.toDouble();
      _stepLength = profile.stepLength;
      
      if (profile.photoUrl.isNotEmpty) {
        _customAvatarUrl = profile.photoUrl;
      }
    } else {
      _nameController = TextEditingController(text: FirebaseAuth.instance.currentUser?.displayName ?? '');
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    try {
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      if (image == null) return;
      
      setState(() => _isUploadingAvatar = true);

      String baseUrl = dotenv.env['API_BASE_URL'] ?? 'http://127.0.0.1:5000';
      if (!kIsWeb && Platform.isAndroid && baseUrl.contains('localhost')) {
        baseUrl = baseUrl.replaceAll('localhost', '10.0.2.2');
      } else if (!kIsWeb && Platform.isAndroid && baseUrl.contains('127.0.0.1')) {
        baseUrl = baseUrl.replaceAll('127.0.0.1', '10.0.2.2');
      }
      final uri = Uri.parse('$baseUrl/api/upload');
      final request = http.MultipartRequest('POST', uri);
      
      if (kIsWeb) {
        final bytes = await image.readAsBytes();
        request.files.add(http.MultipartFile.fromBytes('avatar', bytes, filename: image.name));
      } else {
        request.files.add(await http.MultipartFile.fromPath('avatar', image.path));
      }

      final response = await request.send();
      if (response.statusCode == 200) {
        final responseData = await response.stream.bytesToString();
        final data = json.decode(responseData);
        setState(() {
          _customAvatarUrl = data['url'];
        });
      } else {
        throw Exception('Failed to upload image');
      }

      if (mounted) {
        setState(() => _isUploadingAvatar = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploadingAvatar = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Upload failed. Check backend connection.'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  Future<void> _saveProfile() async {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your name'), backgroundColor: AppColors.danger),
      );
      return;
    }

    final user = ref.read(currentUserProvider);
    if (user == null) return;

    final existingProfile = ref.read(profileStreamProvider).value;

    final newProfile = UserProfile(
      uid: user.uid,
      name: _nameController.text,
      email: user.email ?? '',
      photoUrl: _customAvatarUrl ?? '',
      height: double.parse(_height.toStringAsFixed(1)),
      weight: double.parse(_weight.toStringAsFixed(1)),
      age: _age,
      gender: _selectedGender,
      dailyGoal: _dailyGoal.toInt(),
      stepLength: double.parse(_stepLength.toStringAsFixed(1)),
      createdAt: existingProfile?.createdAt ?? DateTime.now(),
      lastLogin: DateTime.now(),
      coins: existingProfile?.coins ?? 0,
      level: existingProfile?.level ?? 1,
    );

    await ref.read(profileRepositoryProvider).saveProfile(newProfile);

    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/dashboard');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: isDark ? AppColors.darkBgGradient : const LinearGradient(
            colors: [Color(0xFFE2E8F0), Color(0xFFF8FAFC)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24.0, 4.0, 24.0, 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Personal Info',
                        style: theme.textTheme.headlineLarge?.copyWith(
                          fontFamily: 'Outfit',
                          fontWeight: FontWeight.bold,
                          fontSize: 28,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Customize your physical telemetry so StrideAI can estimate step lengths and calories accurately.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontSize: 12,
                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Large Interactive Profile Image Preview
                      Center(
                        child: Stack(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: AppColors.neonAccentGradient,
                              ),
                              child: Container(
                                padding: const EdgeInsets.all(3),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isDark ? AppColors.backgroundDark : Colors.white,
                                ),
                                child: InkWell(
                                  onTap: _isUploadingAvatar ? null : _pickAndUploadImage,
                                  borderRadius: BorderRadius.circular(50),
                                  child: CircleAvatar(
                                    radius: 46,
                                    backgroundColor: AppColors.primary.withOpacity(0.12),
                                    child: _isUploadingAvatar
                                        ? const CircularProgressIndicator(color: AppColors.primary)
                                        : (_customAvatarUrl != null
                                            ? ClipRRect(
                                                borderRadius: BorderRadius.circular(46),
                                                child: _customAvatarUrl!.startsWith('http')
                                                    ? Image.network(
                                                        _customAvatarUrl!,
                                                        width: 92,
                                                        height: 92,
                                                        fit: BoxFit.cover,
                                                        errorBuilder: (ctx, err, st) => const Icon(
                                                          Icons.person_rounded,
                                                          size: 54,
                                                          color: AppColors.primary,
                                                        ),
                                                      )
                                                    : Image.file(
                                                        File(_customAvatarUrl!),
                                                        width: 92,
                                                        height: 92,
                                                        fit: BoxFit.cover,
                                                        errorBuilder: (ctx, err, st) => const Icon(
                                                          Icons.person_rounded,
                                                          size: 54,
                                                          color: AppColors.primary,
                                                        ),
                                                      ),
                                              )
                                            : const Icon(
                                                Icons.person_rounded,
                                                size: 54,
                                                color: AppColors.primary,
                                              )),
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: GestureDetector(
                                onTap: _isUploadingAvatar ? null : _pickAndUploadImage,
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: const BoxDecoration(
                                    color: AppColors.primary,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.camera_alt_rounded,
                                    size: 18,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),


                      // Input Fields Card
                      GlassCard(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Email Display (Read-Only)
                            if (FirebaseAuth.instance.currentUser?.email != null) ...[
                              TextField(
                                controller: TextEditingController(text: FirebaseAuth.instance.currentUser!.email),
                                readOnly: true,
                                style: TextStyle(color: isDark ? Colors.white60 : Colors.black54),
                                decoration: const InputDecoration(
                                  labelText: 'Email Address (Google Account)',
                                  prefixIcon: Icon(Icons.email_rounded, color: AppColors.textMutedDark),
                                  enabled: false,
                                ),
                              ),
                              const SizedBox(height: 12),
                            ],
                            // Full Name Input
                            TextField(
                              controller: _nameController,
                              style: TextStyle(color: isDark ? Colors.white : AppColors.textLight),
                              decoration: const InputDecoration(
                                labelText: 'Your Display Name',
                                prefixIcon: Icon(Icons.person, color: AppColors.textMutedDark),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Gender Chips
                            Text(
                              'Gender',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: ['Male', 'Female', 'Other'].map((gender) {
                                final isSelected = _selectedGender == gender;
                                return Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                                    child: ChoiceChip(
                                      showCheckmark: false,
                                      side: BorderSide.none,
                                      label: Center(
                                          child: Text(
                                        gender,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: isSelected
                                              ? (isDark ? Colors.black : Colors.white)
                                              : (isDark ? Colors.white70 : AppColors.textSecondaryLight),
                                        ),
                                      )),
                                      selected: isSelected,
                                      selectedColor: AppColors.primary,
                                      backgroundColor: isDark ? const Color(0xFF131C2E) : const Color(0xFFE2E8F0),
                                      checkmarkColor: isDark ? Colors.black : Colors.white,
                                      onSelected: (selected) {
                                        if (selected) {
                                          setState(() => _selectedGender = gender);
                                        }
                                      },
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Sliders details
                      GlassCard(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Age Slider
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Age', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                Text('$_age years',
                                    style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 13)),
                              ],
                            ),
                            Slider(
                              value: _age.toDouble(),
                              min: 10.0,
                              max: 100.0,
                              divisions: 90,
                              onChanged: (val) => setState(() => _age = val.toInt()),
                            ),
                            const SizedBox(height: 4),

                            // Height Slider
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Height', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                Text('${_height.toStringAsFixed(0)} cm',
                                    style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 13)),
                              ],
                            ),
                            Slider(
                              value: _height,
                              min: 120.0,
                              max: 220.0,
                              onChanged: (val) => setState(() => _height = val),
                            ),
                            const SizedBox(height: 4),

                            // Weight Slider
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Weight', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                Text('${_weight.toStringAsFixed(1)} kg',
                                    style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 13)),
                              ],
                            ),
                            Slider(
                              value: _weight,
                              min: 40.0,
                              max: 150.0,
                              onChanged: (val) => setState(() => _weight = val),
                            ),
                            const SizedBox(height: 4),

                            // Daily Step Goal
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Daily Step Goal', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                Text('${_dailyGoal.toInt()} Steps',
                                    style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 13)),
                              ],
                            ),
                            Slider(
                              value: _dailyGoal,
                              min: 2000.0,
                              max: 20000.0,
                              divisions: 18,
                              onChanged: (val) => setState(() => _dailyGoal = val),
                            ),
                            const SizedBox(height: 4),

                            // Step Length
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Avg Step Length', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                Text('${_stepLength.toStringAsFixed(0)} cm',
                                    style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 13)),
                              ],
                            ),
                            Slider(
                              value: _stepLength,
                              min: 40.0,
                              max: 100.0,
                              onChanged: (val) => setState(() => _stepLength = val),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Finish Button
                      CustomButton(
                        text: 'Complete Setup',
                        onPressed: _saveProfile,
                        type: ButtonType.primary,
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
