import 'dart:convert';
import 'package:http/http.dart' as http;

class PincodeService {
  // Using Indian Postal API for pincode lookup
  static const String _baseUrl = 'https://api.postalpincode.in/pincode';
  
  /// Get location details by pincode
  /// Returns: {city, district, state} or null if not found
  static Future<Map<String, String>?> getLocationByPincode(String pincode) async {
    if (pincode.length != 6) return null;
    
    try {
      final url = Uri.parse('$_baseUrl/$pincode');
      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data is List && data.isNotEmpty) {
          final postOffice = data[0];
          
          if (postOffice['Status'] == 'Success' && postOffice['PostOffice'] != null) {
            final postOffices = postOffice['PostOffice'] as List;
            
            if (postOffices.isNotEmpty) {
              final firstOffice = postOffices[0];
              
              return {
                'city': firstOffice['Name'] ?? '',
                'district': firstOffice['District'] ?? '',
                'state': firstOffice['State'] ?? '',
              };
            }
          }
        }
      }
      
      return null;
    } catch (e) {
      print('Error fetching pincode data: $e');
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
