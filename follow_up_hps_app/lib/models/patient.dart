class Admission {
  final dynamic docNo;
  final int docSerial;
  final String patientName;
  final String? date;

  Admission({
    required this.docNo,
    required this.docSerial,
    required this.patientName,
    this.date,
  });

  factory Admission.fromJson(Map<String, dynamic> json) {
    return Admission(
      docNo: json['docNo'],
      docSerial: json['docSerial'] ?? 0,
      patientName: json['patientName'] ?? 'بدون اسم',
      date: json['date'],
    );
  }
}

class Patient {
  final String patientNo;
  final String patientName;
  final String? age;
  final int? ageType;
  final int? gender;
  final int? roomNo;
  final int? bedNo;
  final int? roomService;
  final int? buldNo;
  final int? deptNo;
  final String? dctrNo;
  final String? doctorName;
  final String? admDate;
  final dynamic docNo;
  final int docSrl;
  final String? cacheKey;

  Patient({
    required this.patientNo,
    required this.patientName,
    this.age,
    this.ageType,
    this.gender,
    this.roomNo,
    this.bedNo,
    this.roomService,
    this.buldNo,
    this.deptNo,
    this.dctrNo,
    this.doctorName,
    this.admDate,
    this.docNo,
    required this.docSrl,
    this.cacheKey,
  });

  String get genderText {
    if (gender == 1) return 'ذكر';
    if (gender == 2) return 'أنثى';
    return '-';
  }

  String get ageTypeText {
    if (ageType == 1) return 'سنة';
    if (ageType == 2) return 'شهر';
    if (ageType == 3) return 'يوم';
    return '';
  }

  factory Patient.fromJson(Map<String, dynamic> json) {
    final docNo = json['docNo'];
    final docSrl = json['docSrl'] ?? json['docSerial'] ?? 0;
    return Patient(
      patientNo: (json['patientNo'] ?? '').toString(),
      patientName: json['patientName'] ?? json['patName'] ?? 'بدون اسم',
      age: json['age']?.toString(),
      ageType: json['ageType'],
      gender: json['gender'],
      roomNo: json['roomNo'],
      bedNo: json['bedNo'],
      roomService: json['roomService'] ?? json['roomSer'],
      buldNo: json['buldNo'] ?? json['buildingNo'],
      deptNo: json['deptNo'],
      dctrNo: json['dctrNo'],
      doctorName: json['doctorName'],
      admDate: json['admDate'],
      docNo: docNo,
      docSrl: docSrl is int ? docSrl : int.tryParse(docSrl.toString()) ?? 0,
      cacheKey: json['cacheKey'] ?? '${docNo}_$docSrl',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'patientNo': patientNo,
      'patientName': patientName,
      'age': age,
      'ageType': ageType,
      'gender': gender,
      'roomNo': roomNo,
      'bedNo': bedNo,
      'roomService': roomService,
      'buldNo': buldNo,
      'deptNo': deptNo,
      'dctrNo': dctrNo,
      'doctorName': doctorName,
      'admDate': admDate,
      'docNo': docNo,
      'docSrl': docSrl,
      'cacheKey': cacheKey,
    };
  }

  factory Patient.fromAdmission(Map<String, dynamic> json, {Map<String, dynamic>? details}) {
    final docNo = json['docNo'];
    final docSrl = json['docSerial'] ?? 0;
    if (details != null) {
      return Patient.fromJson({...details, 'docNo': docNo, 'docSrl': docSrl});
    }
    return Patient(
      patientNo: '',
      patientName: json['patientName'] ?? '',
      docNo: docNo,
      docSrl: docSrl,
    );
  }
}
