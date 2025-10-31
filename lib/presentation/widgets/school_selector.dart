import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/vehicle_owner_service.dart';
import '../../utils/constants.dart';

class SchoolSelector extends StatefulWidget {
  final Function(int? schoolId, String? schoolName) onSchoolSelected;
  final int? currentSchoolId;

  const SchoolSelector({
    super.key,
    required this.onSchoolSelected,
    this.currentSchoolId,
  });

  @override
  State<SchoolSelector> createState() => _SchoolSelectorState();
}

class _SchoolSelectorState extends State<SchoolSelector> {
  final VehicleOwnerService _vehicleOwnerService = VehicleOwnerService();
  List<Map<String, dynamic>> _schools = [];
  bool _isLoading = false;
  int? _selectedSchoolId;
  String? _selectedSchoolName;

  @override
  void initState() {
    super.initState();
    _selectedSchoolId = widget.currentSchoolId;
    _loadSchools();
  }

  Future<void> _loadSchools() async {
    setState(() => _isLoading = true);
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt(AppConstants.keyUserId);
      
      if (userId == null) {
        _showError(AppConstants.errorUserNotFound);
        return;
      }

      // Get vehicle owner by user ID
      final ownerResponse = await _vehicleOwnerService.getOwnerByUserId(userId);
      
      if (ownerResponse[AppConstants.keySuccess] == true) {
        final ownerData = ownerResponse[AppConstants.keyData];
        final ownerId = ownerData[AppConstants.keyOwnerId];
        
        // Get associated schools
        final schoolsResponse = await _vehicleOwnerService.getAssociatedSchools(ownerId);
        
        if (schoolsResponse[AppConstants.keySuccess] == true) {
          final schoolsData = schoolsResponse[AppConstants.keyData];
          setState(() {
            _schools = List<Map<String, dynamic>>.from(
              schoolsData[AppConstants.keySchools] ?? [],
            );
            if (_schools.isNotEmpty && _selectedSchoolId == null) {
              _selectedSchoolId = _schools.first[AppConstants.keySchoolId];
              _selectedSchoolName = _schools.first[AppConstants.keySchoolName];
              widget.onSchoolSelected(_selectedSchoolId, _selectedSchoolName);
            }
          });
        } else {
          _showError(
            '${AppConstants.errorFailedToLoadSchools}${schoolsResponse[AppConstants.keyMessage]}',
          );
        }
      } else {
        _showError(
          '${AppConstants.errorFailedToLoadOwnerData}${ownerResponse[AppConstants.keyMessage]}',
        );
      }
    } catch (e) {
      _showError('${AppConstants.errorLoadingSchools}$e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppColors.schoolSelectorErrorColor,
        ),
      );
    }
  }

  void _showSchoolSelector() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSizes.schoolSelectorModalRadius),
        ),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(AppSizes.schoolSelectorModalPadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  AppConstants.labelSelectSchool,
                  style: TextStyle(
                    fontSize: AppSizes.schoolSelectorHeaderFontSize,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.schoolSelectorSpacingMD),
            
            // Schools List
            if (_schools.isEmpty)
              const Padding(
                padding: EdgeInsets.all(AppSizes.schoolSelectorModalPadding),
                child: Center(
                  child: Text(
                    AppConstants.labelNoSchoolsAssociated,
                    style: TextStyle(
                      color: AppColors.schoolSelectorEmptyTextColor,
                    ),
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                itemCount: _schools.length,
                itemBuilder: (context, index) {
                  final school = _schools[index];
                  final schoolId = school[AppConstants.keySchoolId];
                  final schoolName = school[AppConstants.keySchoolName];
                  final schoolAddress = school[AppConstants.keyAddress];
                  final isSelected = _selectedSchoolId == schoolId;
                  
                  return Card(
                    margin: const EdgeInsets.only(
                      bottom: AppSizes.schoolSelectorSpacingSM,
                    ),
                    color: isSelected
                        ? AppColors.schoolSelectorPrimaryColor.shade50
                        : null,
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: isSelected
                            ? AppColors.schoolSelectorSelectedColor
                            : AppColors.schoolSelectorUnselectedColor,
                        child: Text(
                          schoolName.substring(
                            AppSizes.schoolSelectorNameSubstringStart,
                            AppSizes.schoolSelectorNameSubstringEnd,
                          ).toUpperCase(),
                          style: const TextStyle(
                            color: AppColors.schoolSelectorTextWhite,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Text(
                        schoolName,
                        style: TextStyle(
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: isSelected
                              ? AppColors.schoolSelectorSelectedColor
                              : AppColors.schoolSelectorTextBlack,
                        ),
                      ),
                      subtitle: Text(schoolAddress ?? ''),
                      trailing: isSelected
                          ? const Icon(
                              Icons.check_circle,
                              color: AppColors.schoolSelectorSelectedColor,
                            )
                          : null,
                      onTap: () {
                        setState(() {
                          _selectedSchoolId = schoolId;
                          _selectedSchoolName = schoolName;
                        });
                        
                        // Save to SharedPreferences
                        SharedPreferences.getInstance().then((prefs) {
                          prefs.setInt(
                            AppConstants.keyCurrentSchoolId,
                            schoolId,
                          );
                          prefs.setString(
                            AppConstants.keyCurrentSchoolName,
                            schoolName,
                          );
                        });
                        
                        widget.onSchoolSelected(schoolId, schoolName);
                        Navigator.pop(context);
                      },
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox(
        width: AppSizes.schoolSelectorLoadingSize,
        height: AppSizes.schoolSelectorLoadingSize,
        child: CircularProgressIndicator(
          strokeWidth: AppSizes.schoolSelectorLoadingStroke,
        ),
      );
    }

    if (_schools.isEmpty) {
      return const Text(
        AppConstants.labelNoSchools,
        style: TextStyle(
          color: AppColors.schoolSelectorNoSchoolsColor,
          fontSize: AppSizes.schoolSelectorNoSchoolsFontSize,
          fontWeight: FontWeight.w500,
        ),
      );
    }

    return GestureDetector(
      onTap: _showSchoolSelector,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.schoolSelectorContainerPaddingH,
          vertical: AppSizes.schoolSelectorContainerPaddingV,
        ),
        decoration: BoxDecoration(
          color: AppColors.schoolSelectorPrimaryColor.shade50,
          borderRadius: BorderRadius.circular(
            AppSizes.schoolSelectorContainerRadius,
          ),
          border: Border.all(
            color: AppColors.schoolSelectorPrimaryColor.shade200,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.school,
              size: AppSizes.schoolSelectorIconSize,
              color: AppColors.schoolSelectorPrimaryColor.shade700,
            ),
            const SizedBox(width: AppSizes.schoolSelectorSpacingXS),
            Flexible(
              child: Text(
                _selectedSchoolName ?? AppConstants.labelSelectSchool,
                style: TextStyle(
                  color: AppColors.schoolSelectorPrimaryColor.shade700,
                  fontSize: AppSizes.schoolSelectorTextFontSize,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: AppSizes.schoolSelectorSpacingXXS),
            Icon(
              Icons.arrow_drop_down,
              size: AppSizes.schoolSelectorIconSize,
              color: AppColors.schoolSelectorPrimaryColor.shade700,
            ),
          ],
        ),
      ),
    );
  }
}