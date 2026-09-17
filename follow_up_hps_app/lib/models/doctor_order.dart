class ProcedureType {
  final int procedureType;
  final String procedureTypeName;

  ProcedureType({required this.procedureType, required this.procedureTypeName});

  factory ProcedureType.fromJson(Map<String, dynamic> json) {
    return ProcedureType(
      procedureType: json['procedureType'] ?? 0,
      procedureTypeName: json['procedureTypeName'] ?? '',
    );
  }
}

class UsageMethod {
  final int codeNo;
  final String codeName;

  UsageMethod({required this.codeNo, required this.codeName});

  factory UsageMethod.fromJson(Map<String, dynamic> json) {
    return UsageMethod(
      codeNo: json['codeNo'] ?? 0,
      codeName: json['codeName'] ?? '',
    );
  }
}

class OrderItem {
  final String itemCode;
  final String itemName;
  final double price;
  final String unit;
  final String? sampleType;
  final double? pSize;

  OrderItem({
    required this.itemCode,
    required this.itemName,
    this.price = 0,
    this.unit = '',
    this.sampleType,
    this.pSize,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      itemCode: json['itemCode'] ?? '',
      itemName: json['itemName'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      unit: json['unit'] ?? '',
      sampleType: json['sampleType'],
      pSize: (json['pSize'] ?? 0).toDouble(),
    );
  }
}

class OrderDetailItem {
  final String itemCode;
  final double pSize;
  final double price;
  final String unit;
  final double quantity;
  final String expectedDate;
  final String notes;
  final int? mthdUse;
  final String? mthdUseDsc;
  final double? durtion;
  final int? durTyp;

  OrderDetailItem({
    required this.itemCode,
    this.pSize = 0,
    this.price = 0,
    this.unit = '',
    this.quantity = 1,
    this.expectedDate = '',
    this.notes = '',
    this.mthdUse,
    this.mthdUseDsc,
    this.durtion,
    this.durTyp,
  });

  Map<String, dynamic> toJson() {
    return {
      'itemCode': itemCode,
      'pSize': pSize,
      'price': price,
      'unit': unit,
      'quantity': quantity,
      'expectedDate': expectedDate,
      'notes': notes,
      if (mthdUse != null) 'mthdUse': mthdUse,
      if (mthdUseDsc != null) 'mthdUseDsc': mthdUseDsc,
      if (durtion != null) 'durtion': durtion,
      if (durTyp != null) 'durTyp': durTyp,
    };
  }
}

class DoctorOrder {
  final int? docSrl;
  final dynamic docNo;
  final String? docDate;
  final String? procedureTypeName;
  final String? doctorName;
  final String? patientName;
  final int? procedureType;
  final int? priorityNo;
  final String? notes;
  final String? refNo;
  final List<OrderDetailItem>? details;
  final bool isSynced;
  final int? localId;

  DoctorOrder({
    this.docSrl,
    this.docNo,
    this.docDate,
    this.procedureTypeName,
    this.doctorName,
    this.patientName,
    this.procedureType,
    this.priorityNo,
    this.notes,
    this.refNo,
    this.details,
    this.isSynced = true,
    this.localId,
  });

  String get priorityText {
    if (priorityNo == 2) return 'عاجل';
    if (priorityNo == 3) return 'حرج';
    return 'عادي';
  }

