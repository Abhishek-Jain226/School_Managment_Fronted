# 🎯 CONSTANTS MIGRATION MASTER PLAN

## 📊 **PROJECT STATISTICS**

### Total Files to Migrate: **150 Dart files**

#### Breakdown by Category:
1. **🎨 Presentation Pages**: 56 files
2. **🧩 Presentation Widgets**: 5 files  
3. **🔄 BLoC Files**: 22 files
4. **🌐 Services**: 21 files
5. **📦 Data Models**: 33 files
6. **⚙️ Config**: 2 files
7. **🛠️ Utils**: 6 files
8. **📍 Root**: 5 files

---

## 📋 **MIGRATION STRATEGY**

### Phase 1: Services (21 files) - **PRIORITY HIGH**
Services use the most hardcoded URLs, keys, and messages.

**Files:**
1. `services/auth_service.dart` ✅ (ALREADY MIGRATED)
2. `services/trip_service.dart`
3. `services/vehicle_service.dart`
4. `services/driver_service.dart`
5. `services/school_service.dart`
6. `services/pincode_service.dart`
7. `services/app_admin_service.dart`
8. `services/vehicle_owner_service.dart`
9. `services/parent_service.dart`
10. `services/report_service.dart`
11. `services/gate_staff_service.dart`
12. `services/excel_parser_service.dart`
13. `services/bulk_student_import_service.dart`
14. `services/pending_service.dart`
15. `services/student_service.dart`
16. `services/master_data_service.dart`
17. `services/trip_student_service.dart`
18. `services/role_service.dart`
19. `services/websocket_notification_service.dart`
20. `services/base_http_service.dart`
21. `services/route_guard.dart` (utils, but service-like)

### Phase 2: Presentation Pages (56 files) - **PRIORITY HIGH**
Pages have the most UI strings, colors, and sizes.

**Dashboard Pages (Priority 1):**
1. `presentation/pages/bloc_app_admin_dashboard.dart`
2. `presentation/pages/bloc_school_admin_dashboard.dart`
3. `presentation/pages/bloc_vehicle_owner_dashboard.dart`
4. `presentation/pages/bloc_driver_dashboard.dart`
5. `presentation/pages/bloc_parent_dashboard.dart`
6. `presentation/pages/gate_staff_dashboard.dart`
7. `presentation/pages/simplified_driver_dashboard.dart`

**Authentication Pages (Priority 2):**
8. `presentation/pages/bloc_login_screen.dart`
9. `presentation/pages/register_school_screen.dart`
10. `presentation/pages/register_vehicle_owner_screen.dart`
11. `presentation/pages/register_driver_screen.dart`
12. `presentation/pages/register_student_screen.dart`
13. `presentation/pages/register_vehicle_screen.dart`
14. `presentation/pages/register_gate_staff.dart`

**Management Pages (Priority 3):**
15. `presentation/pages/simplified_student_management_page.dart`
16. `presentation/pages/student_management_page.dart`
17. `presentation/pages/driver_management_page.dart`
18. `presentation/pages/vehicle_owner_management_page.dart`
19. `presentation/pages/parent_management_page.dart`
20. `presentation/pages/staff_management_page.dart`
21. `presentation/pages/app_admin_school_management.dart`
22. `presentation/pages/section_management_page.dart`
23. `presentation/pages/class_management_page.dart` (if exists)

**Vehicle & Assignment Pages (Priority 4):**
24. `presentation/pages/request_vehicle_assignment_page.dart`
25. `presentation/pages/pending_vehicle_requests_page.dart`
26. `presentation/pages/vehicle_owner_vehicle_management.dart`
27. `presentation/pages/vehicle_owner_driver_management.dart`
28. `presentation/pages/vehicle_owner_driver_assignment.dart`
29. `presentation/pages/vehicle_owner_trip_assignment.dart`
30. `presentation/pages/vehicle_owner_student_trip_assignment.dart`
31. `presentation/pages/register_vehicle_screen.dart`

**Trip & Tracking Pages (Priority 5):**
32. `presentation/pages/trips_list_page.dart`
33. `presentation/pages/create_trip_page.dart`
34. `presentation/pages/vehicle_tracking_page.dart`
35. `presentation/pages/enhanced_vehicle_tracking_page.dart`
36. `presentation/pages/student_attendance_page.dart`

