import '../../utils/constants.dart';

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
  final String contactNo;       
  final String email;
  final String? schoolPhoto;    
  final String createdBy;      

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
      schoolName: json[AppConstants.keySchoolName] ?? '',
      schoolType: json[AppConstants.keySchoolType] ?? '',
      affiliationBoard: json[AppConstants.keyAffiliationBoard] ?? '',
      registrationNumber: json[AppConstants.keyRegistrationNumber] ?? '',
      address: json[AppConstants.keyAddress] ?? '',
      city: json[AppConstants.keyCity] ?? '',
      district: json[AppConstants.keyDistrict] ?? '',
      state: json[AppConstants.keyState] ?? '',
      pincode: json[AppConstants.keyPincode] ?? '',
      contactNo: json[AppConstants.keyContactNo] ?? '',
      email: json[AppConstants.keyEmail] ?? '',
      schoolPhoto: json[AppConstants.keySchoolPhoto],
      createdBy: json[AppConstants.keyCreatedBy] ?? 'SYSTEM',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      AppConstants.keySchoolName: schoolName,
      AppConstants.keySchoolType: schoolType,
      AppConstants.keyAffiliationBoard: affiliationBoard,
      AppConstants.keyRegistrationNumber: registrationNumber,
      AppConstants.keyAddress: address,
      AppConstants.keyCity: city,
      AppConstants.keyDistrict: district,
      AppConstants.keyState: state,
      AppConstants.keyPincode: pincode,
      AppConstants.keyContactNo: contactNo,
      AppConstants.keyEmail: email,
      AppConstants.keySchoolPhoto: schoolPhoto,
      AppConstants.keyCreatedBy: createdBy,
    };
  }
}
