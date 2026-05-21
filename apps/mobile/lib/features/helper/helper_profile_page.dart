import 'package:flutter/material.dart';

import '../../services/profile_service.dart';
import '../../widgets/app_shell.dart';
import '../../widgets/primary_button.dart';

class HelperProfilePage extends StatefulWidget {
  const HelperProfilePage({super.key});

  @override
  State<HelperProfilePage> createState() => _HelperProfilePageState();
}

class _HelperProfilePageState extends State<HelperProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _service = ProfileService();
  final _headline = TextEditingController();
  final _bio = TextEditingController();
  final _skills = TextEditingController();
  final _areas = TextEditingController();
  final _rate = TextEditingController();
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _headline.dispose();
    _bio.dispose();
    _skills.dispose();
    _areas.dispose();
    _rate.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final helper = await _service.helperProfile();
    if (!mounted) return;
    if (helper != null) {
      _headline.text = helper['headline'] as String? ?? '';
      _bio.text = helper['bio'] as String? ?? '';
      _skills.text = ((helper['skills'] as List<dynamic>? ?? [])).join('，');
      _areas.text = ((helper['service_areas'] as List<dynamic>? ?? [])).join('，');
      _rate.text = helper['hourly_rate']?.toString() ?? '';
    }
    setState(() => _loading = false);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await _service.saveHelperProfile(
        headline: _headline.text,
        bio: _bio.text,
        skills: _splitTags(_skills.text),
        serviceAreas: _splitTags(_areas.text),
        hourlyRate: double.tryParse(_rate.text),
      );
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('帮手资料已保存')),
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

  List<String> _splitTags(String value) {
    return value
        .split(RegExp(r'[,，]'))
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toSet()
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: '我要做帮手',
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text(
                    '创建帮手资料',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 6),
                  const Text('添加技能标签和服务地区，之后可以报价或接单。'),
                  const SizedBox(height: 18),
                  TextFormField(
                    controller: _headline,
                    decoration: const InputDecoration(labelText: '一句话介绍'),
                    validator: (value) =>
                        (value?.trim().isEmpty ?? true) ? '请填写介绍' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _bio,
                    maxLines: 4,
                    decoration: const InputDecoration(labelText: '服务说明'),
                    validator: (value) =>
                        (value?.trim().length ?? 0) >= 10 ? null : '请至少填写 10 个字',
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _skills,
                    decoration: const InputDecoration(
                      labelText: '技能标签',
                      hintText: '维修，跑腿，电脑，清洁',
                    ),
                    validator: (value) =>
                        _splitTags(value ?? '').isEmpty ? '请至少填写一个技能' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _areas,
                    decoration: const InputDecoration(
                      labelText: '服务地区',
                      hintText: 'KL，Cheras，PJ',
                    ),
                    validator: (value) =>
                        _splitTags(value ?? '').isEmpty ? '请至少填写一个地区' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _rate,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: '参考时薪 RM（可选）'),
                  ),
                  const SizedBox(height: 20),
                  PrimaryButton(
                    label: '保存并成为帮手',
                    icon: Icons.verified_outlined,
                    isLoading: _saving,
                    onPressed: _save,
                  ),
                ],
              ),
            ),
    );
  }
}
