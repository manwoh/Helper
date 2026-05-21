import '../core/supabase_client.dart';
import '../models/profile.dart';

class ProfileService {
  Future<UserProfile?> currentProfile() async {
    final user = supabase.auth.currentUser;
    if (user == null) return null;

    final row = await supabase
        .from('profiles')
        .select()
        .eq('id', user.id)
        .maybeSingle();

    if (row == null) return null;
    return UserProfile.fromMap(Map<String, dynamic>.from(row));
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
      'phone': phone?.trim(),
      'city': city?.trim(),
      'district': district?.trim(),
      'bio': bio?.trim(),
    }).eq('id', user.id);
  }

  Future<void> setRole(AppRole role) async {
    final user = supabase.auth.currentUser!;
    await supabase.from('profiles').update({'role': role.value}).eq('id', user.id);
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
}
