import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';
import '../config/app_config.dart';
import '../data/models/role.dart';

class RoleService {
  String get base => AppConfig.baseUrl + '/api/roles';
  final AuthService _auth = AuthService();

  // Get all roles
  Future<List<Role>> getAllRoles() async {
    final token = await _auth.getToken();
    final url = Uri.parse(base);
    final headers = {
      if (token != null) "Authorization": "Bearer $token",
    };
    
    final resp = await http.get(url, headers: headers);
    
    if (resp.statusCode == 200) {
      final responseData = jsonDecode(resp.body) as Map<String, dynamic>;
      if (responseData['success'] == true && responseData['data'] != null) {
        final List<dynamic> rolesJson = responseData['data'];
        return rolesJson.map((roleJson) => Role.fromJson(roleJson)).toList();
      } else {
        throw Exception("Failed to get roles: ${responseData['message']}");
      }
    } else {
      throw Exception("Roles request failed: ${resp.statusCode} ${resp.body}");
    }
  }

  // Get roles for staff creation (only GATE_STAFF and DRIVER)
  Future<List<Role>> getStaffRoles() async {
    final allRoles = await getAllRoles();
    return allRoles.where((role) => 
      role.roleName == 'GATE_STAFF' || role.roleName == 'DRIVER'
    ).toList();
  }

  // Get role by ID
  Future<Role> getRoleById(int roleId) async {
    final token = await _auth.getToken();
    final url = Uri.parse("$base/$roleId");
    final headers = {
      if (token != null) "Authorization": "Bearer $token",
    };
    
    final resp = await http.get(url, headers: headers);
    
    if (resp.statusCode == 200) {
      final responseData = jsonDecode(resp.body) as Map<String, dynamic>;
      if (responseData['success'] == true && responseData['data'] != null) {
        return Role.fromJson(responseData['data']);
      } else {
        throw Exception("Failed to get role: ${responseData['message']}");
      }
    } else {
      throw Exception("Role request failed: ${resp.statusCode} ${resp.body}");
    }
  }
}
