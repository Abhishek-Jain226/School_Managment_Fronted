import '../../utils/constants.dart';

class ParentRequest {
  final int? userId;
  final String name;
  final String email;
  final String contactNumber;
  final String relation;
  final String createdBy;

  ParentRequest({
    required this.userId,
    required this.name,
    required this.email,
    required this.contactNumber,
    required this.relation,
    required this.createdBy,
  });

  Map<String, dynamic> toJson() => {
    AppConstants.keyUserId: userId,
    AppConstants.keyName: name,
    AppConstants.keyEmail: email,
    AppConstants.keyContactNumber: contactNumber,
    AppConstants.keyRelation: relation,
    AppConstants.keyCreatedBy: createdBy,
  };
}
