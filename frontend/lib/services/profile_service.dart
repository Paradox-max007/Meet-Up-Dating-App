import 'dart:convert';
import '../../services/api_service.dart';

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
  }) async {
    final response = await _apiService.post('/profile', {
      'name': name,
      'age': age,
      'gender': gender,
      'interested_in': interestedIn,
      'interests': interests,
      'bio': bio,
    });
    
    return response.statusCode == 200 || response.statusCode == 201;
  }

  Future<bool> uploadProfileImages(List<String> base64Images) async {
    final response = await _apiService.post('/profile/images', {
      'images': base64Images,
    });
    return response.statusCode == 200 || response.statusCode == 201;
  }
}
