class SchoolRequest {
  final String schoolName;
  final String schoolType;
  final String affiliationBoard;
  final String registrationNumber;
  final String address;
  final String city;
  final String district;
  final String state;
  final String pincode;
  final String contactNo;       // ✅ backend में "contactNo"
  final String email;
  final String? schoolPhoto;    // ✅ optional
  final String createdBy;       // ✅ backend में चाहिए

  SchoolRequest({
    required this.schoolName,
    required this.schoolType,
    required this.affiliationBoard,
    required this.registrationNumber,
    required this.address,
    required this.city,
    required this.district,
    required this.state,
    required this.pincode,
    required this.contactNo,
    required this.email,
    this.schoolPhoto,
    required this.createdBy,
  });

  factory SchoolRequest.fromJson(Map<String, dynamic> json) {
    return SchoolRequest(
      schoolName: json['schoolName'] ?? '',
      schoolType: json['schoolType'] ?? '',
      affiliationBoard: json['affiliationBoard'] ?? '',
      registrationNumber: json['registrationNumber'] ?? '',
      address: json['address'] ?? '',
      city: json['city'] ?? '',
      district: json['district'] ?? '',
      state: json['state'] ?? '',
      pincode: json['pincode'] ?? '',
      contactNo: json['contactNo'] ?? '',
      email: json['email'] ?? '',
      schoolPhoto: json['schoolPhoto'],
      createdBy: json['createdBy'] ?? 'SYSTEM',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "schoolName": schoolName,
      "schoolType": schoolType,
      "affiliationBoard": affiliationBoard,
      "registrationNumber": registrationNumber,
      "address": address,
      "city": city,
      "district": district,
      "state": state,
      "pincode": pincode,
      "contactNo": contactNo,
      "email": email,
      "schoolPhoto": schoolPhoto,
      "createdBy": createdBy,
    };
  }
}
