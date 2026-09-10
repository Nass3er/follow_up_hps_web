class DoctorOrder {
  final int id;
  final int docNo;
  final String itemCode;
  final String itemName;
  final String category; // 'medication', 'lab', 'rad', 'nursing'
  final String? dosage;
  final String? frequency;
  final String? doctorName;
  final String? orderDate;
  final bool isExecuted;
  final String? executedAt;
  final String? executedBy;
  final String? executionNotes;
  final bool isSynced;

  DoctorOrder({
    required this.id,
    required this.docNo,
    required this.itemCode,
    required this.itemName,
    required this.category,
    this.dosage,
    this.frequency,
    this.doctorName,
    this.orderDate,
    this.isExecuted = false,
    this.executedAt,
    this.executedBy,
    this.executionNotes,
    this.isSynced = true,
  });

  factory DoctorOrder.fromJson(Map<String, dynamic> json) {
    return DoctorOrder(
      id: json['id'] ?? json['Id'] ?? 0,
      docNo: json['docNo'] ?? json['DocNo'] ?? 0,
      itemCode: json['itemCode'] ?? json['ItemCode'] ?? '',
      itemName: json['itemName'] ?? json['ItemName'] ?? 'أمر طبي',
      category: json['category'] ?? json['Category'] ?? 'medication',
      dosage: json['dosage'] ?? json['Dosage'],
      frequency: json['frequency'] ?? json['Frequency'],
      doctorName: json['doctorName'] ?? json['DoctorName'],
      orderDate: json['orderDate'] ?? json['OrderDate'],
      isExecuted: json['isExecuted'] == 1 || json['isExecuted'] == true,
      executedAt: json['executedAt'] ?? json['ExecutedAt'],
      executedBy: json['executedBy'] ?? json['ExecutedBy'],
      executionNotes: json['executionNotes'] ?? json['ExecutionNotes'],
      isSynced: json['isSynced'] == 1 || json['isSynced'] == true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'docNo': docNo,
      'itemCode': itemCode,
      'itemName': itemName,
      'category': category,
      'dosage': dosage,
      'frequency': frequency,
      'doctorName': doctorName,
      'orderDate': orderDate,
      'isExecuted': isExecuted ? 1 : 0,
      'executedAt': executedAt,
      'executedBy': executedBy,
      'executionNotes': executionNotes,
      'isSynced': isSynced ? 1 : 0,
    };
  }

  DoctorOrder copyWithExecution({
    required bool isExecuted,
    String? executedAt,
    String? executedBy,
    String? executionNotes,
    bool? isSynced,
  }) {
    return DoctorOrder(
      id: id,
      docNo: docNo,
      itemCode: itemCode,
      itemName: itemName,
      category: category,
      dosage: dosage,
      frequency: frequency,
      doctorName: doctorName,
      orderDate: orderDate,
      isExecuted: isExecuted,
      executedAt: executedAt ?? this.executedAt,
      executedBy: executedBy ?? this.executedBy,
      executionNotes: executionNotes ?? this.executionNotes,
      isSynced: isSynced ?? this.isSynced,
    );
  }
}
