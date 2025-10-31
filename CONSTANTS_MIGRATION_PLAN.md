# 🔧 CONSTANTS MIGRATION PLAN

## 📋 Overview
Migrate all hardcoded strings, URLs, colors, sizes, and repeated values to `lib/utils/constants.dart` for better maintainability.

## ✅ COMPLETED
- ✅ Created `lib/utils/constants.dart`
- ✅ Added `AppConstants` class - All strings, URLs, keys
- ✅ Added `AppColors` class - All colors with semantic names
- ✅ Added `AppSizes` class - All dimensions, padding, margins, text sizes
- ✅ Added `AppDurations` class - All animation durations

---

## 📂 PHASE 1: Configuration Files

### 1. `lib/config/app_config.dart`
**Constants to Replace:**
- `baseUrl` → `AppConstants.baseUrl`
- API endpoint constructions

**Impact:** High (used everywhere)
**Priority:** ⭐⭐⭐⭐⭐

---

## 📂 PHASE 2: Service Files (lib/services/)

### 2. `lib/services/auth_service.dart`
**Constants to Replace:**
- `'$base/auth/login'` → `AppConstants.loginEndpoint`
- `'jwt_token'` → `AppConstants.keyJwtToken`
- `'userId'` → `AppConstants.keyUserId`
- `'userName'` → `AppConstants.keyUserName`
- `'userRole'` → `AppConstants.keyUserRole`
- Error messages → `AppConstants.error*`

**Priority:** ⭐⭐⭐⭐⭐

### 3. `lib/services/app_admin_service.dart`
**Constants to Replace:**
- `'$base/app-admin/*'` → `AppConstants.schoolsEndpoint`
- `'jwt_token'` → `AppConstants.keyJwtToken`
- `'success'`, `'message'`, `'data'` → `AppConstants.key*`
- Error messages

**Priority:** ⭐⭐⭐⭐

### 4. `lib/services/school_service.dart`
**Constants to Replace:**
- `'$base/schools/*'` → `AppConstants.schoolsEndpoint`
- `'$base/school-admin/*'` → `AppConstants.schoolAdminEndpoint`
- SharedPreferences keys
- Error/success messages

**Priority:** ⭐⭐⭐⭐

### 5. `lib/services/vehicle_service.dart`
**Constants to Replace:**
- `'$base/vehicles/*'` → `AppConstants.vehiclesEndpoint`
- `'$base/vehicle-assignments/*'` → `AppConstants.vehicleAssignmentsEndpoint`
- `'jwt_token'` → `AppConstants.keyJwtToken`
- Status strings: `'PENDING'`, `'APPROVED'`, `'REJECTED'`
- Error messages

**Priority:** ⭐⭐⭐⭐⭐

### 6. `lib/services/driver_service.dart`
**Constants to Replace:**
- `'$base/drivers/*'` → `AppConstants.driversEndpoint`
- SharedPreferences keys
- Error/success messages

**Priority:** ⭐⭐⭐⭐

### 7. `lib/services/student_service.dart`
**Constants to Replace:**
- `'$base/students/*'` → `AppConstants.studentsEndpoint`
- SharedPreferences keys
- Error messages

**Priority:** ⭐⭐⭐⭐

### 8. `lib/services/parent_service.dart`
**Constants to Replace:**
- `'$base/parents/*'` → `AppConstants.parentsEndpoint`
- SharedPreferences keys
- Error messages

**Priority:** ⭐⭐⭐

### 9. `lib/services/trip_service.dart`
**Constants to Replace:**
- `'$base/trips/*'` → `AppConstants.tripsEndpoint`
- Trip type strings
- Trip status strings
- Error messages

**Priority:** ⭐⭐⭐⭐

### 10. `lib/services/vehicle_owner_service.dart`
**Constants to Replace:**
- `'$base/vehicle-owners/*'`
- SharedPreferences keys
- Error messages

**Priority:** ⭐⭐⭐⭐

### 11. `lib/services/gate_staff_service.dart`
**Constants to Replace:**
- `'$base/gate-staff/*'` → `AppConstants.gateStaffEndpoint`
- SharedPreferences keys

**Priority:** ⭐⭐⭐

### 12. `lib/services/websocket_notification_service.dart`
**Constants to Replace:**
- WebSocket URL → `AppConstants.wsUrl`
- Topic strings → `AppConstants.wsTopic*`
- Notification types → `AppConstants.notificationType*`

**Priority:** ⭐⭐⭐⭐⭐

---

## 📂 PHASE 3: Dashboard Pages (lib/presentation/pages/)

### 13. `lib/presentation/pages/bloc_app_admin_dashboard.dart`
**Constants to Replace:**
- Dashboard title → `AppConstants.dashboardAppAdmin`
- Menu items → `AppConstants.menu*`
- SharedPreferences keys
- Action labels
- Empty state messages

**Priority:** ⭐⭐⭐⭐

### 14. `lib/presentation/pages/bloc_school_admin_dashboard.dart`
**Constants to Replace:**
- Dashboard title → `AppConstants.dashboardSchoolAdmin`
- Menu items
- Quick action labels → `AppConstants.quickAction*`
- SharedPreferences keys
- "Logout" → `AppConstants.actionLogout`
- Dialog messages → `AppConstants.dialogTitle*`

**Priority:** ⭐⭐⭐⭐⭐

### 15. `lib/presentation/pages/bloc_vehicle_owner_dashboard.dart`
**Constants to Replace:**
- Dashboard title → `AppConstants.dashboardVehicleOwner`
- Menu items
- SharedPreferences keys
- Action labels
- Error/success messages

**Priority:** ⭐⭐⭐⭐⭐

### 16. `lib/presentation/pages/simplified_driver_dashboard.dart`
**Constants to Replace:**
- Dashboard title → `AppConstants.dashboardDriver`
- Menu items
- Trip status strings
- Action labels

