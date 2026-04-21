import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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

  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  String _gender = 'Other';
  final _bioController = TextEditingController();
  final List<String> _interests = [];
  final _interestController = TextEditingController();

  void _nextStep() {
    if (_currentStep < 3) {
      _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
      setState(() => _currentStep++);
    } else {
      _saveProfile();
    }
  }

  Future<void> _saveProfile() async {
    showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));
    
    final profileService = ProfileService(context.read<ApiService>());
    final success = await profileService.updateProfile(
      name: _nameController.text,
      age: int.tryParse(_ageController.text) ?? 18,
      gender: _gender,
      interestedIn: ['everyone'],
      interests: _interests,
      bio: _bioController.text,
    );

    Navigator.pop(context);

    if (success) {
      Navigator.of(context).pushReplacementNamed('/home');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to save profile')));
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
                  value: (_currentStep + 1) / 4,
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
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _nextStep,
                    child: Text(_currentStep == 3 ? 'Finish Setup' : 'Continue'),
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
      title: "Get Verified",
      subtitle: "Prove you are real and get more matches",
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
                const Icon(Icons.verified_user, size: 64, color: Colors.blueAccent),
                const SizedBox(height: 16),
                const Text(
                  "Verified profiles get 3x more meaningful connections.",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
                const SizedBox(height: 24),
                OutlinedButton.icon(
                  onPressed: () {
                    // Feature implemented in Module 2/3
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Verification feature coming in Module 2!')));
                  },
                  icon: const Icon(Icons.camera_alt),
                  label: const Text("Verify Now"),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: _nextStep,
                  child: const Text("I'll do this later", style: TextStyle(color: Colors.white60)),
                ),
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
