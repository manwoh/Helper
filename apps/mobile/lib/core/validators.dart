class AppValidators {
  static const blockedTerms = <String>[
    '色情',
    '卖淫',
    '裸聊',
    '诈骗',
    '洗钱',
    '赌博',
    '毒品',
    '暴力',
    '打人',
    '人肉',
    '偷拍',
    '侵犯隐私',
    '身份证买卖',
    '银行卡买卖',
    '假证',
    'porn',
    'scam',
    'fraud',
    'weapon',
    'drugs',
  ];

  static String? requiredText(String? value, {int min = 1, int max = 200}) {
    final text = value?.trim() ?? '';
    if (text.length < min) return '请至少填写 $min 个字';
    if (text.length > max) return '最多 $max 个字';
    return containsBlockedTerm(text) ? '内容不符合平台规则' : null;
  }

  static String? optionalMoney(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return null;
    final number = double.tryParse(text);
    if (number == null || number < 0) return '请输入有效金额';
    return null;
  }

  static bool containsBlockedTerm(String value) {
    final lower = value.toLowerCase();
    return blockedTerms.any((term) => lower.contains(term.toLowerCase()));
  }
}