**Priority:** ⭐⭐⭐⭐

### 17. `lib/presentation/pages/parent_dashboard_page.dart`
**Constants to Replace:**
- Dashboard title → `AppConstants.dashboardParent`
- Menu items
- SharedPreferences keys

**Priority:** ⭐⭐⭐

### 18. `lib/presentation/pages/gate_staff_dashboard.dart`
**Constants to Replace:**
- Dashboard title → `AppConstants.dashboardGateStaff`
- Menu items
- Action labels

**Priority:** ⭐⭐⭐

---

## 📂 PHASE 4: Feature Pages

### 19. `lib/presentation/pages/bloc_login_screen.dart`
**Constants to Replace:**
- `"Email"` → `AppConstants.labelEmail`
- `"Password"` → `AppConstants.labelPassword`
- `"Login"` → `AppConstants.actionLogin`
- Validation messages → `AppConstants.validation*`
- Error messages

**Priority:** ⭐⭐⭐⭐⭐

### 20. `lib/presentation/pages/request_vehicle_assignment_page.dart`
**Constants to Replace:**
- Page title
- SharedPreferences keys → `AppConstants.keyOwnerId`, `AppConstants.keySchoolId`
- Status strings → `AppConstants.status*`
- Action labels → `AppConstants.actionSubmit`
- Success/error messages

**Priority:** ⭐⭐⭐⭐⭐

### 21. `lib/presentation/pages/pending_vehicle_requests_page.dart`
**Constants to Replace:**
- Page title
- SharedPreferences keys
- Status strings → `AppConstants.status*`
- Action labels → `AppConstants.actionApprove`, `AppConstants.actionReject`
- Success/error messages → `AppConstants.success*`, `AppConstants.error*`
- Empty state message → `AppConstants.emptyStateNoPendingRequests`

**Priority:** ⭐⭐⭐⭐⭐

### 22. `lib/presentation/pages/student_management_page.dart`
**Constants to Replace:**
- Form labels → `AppConstants.label*`
- Action buttons
- Validation messages
- Success/error messages

**Priority:** ⭐⭐⭐⭐

### 23. `lib/presentation/pages/vehicle_management_page.dart`
**Constants to Replace:**
- Form labels
- Vehicle types → `AppConstants.vehicleType*`
- Action buttons
- Validation messages

**Priority:** ⭐⭐⭐⭐

### 24. `lib/presentation/pages/driver_management_page.dart`
**Constants to Replace:**
- Form labels
- Action buttons
- Validation messages

**Priority:** ⭐⭐⭐

### 25. `lib/presentation/pages/trip_management_page.dart`
**Constants to Replace:**
- Trip types → `AppConstants.tripType*`
- Trip status → `AppConstants.tripStatus*`
- Action labels
- Error messages

**Priority:** ⭐⭐⭐⭐

### 26. `lib/presentation/pages/school_profile_page.dart`
**Constants to Replace:**
- Form labels → `AppConstants.label*`
- Action buttons
- Success/error messages

**Priority:** ⭐⭐⭐

### 27. `lib/presentation/pages/reports_screen.dart`
**Constants to Replace:**
- Page title
- SharedPreferences keys
- Empty state messages
- Error messages

**Priority:** ⭐⭐⭐

---

## 📂 PHASE 5: BLoC Files (lib/bloc/)

### 28. `lib/bloc/auth/auth_bloc.dart`
**Constants to Replace:**
- SharedPreferences keys
- User roles → `AppConstants.role*`
- Error messages

**Priority:** ⭐⭐⭐⭐⭐

### 29. Other BLoC files
**Constants to Replace:**
- Error messages
- Status strings
- SharedPreferences keys

**Priority:** ⭐⭐⭐

---

## 📂 PHASE 6: Widgets & Components

### 30. `lib/presentation/widgets/*`
**Constants to Replace:**
- Common labels
- Action button texts
- Validation messages

**Priority:** ⭐⭐

---

## 📂 PHASE 7: Route Management

### 31. `lib/app_routes.dart`
**Constants to Replace:**
- Route names (optional - keep as is for type safety)

**Priority:** ⭐

---

## 🎯 IMPLEMENTATION ORDER

### **HIGH PRIORITY (Do First):**
1. ✅ Create `constants.dart` file
2. `app_config.dart` - Base URL
3. `auth_service.dart` - Authentication
4. `vehicle_service.dart` - Vehicle assignment workflow
5. `websocket_notification_service.dart` - Real-time updates
6. `bloc_login_screen.dart` - User entry point
7. `bloc_school_admin_dashboard.dart` - Main admin dashboard
8. `bloc_vehicle_owner_dashboard.dart` - Vehicle owner dashboard
9. `request_vehicle_assignment_page.dart` - Critical feature
10. `pending_vehicle_requests_page.dart` - Critical feature

### **MEDIUM PRIORITY:**
11-20: Other services and dashboard pages

### **LOW PRIORITY:**
21-31: Remaining pages, widgets, and components

---

## ✅ CHECKLIST FORMAT

For each file:
- [ ] Import `constants.dart`
- [ ] Replace hardcoded strings
- [ ] Test functionality
- [ ] Remove unused imports/variables
- [ ] Verify no regressions

---

## 🚀 START COMMAND

Ready to start? Reply with:
- `"START"` - I'll begin Phase 1 (High Priority files)
- `"MANUAL"` - You tell me which specific file to start with
- `"SKIP {filename}"` - Skip specific files

---

**Estimated Time:** 
- High Priority: 2-3 hours
- Medium Priority: 3-4 hours
- Low Priority: 2-3 hours
- **Total: ~8-10 hours of work**

**Files to Update: ~30-35 files**

