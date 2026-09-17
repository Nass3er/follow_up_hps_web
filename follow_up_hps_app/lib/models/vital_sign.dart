class VitalSign {
  final int? docSrl;
  final dynamic docNo;
  final int? docSrlAdmt;
  final String? patientNo;
  final String? age;
  final int? ageType;
  final int? roomNo;
  final int? bedNo;
  final int? roomSer;
  final int? buildingNo;
  final String? docTime;
  final int? nurseEmpNo;
  final double? temperature;
  final double? pulseRate;
  final double? respirationRate;
  final double? spO2;
  final double? bloodPressureOne;
  final double? bloodPressureTwo;
  final String? notes;
  final bool isSynced;
  final int? localId;

  VitalSign({
    this.docSrl,
    this.docNo,
    this.docSrlAdmt,
    this.patientNo,
    this.age,
    this.ageType,
    this.roomNo,
    this.bedNo,
    this.roomSer,
    this.buildingNo,
    this.docTime,
    this.nurseEmpNo,
    this.temperature,
    this.pulseRate,
    this.respirationRate,
    this.spO2,
    this.bloodPressureOne,
    this.bloodPressureTwo,
    this.notes,
    this.isSynced = false,
    this.localId,
  });

  String get timeOnly {
    if (docTime == null) return '--:--';
    try {
      final parts = docTime!.split('T');
      if (parts.length > 1) return parts[1].substring(0, 5);
      return docTime!;
    } catch (_) {
      return docTime!;
    }
  }

  String get bpText => '${bloodPressureOne?.toInt() ?? '-'}/${bloodPressureTwo?.toInt() ?? '-'}';

  factory VitalSign.fromJson(Map<String, dynamic> json) {
    return VitalSign(
      docSrl: json['docSrl'],
      docNo: json['docNo'],
      docSrlAdmt: json['docSrlAdmt'],
      patientNo: json['patientNo']?.toString(),
      age: json['age']?.toString(),
      ageType: json['ageType'],
      roomNo: json['roomNo'],
      bedNo: json['bedNo'],
      roomSer: json['roomSer'],
      buildingNo: json['buildingNo'],
      docTime: json['docTime'],
      nurseEmpNo: json['nurseEmpNo'],
      temperature: (json['temperature'] ?? json['temp'])?.toDouble(),
      pulseRate: (json['pulseRate'] ?? json['pulse'])?.toDouble(),
      respirationRate: (json['respirationRate'] ?? json['resp'])?.toDouble(),
      spO2: (json['spO2'] ?? json['o2Sat'])?.toDouble(),
      bloodPressureOne: (json['bloodPressureOne'] ?? json['sysBp'])?.toDouble(),
      bloodPressureTwo: (json['bloodPressureTwo'] ?? json['diaBp'])?.toDouble(),
      notes: json['notes'] ?? json['remarks'],
      isSynced: json['isSynced'] == 1 || json['isSynced'] == true,
      localId: json['id'] ?? json['localId'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (localId != null) 'id': localId,
      'docSrl': docSrl,
      'docNo': docNo,
      'docSrlAdmt': docSrlAdmt,
      'patientNo': patientNo,
      'age': age,
      'ageType': ageType,
      'roomNo': roomNo,
      'bedNo': bedNo,
      'roomSer': roomSer,
      'buildingNo': buildingNo,
      'docTime': docTime,
      'nurseEmpNo': nurseEmpNo,
      'temperature': temperature,
      'pulseRate': pulseRate,
      'respirationRate': respirationRate,
      'spO2': spO2,
      'bloodPressureOne': bloodPressureOne,
      'bloodPressureTwo': bloodPressureTwo,
      'notes': notes,
      'isSynced': isSynced ? 1 : 0,
    };
  }

  Map<String, dynamic> toSaveDto() {
    return {
      'docSrl': docSrl ?? 0,
      'branchNo': 1,
      'docNo': docNo,
      'docSrlAdmt': docSrlAdmt,
      'patientNo': patientNo,
      'age': age,
      'ageType': ageType,
      'roomNo': roomNo,
      'bedNo': bedNo,
      'roomSer': roomSer,
      'buildingNo': buildingNo,
      'docTime': docTime,
      'nurseEmpNo': nurseEmpNo,
      'temperature': temperature,
      'pulseRate': pulseRate,
      'respirationRate': respirationRate,
      'spO2': spO2,
      'bloodPressureOne': bloodPressureOne,
      'bloodPressureTwo': bloodPressureTwo,
      'notes': notes ?? '',
    };
  }
}
