import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../app_routes.dart';
import '../../utils/constants.dart';

class ParentProfileViewPage extends StatelessWidget {
  final Map<String, dynamic>? profileData;

  const ParentProfileViewPage({super.key, this.profileData});

  Map<String, dynamic> get _profileData {
    if (profileData == null) return const <String, dynamic>{};
    final data = profileData![AppConstants.keyData];
    if (data is Map<String, dynamic>) {
      return data;
    }
    return profileData!;
  }

  Map<String, dynamic> get _dashboardData {
    final dashboard = profileData?['dashboard'];
    if (dashboard is Map<String, dynamic>) {
      return dashboard;
    }
    return const <String, dynamic>{};
  }

  String _readValue(List<String> keys) {
    final sources = <Map<String, dynamic>>[
      _profileData,
      _dashboardData,
    ];

    for (final source in sources) {
      final result = _findInMap(source, keys);
      if (result != null && result.isNotEmpty) {
        return result;
      }
    }
    return '';
  }

  String? _findInMap(Map<String, dynamic> map, List<String> keys) {
    for (final key in keys) {
      final value = map[key];
      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
    }
    for (final entry in map.entries) {
      final value = entry.value;
      if (value is Map<String, dynamic>) {
        final nested = _findInMap(value, keys);
        if (nested != null && nested.isNotEmpty) {
          return nested;
        }
      } else if (value is List) {
        for (final item in value) {
          if (item is Map<String, dynamic>) {
            final nested = _findInMap(item, keys);
            if (nested != null && nested.isNotEmpty) {
              return nested;
            }
          }
        }
      }
    }
    return null;
  }

  Uint8List? _decodeImage(String? base64String) {
    if (base64String == null || base64String.isEmpty) return null;
    try {
      final sanitized = base64String.contains(',')
          ? base64String.split(',').last
          : base64String;
      return base64Decode(sanitized);
    } catch (e) {
      debugPrint('Error decoding parent profile image: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final parentName = _readValue([
      AppConstants.keyParentName,
      AppConstants.keyName,
      AppConstants.keyUserName,
    ]);
    final studentName = _readValue([
      AppConstants.keyStudentName,
    ]);
    final schoolName = _readValue([
      AppConstants.keySchoolName,
    ]);
    final email = _readValue([
      AppConstants.keyEmail,
    ]);
    final contact = _readValue([
      AppConstants.keyContactNumber,
      'phone',
    ]);

    final photoString = _readValue([
      AppConstants.keyStudentPhoto,
      'parentPhoto',
    ]);
    final photoBytes = _decodeImage(photoString.isNotEmpty ? photoString : null);

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConstants.labelProfileInformation),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.parentPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: AppColors.parentPrimaryColor.withValues(alpha: 0.15),
                    backgroundImage: photoBytes != null ? MemoryImage(photoBytes) : null,
                    child: photoBytes == null
                        ? const Icon(Icons.person, size: 40, color: AppColors.parentPrimaryColor)
                        : null,
                  ),
                  const SizedBox(height: AppSizes.parentSpacingSM),
                  Text(
                    studentName.isNotEmpty ? studentName : AppConstants.labelStudent,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  if (parentName.isNotEmpty)
                    Text(
                      parentName,
                      style: const TextStyle(color: AppColors.textSecondary),
                      textAlign: TextAlign.center,
                    ),
                  if (schoolName.isNotEmpty)
                    Text(
                      schoolName,
                      style: const TextStyle(color: AppColors.textSecondary),
                      textAlign: TextAlign.center,
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppSizes.parentSpacingMD),
            Card(
              elevation: AppSizes.parentProfileCardElevation,
              child: Padding(
                padding: const EdgeInsets.all(AppSizes.parentPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      AppConstants.labelProfileInformation,
                      style: TextStyle(
                        fontSize: AppSizes.parentProfileTitleFontSize,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppSizes.parentSpacingSM),
                    _InfoRow(
                      icon: Icons.badge,
                      label: AppConstants.labelStudent,
                      value: studentName,
                    ),
                    _InfoRow(
                      icon: Icons.person,
                      label: AppConstants.labelParent,
                      value: parentName,
                    ),
                    _InfoRow(
                      icon: Icons.school,
                      label: AppConstants.labelSchool,
                      value: schoolName,
                    ),
                    _InfoRow(
                      icon: Icons.email,
                      label: AppConstants.labelEmail,
                      value: email,
                    ),
                    _InfoRow(
                      icon: Icons.phone,
                      label: AppConstants.labelContactNumber,
                      value: contact,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSizes.parentSpacingMD),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  final args = <String, dynamic>{
                    AppConstants.keyData: _profileData,
                    if (_dashboardData.isNotEmpty) 'dashboard': _dashboardData,
                  };
                  Navigator.pushNamed(
                    context,
                    AppRoutes.parentProfileUpdate,
                    arguments: args,
                  );
                },
                icon: const Icon(Icons.edit),
                label: const Text(AppConstants.labelUpdateProfile),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final displayValue = value.isNotEmpty ? value : AppConstants.labelNA;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSizes.parentSpacingXS),
      child: Row(
        children: [
          Icon(icon, color: AppColors.parentPrimaryColor),
          const SizedBox(width: AppSizes.parentSpacingSM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(displayValue),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

