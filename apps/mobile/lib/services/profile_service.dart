import '../core/supabase_client.dart';
import '../models/profile.dart';

class ProfileService {
  Future<UserProfile?> currentProfile() async {
    final user = supabase.auth.currentUser;
    if (user == null) return null;

    return ensureCurrentProfile();
  }

  Future<UserProfile> ensureCurrentProfile({String? displayName}) async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      throw StateError('No signed-in user.');
    }

    final row = await supabase
        .from('profiles')
        .select()
        .eq('id', user.id)
        .maybeSingle();

    if (row != null) return UserProfile.fromMap(Map<String, dynamic>.from(row));

    final metadataName = user.userMetadata?['display_name'];
    final fallbackName = displayName?.trim().isNotEmpty == true
        ? displayName!.trim()
        : metadataName is String && metadataName.trim().isNotEmpty
            ? metadataName.trim()
            : user.email?.split('@').first ?? '新用户';

    final inserted = await supabase
        .from('profiles')
        .insert({
          'id': user.id,
          'display_name': fallbackName,
          'role': AppRole.user.value,
        })
        .select()
        .single();

    return UserProfile.fromMap(Map<String, dynamic>.from(inserted));
  }

  Future<void> updateProfile({
    required String displayName,
    String? phone,
    String? city,
    String? district,
    String? bio,
  }) async {
    final user = supabase.auth.currentUser!;
    await supabase.from('profiles').update({
      'display_name': displayName.trim(),
      'phone': _blankToNull(phone),
      'city': _blankToNull(city),
      'district': _blankToNull(district),
      'bio': _blankToNull(bio),
    }).eq('id', user.id);
  }

  Future<void> setRole(AppRole role) async {
    if (role == AppRole.admin) {
      throw ArgumentError('Admin role cannot be selected from the app.');
    }

    final user = supabase.auth.currentUser!;
    await supabase.from('profiles').update({'role': role.value}).eq('id', user.id);
  }

  Future<UserProfile> saveProfile({
    required String displayName,
    required AppRole role,
    String? phone,
    String? city,
    String? district,
    String? bio,
  }) async {
    await updateProfile(
      displayName: displayName,
      phone: phone,
      city: city,
      district: district,
      bio: bio,
    );
    await setRole(role);
    return ensureCurrentProfile();
  }

  Future<Map<String, dynamic>?> helperProfile() async {
    final user = supabase.auth.currentUser;
    if (user == null) return null;

    final row = await supabase
        .from('helper_profiles')
        .select()
        .eq('user_id', user.id)
        .maybeSingle();

    return row == null ? null : Map<String, dynamic>.from(row);
  }

  Future<void> saveHelperProfile({
    required String headline,
    required String bio,
    required List<String> skills,
    required List<String> serviceAreas,
    double? hourlyRate,
  }) async {
    final user = supabase.auth.currentUser!;
    await supabase.from('helper_profiles').upsert({
      'user_id': user.id,
      'headline': headline.trim(),
      'bio': bio.trim(),
      'skills': skills,
      'service_areas': serviceAreas,
      'hourly_rate': hourlyRate,
      'is_available': true,
    }, onConflict: 'user_id');

    await setRole(AppRole.helper);
  }

  String? _blankToNull(String? value) {
    final text = value?.trim() ?? '';
    return text.isEmpty ? null : text;
  }
}
