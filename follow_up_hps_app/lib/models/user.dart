class User {
  final String username;
  final String token;
  final int? branchNo;
  final bool isAdmin;
  final String? companyName;

  User({
    required this.username,
    required this.token,
    this.branchNo,
    this.isAdmin = false,
    this.companyName,
  });

  factory User.fromJson(Map<String, dynamic> json, String token) {
    return User(
      username: json['unique_name'] ?? json['sub'] ?? 'مستخدم',
      token: token,
      branchNo: json['BranchNo'] != null ? int.tryParse(json['BranchNo'].toString()) : null,
      isAdmin: json['IsAdmin'] == "1" || json['IsAdmin'] == true,
      companyName: json['CompanyName'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'token': token,
      'branchNo': branchNo,
      'isAdmin': isAdmin,
      'companyName': companyName,
    };
  }
}
