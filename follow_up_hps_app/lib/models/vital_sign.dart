class VitalSign {
  final int? id;
  final int docNo;
  final String? time;
  final String? date;
  final double? sysBp;
  final double? diaBp;
  final double? pulse;
  final double? temp;
  final double? resp;
  final double? o2Sat;
  final int? painScore;
  final String? position;
  final String? remarks;
  final bool isSynced;
  final String? createdAt;

  VitalSign({
    this.id,
    required this.docNo,
    this.time,
    this.date,
    this.sysBp,
    this.diaBp,
    this.pulse,
    this.temp,
    this.resp,
    this.o2Sat,
    this.painScore,
    this.position,
    this.remarks,
    this.isSynced = false,
    this.createdAt,
  });

  factory VitalSign.fromJson(Map<String, dynamic> json) {
    return VitalSign(
      id: json['id'],
      docNo: json['docNo'] ?? json['DocNo'] ?? 0,
      time: json['time'] ?? json['Time'],
      date: json['date'] ?? json['Date'],
      sysBp: (json['sysBp'] ?? json['SysBp'])?.toDouble(),
      diaBp: (json['diaBp'] ?? json['DiaBp'])?.toDouble(),
      pulse: (json['pulse'] ?? json['Pulse'])?.toDouble(),
      temp: (json['temp'] ?? json['Temp'])?.toDouble(),
      resp: (json['resp'] ?? json['Resp'])?.toDouble(),
      o2Sat: (json['o2Sat'] ?? json['O2Sat'])?.toDouble(),
      painScore: json['painScore'] ?? json['PainScore'],
      position: json['position'] ?? json['Position'],
      remarks: json['remarks'] ?? json['Remarks'],
      isSynced: json['isSynced'] == 1 || json['isSynced'] == true,
      createdAt: json['createdAt'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'docNo': docNo,
      'time': time,
      'date': date,
      'sysBp': sysBp,
      'diaBp': diaBp,
      'pulse': pulse,
      'temp': temp,
      'resp': resp,
      'o2Sat': o2Sat,
      'painScore': painScore,
      'position': position,
      'remarks': remarks,
      'isSynced': isSynced ? 1 : 0,
      'createdAt': createdAt ?? DateTime.now().toIso8601String(),
    };
  }

  Map<String, dynamic> toApiDto() {
    return {
      'docNo': docNo,
      'time': time,
      'date': date,
      'sysBp': sysBp,
      'diaBp': diaBp,
      'pulse': pulse,
      'temp': temp,
      'resp': resp,
      'o2Sat': o2Sat,
      'painScore': painScore,
      'position': position,
      'remarks': remarks,
    };
  }
}
