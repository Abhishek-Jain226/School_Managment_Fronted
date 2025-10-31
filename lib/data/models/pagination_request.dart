// lib/data/models/pagination_request.dart
import '../../utils/constants.dart';

class PaginationRequest {
  final int page;
  final int size;

  PaginationRequest({required this.page, required this.size});

  Map<String, dynamic> toJson() => {
        AppConstants.keyPage: page,
        AppConstants.keySize: size,
      };
}
