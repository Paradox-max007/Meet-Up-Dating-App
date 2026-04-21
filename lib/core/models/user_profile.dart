class UserProfile {
  final String id;
  final String name;
  final int age;
  final String gender;
  final List<String> interests;
  final String bio;
  final List<String> images;
  final List<bool> imagePrivacyFlags;

  UserProfile({
    required this.id,
    required this.name,
    required this.age,
    required this.gender,
    required this.interests,
    required this.bio,
    required this.images,
    required this.imagePrivacyFlags,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      age: json['age'] ?? 0,
      gender: json['gender'] ?? '',
      interests: List<String>.from(json['interests'] ?? []),
      bio: json['bio'] ?? '',
      images: List<String>.from(json['images'] ?? []),
      imagePrivacyFlags: List<bool>.from(json['image_privacy_flags'] ?? []),
    );
  }
}
