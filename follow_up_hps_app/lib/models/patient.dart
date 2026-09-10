class Patient {
  final int docNo;
  final String patNo;
  final String patName;
  final String? doctorName;
  final String? roomNo;
  final String? bedNo;
  final String? age;
  final String? gender;
  final String? admissionDate;

  Patient({
    required this.docNo,
    required this.patNo,
    required this.patName,
    this.doctorName,
    this.roomNo,
    this.bedNo,
    this.age,
    this.gender,
    this.admissionDate,
  });

  factory Patient.fromJson(Map<String, dynamic> json) {
    return Patient(
      docNo: json['docNo'] ?? json['DocNo'] ?? 0,
      patNo: json['patNo']?.toString() ?? json['PatNo']?.toString() ?? '',
      patName: json['patName'] ?? json['PatName'] ?? json['patientName'] ?? 'بدون اسم',
      doctorName: json['doctorName'] ?? json['DoctorName'],
      roomNo: json['roomNo']?.toString() ?? json['RoomNo']?.toString(),
      bedNo: json['bedNo']?.toString() ?? json['BedNo']?.toString(),
      age: json['age']?.toString() ?? json['Age']?.toString(),
      gender: json['gender'] ?? json['Gender'],
      admissionDate: json['admissionDate'] ?? json['AdmissionDate'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'docNo': docNo,
      'patNo': patNo,
      'patName': patName,
      'doctorName': doctorName,
      'roomNo': roomNo,
      'bedNo': bedNo,
      'age': age,
      'gender': gender,
      'admissionDate': admissionDate,
    };
  }
}
