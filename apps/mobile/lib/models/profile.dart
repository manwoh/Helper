enum AppRole {
  user('user', '普通用户'),
  helper('helper', '帮手'),
  merchant('merchant', '商家'),
  admin('admin', '管理员');

  const AppRole(this.value, this.label);

  final String value;
  final String label;

  static const selectable = [AppRole.user, AppRole.helper, AppRole.merchant];

  static AppRole fromValue(String? value) {
    return AppRole.values.firstWhere(
      (role) => role.value == value,
      orElse: () => AppRole.user,
    );
  }
}

class UserProfile {
  const UserProfile({
    required this.id,
    required this.displayName,
    required this.role,
    this.phone,
    this.avatarUrl,
    this.city,
    this.district,
    this.bio,
    this.isBlocked = false,
  });

  final String id;
  final String displayName;
  final AppRole role;
  final String? phone;
  final String? avatarUrl;
  final String? city;
  final String? district;
  final String? bio;
  final bool isBlocked;

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      id: map['id'] as String,
      displayName: map['display_name'] as String? ?? '新用户',
      role: AppRole.fromValue(map['role'] as String?),
      phone: map['phone'] as String?,
      avatarUrl: map['avatar_url'] as String?,
      city: map['city'] as String?,
      district: map['district'] as String?,
      bio: map['bio'] as String?,
      isBlocked: map['is_blocked'] as bool? ?? false,
    );
  }
}
