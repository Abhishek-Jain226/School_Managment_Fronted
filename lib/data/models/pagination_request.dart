// lib/data/models/pagination_request.dart
class PaginationRequest {
  final int page;
  final int size;

  PaginationRequest({required this.page, required this.size});

  Map<String, dynamic> toJson() => {
        'page': page,
        'size': size,
      };
}
