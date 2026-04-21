import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../services/api_service.dart';
import '../core/models/user_profile.dart';

class ProfileService {
  final ApiService _apiService;

  ProfileService(this._apiService);

  Future<bool> updateProfile({
    required String name,
    required int age,
    required String gender,
    required List<String> interestedIn,
    required List<String> interests,
    required String bio,
    List<String>? images,
    List<bool>? imagePrivacyFlags,
  }) async {
    final response = await _apiService.post('/users/profile', {
      'name': name,
      'age': age,
      'gender': gender,
      'interested_in': interestedIn,
      'interests': interests,
      'bio': bio,
      if (images != null) 'images': images,
      if (imagePrivacyFlags != null) 'image_privacy_flags': imagePrivacyFlags,
    });
    
    debugPrint('[ProfileService] POST /users/profile status: ${response.statusCode}');
    debugPrint('[ProfileService] Response body: ${response.body.substring(0, response.body.length.clamp(0, 300))}');
    
    return response.statusCode == 200 || response.statusCode == 201;
  }

  Future<List<UserProfile>> getDiscoveryProfiles() async {
    final response = await _apiService.get('/users/discover');
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => UserProfile.fromJson(json)).toList();
    }
    return [];
  }
}
