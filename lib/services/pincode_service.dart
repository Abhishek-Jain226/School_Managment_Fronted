import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';

class PincodeService {
  // Using Indian Postal API for pincode lookup
  static const String _baseUrl = AppConstants.pincodeApiBaseUrl;
  
  /// Get location details by pincode
  /// Returns: {cities: [list of cities], district, state} or null if not found
  static Future<Map<String, dynamic>?> getLocationByPincode(String pincode) async {
    if (pincode.length != 6) return null;
    
    try {
      final url = Uri.parse('$_baseUrl/$pincode');
      debugPrint('🔍 PincodeService: Fetching from URL: $url');
      final response = await http.get(url);
      debugPrint('🔍 PincodeService: Response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        debugPrint('🔍 PincodeService: Response data type: ${data.runtimeType}');
        debugPrint('🔍 PincodeService: Response data: $data');
        
        if (data is List && data.isNotEmpty) {
          final postOffice = data[0];
          debugPrint('🔍 PincodeService: PostOffice type: ${postOffice.runtimeType}');
          debugPrint('🔍 PincodeService: PostOffice data: $postOffice');
          
          if (postOffice is Map) {
            final status = postOffice[AppConstants.keyStatus]?.toString() ?? '';
            debugPrint('🔍 PincodeService: Status from API: "$status", Expected: "${AppConstants.statusValueSuccess}"');
            
            // Try to get post offices even if status doesn't exactly match
            final postOfficesData = postOffice[AppConstants.keyPostOffice];
            debugPrint('🔍 PincodeService: PostOffice data type: ${postOfficesData?.runtimeType}');
            
            if (postOfficesData != null) {
              // Safely handle postOffices - could be List or other type
              List postOffices = [];
              if (postOfficesData is List) {
                postOffices = postOfficesData;
              } else {
                debugPrint('⚠️ ${AppConstants.errorFetchingPincodeData}: PostOffice is not a List, type: ${postOfficesData.runtimeType}');
                return null;
              }
              
              debugPrint('🔍 PincodeService: Post offices count: ${postOffices.length}');
              
              if (postOffices.isNotEmpty) {
                final firstOffice = postOffices[0];
                
                if (firstOffice is! Map) {
                  debugPrint('⚠️ ${AppConstants.errorFetchingPincodeData}: First office is not a Map, type: ${firstOffice.runtimeType}');
                  return null;
                }
                
                debugPrint('🔍 PincodeService: First office data: $firstOffice');
                
                // Extract ALL unique city names from post offices
                // API returns 'Name' with capital N, not 'name'
                final Set<String> citySet = {};
                for (var office in postOffices) {
                  if (office is Map) {
                    final cityName = office[AppConstants.keyNameCaps]?.toString() ?? '';
                    if (cityName.isNotEmpty) {
                      citySet.add(cityName);
                    }
                  }
                }
                
                debugPrint('🔍 PincodeService: Extracted cities: $citySet');
                
                // Only return if we have at least one city
                if (citySet.isNotEmpty) {
                  final district = firstOffice[AppConstants.keyDistrictCaps]?.toString() ?? '';
                  final state = firstOffice[AppConstants.keyStateCaps]?.toString() ?? '';
                  debugPrint('✅ PincodeService: Returning - Cities: $citySet, District: $district, State: $state');
                  
                  return {
                    AppConstants.keyCities: citySet.toList(), // List of ALL cities
                    AppConstants.keyDistrict: district,
                    AppConstants.keyState: state,
                  };
                } else {
                  debugPrint('⚠️ PincodeService: No cities found in post offices');
                }
              } else {
                debugPrint('⚠️ PincodeService: Post offices list is empty');
              }
            } else {
              debugPrint('⚠️ PincodeService: PostOffice key is null in response');
            }
          } else {
            debugPrint('⚠️ PincodeService: First element is not a Map');
          }
        } else {
          debugPrint('⚠️ PincodeService: Response is not a List or is empty');
        }
      } else {
        debugPrint('⚠️ PincodeService: HTTP error, status code: ${response.statusCode}');
      }
      
      return null;
    } catch (e) {
      debugPrint('${AppConstants.errorFetchingPincodeData}: $e');
      return null;
    }
  }
  
  /// Validate pincode format
  static bool isValidPincode(String pincode) {
    return RegExp(r'^[0-9]{6}$').hasMatch(pincode);
  }
  
  /// Get common Indian states for fallback
  static List<String> getIndianStates() {
    return [
      'Andhra Pradesh',
      'Arunachal Pradesh',
      'Assam',
      'Bihar',
      'Chhattisgarh',
      'Goa',
      'Gujarat',
      'Haryana',
      'Himachal Pradesh',
      'Jharkhand',
      'Karnataka',
      'Kerala',
      'Madhya Pradesh',
      'Maharashtra',
      'Manipur',
      'Meghalaya',
      'Mizoram',
      'Nagaland',
      'Odisha',
      'Punjab',
      'Rajasthan',
      'Sikkim',
      'Tamil Nadu',
      'Telangana',
      'Tripura',
      'Uttar Pradesh',
      'Uttarakhand',
      'West Bengal',
      'Andaman and Nicobar Islands',
      'Chandigarh',
      'Dadra and Nagar Haveli',
      'Daman and Diu',
      'Delhi',
      'Jammu and Kashmir',
      'Ladakh',
      'Lakshadweep',
      'Puducherry'
    ];
  }
}
