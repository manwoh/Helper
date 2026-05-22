import 'task.dart';

const urgentPublishFee = 3.0;

class TaskCreateInput {
  const TaskCreateInput({
    required this.taskKind,
    required this.title,
    required this.description,
    required this.locationText,
    required this.isUrgent,
    this.categoryId,
    this.subcategoryId,
    this.city,
    this.district,
    this.budgetMin,
    this.budgetMax,
  });

  final TaskKind taskKind;
  final String title;
  final String description;
  final String locationText;
  final String? categoryId;
  final String? subcategoryId;
  final String? city;
  final String? district;
  final double? budgetMin;
  final double? budgetMax;
  final bool isUrgent;

  String? get budgetRangeError {
    if (budgetMin != null && budgetMax != null && budgetMax! < budgetMin!) {
      return '最高预算不能低于最低预算';
    }
    return null;
  }

  Map<String, dynamic> toInsertMap({required String creatorId}) {
    return {
      'creator_id': creatorId,
      'task_type': taskKind.value,
      'title': title.trim(),
      'description': description.trim(),
      'location_text': locationText.trim(),
      'category_id': _blankToNull(categoryId),
      'subcategory_id': _blankToNull(subcategoryId),
      'city': _blankToNull(city),
      'district': _blankToNull(district),
      'budget_min': budgetMin,
      'budget_max': budgetMax,
      'is_urgent': isUrgent,
      'urgent_fee': isUrgent ? urgentPublishFee : 0,
      'status': 'open',
    };
  }

  static double? parseOptionalMoney(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return null;
    return double.tryParse(text);
  }

  static String? _blankToNull(String? value) {
    final text = value?.trim() ?? '';
    return text.isEmpty ? null : text;
  }
}
