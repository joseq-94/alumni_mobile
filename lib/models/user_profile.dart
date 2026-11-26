// One user profile, plus the name and bio rules shared by the form and data sources.
class UserProfile {
  final int id;
  final String name;
  final String email;
  final String bio;
  final String? pictureUrl;
  UserProfile({
    required this.id,
    required this.name,
    required this.email,
    this.bio = '',
    this.pictureUrl,
  });

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      id: map['id'] as int,
      name: map['name'] as String,
      email: map['email'] as String,
      bio: map['bio'] as String? ?? '',
      pictureUrl: map['picture_url'] as String?,
    );
  }
  // Only editable fields are sent to the server.
  Map<String, dynamic> toMap() => {'name': name, 'bio': bio};

  static String? validateName(String? value) {
    final name = value?.trim() ?? '';
    if (name.isEmpty) return 'Enter your name.';
    if (name.length > 255) return 'Use 255 characters or fewer.';
    return null;
  }

  static String? validateBio(String? value) {
    if ((value ?? '').length > 1000) return 'Use 1000 characters or fewer.';
    return null;
  }
}