**Profile & Reports Pages (Priority 6):**
37. `presentation/pages/school_profile_page.dart`
38. `presentation/pages/vehicle_owner_profile.dart`
39. `presentation/pages/driver_profile_page.dart`
40. `presentation/pages/driver_reports_page.dart`
41. `presentation/pages/app_admin_profile_page.dart`
42. `presentation/pages/parent_profile_update_page.dart`
43. `presentation/pages/StudentProfilePage.dart`

**Report & History Pages (Priority 7):**
44. `presentation/pages/reports_screen.dart`
45. `presentation/pages/monthly_report_page.dart`
46. `presentation/pages/attendance_history_page.dart`

**Utility Pages (Priority 8):**
47. `presentation/pages/notification_page.dart`
48. `presentation/pages/bulk_student_import_page.dart`
49-56. **Other remaining pages**

### Phase 3: BLoC Files (22 files) - **PRIORITY MEDIUM**
BLoC files have state messages and error strings.

1. `bloc/auth/auth_bloc.dart` - Auth state management
2. `bloc/app_admin/app_admin_bloc.dart`
3. `bloc/school/school_bloc.dart`
4. `bloc/vehicle_owner/vehicle_owner_bloc.dart`
5. `bloc/driver/driver_bloc.dart`
6. `bloc/parent/parent_bloc.dart`
7. `bloc/notification/notification_bloc.dart`
8. `bloc/auth/auth_event.dart`
9. `bloc/auth/auth_state.dart`
10. `bloc/app_admin/app_admin_event.dart`
11. `bloc/app_admin/app_admin_state.dart`
12. `bloc/school/school_event.dart`
13. `bloc/school/school_state.dart`
14. `bloc/vehicle_owner/vehicle_owner_event.dart`
15. `bloc/vehicle_owner/vehicle_owner_state.dart`
16. `bloc/driver/driver_event.dart`
17. `bloc/driver/driver_state.dart`
18. `bloc/parent/parent_event.dart`
19. `bloc/parent/parent_state.dart`
20. `bloc/notification/notification_event.dart`
21. `bloc/notification/notification_state.dart`
22. `bloc/bloc_providers.dart`

### Phase 4: Data Models (33 files) - **PRIORITY LOW**
Models mostly have field names, minimal strings.

1. `data/models/trip.dart`
2. `data/models/trip_status.dart`
3. `data/models/trip_type.dart`
4. `data/models/trip_request.dart`
5. `data/models/driver_dashboard.dart`
6. `data/models/driver_profile.dart`
7. `data/models/driver_reports.dart`
8. `data/models/parent_dashboard.dart`
9. `data/models/parent_notification.dart`
10. `data/models/student_attendance.dart`
11. `data/models/attendance_history.dart`
12. `data/models/monthly_report.dart`
13. `data/models/vehicle_owner_request.dart`
14. `data/models/New_vehicle_request.dart`
15. `data/models/bulk_student_import_request.dart`
16. `data/models/bulk_import_result.dart`
17. `data/models/notification_request.dart`
18. `data/models/websocket_notification.dart`
19. `data/models/role.dart`
20-33. **Other model files**

### Phase 5: Widgets (5 files) - **PRIORITY MEDIUM**
5. `presentation/widgets/notification_badge.dart`
1. `presentation/widgets/notification_card.dart`
2. `presentation/widgets/notification_toast.dart`
3. `presentation/widgets/register_selection_dialog.dart`
4. **Other widget files**

### Phase 6: Config & Utils (13 files) - **PRIORITY LOW**
1. `config/app_config.dart`
2. `config/environment.dart`
3. `utils/constants.dart` ✅ (ALREADY CREATED)
4. `utils/app_logger.dart`
5. `utils/loading_widgets.dart`
6. `utils/error_handler.dart`
7. `utils/state_manager.dart`
8. `app_routes.dart`
9. `app.dart`
10. `config.dart`

---

## 🎯 **WHAT TO REPLACE**

