class IntakeOutputRecord {
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
  final double? inIvf;
  final double? inOral;
  final double? inNgt;
  final double? inBld;
  final double? inOthr;
  final double? outUrine;
  final double? outGstrc;
  final double? outDrng1;
  final double? outDrng2;
  final double? outEmss;
  final double? outOthr;
  final String? notes;
  final bool isSynced;
  final int? localId;

  IntakeOutputRecord({
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
    this.inIvf,
    this.inOral,
    this.inNgt,
    this.inBld,
    this.inOthr,
    this.outUrine,
    this.outGstrc,
    this.outDrng1,
    this.outDrng2,
    this.outEmss,
    this.outOthr,
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

  double get totalIntake =>
      (inIvf ?? 0) + (inOral ?? 0) + (inNgt ?? 0) + (inBld ?? 0) + (inOthr ?? 0);

  double get totalOutput =>
      (outUrine ?? 0) + (outGstrc ?? 0) + (outDrng1 ?? 0) + (outDrng2 ?? 0) + (outEmss ?? 0) + (outOthr ?? 0);

  factory IntakeOutputRecord.fromJson(Map<String, dynamic> json) {
    return IntakeOutputRecord(
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
      inIvf: (json['inIvf'] ?? 0).toDouble(),
      inOral: (json['inOral'] ?? 0).toDouble(),
      inNgt: (json['inNgt'] ?? 0).toDouble(),
      inBld: (json['inBld'] ?? 0).toDouble(),
      inOthr: (json['inOthr'] ?? 0).toDouble(),
      outUrine: (json['outUrine'] ?? 0).toDouble(),
      outGstrc: (json['outGstrc'] ?? 0).toDouble(),
      outDrng1: (json['outDrng1'] ?? 0).toDouble(),
      outDrng2: (json['outDrng2'] ?? 0).toDouble(),
      outEmss: (json['outEmss'] ?? 0).toDouble(),
      outOthr: (json['outOthr'] ?? 0).toDouble(),
      notes: json['notes'],
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
      'inIvf': inIvf,
      'inOral': inOral,
      'inNgt': inNgt,
      'inBld': inBld,
      'inOthr': inOthr,
      'outUrine': outUrine,
      'outGstrc': outGstrc,
      'outDrng1': outDrng1,
      'outDrng2': outDrng2,
      'outEmss': outEmss,
      'outOthr': outOthr,
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
      'inIvf': inIvf ?? 0,
      'inOral': inOral ?? 0,
      'inNgt': inNgt ?? 0,
      'inBld': inBld ?? 0,
      'inOthr': inOthr ?? 0,
      'outUrine': outUrine ?? 0,
      'outGstrc': outGstrc ?? 0,
      'outDrng1': outDrng1 ?? 0,
      'outDrng2': outDrng2 ?? 0,
      'outEmss': outEmss ?? 0,
      'outOthr': outOthr ?? 0,
      'notes': notes ?? '',
    };
  }
}
