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

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  late final TextEditingController _nameController;
  String _selectedGender = 'Male';
  int _age = 26;
  double _height = 178.0;
  double _weight = 74.0;
  double _dailyGoal = 10000.0;
  double _stepLength = 72.0;
  String? _customAvatarUrl;
  bool _isUploadingAvatar = false;
  bool _isSaving = false;

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
      if (profile.photoUrl.startsWith('http')) {
        _customAvatarUrl = profile.photoUrl;
      }
    } else {
      _nameController = TextEditingController(text: '');
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
        
        // Auto-save the profile picture to Firestore immediately
        final existingProfile = ref.read(profileStreamProvider).value;
        if (existingProfile != null && _customAvatarUrl != null) {
          await ref.read(profileRepositoryProvider).saveProfile(
            existingProfile.copyWith(photoUrl: _customAvatarUrl)
          );
        }
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

  Future<void> _showManualInputDialog({
    required String title,
    required num currentValue,
    required num min,
    required num max,
    required Function(num) onSave,
    bool isInt = false,
  }) async {
    final controller = TextEditingController(
        text: isInt ? currentValue.toInt().toString() : currentValue.toStringAsFixed(1));
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Enter $title'),
          content: TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              hintText: 'Between $min and $max',
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            TextButton(
              onPressed: () {
                final val = num.tryParse(controller.text);
                if (val != null && val >= min && val <= max) {
                  onSave(val);
                  Navigator.pop(context);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Please enter a valid number between $min and $max'), backgroundColor: AppColors.danger),
                  );
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _saveProfile() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your name'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final user = ref.read(currentUserProvider);
      if (user == null) return;
      
      final existingProfile = ref.read(profileStreamProvider).value;

      final newProfile = existingProfile != null 
          ? existingProfile.copyWith(
              name: _nameController.text.trim(),
              photoUrl: _customAvatarUrl ?? '',
              height: double.parse(_height.toStringAsFixed(1)),
              weight: double.parse(_weight.toStringAsFixed(1)),
              age: _age,
              gender: _selectedGender,
              dailyGoal: _dailyGoal.toInt(),
              stepLength: double.parse(_stepLength.toStringAsFixed(1)),
            )
          : UserProfile(
              uid: user.uid,
              name: _nameController.text.trim(),
              email: user.email ?? '',
              photoUrl: _customAvatarUrl ?? '',
              height: double.parse(_height.toStringAsFixed(1)),
              weight: double.parse(_weight.toStringAsFixed(1)),
              age: _age,
              gender: _selectedGender,
              dailyGoal: _dailyGoal.toInt(),
              stepLength: double.parse(_stepLength.toStringAsFixed(1)),
              createdAt: DateTime.now(),
              lastLogin: DateTime.now(),
            );

      await ref.read(profileRepositoryProvider).saveProfile(newProfile);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update profile: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Edit Profile',
          style: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: isDark ? Colors.white : Colors.black,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
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
                  padding: const EdgeInsets.fromLTRB(24.0, 16.0, 24.0, 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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
                                GestureDetector(
                                  onTap: () => _showManualInputDialog(
                                    title: 'Age',
                                    currentValue: _age,
                                    min: 10,
                                    max: 100,
                                    isInt: true,
                                    onSave: (v) => setState(() => _age = v.toInt()),
                                  ),
                                  child: Text('$_age years',
                                      style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 13, decoration: TextDecoration.underline, decorationColor: AppColors.primary)),
                                ),
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
                                GestureDetector(
                                  onTap: () => _showManualInputDialog(
                                    title: 'Height (cm)',
                                    currentValue: _height,
                                    min: 120,
                                    max: 220,
                                    onSave: (v) => setState(() => _height = v.toDouble()),
                                  ),
                                  child: Text('${_height.toStringAsFixed(0)} cm',
                                      style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 13, decoration: TextDecoration.underline, decorationColor: AppColors.primary)),
                                ),
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
                                GestureDetector(
                                  onTap: () => _showManualInputDialog(
                                    title: 'Weight (kg)',
                                    currentValue: _weight,
                                    min: 40,
                                    max: 150,
                                    onSave: (v) => setState(() => _weight = v.toDouble()),
                                  ),
                                  child: Text('${_weight.toStringAsFixed(1)} kg',
                                      style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 13, decoration: TextDecoration.underline, decorationColor: AppColors.primary)),
                                ),
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
                                GestureDetector(
                                  onTap: () => _showManualInputDialog(
                                    title: 'Daily Step Goal',
                                    currentValue: _dailyGoal,
                                    min: 2000,
                                    max: 50000,
                                    isInt: true,
                                    onSave: (v) => setState(() => _dailyGoal = v.toDouble()),
                                  ),
                                  child: Text('${_dailyGoal.toInt()} Steps',
                                      style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 13, decoration: TextDecoration.underline, decorationColor: AppColors.primary)),
                                ),
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
                                const Text('Step Length', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                GestureDetector(
                                  onTap: () => _showManualInputDialog(
                                    title: 'Step Length (cm)',
                                    currentValue: _stepLength,
                                    min: 40,
                                    max: 120,
                                    onSave: (v) => setState(() => _stepLength = v.toDouble()),
                                  ),
                                  child: Text('${_stepLength.toStringAsFixed(1)} cm',
                                      style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 13, decoration: TextDecoration.underline, decorationColor: AppColors.primary)),
                                ),
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

                      // Save Button
                      CustomButton(
                        text: 'Save Changes',
                        onPressed: _saveProfile,
                        isLoading: _isSaving,
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