### 1. **Hardcoded URLs** → `AppConstants`
```dart
// ❌ BEFORE
final url = "http://10.245.176.208:9001/api/vehicles";

// ✅ AFTER
final url = "${AppConstants.vehiclesEndpoint}";
```

### 2. **SharedPreferences Keys** → `AppConstants.key*`
```dart
// ❌ BEFORE
prefs.getString("jwt_token");
prefs.getInt("schoolId");

// ✅ AFTER
prefs.getString(AppConstants.keyJwtToken);
prefs.getInt(AppConstants.keySchoolId);
```

### 3. **Role Strings** → `AppConstants.role*`
```dart
// ❌ BEFORE
if (role == "DRIVER") { }

// ✅ AFTER
if (role == AppConstants.roleDriver) { }
```

### 4. **Status Strings** → `AppConstants.status*`
```dart
// ❌ BEFORE
status: "PENDING"

// ✅ AFTER
status: AppConstants.statusPending
```

### 5. **Colors** → `AppColors`
```dart
// ❌ BEFORE
color: Colors.blue
backgroundColor: Color(0xFF2196F3)

// ✅ AFTER
color: AppColors.primaryColor
backgroundColor: AppColors.cardBackground
```

### 6. **Sizes** → `AppSizes`
```dart
// ❌ BEFORE
padding: EdgeInsets.all(16.0)
fontSize: 14.0
borderRadius: BorderRadius.circular(8.0)

// ✅ AFTER
padding: EdgeInsets.all(AppSizes.paddingMD)
fontSize: AppSizes.textMD
borderRadius: BorderRadius.circular(AppSizes.radiusSM)
```

### 7. **Durations** → `AppDurations`
```dart
// ❌ BEFORE
duration: Duration(milliseconds: 300)
Duration(seconds: 3)

// ✅ AFTER
duration: AppDurations.normal
AppDurations.snackbarShort
```

### 8. **Common Strings** → `AppConstants`
```dart
// ❌ BEFORE
Text("Loading...")
"Success"
"Error"
"Are you sure you want to logout?"

// ✅ AFTER
Text(AppConstants.msgLoading)
AppConstants.msgSuccess
AppConstants.msgError
AppConstants.msgConfirmLogout
```

---

## ✅ **MIGRATION CHECKLIST**

### For Each File:
1. ✅ Read the entire file
2. ✅ Identify all hardcoded values:
   - URLs
   - API endpoints
   - SharedPreferences keys
   - Role strings
   - Status strings
   - Colors
   - Padding/Margin values
   - Font sizes
   - Border radius
   - Durations
   - Common messages
   - Labels
   - Validation messages
3. ✅ Replace with constants from `AppConstants`, `AppColors`, `AppSizes`, `AppDurations`
4. ✅ Add `import 'package:school_tracker/utils/constants.dart';` if not present
5. ✅ Verify no compilation errors
6. ✅ Mark file as ✅ MIGRATED

---

## 📝 **MIGRATION ORDER**

### START HERE (Most Impact):
1. **Services** (High usage, backend integration)
2. **Dashboard Pages** (User-facing, heavily used)
3. **Auth Pages** (Entry point)
4. **Management Pages** (Core functionality)
5. **BLoC Files** (State management)
6. **Other Pages**
7. **Widgets**
8. **Models** (Low priority, mostly data)
9. **Config/Utils**

---

## 🚀 **EXECUTION PLAN**

I will migrate **ONE FILE AT A TIME** in the order specified above, ensuring:
- ✅ Complete file review
- ✅ All hardcoded values replaced
- ✅ Import statement added
- ✅ No errors introduced
- ✅ Clean, readable code

**TOTAL ESTIMATED TIME**: 4-6 hours for all 150 files
**FILES PER HOUR**: ~25-30 files (average 2-3 minutes per file)

---

## 📊 **PROGRESS TRACKER**

### Completed: 2 / 150 files (1.3%)
- ✅ `utils/constants.dart` (created)
- ✅ `services/auth_service.dart` (migrated)

### In Progress: 0 / 150 files
### Remaining: 148 / 150 files (98.7%)

---

**Ready to begin systematic migration!** 🎯

