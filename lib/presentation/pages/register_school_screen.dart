import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../utils/constants.dart';
import '../../app_routes.dart';
import '../../data/models/school_request.dart';
import '../../services/school_service.dart';
import '../../services/pincode_service.dart';

class RegisterSchoolScreen extends StatefulWidget {
  const RegisterSchoolScreen({super.key});

  @override
  State<RegisterSchoolScreen> createState() => _RegisterSchoolScreenState();
}

class _RegisterSchoolScreenState extends State<RegisterSchoolScreen> {
  final _formKey = GlobalKey<FormState>();
  final _service = SchoolService();
  bool _isLoading = false;

  // Controllers
  final TextEditingController _schoolName = TextEditingController();
  final TextEditingController _registrationNumber = TextEditingController();
  final TextEditingController _address = TextEditingController();
  final TextEditingController _city = TextEditingController();
  final TextEditingController _district = TextEditingController();
  final TextEditingController _state = TextEditingController();
  final TextEditingController _pincode = TextEditingController();
  final TextEditingController _contactNo = TextEditingController();
  final TextEditingController _email = TextEditingController();

  // Dropdown values
  String? _schoolType;
  String? _affiliationBoard;

  // Image
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  // Pincode auto-fill state
  bool _isLoadingPincode = false;
  bool _isPincodeAutoFilled = false;
  
  // City dropdown state
  List<String> _availableCities = [];
  String? _selectedCity;

  Future<void> _pickImage(ImageSource source) async {
    final picked = await _picker.pickImage(source: source);
    if (picked != null) {
      setState(() {
        _selectedImage = File(picked.path);
      });
    }
  }

