import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/validators.dart';
import '../../models/app_category.dart';
import '../../models/task.dart';
import '../../services/task_service.dart';
import '../../services/upload_service.dart';
import '../../widgets/app_shell.dart';
import '../../widgets/primary_button.dart';

class CreateTaskPage extends StatefulWidget {
  const CreateTaskPage({super.key, required this.taskKind});

  final TaskKind taskKind;

  @override
  State<CreateTaskPage> createState() => _CreateTaskPageState();
}

class _CreateTaskPageState extends State<CreateTaskPage> {
  final _formKey = GlobalKey<FormState>();
  final _taskService = TaskService();
  final _uploadService = UploadService();
  final _picker = ImagePicker();
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _location = TextEditingController();
  final _city = TextEditingController();
  final _district = TextEditingController();
  final _budgetMin = TextEditingController();
  final _budgetMax = TextEditingController();
  List<AppCategory> _categories = [];
  List<XFile> _images = [];
  String? _categoryId;
  String? _subcategoryId;
  bool _isUrgent = false;
  bool _loading = true;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _location.dispose();
    _city.dispose();
    _district.dispose();
    _budgetMin.dispose();
    _budgetMax.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    final categories = await _taskService.fetchCategories(taskKind: widget.taskKind);
    if (mounted) {
      setState(() {
        _categories = categories;
        _loading = false;
      });
    }
  }

  Future<void> _pickImages() async {
    final files = await _picker.pickMultiImage(imageQuality: 82);
    if (files.isNotEmpty && mounted) {
      setState(() => _images = files.take(6).toList());
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);

    try {
      final taskId = await _taskService.createTask(
        taskKind: widget.taskKind,
        title: _title.text,
        description: _description.text,
        locationText: _location.text,
        categoryId: _categoryId,
        subcategoryId: _subcategoryId,
        city: _city.text,
        district: _district.text,
        budgetMin: double.tryParse(_budgetMin.text),
        budgetMax: double.tryParse(_budgetMax.text),
        isUrgent: _isUrgent,
      );

      for (final image in _images) {
        final uploaded = await _uploadService.uploadTaskImage(
          taskId: taskId,
          file: image,
        );
        await _taskService.addTaskImage(
          taskId: taskId,
          storagePath: uploaded.path,
          publicUrl: uploaded.publicUrl,
        );
      }

      if (!context.mounted) return;
      context.go('/tasks/$taskId');
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('发布失败：$error')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final parents = _categories.where((item) => item.parentId == null).toList();
    final children = _categories
        .where((item) => item.parentId == _categoryId)
        .toList();

    return AppShell(
      title: widget.taskKind.label,
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  TextFormField(
                    controller: _title,
                    decoration: const InputDecoration(labelText: '标题'),
                    validator: (value) => AppValidators.requiredText(
                      value,
                      min: 4,
                      max: 80,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _description,
                    maxLines: 5,
                    decoration: const InputDecoration(labelText: '详细说明'),
                    validator: (value) => AppValidators.requiredText(
                      value,
                      min: 10,
                      max: 2000,
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _categoryId,
                    decoration: const InputDecoration(labelText: '分类'),
                    items: parents
                        .map(
                          (item) => DropdownMenuItem(
                            value: item.id,
                            child: Text(item.name),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        _categoryId = value;
                        _subcategoryId = null;
                      });
                    },
                    validator: (value) => value == null ? '请选择分类' : null,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _subcategoryId,
                    decoration: const InputDecoration(labelText: '子分类'),
                    items: children
                        .map(
                          (item) => DropdownMenuItem(
                            value: item.id,
                            child: Text(item.name),
                          ),
                        )
                        .toList(),
                    onChanged: children.isEmpty
                        ? null
                        : (value) => setState(() => _subcategoryId = value),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _location,
                    decoration: const InputDecoration(labelText: '地点或服务范围'),
                    validator: (value) => AppValidators.requiredText(
                      value,
                      min: 2,
                      max: 160,
                    ),
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
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _budgetMin,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: '最低预算 RM'),
                          validator: AppValidators.optionalMoney,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _budgetMax,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: '最高预算 RM'),
                          validator: AppValidators.optionalMoney,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    value: _isUrgent,
                    contentPadding: EdgeInsets.zero,
                    title: const Text('加急发布'),
                    subtitle: const Text('预留加急发布费接口，当前仅标记展示'),
                    onChanged: (value) => setState(() => _isUrgent = value),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: _pickImages,
                    icon: const Icon(Icons.add_photo_alternate_outlined),
                    label: Text(_images.isEmpty ? '上传任务图片' : '已选择 ${_images.length} 张图片'),
                  ),
                  const SizedBox(height: 20),
                  PrimaryButton(
                    label: '发布任务',
                    icon: Icons.send_outlined,
                    isLoading: _submitting,
                    onPressed: _submit,
                  ),
                ],
              ),
            ),
    );
  }
}
