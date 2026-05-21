import 'task.dart';

class AppCategory {
  const AppCategory({
    required this.id,
    required this.name,
    required this.slug,
    this.parentId,
    this.taskType,
  });

  final String id;
  final String name;
  final String slug;
  final String? parentId;
  final TaskKind? taskType;

  factory AppCategory.fromMap(Map<String, dynamic> map) {
    return AppCategory(
      id: map['id'] as String,
      name: map['name'] as String? ?? '',
      slug: map['slug'] as String? ?? '',
      parentId: map['parent_id'] as String?,
      taskType: taskKindFromValue(map['task_type'] as String?),
    );
  }
}
