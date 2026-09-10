class IntakeOutputRecord {
  final int? id;
  final int docNo;
  final String category; // 'intake' or 'output'
  final String typeName;
  final double amount;
  final String? time;
  final String? date;
  final String? notes;
  final bool isSynced;
  final String? createdAt;

  IntakeOutputRecord({
    this.id,
    required this.docNo,
    required this.category,
    required this.typeName,
    required this.amount,
    this.time,
    this.date,
    this.notes,
    this.isSynced = false,
    this.createdAt,
  });

  factory IntakeOutputRecord.fromJson(Map<String, dynamic> json) {
    return IntakeOutputRecord(
      id: json['id'],
      docNo: json['docNo'] ?? json['DocNo'] ?? 0,
      category: json['category'] ?? json['Category'] ?? 'intake',
      typeName: json['typeName'] ?? json['TypeName'] ?? json['type'] ?? 'سوائل',
      amount: (json['amount'] ?? json['Amount'] ?? 0).toDouble(),
      time: json['time'] ?? json['Time'],
      date: json['date'] ?? json['Date'],
      notes: json['notes'] ?? json['Notes'],
      isSynced: json['isSynced'] == 1 || json['isSynced'] == true,
      createdAt: json['createdAt'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'docNo': docNo,
      'category': category,
      'typeName': typeName,
      'amount': amount,
      'time': time,
      'date': date,
      'notes': notes,
      'isSynced': isSynced ? 1 : 0,
      'createdAt': createdAt ?? DateTime.now().toIso8601String(),
    };
  }

  Map<String, dynamic> toApiDto() {
    return {
      'docNo': docNo,
      'category': category,
      'typeName': typeName,
      'amount': amount,
      'time': time,
      'date': date,
      'notes': notes,
    };
  }
}
