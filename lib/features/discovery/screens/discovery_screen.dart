import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/models/user_profile.dart';
import '../../../services/profile_service.dart';

class DiscoveryScreen extends StatefulWidget {
  const DiscoveryScreen({super.key});

  @override
  State<DiscoveryScreen> createState() => _DiscoveryScreenState();
}

class _DiscoveryScreenState extends State<DiscoveryScreen> {
  late Future<List<UserProfile>> _profilesFuture;

  @override
  void initState() {
    super.initState();
    _profilesFuture = context.read<ProfileService>().getDiscoveryProfiles();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<List<UserProfile>>(
        future: _profilesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                'Data not available',
                style: TextStyle(fontSize: 20, color: Colors.grey),
              ),
            );
          }

          final profiles = snapshot.data!;
          return PageView.builder(
            scrollDirection: Axis.vertical,
            itemCount: profiles.length,
            itemBuilder: (context, index) {
              return DiscoveryCard(profile: profiles[index]);
            },
          );
        },
      ),
    );
  }
}

class DiscoveryCard extends StatelessWidget {
  final UserProfile profile;

  const DiscoveryCard({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Image Swiper (Horizontal)
        PageView.builder(
          itemCount: profile.images.length,
          itemBuilder: (context, imgIndex) {
            final isPrivate = profile.imagePrivacyFlags[imgIndex];
            final imageBytes = base64Decode(profile.images[imgIndex]);

            return Stack(
              fit: StackFit.expand,
              children: [
                ImageFiltered(
                  imageFilter: ImageFilter.blur(
                    sigmaX: isPrivate ? 15.0 : 0.0,
                    sigmaY: isPrivate ? 15.0 : 0.0,
                  ),
                  child: Image.memory(
                    imageBytes,
                    fit: BoxFit.cover,
                  ),
                ),
                if (isPrivate)
                  const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.lock, color: Colors.white, size: 48),
                        SizedBox(height: 8),
                        Text(
                          "Private Photo",
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
              ],
            );
          },
        ),
        
        // Profile Info Overlay
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.transparent, Colors.black87],
              stops: [0.6, 1.0],
            ),
          ),
        ),
        Positioned(
          bottom: 40,
          left: 20,
          right: 20,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "${profile.name}, ${profile.age}",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: profile.interests.map((i) => Chip(
                  label: Text(i, style: const TextStyle(fontSize: 12)),
                  backgroundColor: Colors.white24,
                  labelStyle: const TextStyle(color: Colors.white),
                )).toList(),
              ),
              const SizedBox(height: 8),
              Text(
                profile.bio,
                style: const TextStyle(color: Colors.white70, fontSize: 16),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