  factory DoctorOrder.fromJson(Map<String, dynamic> json) {
    return DoctorOrder(
      docSrl: json['docSrl'],
      docNo: json['docNo'],
      docDate: json['docDate'],
      procedureTypeName: json['procedureTypeName'],
      doctorName: json['doctorName'] ?? json['dctrName'],
      patientName: json['patientName'],
      procedureType: json['procedureType'],
      priorityNo: json['priorityNo'],
      notes: json['notes'],
      refNo: json['refNo'],
      details: json['details'] != null
          ? (json['details'] as List).map((d) => OrderDetailItem(
                itemCode: d['itemCode'] ?? '',
                pSize: (d['pSize'] ?? 0).toDouble(),
                price: (d['price'] ?? 0).toDouble(),
                unit: d['unit'] ?? '',
                quantity: (d['quantity'] ?? 1).toDouble(),
                expectedDate: d['expectedDate'] ?? '',
                notes: d['notes'] ?? '',
                mthdUse: d['mthdUse'],
                mthdUseDsc: d['mthdUseDsc'],
                durtion: (d['durtion'] ?? 0).toDouble(),
                durTyp: d['durTyp'],
              )).toList()
          : null,
      isSynced: json['isSynced'] == 1 || json['isSynced'] == true,
      localId: json['id'] ?? json['localId'],
    );
  }

  Map<String, dynamic> toSaveDto({
    required int branchNo,
    required dynamic admissionDocNo,
    required int admissionDocSrl,
    required String patientNo,
    required int roomSer,
    required int roomNo,
    required int deptNo,
    required int buildNo,
    required int bedNo,
    required int gender,
    required String age,
    required int ageType,
    required String doctorNo,
  }) {
    return {
      'docSrl': docSrl ?? 0,
      'branchNo': branchNo,
      'procedureType': procedureType,
      'docNo': 1,
      'docDate': docDate,
      'docTime': '2000-01-01T${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}:00',
      'priorityNo': priorityNo ?? 1,
      'docNoAdmission': admissionDocNo,
      'docSrlAdmission': admissionDocSrl,
      'patientNo': patientNo,
      'roomSer': roomSer,
      'roomNo': roomNo,
      'deptNo': deptNo,
      'buildNo': buildNo,
      'bedNo': bedNo,
      'gender': gender,
      'age': age,
      'ageType': ageType,
      'doctorNo': doctorNo,
      'notes': notes ?? '',
      'refNo': refNo ?? '',
      'details': details?.map((d) => d.toJson()).toList() ?? [],
    };
  }
}

class LabResult {
  final int? docSrl;
  final dynamic docNo;
  final String? docDate;
  final String? doctorName;
  final List<LabResultDetail>? details;

  LabResult({
    this.docSrl,
    this.docNo,
    this.docDate,
    this.doctorName,
    this.details,
  });

  factory LabResult.fromJson(Map<String, dynamic> json) {
    return LabResult(
      docSrl: json['docSrl'],
      docNo: json['docNo'],
      docDate: json['docDate'],
      doctorName: json['doctorName'] ?? json['dctrName'],
      details: json['details'] != null
          ? (json['details'] as List).map((d) => LabResultDetail.fromJson(d)).toList()
          : null,
    );
  }
}

class LabResultDetail {
  final String tstCode;
  final String itemCode;
  final String itemName;
  final String? itemClassName;
  final String result;
  final String normalValue;
  final String unit;
  final String? serviceName;

  LabResultDetail({
    required this.tstCode,
    required this.itemCode,
    required this.itemName,
    this.itemClassName,
    required this.result,
    required this.normalValue,
    required this.unit,
    this.serviceName,
  });

  factory LabResultDetail.fromJson(Map<String, dynamic> json) {
    return LabResultDetail(
      tstCode: json['tstCode'] ?? '',
      itemCode: json['itemCode'] ?? '',
      itemName: json['itemName'] ?? '',
      itemClassName: json['itemClassName'],
      result: json['result'] ?? '',
      normalValue: json['normalValue'] ?? '',
      unit: json['unit'] ?? '',
      serviceName: json['serviceName'],
    );
  }
}

class Nurse {
  final int empNo;
  final String empName;

  Nurse({required this.empNo, required this.empName});

  factory Nurse.fromJson(Map<String, dynamic> json) {
    return Nurse(
      empNo: json['empNo'] ?? 0,
      empName: json['empName'] ?? '',
    );
  }
}