  /// Auto-fill city, district, state based on pincode
  Future<void> _autoFillLocationFromPincode(String pincode) async {
    if (!PincodeService.isValidPincode(pincode)) {
      setState(() {
        _isPincodeAutoFilled = false;
        _isLoadingPincode = false;
        _availableCities = [];
        _selectedCity = null;
      });
      return;
    }

    setState(() {
      _isLoadingPincode = true;
    });

    try {
      debugPrint('🔍 Fetching location for pincode: $pincode');
      final locationData = await PincodeService.getLocationByPincode(pincode);
      debugPrint('🔍 Location data received: $locationData');
      
      if (locationData != null) {
        // Safely extract cities list with proper type checking
        List<String> cities = [];
        final citiesData = locationData[AppConstants.keyCities];
        debugPrint('🔍 Cities data from response: $citiesData (type: ${citiesData.runtimeType})');
        
        if (citiesData != null) {
          if (citiesData is List) {
            cities = citiesData.map((e) => e?.toString() ?? '').where((e) => e.isNotEmpty).toList().cast<String>();
          } else if (citiesData is Set) {
            cities = citiesData.map((e) => e?.toString() ?? '').where((e) => e.isNotEmpty).toList().cast<String>();
          } else {
            // Try to convert any other type
            try {
              final converted = List<String>.from(citiesData.map((e) => e.toString()));
              cities = converted.where((e) => e.isNotEmpty).toList();
            } catch (e) {
              debugPrint('⚠️ Failed to convert cities data: $e');
            }
          }
        }
        
        debugPrint('🔍 Extracted cities list: $cities (count: ${cities.length})');
        
        // Only auto-fill if we have valid city data
        if (cities.isNotEmpty) {
          setState(() {
            _availableCities = cities;
            _selectedCity = cities[0]; // Auto-select first city
            _district.text = locationData[AppConstants.keyDistrict] ?? '';
            _state.text = locationData[AppConstants.keyState] ?? '';
            _isPincodeAutoFilled = true;
          });
          
          // Show success message
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  cities.length > 1
                    ? AppConstants.msgFoundLocationsSelect.replaceFirst('%d', cities.length.toString())
                    : '${AppConstants.msgLocationAutoFilledPrefix}${cities[0]}, ${locationData[AppConstants.keyDistrict] ?? ''}, ${locationData[AppConstants.keyState] ?? ''}'
                ),
                backgroundColor: cities.length > 1 ? Colors.blue : Colors.green,
                duration: Duration(seconds: cities.length > 1 ? AppSizes.registerSchoolSnackBarDuration : AppSizes.registerSchoolSnackBarDurationShort),
              ),
            );
          }
        } else {
          // No cities found in response
          setState(() {
            _isPincodeAutoFilled = false;
            _availableCities = [];
            _selectedCity = null;
          });
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(AppConstants.msgPincodeNotFoundManual),
                backgroundColor: Colors.orange,
                duration: Duration(seconds: AppSizes.registerSchoolSnackBarDurationShort),
              ),
            );
          }
        }
      } else {
        setState(() {
          _isPincodeAutoFilled = false;
          _availableCities = [];
          _selectedCity = null;
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(AppConstants.msgPincodeNotFoundManual),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: AppSizes.registerSchoolSnackBarDurationShort),
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        _isPincodeAutoFilled = false;
        _availableCities = [];
        _selectedCity = null;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppConstants.msgErrorFetchingLocation}$e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: AppSizes.registerSchoolSnackBarDurationShort),
          ),
        );
      }
    } finally {
      setState(() {
        _isLoadingPincode = false;
      });
    }
  }

  /// Allow manual editing of location fields
  void _enableManualEdit() {
    setState(() {
      _isPincodeAutoFilled = false;
      _availableCities = [];
      _selectedCity = null;
      // Clear the city text field when enabling manual edit
      _city.clear();
    });
  }

  @override
  void dispose() {
    // Dispose all controllers to prevent memory leaks
    _schoolName.dispose();
    _registrationNumber.dispose();
    _address.dispose();
    _city.dispose();
    _district.dispose();
    _state.dispose();
    _pincode.dispose();
    _contactNo.dispose();
    _email.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      debugPrint('🔹 Starting school registration for: ${_schoolName.text}');
      
      String? base64Photo;
      if (_selectedImage != null) {
        base64Photo = base64Encode(await _selectedImage!.readAsBytes());
        debugPrint('🔹 Photo encoded, size: ${base64Photo.length} characters');
      }

      final request = SchoolRequest(
        schoolName: _schoolName.text,
        schoolType: _schoolType!,
        affiliationBoard: _affiliationBoard!,
        registrationNumber: _registrationNumber.text,
        address: _address.text,
        city: _selectedCity ?? _city.text, // Use selected city from dropdown or manual input
        district: _district.text,
        state: _state.text,
        pincode: _pincode.text,
        contactNo: _contactNo.text,
        email: _email.text,
        schoolPhoto: base64Photo,
        createdBy: AppConstants.registerSchoolCreatedBy,
      );

      debugPrint('🔹 Sending registration request to backend...');
      final response = await _service.registerSchool(request);
      
      debugPrint('🔹 Registration response: $response');
      
      if (mounted) {
        if (response[AppConstants.keySuccess] == true) {
          debugPrint('✅ School registered successfully!');
          _showSuccessDialog();
        } else {
          debugPrint('❌ Registration failed: ${response[AppConstants.keyMessage]}');
          _showErrorSnackBar(response[AppConstants.keyMessage] ?? AppConstants.msgRegistrationFailed);
        }
      }
    } catch (e) {
      debugPrint('❌ Exception during registration: $e');
      if (mounted) {
        String errorMessage = AppConstants.msgFailedToRegisterSchool;
        
        // Extract specific error message if available
        if (e.toString().contains(AppConstants.msgFailedToRegisterSchool)) {
          errorMessage = e.toString().replaceAll('${AppConstants.labelException}: ', '');
        } else {
          errorMessage = '${AppConstants.labelError}: ${e.toString()}';
        }
        
        _showErrorSnackBar(errorMessage);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text(AppConstants.msgRegistrationSuccessful),
        content: const Text(AppConstants.msgSchoolRegisteredSuccess),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).pushReplacementNamed(AppRoutes.login);
            },
            child: const Text(AppConstants.labelGoToLogin),
          ),
        ],
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: AppSizes.registerSchoolSnackBarDuration),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppConstants.labelSchoolRegistration)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.registerSchoolPadding),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // ---------- Form Fields ----------
              TextFormField(
                controller: _schoolName,
                decoration: const InputDecoration(
                  labelText: AppConstants.labelSchoolName,
                  hintText: AppConstants.hintSchoolName,
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return AppConstants.msgEnterSchoolName;
                  if (v.length < AppSizes.registerSchoolNameMinLength) return AppConstants.msgSchoolNameMinChars;
                  if (v.length > AppSizes.registerSchoolNameMaxLength) return AppConstants.msgSchoolNameMaxChars;
                  return null;
                },
              ),

              DropdownButtonFormField<String>(
                value: _schoolType,
                items: [
                  AppConstants.schoolTypePrivate,
                  AppConstants.schoolTypeGovernment,
                  AppConstants.schoolTypeInternational
                ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                onChanged: (val) => setState(() => _schoolType = val),
                decoration: const InputDecoration(labelText: AppConstants.labelSchoolType),
                validator: (v) => v == null ? AppConstants.msgSelectSchoolType : null,
              ),

              DropdownButtonFormField<String>(
                value: _affiliationBoard,
                items: [
                  AppConstants.affiliationBoardCBSE,
                  AppConstants.affiliationBoardICSE,
                  AppConstants.affiliationBoardStateBoard
                ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                onChanged: (val) => setState(() => _affiliationBoard = val),
                decoration: const InputDecoration(labelText: AppConstants.labelAffiliationBoard),
                validator: (v) => v == null ? AppConstants.msgSelectAffiliationBoard : null,
              ),

              TextFormField(
                controller: _registrationNumber,
                decoration: const InputDecoration(
                  labelText: AppConstants.labelRegistrationNumber,
                  hintText: AppConstants.hintRegistrationNumber,
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return AppConstants.msgEnterRegistrationNumber;
                  if (v.length < AppSizes.registerSchoolRegNumberMinLength) return AppConstants.msgRegistrationNumberMinChars;
                  if (v.length > AppSizes.registerSchoolRegNumberMaxLength) return AppConstants.msgRegistrationNumberMaxChars;
                  return null;
                },
              ),

              TextFormField(
                controller: _pincode,
                decoration: InputDecoration(
                  labelText: AppConstants.labelPincode,
                  hintText: AppConstants.hintPincode6Digit,
                  suffixIcon: _isLoadingPincode 
                    ? const SizedBox(
                        width: AppSizes.registerSchoolLoaderSize,
                        height: AppSizes.registerSchoolLoaderSize,
                        child: Padding(
                          padding: EdgeInsets.all(AppSizes.registerSchoolLoaderPadding),
                          child: CircularProgressIndicator(strokeWidth: AppSizes.registerSchoolLoaderStroke),
                        ),
                      )
                    : _isPincodeAutoFilled
                        ? const Icon(Icons.check_circle, color: Colors.green)
                        : null,
                ),
                keyboardType: TextInputType.number,
                maxLength: AppSizes.registerSchoolPincodeLength,
                onChanged: (value) {
                  // Reset auto-fill status when pincode changes
                  if (_isPincodeAutoFilled) {
                    setState(() {
                      _isPincodeAutoFilled = false;
                    });
                  }
                  
                  // Auto-fill when 6 digits are entered
                  if (value.length == AppSizes.registerSchoolPincodeLength) {
                    _autoFillLocationFromPincode(value);
                  }
                },
                validator: (v) {
                  if (v == null || v.isEmpty) return AppConstants.msgEnterPincode;
                  if (v.length != AppSizes.registerSchoolPincodeLength) return AppConstants.msgPincodeMustBe6Digits;
                  if (!RegExp(r'^[0-9]{6}$').hasMatch(v)) return AppConstants.msgPincodeOnlyNumbers;
                  return null;
                },
              ),

              // City Dropdown (when auto-filled) or Text Field (manual entry)
              if (_isPincodeAutoFilled && _availableCities.isNotEmpty)
                DropdownButtonFormField<String>(
                  value: _selectedCity,
                  decoration: InputDecoration(
                    labelText: AppConstants.labelCity,
                    suffixIcon: const Icon(Icons.auto_awesome, color: Colors.blue, size: AppSizes.registerSchoolInfoIconSize2),
                    helperText: _availableCities.length > 1 
                      ? '${_availableCities.length}${AppConstants.helperMultipleLocations}'
                      : null,
                  ),
                  items: _availableCities
                      .map((city) => DropdownMenuItem(
                            value: city,
                            child: Text(city),
                          ))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedCity = value;
                    });
                  },
                  validator: (v) => v == null || v.isEmpty ? AppConstants.msgSelectCity : null,
                )
              else
                TextFormField(
                  controller: _city,
                  decoration: const InputDecoration(
                    labelText: AppConstants.labelCity,
                    hintText: AppConstants.hintCityName,
                  ),
                  validator: (v) => v!.isEmpty ? AppConstants.msgEnterCity : null,
                  onChanged: (value) {
                    // Clear selected city when manually editing
                    setState(() {
                      _selectedCity = null;
                    });
                  },
                ),

              TextFormField(
                controller: _district,
                decoration: InputDecoration(
                  labelText: AppConstants.labelDistrict,
                  suffixIcon: _isPincodeAutoFilled 
                    ? const Icon(Icons.auto_awesome, color: Colors.blue, size: AppSizes.registerSchoolInfoIconSize2)
                    : null,
                ),
                readOnly: _isPincodeAutoFilled,
                validator: (v) => v!.isEmpty ? AppConstants.msgEnterDistrict : null,
              ),

              TextFormField(
                controller: _state,
                decoration: InputDecoration(
                  labelText: AppConstants.labelState,
                  suffixIcon: _isPincodeAutoFilled 
                    ? const Icon(Icons.auto_awesome, color: Colors.blue, size: AppSizes.registerSchoolInfoIconSize2)
                    : null,
                ),
                readOnly: _isPincodeAutoFilled,
                validator: (v) => v!.isEmpty ? AppConstants.msgEnterState : null,
              ),

              // Manual Edit Button (shown when auto-filled)
              if (_isPincodeAutoFilled)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSizes.registerSchoolInfoPadding),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: Colors.blue, size: AppSizes.registerSchoolInfoIconSize),
                      const SizedBox(width: AppSizes.registerSchoolInfoPadding),
                      const Expanded(
                        child: Text(
                          AppConstants.infoLocationAutoFilled,
                          style: TextStyle(color: Colors.blue, fontSize: AppSizes.registerSchoolInfoFontSize),
                        ),
                      ),
                      TextButton(
                        onPressed: _enableManualEdit,
                        child: const Text(AppConstants.labelEditManually, style: TextStyle(fontSize: AppSizes.registerSchoolInfoFontSize)),
                      ),
                    ],
                  ),
                ),

              TextFormField(
                controller: _address,
                decoration: const InputDecoration(labelText: AppConstants.labelAddress),
                validator: (v) => v!.isEmpty ? AppConstants.msgEnterAddress : null,
              ),

              TextFormField(
                controller: _contactNo,
                decoration: const InputDecoration(
                  labelText: AppConstants.labelContactNumber,
                  hintText: AppConstants.hintMobileNumber,
                ),
                keyboardType: TextInputType.phone,
                maxLength: AppSizes.registerSchoolContactLength,
                validator: (v) {
                  if (v == null || v.isEmpty) return AppConstants.msgEnterContactNumber;
                  if (v.length != AppSizes.registerSchoolContactLength) return AppConstants.msgContactNumberMustBe10DigitsOnly;
                  if (!RegExp(r'^[0-9]{10}$').hasMatch(v)) return AppConstants.msgContactNumberOnlyNumbers;
                  return null;
                },
              ),

              TextFormField(
                controller: _email,
                decoration: const InputDecoration(
                  labelText: AppConstants.labelEmail,
                  hintText: AppConstants.hintSchoolEmailAddress,
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (v) {
                  if (v == null || v.isEmpty) return AppConstants.msgEnterEmailAddress;
                  if (v.length > AppSizes.registerSchoolEmailMaxLength) return AppConstants.msgEmailMustNotExceed150Chars;
                  if (!RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(v)) {
                    return AppConstants.msgPleaseEnterValidEmailAddress;
                  }
                  return null;
                },
              ),

              const SizedBox(height: AppSizes.registerSchoolSpacingLG),

              // ---------- Photo Section (Bottom) ----------
              Column(
                children: [
                  GestureDetector(
                    onTap: () => _pickImage(ImageSource.gallery),
                    child: CircleAvatar(
                      radius: AppSizes.registerSchoolAvatarRadius,
                      backgroundColor: Colors.grey[300],
                      backgroundImage:
                          _selectedImage != null ? FileImage(_selectedImage!) : null,
                      child: _selectedImage == null
                          ? const Icon(Icons.add_a_photo,
                              size: AppSizes.registerSchoolIconSize, color: Colors.black54)
                          : null,
                    ),
                  ),
                  const SizedBox(height: AppSizes.registerSchoolSpacing),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => _pickImage(ImageSource.gallery),
                        icon: const Icon(Icons.photo),
                        label: const Text(AppConstants.labelGallery),
                      ),
                      const SizedBox(width: AppSizes.registerSchoolSpacing),
                      ElevatedButton.icon(
                        onPressed: () => _pickImage(ImageSource.camera),
                        icon: const Icon(Icons.camera_alt),
                        label: const Text(AppConstants.labelCamera),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: AppSizes.registerSchoolSpacingLG),

              // ---------- Submit ----------
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitForm,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: AppSizes.registerSchoolButtonPadding),
                  ),
                  child: _isLoading
                      ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: AppSizes.registerSchoolLoaderSize,
                              height: AppSizes.registerSchoolLoaderSize,
                              child: CircularProgressIndicator(strokeWidth: AppSizes.registerSchoolLoaderStroke),
                            ),
                            SizedBox(width: AppSizes.registerSchoolSpacing),
                            Text(AppConstants.labelRegistering),
                          ],
                        )
                      : const Text(AppConstants.labelRegisterSchool),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
