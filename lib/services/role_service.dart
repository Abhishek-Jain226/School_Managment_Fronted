import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';
import 'auth_service.dart';
import '../config/app_config.dart';
import '../data/models/role.dart';

class RoleService {
  String get base => AppConfig.baseUrl + AppConstants.endpointRoles;
  final AuthService _auth = AuthService();

  // Get all roles
  Future<List<Role>> getAllRoles() async {
    final token = await _auth.getToken();
    final url = Uri.parse(base);
    final headers = {
      if (token != null) AppConstants.headerAuthorization: "${AppConstants.headerBearer}$token",
    };
    
    final resp = await http.get(url, headers: headers);
    
    if (resp.statusCode == 200) {
      final responseData = jsonDecode(resp.body) as Map<String, dynamic>;
      if (responseData[AppConstants.keySuccess] == true && responseData[AppConstants.keyData] != null) {
        final List<dynamic> rolesJson = responseData[AppConstants.keyData];
        return rolesJson.map((roleJson) => Role.fromJson(roleJson)).toList();
      } else {
        throw Exception("${AppConstants.errorFailedToGetRoles}: ${responseData[AppConstants.keyMessage]}");
      }
    } else {
      throw Exception("${AppConstants.errorRolesRequestFailed}: ${resp.statusCode} ${resp.body}");
    }
  }

  // Get roles for staff creation (only GATE_STAFF and DRIVER)
  Future<List<Role>> getStaffRoles() async {
    final allRoles = await getAllRoles();
    return allRoles.where((role) => 
      role.roleName == AppConstants.roleGateStaff || role.roleName == AppConstants.roleDriver
    ).toList();
  }

  // Get role by ID
  Future<Role> getRoleById(int roleId) async {
    final token = await _auth.getToken();
    final url = Uri.parse("$base/$roleId");
    final headers = {
      if (token != null) AppConstants.headerAuthorization: "${AppConstants.headerBearer}$token",
    };
    
    final resp = await http.get(url, headers: headers);
    
    if (resp.statusCode == 200) {
      final responseData = jsonDecode(resp.body) as Map<String, dynamic>;
      if (responseData[AppConstants.keySuccess] == true && responseData[AppConstants.keyData] != null) {
        return Role.fromJson(responseData[AppConstants.keyData]);
      } else {
        throw Exception("${AppConstants.errorFailedToGetRole}: ${responseData[AppConstants.keyMessage]}");
      }
    } else {
      throw Exception("${AppConstants.errorRoleRequestFailed}: ${resp.statusCode} ${resp.body}");
    }
  }
}
