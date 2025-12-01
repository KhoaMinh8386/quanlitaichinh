class Transaction {
  final String id;
  final double amount;
  final String type; // 'income' or 'expense'
  final String description;
  final DateTime postedAt;
  final Category? category;
  final BankAccount? account;
  final String? notes;
  final String classificationSource; // 'AUTO' or 'MANUAL'

  Transaction({
    required this.id,
    required this.amount,
    required this.type,
    required this.description,
    required this.postedAt,
    this.category,
    this.account,
    this.notes,
    required this.classificationSource,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'],
      amount: (json['amount'] as num).toDouble(),
      type: json['type'],
      description: json['description'] ?? '',
      postedAt: DateTime.parse(json['postedAt']),
      category: json['category'] != null ? Category.fromJson(json['category']) : null,
      account: json['account'] != null ? BankAccount.fromJson(json['account']) : null,
      notes: json['notes'],
      classificationSource: json['classificationSource'] ?? 'AUTO',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'amount': amount,
      'type': type,
      'description': description,
      'postedAt': postedAt.toIso8601String(),
      'category': category?.toJson(),
      'account': account?.toJson(),
      'notes': notes,
      'classificationSource': classificationSource,
    };
  }

  bool get isIncome => type == 'income';
  bool get isExpense => type == 'expense';
}

class Category {
  final int id;
  final String name;
  final String type; // 'income' or 'expense'
  final String? icon;
  final String? color;

  Category({
    required this.id,
    required this.name,
    required this.type,
    this.icon,
    this.color,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      name: json['name'],
      type: json['type'] ?? 'expense',
      icon: json['icon'],
      color: json['color'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'icon': icon,
      'color': color,
    };
  }

  bool get isIncome => type == 'income';
  bool get isExpense => type == 'expense';
}

class BankAccount {
  final String id;
  final String bankName;
  final String? accountAlias;
  final String? accountNumberMask;

  BankAccount({
    required this.id,
    required this.bankName,
    this.accountAlias,
    this.accountNumberMask,
  });

  factory BankAccount.fromJson(Map<String, dynamic> json) {
    return BankAccount(
      id: json['id'],
      bankName: json['bankName'],
      accountAlias: json['accountAlias'],
      accountNumberMask: json['accountNumberMask'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'bankName': bankName,
      'accountAlias': accountAlias,
      'accountNumberMask': accountNumberMask,
    };
  }

  String get displayName => accountAlias ?? bankName;
}
