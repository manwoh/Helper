import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/profile.dart';
import '../../services/auth_service.dart';
import '../../services/profile_service.dart';
import '../../widgets/app_shell.dart';
import '../../widgets/primary_button.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _profileService = ProfileService();
  final _authService = AuthService();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _city = TextEditingController();
  final _district = TextEditingController();
  final _bio = TextEditingController();
  AppRole _role = AppRole.user;
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _city.dispose();
    _district.dispose();
    _bio.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final profile = await _profileService.currentProfile();
    if (profile == null || !mounted) return;
    setState(() {
      _name.text = profile.displayName;
      _phone.text = profile.phone ?? '';
      _city.text = profile.city ?? '';
      _district.text = profile.district ?? '';
      _bio.text = profile.bio ?? '';
      _role = profile.role == AppRole.admin ? AppRole.user : profile.role;
      _loading = false;
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await _profileService.updateProfile(
        displayName: _name.text,
        phone: _phone.text,
        city: _city.text,
        district: _district.text,
        bio: _bio.text,
      );
      await _profileService.setRole(_role);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('资料已保存')),
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('保存失败：$error')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _signOut() async {
    await _authService.signOut();
    if (!context.mounted) return;
    context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: '我的资料',
      actions: [
        IconButton(
          tooltip: '退出登录',
          onPressed: _signOut,
          icon: const Icon(Icons.logout),
        ),
      ],
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text(
                    '选择身份',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 10),
                  SegmentedButton<AppRole>(
                    segments: const [
                      ButtonSegment(
                        value: AppRole.user,
                        label: Text('普通用户'),
                        icon: Icon(Icons.person_outline),
                      ),
                      ButtonSegment(
                        value: AppRole.helper,
                        label: Text('帮手'),
                        icon: Icon(Icons.handyman_outlined),
                      ),
                      ButtonSegment(
                        value: AppRole.merchant,
                        label: Text('商家'),
                        icon: Icon(Icons.storefront_outlined),
                      ),
                    ],
                    selected: {_role},
                    onSelectionChanged: (value) => setState(() => _role = value.first),
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _name,
                    decoration: const InputDecoration(labelText: '昵称'),
                    validator: (value) =>
                        (value?.trim().isEmpty ?? true) ? '请填写昵称' : null,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _phone,
                    decoration: const InputDecoration(labelText: '电话'),
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _city,
                          decoration: const InputDecoration(labelText: '城市'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _district,
                          decoration: const InputDecoration(labelText: '地区'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _bio,
                    maxLines: 3,
                    decoration: const InputDecoration(labelText: '简介'),
                  ),
                  const SizedBox(height: 20),
                  PrimaryButton(
                    label: '保存资料',
                    icon: Icons.save_outlined,
                    isLoading: _saving,
                    onPressed: _save,
                  ),
                ],
              ),
            ),
    );
  }
}
