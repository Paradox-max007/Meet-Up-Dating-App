import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:reorderable_grid_view/reorderable_grid_view.dart';
import 'dart:ui';
import '../../../core/theme/theme_service.dart';
import '../../../services/profile_service.dart';
import '../../../services/api_service.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  final int _totalSteps = 5;

  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  String _gender = 'Other';
  final _bioController = TextEditingController();
  final List<String> _interests = [];
  final _interestController = TextEditingController();

  // Photos State
  final List<XFile> _images = [];
  final List<bool> _isPrivate = [];
  final ImagePicker _picker = ImagePicker();
  bool _skippedVerification = false;

  @override
  void initState() {
    super.initState();
    _nameController.addListener(() => setState(() {}));
    _ageController.addListener(() => setState(() {}));
    _bioController.addListener(() => setState(() {}));
  }

  void _nextStep() {
    if (_currentStep < _totalSteps - 1) {
      _pageController.nextPage(duration: const Duration(milliseconds: 500), curve: Curves.easeOutQuart);
      setState(() => _currentStep++);
      FocusScope.of(context).unfocus(); // Ensure keyboard goes down between steps
    } else {
      _saveProfile();
    }
  }

  bool get _isStepValid {
    switch (_currentStep) {
      case 0:
        return _nameController.text.trim().isNotEmpty && 
               _ageController.text.trim().isNotEmpty && 
               _gender.isNotEmpty;
      case 1:
        return _interests.isNotEmpty;
      case 2:
        return _bioController.text.trim().isNotEmpty;
      case 3:
        return _images.isNotEmpty;
      case 4:
        return true;
      default:
        return true;
    }
  }

  Future<void> _pickImage() async {
    if (_images.length >= 8) return;
    
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (image != null) {
      setState(() {
        _images.add(image);
        _isPrivate.add(false); // Default to public
      });
    }
  }

  Future<void> _saveProfile() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final apiService = ApiService(); // Gets singleton
      final profileService = ProfileService(apiService);

      // Log current token state
      debugPrint('[ProfileSetup] Token available: ${apiService.token != null}');

      // Convert images to base64
      List<String> base64Images = [];
      for (var image in _images) {
        final bytes = await File(image.path).readAsBytes();
        base64Images.add(base64Encode(bytes));
      }

      final success = await profileService.updateProfile(
        name: _nameController.text,
        age: int.tryParse(_ageController.text) ?? 18,
        gender: _gender,
        interestedIn: ['everyone'],
        interests: _interests,
        bio: _bioController.text,
        images: base64Images,
        imagePrivacyFlags: _isPrivate,
      );

      if (mounted) Navigator.pop(context);

      if (success) {
        if (mounted) Navigator.of(context).pushReplacementNamed('/home');
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Server error. Check backend logs.'),
              duration: Duration(seconds: 4),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      debugPrint('[ProfileSetup] Save error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Cannot reach server: ${e.toString().substring(0, e.toString().length.clamp(0, 80))}'),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeService = Provider.of<ThemeService>(context);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: themeService.mainGradient),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: LinearProgressIndicator(
                  value: _currentStep == _totalSteps - 1 && _isStepValid ? 1.0 : (_currentStep + 1) / _totalSteps,
                  backgroundColor: Colors.white24,
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _buildStep1(),
                    _buildStep2(),
                    _buildStep3(),
                    _buildStep4(),
                    _buildStep5(),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isStepValid ? _nextStep : null,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      disabledBackgroundColor: Colors.white10,
                      disabledForegroundColor: Colors.white30,
                    ),
                    child: Text(_currentStep == _totalSteps - 1 ? 'Finish Setup' : 'Continue'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep4() {
    return _buildStepContainer(
      title: "Add Photos",
      subtitle: "Add up to 8 photos. Drag to reorder. Tap the lock to make an image private (blurred for others).",
      child: Column(
        children: [
          SizedBox(
            height: 400,
            child: ReorderableGridView.count(
              crossAxisCount: 3,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1,
              onReorder: (oldIndex, newIndex) {
                setState(() {
                  final image = _images.removeAt(oldIndex);
                  _images.insert(newIndex, image);
                  final privacy = _isPrivate.removeAt(oldIndex);
                  _isPrivate.insert(newIndex, privacy);
                });
              },
              children: [
                ...Iterable.generate(_images.length).map((index) {
                  return Container(
                    key: ValueKey(_images[index].path),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white24),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        ImageFiltered(
                          imageFilter: ImageFilter.blur(
                            sigmaX: _isPrivate[index] ? 5.0 : 0.0,
                            sigmaY: _isPrivate[index] ? 5.0 : 0.0,
                          ),
                          child: Image.file(File(_images[index].path), fit: BoxFit.cover),
                        ),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: GestureDetector(
                            onTap: () => setState(() => _isPrivate[index] = !_isPrivate[index]),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.black54,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                _isPrivate[index] ? Icons.lock : Icons.lock_open,
                                size: 16,
                                color: _isPrivate[index] ? Colors.amber : Colors.white,
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 4,
                          right: 4,
                          child: GestureDetector(
                            onTap: () => setState(() {
                              _images.removeAt(index);
                              _isPrivate.removeAt(index);
                            }),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                              child: const Icon(Icons.close, size: 16, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                if (_images.length < 8)
                  GestureDetector(
                    key: const ValueKey('add_button'),
                    onTap: _pickImage,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white24, style: BorderStyle.solid),
                      ),
                      child: const Icon(Icons.add_a_photo, color: Colors.white70),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep5() {
    return _buildStepContainer(
      title: _skippedVerification ? "Profile Ready!" : "Get Verified",
      subtitle: _skippedVerification 
        ? "You can always verify your profile later from settings."
        : "Prove you are real and get more matches",
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white24),
            ),
            child: Column(
              children: [
                Icon(
                  _skippedVerification ? Icons.check_circle_outline : Icons.verified_user, 
                  size: 64, 
                  color: _skippedVerification ? Colors.greenAccent : Colors.blueAccent
                ),
                const SizedBox(height: 16),
                Text(
                  _skippedVerification 
                    ? "Your profile is complete. Click 'Finish Setup' to start discovering connections."
                    : "Verified profiles get 3x more meaningful connections.",
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 18, color: Colors.white),
                ),
                const SizedBox(height: 24),
                if (!_skippedVerification) ...[
                  OutlinedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Verification feature coming in Module 2!')));
                    },
                    icon: const Icon(Icons.camera_alt),
                    label: const Text("Verify Now"),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => setState(() => _skippedVerification = true),
                    child: const Text("I'll do this later", style: TextStyle(color: Colors.white60)),
                  ),
                ] else
                  const Icon(Icons.celebration, color: Colors.amber, size: 48),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep1() {
    return _buildStepContainer(
      title: "The Basics",
      subtitle: "Tell us who you are",
      child: Column(
        children: [
          _buildField("Full Name", _nameController),
          const SizedBox(height: 20),
          _buildField("Age", _ageController, keyboardType: TextInputType.number),
          const SizedBox(height: 20),
          DropdownButtonFormField<String>(
            value: _gender,
            dropdownColor: Colors.grey[900],
            style: const TextStyle(color: Colors.white),
            decoration: _inputDecoration("Gender"),
            items: ['Male', 'Female', 'Non-binary', 'Other'].map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
            onChanged: (val) => setState(() => _gender = val!),
          ),
        ],
      ),
    );
  }

  Widget _buildStep2() {
    return _buildStepContainer(
      title: "Interests",
      subtitle: "What makes you, you?",
      child: Column(
        children: [
          TextField(
            controller: _interestController,
            style: const TextStyle(color: Colors.white),
            decoration: _inputDecoration("Add an interest (e.g. Hiking)").copyWith(
              suffixIcon: IconButton(
                icon: const Icon(Icons.add, color: Colors.white),
                onPressed: () {
                  if (_interestController.text.isNotEmpty) {
                    setState(() {
                      _interests.add(_interestController.text.trim());
                      _interestController.clear();
                    });
                  }
                },
              ),
            ),
            onSubmitted: (val) {
              if (val.isNotEmpty) {
                setState(() {
                  _interests.add(val.trim());
                  _interestController.clear();
                });
              }
            },
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 8,
            children: _interests.map((i) => Chip(
              label: Text(i),
              onDeleted: () => setState(() => _interests.remove(i)),
            )).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildStep3() {
    return _buildStepContainer(
      title: "About You",
      subtitle: "Write a short bio",
      child: TextField(
        controller: _bioController,
        maxLines: 5,
        style: const TextStyle(color: Colors.white),
        decoration: _inputDecoration("Bio..."),
      ),
    );
  }

  Widget _buildStepContainer({required String title, required String subtitle, required Widget child}) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 40),
          Text(title, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 16),
          Text(subtitle, style: const TextStyle(fontSize: 16, color: Colors.white70)),
          const SizedBox(height: 40),
          child,
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white70),
      filled: true,
      fillColor: Colors.white.withOpacity(0.1),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
    );
  }

  Widget _buildField(String label, TextEditingController controller, {TextInputType keyboardType = TextInputType.text}) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      decoration: _inputDecoration(label),
    );
  }
}
