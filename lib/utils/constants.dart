import 'package:flutter/material.dart';

/// ========================================
/// APP CONSTANTS
/// All constants used across the application
/// ========================================

class AppConstants {
  // Prevent instantiation
  AppConstants._();

  /// ========================================
  /// API ENDPOINTS
  /// ========================================
  
  // Base URLs
  static const String baseUrl = 'http://10.245.176.208:9001';
  static const String apiBase = '$baseUrl/api';
  
  // HTTP Headers
  static const String headerContentType = 'Content-Type';
  static const String headerApplicationJson = 'application/json';
  static const String headerAuthorization = 'Authorization';
  static const String headerBearer = 'Bearer ';
  static const String headerAccept = 'Accept';
  
  // Authentication Endpoints
  static const String loginEndpoint = '$apiBase/auth/login';
  static const String registerEndpoint = '$apiBase/auth/register';
  static const String logoutEndpoint = '$apiBase/auth/logout';
  
  // User Endpoints
  static const String userProfileEndpoint = '$apiBase/users';
  
  // School Endpoints
  static const String schoolsEndpoint = '$apiBase/schools';
  static const String schoolAdminEndpoint = '$apiBase/school-admin';
  
  // Vehicle Endpoints
  static const String vehiclesEndpoint = '$apiBase/vehicles';
  static const String vehicleAssignmentsEndpoint = '$apiBase/vehicle-assignments';
  
  // Driver Endpoints
  static const String driversEndpoint = '$apiBase/drivers';
  
  // Student Endpoints
  static const String studentsEndpoint = '$apiBase/students';
  
  // Parent Endpoints
  static const String parentsEndpoint = '$apiBase/parents';
  
  // External API URLs
  static const String pincodeApiBaseUrl = 'https://api.postalpincode.in/pincode';
  
  // API Status Values
  static const String statusValueSuccess = 'Success';
  
  // Trip Endpoints
  static const String tripsEndpoint = '$apiBase/trips';
  
  // Gate Staff Endpoints
  static const String gateStaffEndpoint = '$apiBase/gate-staff';
  
  // WebSocket
  static const String wsUrl = 'ws://10.245.176.208:9001/ws/websocket';
  static const String wsPath = '/ws/websocket';
  static const String wsProtocolHttp = 'http://';
  static const String wsProtocolHttps = 'https://';
  static const String wsProtocolWs = 'ws://';
  static const String wsProtocolWss = 'wss://';
  static const String wsDestinationSend = '/app/chat.sendMessage';

  /// ========================================
  /// SHARED PREFERENCES KEYS
  /// ========================================
  
  static const String keyJwtToken = 'jwt_token';
  static const String keyUserId = 'userId';
  static const String keyUserName = 'userName';
  static const String keyUserRole = 'userRole';
  static const String keyEmail = 'email';
  static const String keyContactNumber = 'contactNumber';
  static const String keySchoolId = 'schoolId';
  static const String keySchoolName = 'schoolName';
  static const String keyCurrentSchoolId = 'currentSchoolId';
  static const String keyCurrentSchoolName = 'currentSchoolName';
  static const String keyOwnerId = 'ownerId';
  static const String keyVehicleId = 'vehicleId';
  static const String keyDriverId = 'driverId';
  static const String keyParentId = 'parentId';
  static const String keyStudentId = 'studentId';
  static const String keyStudentName = 'studentName';
  static const String keyIsActive = 'isActive';
  static const String keyRememberMe = 'rememberMe';
  static const String keyLoginId = 'loginId';
  static const String keyPassword = 'password';
  static const String keyId = 'id';
  static const String keyToken = 'token';
  static const String keyOtp = 'otp';
  static const String keyNewPassword = 'newPassword';
  static const String keyError = 'error';
  static const String keySchoolInfo = 'school_info';
  static const String keyStaffList = 'staffList';
  static const String keyTotalCount = 'totalCount';
  static const String keyActiveCount = 'activeCount';
  static const String keyStudentsPresent = 'studentsPresent';
  static const String keyTotalStudents = 'totalStudents';
  static const String keyAttendanceRate = 'attendanceRate';
  static const String keyName = 'name';
  static const String keyContact = 'contact';
  static const String keyRole = 'role';
  static const String keyRoles = 'roles';
  static const String keyCode = 'code';
  static const String keyUserData = 'user_data';
  static const String keyJoinDate = 'joinDate';
  static const String keyUpdatedBy = 'updatedBy';
  static const String keyUpdatedDate = 'updatedDate';
  static const String keyCreatedBy = 'createdBy';
  static const String keyCreatedDate = 'createdDate';
  static const String keyClassName = 'className';
  static const String keyClassOrder = 'classOrder';
  static const String keyDescription = 'description';
  static const String keyStartDate = 'startDate';
  static const String keyEndDate = 'endDate';
  static const String keySchools = 'schools';
  static const String keyVehicles = 'vehicles';
  static const String keyDrivers = 'drivers';
  static const String keyTrips = 'trips';
  static const String keyTripId = 'tripId';
  static const String keyRemarks = 'remarks';
  static const String keyTargetUserId = 'targetUserId';
  static const String keyTargetRole = 'targetRole';
  static const String keyTargetSchoolId = 'targetSchoolId';
  static const String keyTargetUser = 'targetUser';
  static const String keyTimestamp = 'timestamp';
  static const String keyAction = 'action';
  static const String keyEntityType = 'entityType';
  static const String keyEntityId = 'entityId';
  static const String keyTripStudentId = 'tripStudentId';

  // Excel Import/Export
  static const String keyBulkImport = 'BulkImport';
  static const String keyFirstName = 'firstName';
  static const String keyMiddleName = 'middleName';
  static const String keyLastName = 'lastName';
  static const String keyFatherName = 'fatherName';
  static const String keyMotherName = 'motherName';
  static const String keyParentRelation = 'parentRelation';
  static const String keyPrimaryContact = 'primaryContactNumber';
  static const String keyAlternateContact = 'alternateContactNumber';
  static const String keyDateOfBirth = 'dateOfBirth';
  static const String keyGender = 'gender';
  static const String keyClassId = 'classId';
  static const String keySectionId = 'sectionId';
  static const String keySectionName = 'sectionName';
  static const String keyStudentPhoto = 'studentPhoto';
  static const String keySendActivationEmails = 'sendActivationEmails';
  static const String keyEmailGenerationStrategy = 'emailGenerationStrategy';
  static const String keySchoolDomain = 'schoolDomain';
  static const String keyLatitude = 'latitude';
  static const String keyLongitude = 'longitude';
  static const String keyMonth = 'month';
  static const String keyYear = 'year';
  static const String keyFromDate = 'fromDate';
  static const String keyToDate = 'toDate';
  static const String keyVerifyToken = 'token';
  static const String keyValue = 'value';
  static const String keyLabel = 'label';
  
  // Attendance History Keys
  static const String keyTotalDays = 'totalDays';
  static const String keyPresentDays = 'presentDays';
  static const String keyAbsentDays = 'absentDays';
  static const String keyLateDays = 'lateDays';
  static const String keyAttendancePercentage = 'attendancePercentage';
  static const String keyAttendanceRecords = 'attendanceRecords';
  static const String keyDate = 'date';
  static const String keyDayOfWeek = 'dayOfWeek';
  static const String keyIsPresent = 'isPresent';
  static const String keyIsAbsent = 'isAbsent';
  static const String keyIsLate = 'isLate';
  static const String keyArrivalTime = 'arrivalTime';
  static const String keyDepartureTime = 'departureTime';
  
  // Pincode API Response Keys
  static const String keyCities = 'cities';
  static const String keyDistrict = 'district';
  static const String keyState = 'state';
  static const String keyStatus = 'Status';
  static const String keyPostOffice = 'PostOffice';
  static const String keyNameCaps = 'Name'; // API returns 'Name' with capital N
  static const String keyDistrictCaps = 'District';
  static const String keyStateCaps = 'State';
  
  // Report Query Parameter Keys
  static const String keyFilterType = 'filterType';
  static const String keyType = 'type';
  static const String keyFormat = 'format';
  static const String keyActivationCode = 'activationCode';
  static const String keyNewRoleId = 'newRoleId';
  static const String keyFilterTypeAll = 'all';
  static const String keyPickupOrder = 'pickupOrder';

  // Bulk Import Keys
  static const String keyTotalRows = 'totalRows';
  static const String keySuccessfulImports = 'successfulImports';
  static const String keyFailedImports = 'failedImports';
  static const String keyResults = 'results';
  static const String keyErrors = 'errors';
  static const String keyRowNumber = 'rowNumber';
  static const String keyErrorMessage = 'errorMessage';
  static const String keyParentEmail = 'parentEmail';

  // Driver Dashboard Keys
  static const String keyDriverName = 'driverName';
  static const String keyDriverContactNumber = 'driverContactNumber';
  static const String keyDriverPhoto = 'driverPhoto';
  static const String keyOwnerPhoto = 'ownerPhoto';
  static const String keyOwnerName = 'ownerName';
  static const String keyVehicleNumber = 'vehicleNumber';
  static const String keyVehicleType = 'vehicleType';
  static const String keyVehicleCapacity = 'vehicleCapacity';
  static const String keyTotalTripsToday = 'totalTripsToday';
  static const String keyCompletedTrips = 'completedTrips';
  static const String keyPendingTrips = 'pendingTrips';
  static const String keyTotalStudentsToday = 'totalStudentsToday';
  static const String keyStudentsPickedUp = 'studentsPickedUp';
  static const String keyStudentsDropped = 'studentsDropped';
  static const String keyStudentsAbsent = 'studentsAbsent';
  static const String keyScheduledTime = 'scheduledTime';
  static const String keyEstimatedDurationMinutes = 'estimatedDurationMinutes';
  static const String keyTripStartTime = 'tripStartTime';
  static const String keyTripEndTime = 'tripEndTime';
  static const String keyPickupLocation = 'pickupLocation';
  static const String keyDropLocation = 'dropLocation';
  static const String keyDropOrder = 'dropOrder';
  static const String keyPickupTime = 'pickupTime';
  static const String keyDropTime = 'dropTime';
  static const String keyParentName = 'parentName';
  static const String keyParentContactNumber = 'parentContactNumber';
  static const String keyCurrentTripId = 'currentTripId';
  static const String keyCurrentTripName = 'currentTripName';
  static const String keyCurrentTripStatus = 'currentTripStatus';
  static const String keyCurrentTripStartTime = 'currentTripStartTime';
  static const String keyCurrentTripStudentCount = 'currentTripStudentCount';
  static const String keyRecentActivities = 'recentActivities';
  static const String keyActivityId = 'activityId';
  static const String keyActivityType = 'activityType';
  static const String keyActivityTime = 'activityTime';
  static const String keyLocation = 'location';

  // Driver Profile Keys
  static const String keyDriverAddress = 'driverAddress';
  static const String keyLicenseNumber = 'licenseNumber';
  static const String keyEmergencyContact = 'emergencyContact';
  static const String keyBloodGroup = 'bloodGroup';
  static const String keyExperience = 'experience';

  // Driver Reports Keys
  static const String keyTotalTripsCompleted = 'totalTripsCompleted';
  static const String keyTotalStudentsTransported = 'totalStudentsTransported';
  static const String keyTotalDistanceCovered = 'totalDistanceCovered';
  static const String keyAverageRating = 'averageRating';
  static const String keyTodayTrips = 'todayTrips';
  static const String keyTodayStudents = 'todayStudents';
  static const String keyTodayPickups = 'todayPickups';
  static const String keyTodayDrops = 'todayDrops';
  static const String keyWeekTrips = 'weekTrips';
  static const String keyWeekStudents = 'weekStudents';
  static const String keyWeekPickups = 'weekPickups';
  static const String keyWeekDrops = 'weekDrops';
  static const String keyMonthTrips = 'monthTrips';
  static const String keyMonthStudents = 'monthStudents';
  static const String keyMonthPickups = 'monthPickups';
  static const String keyMonthDrops = 'monthDrops';
  static const String keyRecentTrips = 'recentTrips';
  static const String keyTotalTrips = 'totalTrips';
  static const String keyStudentsCount = 'studentsCount';
  static const String keyTripType = 'tripType';
  static const String keyTripNumber = 'tripNumber';
  static const String keyTripDate = 'tripDate';
  static const String keyStartTime = 'startTime';
  static const String keyEndTime = 'endTime';
  static const String keyRoute = 'route';
  static const String keyRouteName = 'routeName';
  static const String keyRouteDescription = 'routeDescription';

  // Monthly Report Keys
  static const String keyMonthName = 'monthName';
  static const String keyTotalSchoolDays = 'totalSchoolDays';
  static const String keyMissedTrips = 'missedTrips';
  static const String keyTripCompletionRate = 'tripCompletionRate';
  static const String keyPerformanceMetrics = 'performanceMetrics';
  static const String keyDailyReports = 'dailyReports';
  static const String keyWeeklyReports = 'weeklyReports';
  static const String keyAttendanceStatus = 'attendanceStatus';
  static const String keyTripStatus = 'tripStatus';
  static const String keyTripStatusId = 'tripStatusId';
  static const String keyStatusDisplay = 'statusDisplay';
  static const String keyStatusTime = 'statusTime';
  static const String keyTotalTimeMinutes = 'totalTimeMinutes';
  static const String keyTotalTimeDisplay = 'totalTimeDisplay';
  static const String keyWeekNumber = 'weekNumber';
  static const String keyWeekStart = 'weekStart';
  static const String keyWeekEnd = 'weekEnd';
  static const String keyWeeklyAttendancePercentage = 'weeklyAttendancePercentage';

  // Vehicle Request Keys
  static const String keyRegistrationNumber = 'registrationNumber';
  static const String keyVehiclePhoto = 'vehiclePhoto';
  static const String keyCapacity = 'capacity';

  // Notification Request Keys
  static const String keyDispatchLogId = 'dispatchLogId';
  static const String keyNotificationType = 'notificationType';
  static const String keyTitle = 'title';
  static const String keyStudentIds = 'studentIds';
  static const String keySendSms = 'sendSms';
  static const String keySendEmail = 'sendEmail';
  static const String keySendPushNotification = 'sendPushNotification';
  static const String keyMinutesBeforeArrival = 'minutesBeforeArrival';

  // Pagination Request Keys
  static const String keyPage = 'page';
  static const String keySize = 'size';

  // Parent Dashboard Keys
  static const String keyTodayAttendanceStatus = 'todayAttendanceStatus';
  static const String keyTodayArrivalTime = 'todayArrivalTime';
  static const String keyTodayDepartureTime = 'todayDepartureTime';
  static const String keyRecentNotifications = 'recentNotifications';
  static const String keyLastUpdated = 'lastUpdated';

  // Parent Notification Keys
  static const String keyNotificationId = 'notificationId';
  static const String keyEventType = 'eventType';
  static const String keyTripName = 'tripName';
  static const String keyNotificationTime = 'notificationTime';
  static const String keyIsRead = 'isRead';
  static const String keyPriority = 'priority';

  // Parent Request Keys
  static const String keyRelation = 'relation';

  // Role Keys
  static const String keyRoleId = 'roleId';
  static const String keyRoleName = 'roleName';

  // School Request Keys
  static const String keySchoolType = 'schoolType';
  static const String keyAffiliationBoard = 'affiliationBoard';
  static const String keyContactNo = 'contactNo';
  static const String keySchoolPhoto = 'schoolPhoto';
  static const String keyAddress = 'address';
  static const String keyCity = 'city';
  static const String keyPincode = 'pincode';

  // Student Attendance Keys
  static const String keyEventTime = 'eventTime';
  static const String keySendNotificationToParent = 'sendNotificationToParent';
  static const String keyNotificationMessage = 'notificationMessage';

  /// ========================================
  /// USER ROLES
  /// ========================================
  
  static const String roleAppAdmin = 'APP_ADMIN';
  static const String roleSchoolAdmin = 'SCHOOL_ADMIN';
  static const String roleVehicleOwner = 'VEHICLE_OWNER';
  static const String roleDriver = 'DRIVER';
  static const String roleParent = 'PARENT';
  static const String roleGateStaff = 'GATE_STAFF';

  /// ========================================
  /// NOTIFICATION TYPES
  /// ========================================
  
  static const String notificationTypeSystemAlert = 'SYSTEM_ALERT';
  static const String notificationTypeVehicleAssignment = 'VEHICLE_ASSIGNMENT';
  static const String notificationTypeTripUpdate = 'TRIP_UPDATE';
  static const String notificationTypeAttendance = 'ATTENDANCE';

  /// ========================================
  /// ENVIRONMENT
  /// ========================================
  
  // Environment Types
  static const String envDevelopment = 'development';
  static const String envProduction = 'production';
  static const String envLocal = 'local';
  
  // Environment Config Keys
  static const String configKeyBaseUrl = 'baseUrl';
  static const String configKeyApiTimeout = 'apiTimeout';
  static const String configKeyDebugMode = 'debugMode';
  
  // Environment Config Values
  static const String configValueTrue = 'true';
  static const String configValueFalse = 'false';
  static const String configTimeoutDev = '30000';
  static const String configTimeoutProd = '15000';
  
  // Environment Log Messages
  static const String logEnvironmentConfig = '🔧 Environment Configuration:';
  static const String logCurrentEnvironment = '   Current Environment: ';
  static const String logBaseUrl = '   Base URL: ';
  static const String logApiTimeout = '   API Timeout: ';
  static const String logApiTimeoutMs = 'ms';
  static const String logDebugMode = '   Debug Mode: ';
  
  // AppConfig Log Messages
  static const String logAppConfig = '🔧 App Configuration:';
  static const String logEnvironment = '   Environment: ';
  static const String logAuthUrl = '   Auth URL: ';
  static const String logSchoolsUrl = '   Schools URL: ';

  /// ========================================
  /// REQUEST STATUS
  /// ========================================
  
  static const String statusPending = 'PENDING';
  static const String statusApproved = 'APPROVED';
  static const String statusRejected = 'REJECTED';

  /// ========================================
  /// VEHICLE TYPES
  /// ========================================
  
  static const String vehicleTypeBus = 'Bus';
  static const String vehicleTypeCar = 'Car';
  static const String vehicleTypeVan = 'Van';

  /// ========================================
  /// TRIP TYPES
  /// ========================================
  
  static const String tripTypeMorningPickup = 'MORNING_PICKUP';
  static const String tripTypeAfternoonDrop = 'AFTERNOON_DROP';
  static const String tripTypeFieldTrip = 'FIELD_TRIP';
  static const String tripTypeSpecial = 'SPECIAL_TRIP';

  /// ========================================
  /// TRIP STATUS
  /// ========================================
  
  static const String tripStatusNotStarted = 'NOT_STARTED';
  static const String tripStatusInProgress = 'IN_PROGRESS';
  static const String tripStatusCompleted = 'COMPLETED';
  static const String tripStatusCancelled = 'CANCELLED';
  static const String tripStatusDelayed = 'DELAYED';

  /// ========================================
  /// NOTIFICATION TYPES
  /// ========================================
  
  static const String notificationTypeVehicleRequest = 'VEHICLE_ASSIGNMENT_REQUEST';
  static const String notificationTypeVehicleApproved = 'VEHICLE_ASSIGNMENT_APPROVED';
  static const String notificationTypeVehicleRejected = 'VEHICLE_ASSIGNMENT_REJECTED';
  static const String notificationTypeTripStarted = 'TRIP_STARTED';
  static const String notificationTypeTripCompleted = 'TRIP_COMPLETED';
  static const String notificationTypeStudentPickup = 'STUDENT_PICKUP';
  static const String notificationTypeStudentDrop = 'STUDENT_DROP';

  /// ========================================
  /// COMMON STRINGS
  /// ========================================
  
  // App Info
  static const String appName = 'School Tracker';
  static const String appVersion = '1.0.0';
  
  // Common Actions
  static const String actionSave = 'Save';
  static const String actionCancel = 'Cancel';
  static const String actionDelete = 'Delete';
  static const String actionEdit = 'Edit';
  static const String actionAdd = 'Add';
  static const String actionUpdate = 'Update';
  static const String actionSubmit = 'Submit';
  static const String actionApprove = 'Approve';
  static const String actionReject = 'Reject';
  static const String actionConfirm = 'Confirm';
  static const String actionLogout = 'Logout';
  static const String actionLogin = 'Login';
  static const String actionRegister = 'Register';
  static const String actionRefresh = 'Refresh';
  static const String actionRefreshCaps = 'REFRESH';
  static const String actionSearch = 'Search';
  static const String actionFilter = 'Filter';
  static const String actionSort = 'Sort';
  static const String actionExport = 'Export';
  static const String actionClose = 'Close';
  static const String actionApproveLC = 'approve';
  static const String actionRejectLC = 'reject';
  static const String actionRetry = 'Retry';
  
  // Common Messages
  static const String msgSuccess = 'Success';
  static const String msgError = 'Error';
  static const String msgLoading = 'Loading...';
  static const String msgNoData = 'No data found';
  static const String msgNetworkError = 'Network error. Please try again.';
  static const String msgUnauthorized = 'Unauthorized. Please login again.';
  static const String msgServerError = 'Server error. Please try again later.';
  static const String msgInvalidInput = 'Invalid input. Please check and try again.';
  static const String msgConfirmDelete = 'Are you sure you want to delete?';
  static const String msgConfirmLogout = 'Are you sure you want to logout?';
  static const String msgDataSaved = 'Data saved successfully';
  static const String msgDataUpdated = 'Data updated successfully';
  static const String msgDataDeleted = 'Data deleted successfully';
  
  // Form Labels
  static const String labelEmail = 'Email';
  static const String labelPassword = 'Password';
  static const String labelConfirmPassword = 'Confirm Password';
  static const String labelName = 'Name';
  static const String labelPhone = 'Phone Number';
  static const String labelAddress = 'Address';
  static const String labelCity = 'City';
  static const String labelState = 'State';
  static const String labelPincode = 'Pincode';
  static const String labelSchool = 'School';
  static const String labelVehicle = 'Vehicle';
  static const String labelDriver = 'Driver';
  static const String labelStudent = 'Student';
  static const String labelParent = 'Parent';
  // labelClass and labelSection are defined globally already
  static const String labelRollNumber = 'Roll Number';
  static const String labelRegistrationNumber = 'Registration Number';
  static const String labelVehicleNumber = 'Vehicle Number';
  static const String labelVehicleType = 'Vehicle Type';
  static const String labelCapacity = 'Capacity';
  static const String labelRoute = 'Route';
  static const String labelStatus = 'Status';
  static const String labelDate = 'Date';
  static const String labelTime = 'Time';
  
  // Validation Messages
  static const String validationEmailRequired = 'Email is required';
  static const String validationEmailInvalid = 'Invalid email format';
  static const String validationPasswordRequired = 'Password is required';
  static const String validationPasswordLength = 'Password must be at least 6 characters';
  static const String validationPasswordMismatch = 'Passwords do not match';
  static const String validationNameRequired = 'Name is required';
  static const String validationPhoneRequired = 'Phone number is required';
  static const String validationPhoneInvalid = 'Invalid phone number';
  static const String validationFieldRequired = 'This field is required';

  /// ========================================
  /// DASHBOARD TITLES
  /// ========================================
  
  static const String dashboardAppAdmin = 'App Admin Dashboard';
  static const String dashboardSchoolAdmin = 'School Admin Dashboard';
  static const String dashboardVehicleOwner = 'Vehicle Owner Dashboard';
  static const String dashboardDriver = 'Driver Dashboard';
  static const String dashboardParent = 'Parent Dashboard';
  static const String dashboardGateStaff = 'Gate Staff Dashboard';

  /// ========================================
  /// MENU ITEMS
  /// ========================================
  
  // Common Menu Items
  static const String menuDashboard = 'Dashboard';
  static const String menuProfile = 'Profile';
  static const String menuSettings = 'Settings';
  static const String menuNotifications = 'Notifications';
  static const String menuReports = 'Reports';
  static const String menuLogout = 'Logout';
  
  // School Admin Menu
  static const String menuStudents = 'Students';
  static const String menuVehicles = 'Vehicles';
  static const String menuDrivers = 'Drivers';
  static const String menuParents = 'Parents';
  static const String menuTrips = 'Trips';
  static const String menuClasses = 'Classes';
  static const String menuSections = 'Sections';
  static const String menuPendingRequests = 'Pending Requests';
  
  /// ========================================
  /// DASHBOARD SPECIFIC STRINGS
  /// ========================================
  
  // Alert Dialog Strings
  static const String alertSystemAlert = 'System Alert';
  static const String alertDismiss = 'DISMISS';
  static const String alertViewDetails = 'VIEW DETAILS';
  static const String alertConfirmLogout = 'Confirm Logout';
  static const String alertLogoutMessage = 'Are you sure you want to logout?';
  static const String alertYes = 'YES';
  static const String alertNo = 'NO';
  static const String alertOk = 'OK';
  static const String alertError = 'Error';
  static const String alertWarning = 'Warning';
  static const String alertInfo = 'Information';
  
  // Dashboard Quick Actions
  static const String quickActionAddStudent = 'Add Student';
  static const String quickActionAddVehicle = 'Add Vehicle';
  static const String quickActionAddDriver = 'Add Driver';
  static const String quickActionCreateTrip = 'Create Trip';
  static const String quickActionViewReports = 'View Reports';
  static const String quickActionViewRequests = 'View Requests';
  static const String menuVehicleOwners = 'Vehicle Owners';
  static const String menuGateStaff = 'Gate Staff';
  static const String menuBulkImport = 'Bulk Student Import';
  
  // Vehicle Owner Menu
  static const String menuMyVehicles = 'My Vehicles';
  static const String menuMyDrivers = 'My Drivers';
  static const String menuRequestAssignment = 'Request Vehicle Assignment';
  static const String menuDriverAssignment = 'Driver Assignment';
  static const String menuSchoolMapping = 'School Mapping';
  static const String menuStudentTripAssignment = 'Student-Trip Assignment';

  /// ========================================
  /// API ENDPOINTS
  /// ========================================
  
  // Auth Endpoints
  static const String endpointCompleteRegistration = '/complete-registration';
  static const String endpointLogin = '/login';
  static const String endpointForgotPassword = '/forgot-password';
  static const String endpointResetPassword = '/reset-password';

  // Student Endpoints
  static const String endpointBulkImport = '/bulk-import';
  static const String endpointBulkValidate = '/bulk-validate';

  // Gate Staff Endpoints
  static const String endpointGateStaff = '/api/gate-staff';
  
  // Role Endpoints
  static const String endpointRoles = '/api/roles';

  // HTTP Methods
  static const String httpMethodGet = 'GET';
  static const String httpMethodPost = 'POST';
  static const String httpMethodPut = 'PUT';
  static const String httpMethodDelete = 'DELETE';

  // Log Labels
  static const String logLabelStatus = 'Status';
  static const String logLabelRequestBody = 'Request Body';
  static const String logLabelError = 'Error';
  
  // WebSocket Log Messages
  static const String logWebSocketUserData = 'WebSocket User Data: Role=';
  static const String logWebSocketBaseUrl = '🔍 AppConfig.baseUrl: ';
  static const String logWebSocketConstructedUrl = '🔍 Constructed WebSocket URL: ';
  static const String logWebSocketConnecting = 'Connecting to STOMP WebSocket: ';
  static const String logWebSocketConnected = 'STOMP connected successfully';
  static const String logWebSocketStompError = 'STOMP Error: ';
  static const String logWebSocketDisconnected = 'WebSocket disconnected';
  static const String logWebSocketError = 'WebSocket Error: ';
  static const String logWebSocketMessageReceived = 'STOMP message received: ';
  static const String logWebSocketParsedMessage = 'Parsed STOMP JSON message: ';
  static const String logWebSocketNotificationProcessed = '✅ STOMP notification processed successfully';
  static const String logWebSocketSubscribedSchool = 'Subscribed to school notifications: ';
  static const String logWebSocketSubscribedUser = 'Subscribed to user notifications: ';
  static const String logWebSocketSubscribedRole = 'Subscribed to role notifications: ';
  static const String logWebSocketSubscribedGeneral = 'Subscribed to general notifications: ';
  static const String logWebSocketAttemptReconnect = 'Attempting to reconnect...';
  static const String logWebSocketDisconnectedStomp = 'STOMP WebSocket disconnected';
  static const String logWebSocketDebug = 'STOMP Debug: ';

  /// ========================================
  /// ERROR MESSAGES
  /// ========================================
  
  static const String errorNoAuthToken = 'No authentication token found';
  static const String errorFailedToFetchData = 'Failed to fetch data';
  static const String errorFailedToSaveData = 'Failed to save data';
  static const String errorFailedToUpdateData = 'Failed to update data';
  static const String errorFailedToDeleteData = 'Failed to delete data';
  static const String errorInvalidCredentials = 'Invalid credentials';
  static const String errorActivationFailed = 'Activation failed';
  static const String errorForgotPasswordFailed = 'Forgot password failed';
  static const String errorResetPasswordFailed = 'Reset password failed';
  static const String errorFailedToParseResponse = 'Failed to parse response';
  static const String errorRequestFailedWithStatus = 'Request failed with status';
  static const String errorRequiredFieldMissing = 'Required field missing';
  static const String errorFailedToConvertResponse = 'Failed to convert response';
  static const String errorOperationFailed = 'failed';
  static const String errorNoStudentsProvided = 'No students provided';
  static const String errorAuthTokenNotAvailable = 'Authentication token not available';
  static const String errorValidationFailed = 'Validation failed';
  static const String errorInvalidRequestData = 'Invalid request data';
  static const String errorAuthenticationFailed = 'Authentication failed. Please login again.';
  static const String errorAccessDenied = 'Access denied';
  static const String errorNoPermissionImport = 'You don\'t have permission to import students';
  static const String errorNoPermissionValidate = 'You don\'t have permission to validate students';
  static const String errorServerError = 'Server error';
  static const String errorTryAgainLater = 'Please try again later';
  static const String errorNetworkError = 'Network error';
  static const String errorNoSheetsFound = 'No sheets found in Excel file';
  static const String errorInsufficientColumns = 'has insufficient columns. Expected at least 7 columns (up to Email)';
  static const String errorFirstNameRequired = 'First name is required';
  static const String errorLastNameRequired = 'Last name is required';
  static const String errorFatherNameRequired = 'Father name is required';
  static const String errorPrimaryContactRequired = 'Primary contact is required';
  static const String errorEmailRequired = 'Parent email is required';
  static const String errorEmailRequiredActivation = 'for account activation';
  static const String errorParsingExcel = 'Error parsing Excel file';
  static const String errorParsingRow = 'Error parsing row';
  static const String errorFailedToEncodeExcel = 'Failed to encode Excel file';
  static const String errorAtRow = 'at row';
  static const String errorApiError = 'API Error';
  static const String errorRequestFailed = 'Request failed with status';
  static const String errorFailedToGet = 'Failed to get';
  static const String errorRequestFailedColon = 'request failed';
  static const String errorInvalidResponseFormat = 'Invalid response format';
  static const String errorPrefix = 'Error';
  static const String errorVerifyTokenFailed = 'Verify token failed';
  static const String errorFetchingPincodeData = 'Error fetching pincode data';
  static const String errorAttendanceReportFailed = 'Attendance report request failed';
  static const String errorDispatchLogsReportFailed = 'Dispatch logs report request failed';
  static const String errorNotificationLogsReportFailed = 'Notification logs report request failed';
  static const String errorExportReportFailed = 'Export report request failed';
  static const String errorDownloadReportFailed = 'Download report request failed';
  static const String errorFailedToGetRoles = 'Failed to get roles';
  static const String errorRolesRequestFailed = 'Roles request failed';
  static const String errorFailedToGetRole = 'Failed to get role';
  static const String errorRoleRequestFailed = 'Role request failed';
  static const String errorRegistrationFailed = 'Registration failed';
  static const String errorUnknown = 'Unknown error';
  static const String errorFailedToRegisterSchool = 'Failed to register school (HTTP ';
  static const String errorFailedToFetchSchools = 'Failed to fetch schools';
  static const String errorFailedToFetchSchoolDashboard = 'Failed to fetch school dashboard';
  static const String errorFailedToFetchSchoolStudents = 'Failed to fetch school students';
  static const String errorFailedToFetchSchoolStaff = 'Failed to fetch school staff';
  static const String errorFailedToFetchSchoolVehicles = 'Failed to fetch school vehicles';
  static const String errorFailedToFetchSchoolTrips = 'Failed to fetch school trips';
  static const String errorFailedToFetchSchoolProfile = 'Failed to fetch school profile';
  static const String errorFailedToUpdateSchoolProfile = 'Failed to update school profile';
  static const String errorFailedToFetchSchoolReports = 'Failed to fetch school reports';
  static const String errorFailedToCreateStaff = 'Failed to create staff';
  static const String errorFailedToAssignVehicle = 'Failed to assign vehicle';
  static const String errorFailedToGetVehiclesInTransit = 'Failed to get vehicles in transit';
  static const String errorFailedToGetTodayAttendance = 'Failed to get today\'s attendance';
  static const String errorFailedToGetSchoolDetails = 'Failed to get school details';
  static const String errorFailedToGetStaffList = 'Failed to get staff list';
  static const String errorFailedToUpdateStaffStatus = 'Failed to update staff status';
  static const String errorFailedToUpdateStaffDetails = 'Failed to update staff details';
  static const String errorFailedToDeleteStaff = 'Failed to delete staff';
  static const String errorFailedToGetStaffByName = 'Failed to get staff by name';
  static const String errorFailedToUpdateStaffRole = 'Failed to update staff role';
  static const String errorFailedToGetAllUsers = 'Failed to get all users';
  static const String errorFailedToGetDashboardStats = 'Failed to get dashboard stats';
  static const String errorGettingStudentCount = 'Error getting student count';
  static const String errorExceptionGettingStudentCount = 'Exception getting student count';
  static const String errorCreateStudentFailed = 'Create student failed';
  static const String errorFailedToFetchStudents = 'Failed to fetch students';
  static const String errorVehicleRegisterFailed = 'Vehicle register failed';
  static const String errorFailedToFetchVehicles = 'Failed to fetch vehicles';
  static const String errorSessionExpired = 'Session expired. Please login again.';
  static const String errorNoVehiclesFound = 'No vehicles found';
  static const String errorNoStudentsFound = 'No students found';
  static const String errorNoDriversFound = 'No drivers found';
  static const String errorNoTripsFound = 'No trips found';
  static const String errorNoRequestsFound = 'No requests found';
  static const String errorLoginFailed = 'Login failed';
  static const String errorLogoutFailed = 'Logout failed';
  static const String errorFailedToSendOtp = 'Failed to send OTP';
  static const String errorFailedToResetPassword = 'Failed to reset password';
  static const String errorTokenRefreshFailed = 'Token refresh failed';
  static const String errorCheckingAuthStatus = 'Error checking auth status';
  static const String errorGettingUserData = 'Error getting user data';
  static const String errorFailedToLoadDriverDashboard = 'Failed to load driver dashboard';
  static const String errorFailedToLoadTrips = 'Failed to load trips';
  static const String errorFailedToLoadDriverProfile = 'Failed to load driver profile';
  static const String errorDriverProfileNotFound = 'Driver profile not found. Please ensure your account is activated and a vehicle is assigned.';
  static const String errorFailedToLoadDriverReports = 'Failed to load driver reports';
  static const String errorDriverReportsNotFound = 'Driver reports not found. Please ensure your account is activated and a vehicle is assigned.';
  static const String errorFailedToLoadTripStudents = 'Failed to load trip students';
  static const String errorFailedToMarkAttendance = 'Failed to mark attendance';
  static const String errorFailedToSendNotification = 'Failed to send notification';
  static const String errorFailedToUpdateLocation = 'Failed to update location';
  static const String errorFailedToEndTrip = 'Failed to end trip';
  static const String errorFailedToSend5MinAlert = 'Failed to send 5-minute alert';
  static const String errorFailedToMarkPickupHome = 'Failed to mark pickup from home';
  static const String errorFailedToMarkDropSchool = 'Failed to mark drop to school';
  static const String errorFailedToMarkPickupSchool = 'Failed to mark pickup from school';
  static const String errorFailedToMarkDropHome = 'Failed to mark drop to home';
  static const String errorFailedToConnectNotifications = 'Failed to connect to notifications';
  static const String errorFailedToDisconnect = 'Failed to disconnect';
  static const String errorFailedToSubscribeChannel = 'Failed to subscribe to channel';
  static const String errorFailedToUnsubscribeChannel = 'Failed to unsubscribe from channel';
  static const String errorFailedToSendMessage = 'Failed to send message';
  static const String errorFailedToLoadParentDashboard = 'Failed to load parent dashboard';
  static const String errorFailedToLoadParentProfile = 'Failed to load parent profile';
  static const String errorFailedToUpdateParentProfile = 'Failed to update profile';
  static const String errorFailedToLoadParentStudents = 'Failed to load students';
  static const String errorFailedToLoadParentTrips = 'Failed to load trips';
  static const String errorFailedToLoadParentNotifications = 'Failed to load notifications';
  static const String errorFailedToLoadAttendanceHistory = 'Failed to load attendance history';
  static const String errorFailedToLoadMonthlyReport = 'Failed to load monthly report';
  static const String errorFailedToLoadVehicleTracking = 'Failed to load vehicle tracking';
  static const String errorFailedToLoadDriverLocation = 'Failed to load driver location';
  static const String errorFailedToLoadSchoolDashboard = 'Failed to load school dashboard';
  static const String errorFailedToLoadSchoolProfile = 'Failed to load school profile';
  static const String errorFailedToLoadSchoolStudents = 'Failed to load students';
  static const String errorFailedToLoadSchoolStaff = 'Failed to load staff';
  static const String errorFailedToLoadSchoolVehicles = 'Failed to load vehicles';
  static const String errorFailedToLoadSchoolTrips = 'Failed to load trips';
  static const String errorFailedToLoadSchoolReports = 'Failed to load reports';
  static const String errorFailedToLoadVehicleOwnerDashboard = 'Failed to load vehicle owner dashboard';
  static const String errorFailedToLoadVehicleOwnerProfile = 'Failed to load vehicle owner profile';
  static const String errorFailedToUpdateVehicleOwnerProfile = 'Failed to update profile';
  static const String errorFailedToLoadVehicleOwnerVehicles = 'Failed to load vehicles';
  static const String errorFailedToLoadVehicleOwnerDrivers = 'Failed to load drivers';
  static const String errorFailedToLoadVehicleOwnerTrips = 'Failed to load trips';
  static const String errorFailedToLoadVehicleOwnerReports = 'Failed to load reports';
  static const String errorFailedToAddVehicle = 'Failed to add vehicle';
  static const String errorFailedToAddDriver = 'Failed to add driver';
  static const String errorFailedToAssignDriver = 'Failed to assign driver';
  
  // HTTP Error Messages (for ErrorHandler)
  static const String errorBadRequest = 'Bad Request - Please check your input';
  static const String errorUnauthorized = 'Unauthorized - Please login again';
  static const String errorForbidden = 'Forbidden - You do not have permission';
  static const String errorNotFound = 'Not Found - Resource not available';
  static const String errorConflict = 'Conflict - Resource already exists';
  static const String errorValidationError = 'Validation Error - Please check your input';
  static const String errorInternalServerError = 'Internal Server Error - Please try again later';
  static const String errorServiceUnavailable = 'Service Unavailable - Please try again later';
  static const String errorRequestFailedStatus = 'Request failed with status';
  
  // Network Error Messages
  static const String errorNetworkOccurred = 'Network error occurred';
  static const String errorNoInternetConnection = 'No internet connection. Please check your network.';
  static const String errorRequestTimeout = 'Request timeout. Please try again.';
  static const String errorConnectionFailed = 'Connection failed. Please check your internet connection.';
  static const String errorUnexpectedOccurred = 'An unexpected error occurred';
  
  // User-Friendly Error Messages (for ErrorHandler)
  static const String errorCheckInternetTryAgain = 'Please check your internet connection and try again.';
  static const String errorLoginAgainToContinue = 'Please login again to continue.';
  static const String errorServerTryAgainLater = 'Server error. Please try again later.';
  static const String errorSomethingWentWrong = 'Something went wrong. Please try again.';
  
  // Error Codes (for ErrorHandler)
  static const String errorCodeBadRequest = 'BAD_REQUEST';
  static const String errorCodeUnauthorized = 'UNAUTHORIZED';
  static const String errorCodeForbidden = 'FORBIDDEN';
  static const String errorCodeNotFound = 'NOT_FOUND';
  static const String errorCodeConflict = 'CONFLICT';
  static const String errorCodeValidationError = 'VALIDATION_ERROR';
  static const String errorCodeInternalError = 'INTERNAL_ERROR';
  static const String errorCodeServiceUnavailable = 'SERVICE_UNAVAILABLE';
  static const String errorCodeHttpError = 'HTTP_ERROR';
  
  // UI Labels for Error Dialogs
  static const String labelError = 'Error';
  static const String labelOk = 'OK';
  static const String labelDismiss = 'Dismiss';
  
  // State Manager Labels
  static const String labelNoDataAvailable = 'No data available';
  static const String labelLoading = 'Loading...';
  
  // Notification Badge Labels
  static const String labelNotificationOverflow = '99+';
  
  // Notification Card Labels
  static const String labelJustNow = 'Just now';
  static const String labelMinutesAgo = 'm ago';
  static const String labelHoursAgo = 'h ago';
  static const String labelDaysAgo = 'd ago';
  
  // School Selector Labels
  static const String labelSelectSchool = 'Select School';
  static const String labelNoSchools = 'No Schools';
  static const String labelNoSchoolsAssociated = 'No schools associated with your account';
  
  // School Selector Error Messages
  static const String errorUserNotFound = 'User not found. Please login again.';
  static const String errorFailedToLoadSchools = 'Failed to load schools: ';
  static const String errorFailedToLoadOwnerData = 'Failed to load owner data: ';
  static const String errorLoadingSchools = 'Error loading schools: ';
  
  // Activation Screen Labels
  static const String labelActivateAccount = 'Activate Account';
  static const String labelChooseUsername = 'Choose Username';
  static const String labelActivateCreateAccount = 'Activate & Create Account';
  static const String labelRegisterAgain = 'Register Again';
  static const String labelSchoolInformation = 'School Information';
  static const String labelSchoolWithColon = 'School: ';
  static const String labelEmailWithColon = 'Email: ';
  static const String labelAgreeToThe = 'I agree to the ';
  static const String labelPrivacyPolicyTerms = 'Privacy Policy & Terms';
  
  // Activation Screen Messages
  static const String msgInvalidActivationLink = 'Invalid activation link';
  static const String msgInvalidTokenExpired = 'This activation link is invalid or expired.';
  static const String msgUnableToVerify = 'Unable to verify activation link. Please try again.';
  static const String msgAgreeToTerms = 'Please agree to Privacy Policy & Terms';
  static const String msgRegistrationCompleted = 'Registration completed. You can now login.';
  static const String msgActivationFailed = 'Activation failed';
  static const String msgActivationFailedPrefix = 'Activation failed: ';
  
  // Activation Screen Titles
  static const String titleInvalidToken = 'Invalid Token';
  static const String titleVerificationFailed = 'Verification Failed';
  
  // Activation Screen Validation Messages
  static const String validationEnterUsername = 'Enter username';
  static const String validationMinChars = 'Min 6 chars';
  static const String validationPasswordsDoNotMatch = 'Passwords do not match';
  static const String labelRequired = 'Required';
  
  // Activation Screen Entity Types
  static const String entityTypeSchool = 'SCHOOL';
  
  // App Admin Profile Labels
  static const String labelAppAdminProfile = 'App Admin Profile';
  static const String labelAppAdministrator = 'App Administrator';
  static const String labelProfileInformation = 'Profile Information';
  static const String labelAccountInformation = 'Account Information';
  static const String labelFullName = 'Full Name';
  static const String labelEmailAddress = 'Email Address';
  static const String labelMobileNumber = 'Mobile Number';
  static const String labelUserId = 'User ID';
  static const String labelRole = 'Role';
  static const String labelAccountStatus = 'Account Status';
  static const String labelLastLogin = 'Last Login';
  static const String labelAccountCreated = 'Account Created';
  static const String labelCancel = 'Cancel';
  static const String buttonOk = 'OK';
  static const String labelSaveChanges = 'Save Changes';
  
  // App Admin Profile Default Values
  static const String defaultAppAdminName = 'App Admin';
  static const String defaultAppAdminEmail = 'appadmin@kidstracker.com';
  static const String defaultAppAdminMobile = '9999999999';
  static const String defaultAppAdminUserId = 'APP_ADMIN_001';
  static const String defaultAccountStatusActive = 'Active';
  static const String defaultLastLoginJustNow = 'Just now';
  static const String defaultAccountCreatedSystem = 'System Generated';
  
  // App Admin Profile Messages
  static const String msgErrorLoadingProfile = 'Error loading profile data: ';
  static const String msgProfileUpdatedSuccessfully = 'Profile updated successfully!';
  static const String msgErrorUpdatingProfile = 'Error updating profile: ';
  
  // App Admin Profile Validation Messages
  static const String validationEnterName = 'Please enter your name';
  static const String validationEnterEmail = 'Please enter your email';
  static const String validationEnterValidEmail = 'Please enter a valid email';
  static const String validationEnterMobile = 'Please enter your mobile number';
  static const String validationEnterValid10DigitMobile = 'Please enter a valid 10-digit mobile number';
  
  // Validation Regex Patterns
  static const String regexEmail = r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$';
  static const String regexPhone10Digit = r'^[0-9]{10}$';
  
  // School Management Labels
  static const String labelSchoolManagement = 'School Management';
  static const String labelTotalSchools = 'Total Schools';
  static const String labelActive = 'Active';
  static const String labelInactive = 'Inactive';
  static const String labelSearch = 'Search';
  static const String labelDeactivate = 'Deactivate';
  static const String labelActivate = 'Activate';
  static const String labelSetDates = 'Set Dates';
  static const String labelResendActivationLink = 'Resend Activation Link';
  static const String labelUpdateDatesFor = 'Update Dates for';
  static const String labelStartDate = 'Start Date';
  static const String labelEndDate = 'End Date';
  static const String labelNotSet = 'Not set';
  static const String labelUpdate = 'Update';
  static const String labelResend = 'Resend';
  
  // School Management Hints/Placeholders
  static const String hintSearchSchools = 'Search schools by name, city, or state...';
  
  // School Management Messages
  static const String msgErrorLoadingData = 'Error loading data: ';
  static const String msgSearchFailed = 'Search failed';
  static const String msgErrorSearchingSchools = 'Error searching schools: ';
  static const String msgStatusUpdatedSuccessfully = 'Status updated successfully';
  static const String msgFailedToUpdateStatus = 'Failed to update status';
  static const String msgErrorUpdatingStatus = 'Error updating status: ';
  static const String msgDatesUpdatedSuccessfully = 'Dates updated successfully';
  static const String msgFailedToUpdateDates = 'Failed to update dates';
  static const String msgErrorUpdatingDates = 'Error updating dates: ';
  static const String msgActivationLinkSentSuccessfully = 'Activation link sent successfully';
  static const String msgFailedToSendActivationLink = 'Failed to send activation link';
  static const String msgErrorSendingActivationLink = 'Error sending activation link: ';
  static const String msgSendingActivationLink = 'Sending activation link...';
  static const String msgNoSchoolsFoundFor = 'No schools found for';
  static const String msgNoSchoolsFound = 'No schools found';
  static const String msgConfirmResendActivationLink = 'Are you sure you want to resend the activation link for';
  
  // School Management Date Formats
  static const String labelSession = 'Session:';
  static const String labelStarts = 'Starts:';
  static const String labelEnds = 'Ends:';
  static const String labelNoDatesSet = 'No dates set';
  
  // School Management Defaults
  static const String defaultUnknownSchool = 'Unknown School';
  static const String defaultSchoolName = 'School';
  static const int defaultDatePickerFirstYear = 2020;
  static const int defaultDatePickerLastYear = 2030;
  
  // School Management JSON Keys
  static const String keyTotalSchools = 'totalSchools';
  static const String keyActiveSchools = 'activeSchools';
  static const String keyInactiveSchools = 'inactiveSchools';
  static const String keyHasActiveUser = 'hasActiveUser';
  
  // Attendance History Labels
  static const String labelAttendanceHistory = 'Attendance History';
  static const String labelTotalDays = 'Total Days';
  static const String labelPresent = 'Present';
  static const String labelAbsent = 'Absent';
  static const String labelLate = 'Late';
  static const String labelAttendancePercentage = 'Attendance Percentage';
  static const String labelFrom = 'From:';
  static const String labelTo = 'To:';
  static const String labelDailyRecords = 'Daily Records';
  static const String labelArrival = 'Arrival:';
  static const String labelDeparture = 'Departure:';
  static const String labelRemarks = 'Remarks:';
  static const String labelUnknown = 'Unknown';
  static const String labelRetry = 'Retry';
  
  // Attendance History Tooltips
  static const String tooltipSelectDateRange = 'Select Date Range';
  static const String tooltipRefresh = 'Refresh';
  
  // Attendance History Messages
  static const String msgUserIdNotFound = 'User ID not found. Please login again.';
  static const String msgErrorLoadingAttendanceHistory = 'Error loading attendance history: ';
  static const String msgNoAttendanceData = 'No attendance data found';
  static const String msgNoAttendanceRecords = 'No attendance records found for the selected period';
  
  // Attendance History Thresholds
  static const double attendanceExcellentThreshold = 90.0;
  static const double attendanceGoodThreshold = 75.0;
  static const int attendanceDefaultDaysBack = 30;
  static const int attendanceDatePickerFirstYear = 2020;
  
  // App Admin Dashboard Labels
  static const String labelAppAdminDashboard = 'App Admin Dashboard';
  static const String labelAppAdminMenu = 'App Admin Menu';
  static const String labelProfile = 'Profile';
  static const String labelSystemReports = 'System Reports';
  static const String labelSystemStatistics = 'System Statistics';
  static const String labelTotalUsers = 'Total Users';
  static const String labelActiveSessions = 'Active Sessions';
  static const String labelSchoolsOverview = 'Schools Overview';
  static const String labelViewAll = 'View All';
  static const String labelQuickActions = 'Quick Actions';
  static const String labelManageSchools = 'Manage Schools';
  static const String labelSettings = 'Settings';
  static const String labelSystemAlert = 'System Alert';
  static const String labelViewDetails = 'VIEW DETAILS';
  static const String labelID = 'ID:';
  static const String labelNA = 'N/A';
  
  // App Admin Dashboard Messages
  static const String msgNoSchoolsRegistered = 'No schools registered';
  static const String msgWebSocketInitialized = '✅ WebSocket initialized for App Admin Dashboard';
  static const String msgReceivedNotification = '🔔 Received notification: ';
  static const String msgReceivedSystemAlert = '🚨 Received system alert: ';
  static const String msgNotificationStreamError = '❌ Notification stream error: ';
  static const String msgSystemAlertStreamError = '❌ System alert stream error: ';
  static const String msgWebSocketInitError = '❌ WebSocket initialization error: ';
  static const String msgNoDataAvailable = 'No data available';
  
  // App Admin Dashboard Notification Types
  static const String notifTypeNewSchoolRegistration = 'NEW_SCHOOL_REGISTRATION';
  static const String notifTypeSystemError = 'SYSTEM_ERROR';
  static const String notifTypeEmergencyAlert = 'EMERGENCY_ALERT';
  static const String notifTypeDatabaseBackup = 'DATABASE_BACKUP_COMPLETED';
  static const String notifTypeSystemAlert = 'SYSTEM_ALERT';
  static const String notifTypeAlert = 'ALERT';
  static const String notifTypeInfo = 'INFO';
  static const String notifTypeSuccess = 'SUCCESS';
  
  // App Admin Dashboard JSON Keys
  static const String keyTotalUsers = 'totalUsers';
  static const String keyActiveSessions = 'activeSessions';
  
  // Driver Dashboard Labels
  static const String labelDriverDashboard = 'Driver Dashboard';
  static const String labelDriverMenu = 'Driver Menu';
  static const String labelReports = 'Reports';
  static const String labelDriverPerformanceSummary = 'Driver Performance Summary';
  static const String labelTotalTrips = 'Total Trips';
  static const String labelTotalStudents = 'Total Students';
  static const String labelStudentsPickedUp = 'Students Picked Up';
  static const String labelStudentsDropped = 'Students Dropped';
  static const String labelSelectTripType = 'Select Trip Type';
  static const String labelMorningPickup = 'Morning Pickup';
  static const String labelAfternoonDrop = 'Afternoon Drop';
  static const String labelSelectTrip = 'Select Trip';
  static const String labelChooseTrip = 'Choose a trip';
  static const String labelSelectedTrip = 'Selected Trip';
  static const String labelTrip = 'Trip:';
  static const String labelActiveTripStatus = 'Active';
  static const String labelInactiveTripStatus = 'Inactive';
  static const String labelStopTrip = 'Stop Trip';
  static const String labelStartTrip = 'Start Trip';
  static const String labelViewStudents = 'View Students';
  static const String labelLocationPermissionRequired = 'Location Permission Required';
  static const String labelLocationSettings = 'Location Settings';
  static const String labelOpenSettings = 'Open Settings';
  static const String labelHelpSupport = 'Help & Support';
  static const String labelTripActiveTracking = 'Trip Active - Location Tracking';
  static const String labelTripInactive = 'Trip Inactive';
  static const String labelDriverInstructions = 'Driver Instructions';
  static const String textDriverInstructions =
      "1. Select a trip from the dropdown above\n"
      "2. Click 'View Students' to see pickup order\n"
      "3. Click 'Send Alert' to notify parents\n"
      "4. Mark pickup/drop for each student";
  static const String textHelpSupportContent =
      'For any issues or questions:\n\n'
      '• Contact your school administrator\n'
      '• Check your internet connection\n'
      '• Make sure you\'re in the correct time slot\n'
      '• Refresh the app if data seems outdated';
  static const String msgLimitedData = 'Limited data available. ';
  static const String msgProfileNotLoaded = 'Profile not loaded. ';
  static const String msgReportsNotAvailable = 'Reports not available. ';
  static const String msgEnsureActivatedAndAssigned =
      'Please ensure your account is activated and a vehicle is assigned.';
  static const String msgProfileNotLoadedWait = 'Profile data not loaded yet. Please wait...';
  static const String msgReportsNotLoadedWait = 'Reports data not loaded yet. Please wait...';
  static const String msgSendingFiveMinuteAlert = 'Sending 5-minute alert...';
  static const String msgNoMorningTrips = 'No morning pickup trips available';
  static const String msgNoAfternoonTrips = 'No afternoon drop trips available';
  static const String msgTripStoppedSuccessfully = 'Trip stopped successfully';
  static const String msgFailedToStopTrip = 'Failed to stop trip';
  static const String msgErrorStoppingTrip = 'Error stopping trip: ';
  static const String msgLocationPermissionRequired =
      'This app needs location permission to track your trip and share your location with parents. Please grant location permission in the app settings.';
  static const String msgEnableLocationServices =
      'Location services are disabled. Please enable them in your device settings to start trip tracking.';
  static const String msgDriverAccountNotActivated =
      'Your driver account is not activated yet. Please check your email for the activation link or contact your administrator.';
  static const String msgNoVehicleAssigned =
      'No vehicle is currently assigned to you. Please contact your school administrator to assign a vehicle.';
  static const String msgSelectTripFirst = 'Please select a trip first';
  
  // Driver Dashboard Messages
  static const String msgDriverIdNotFound = 'Driver ID not found. Please login again.';
  static const String msgLocationPermissionMsg = 'Please enable location permission to start the trip.';
  static const String msgLocationPermissionDenied = 'Location permission is permanently denied. Please enable it in app settings.';
  static const String msgWebSocketInitializedDriver = '✅ WebSocket initialized for Driver Dashboard';
  static const String msgReceivedTripUpdate = '🚌 Received trip update: ';
  static const String msgTripUpdateStreamError = '❌ Trip update stream error: ';
  
  // Driver Dashboard Notification Types
  static const String notifTypeTripAssigned = 'TRIP_ASSIGNED';
  static const String notifTypeTripCancelled = 'TRIP_CANCELLED';
  static const String notifTypeRouteChanged = 'ROUTE_CHANGED';
  static const String notifTypeStudentAbsent = 'STUDENT_ABSENT';
  static const String notifTypeArrival = 'ARRIVAL';
  static const String notifTypePickup = 'PICKUP';
  static const String notifTypeDrop = 'DROP';
  
  // Login Screen Labels
  static const String labelSchoolTracker = 'School Tracker';
  static const String labelLoginId = 'Login ID';
  static const String labelLogin = 'Login';
  static const String labelRegisterSchoolLink = "Don't have an account? Register your school";
  static const String labelForgotPassword = 'Forgot Password?';
  static const String labelView = 'VIEW';
  
  // Login Screen Validation Messages
  static const String msgEnterLoginId = 'Please enter your login ID';
  static const String msgEnterPassword = 'Please enter your password';
  
  // Parent Dashboard Labels
  static const String labelParentDashboard = 'Parent Dashboard';
  static const String labelParentMenu = 'Parent Menu';
  static const String labelChildren = 'Children';
  static const String labelActiveTrips = 'Active Trips';
  static const String labelAttendance = 'Attendance';
  static const String labelQuickStats = 'Quick Stats';
  static const String labelChildrenStatus = 'Children Status';
  static const String labelRecentNotifications = 'Recent Notifications';
  static const String labelTrackVehicle = 'Track Vehicle';
  static const String labelMonthlyReport = 'Monthly Report';
  static const String labelSafe = 'Safe';
  static const String labelNotification = 'Notification';
  static const String labelNotifications = 'Notifications';
  static const String labelAttendancePercent = '95%';
  
  // Parent Dashboard Messages
  static const String msgNoChildrenRegistered = 'No children registered';
  static const String msgNoNotifications = 'No notifications';
  static const String msgWebSocketInitializedParent = '✅ WebSocket initialized for Parent Dashboard';
  static const String msgReceivedPickupNotification = '🚌 Received pickup notification: ';
  static const String msgReceivedDropNotification = '🏠 Received drop notification: ';
  static const String msgPickupNotificationError = '❌ Pickup notification error: ';
  static const String msgDropNotificationError = '❌ Drop notification error: ';
  
  // Parent Dashboard Notification Types
  static const String notifTypePickupNotification = 'PICKUP_NOTIFICATION';
  static const String notifTypeDropNotification = 'DROP_NOTIFICATION';
  static const String notifTypePickupFromHome = 'PICKUP_FROM_HOME';
  static const String notifTypeDropToHome = 'DROP_TO_HOME';
  static const String notifTypeStudentAbsentParent = 'STUDENT_ABSENT';
  static const String notifTypeTripDelayed = 'TRIP_DELAYED';
  static const String notifTypePickupFromParent = 'PICKUP_FROM_PARENT';
  static const String notifTypeDropToParent = 'DROP_TO_PARENT';
  static const String notifTypeDelayNotification = 'DELAY_NOTIFICATION';
  
  // School Admin Dashboard Labels
  static const String labelSchoolAdminDashboard = 'School Admin Dashboard';
  static const String labelSchoolAdminMenu = 'School Admin Menu';
  static const String labelDashboard = 'Dashboard';
  static const String labelSchoolProfile = 'School Profile';
  static const String labelStudents = 'Students';
  static const String labelBulkStudentImport = 'Bulk Student Import';
  static const String labelClassManagement = 'Class Management';
  static const String labelSectionManagement = 'Section Management';
  static const String labelPeople = 'People';
  static const String labelStaff = 'Staff';
  static const String labelVehicleOwners = 'Vehicle Owners';
  static const String labelDrivers = 'Drivers';
  static const String labelParents = 'Parents';
  static const String labelTransport = 'Transport';
  static const String labelVehicles = 'Vehicles';
  static const String labelTrips = 'Trips';
  static const String labelRecentActivities = 'Recent Activities';
  static const String labelAddStudent = 'Add Student';
  static const String labelAddVehicleOwner = 'Add Vehicle Owner';
  static const String labelAddStaff = 'Add Staff';
  static const String labelCreateTrip = 'Create Trip';
  static const String labelViewPendingRequests = 'View Pending Requests';
  static const String labelPendingRequests = 'Pending Requests';
  static const String labelNew = 'NEW';
  static const String labelApprovals = 'Approvals';
  
  // School Admin Dashboard Messages
  static const String msgSchoolIdNotFound = 'School ID not found. Please login again.';
  static const String msgNoRecentActivities = 'No recent activities';
  static const String msgWebSocketInitializedSchoolAdmin = '✅ WebSocket initialized for School Admin Dashboard';
  
  // School Admin Dashboard Notification Types
  static const String notifTypeTripStarted = 'TRIP_STARTED';
  static const String notifTypeTripCompleted = 'TRIP_COMPLETED';
  static const String notifTypeTripAlert = 'TRIP_ALERT';
  static const String notifTypeStudentAbsentSchool = 'STUDENT_ABSENT';
  static const String notifTypeDriverDelayed = 'DRIVER_DELAYED';
  static const String notifTypeVehicleAssignmentRequest = 'VEHICLE_ASSIGNMENT_REQUEST';
  
  // Vehicle Owner Dashboard Labels
  static const String labelVehicleOwnerDashboard = 'Vehicle Owner Dashboard';
  static const String labelVehicleOwnerMenu = 'Vehicle Owner Menu';
  static const String labelDriverAssignment = 'Driver Assignment';
  static const String labelSchoolMapping = 'School Mapping';
  static const String labelStudentTripAssignment = 'Student-Trip Assignment';
  static const String labelLogout = 'Logout';
  static const String labelTotalRevenue = 'Total Revenue';
  static const String labelAddVehicle = 'Add Vehicle';
  static const String labelAddDriver = 'Add Driver';
  static const String labelAssignDriver = 'Assign Driver';
  static const String labelRequestSchoolAssignment = 'Request School Assignment';
  static const String labelManageTrips = 'Manage Trips';
  
  // Vehicle Owner Dashboard Messages
  static const String msgOwnerIdNotFound = 'Vehicle owner ID not found. Please login again.';
  static const String msgWebSocketInitializedVehicleOwner = '✅ WebSocket initialized for Vehicle Owner Dashboard';
  
  // Vehicle Owner Dashboard Notification Types
  static const String notifTypeVehicleAssignmentApproved = 'VEHICLE_ASSIGNMENT_APPROVED';
  static const String notifTypeVehicleAssignmentRejected = 'VEHICLE_ASSIGNMENT_REJECTED';
  static const String notifTypeDriverAlert = 'DRIVER_ALERT';
  
  // Bulk Student Import Labels
  static const String labelBulkImport = 'Bulk Student Import';
  static const String labelSchoolID = 'School ID';
  static const String labelImportConfiguration = 'Import Configuration';
  static const String labelSchoolEmailDomain = 'School Email Domain';
  static const String labelEmailStrategy = 'Email Strategy';
  static const String labelParentEmailRequired = 'Parent Email is Required';
  static const String labelSendActivationEmails = 'Send Activation Emails';
  static const String labelExcelFile = 'Excel File';
  static const String labelSelectExcelFile = 'Select Excel File';
  static const String labelDownloadTemplate = 'Download Template';
  static const String labelValidateData = 'Validate Data';
  static const String labelImportStudents = 'Import Students';
  static const String labelValidationResults = 'Validation Results';
  static const String labelImportResults = 'Import Results';
  static const String labelTotal = 'Total';
  static const String labelSuccess = 'Success';
  static const String labelFailed = 'Failed';
  static const String labelImportSummary = 'Import Summary';
  static const String labelTotalRows = 'Total Rows';
  static const String labelSuccessful = 'Successful';
  static const String labelDetails = 'Details';
  static const String labelRow = 'Row';
  static const String labelValidating = 'Validating...';
  static const String labelImporting = 'Importing...';
  static const String labelSelected = 'Selected';
  
  // Bulk Student Import Messages
  static const String msgErrorPickingFile = 'Error picking file: ';
  static const String msgTemplateDownloaded = 'Template downloaded to: ';
  static const String msgErrorDownloadingTemplate = 'Error downloading template: ';
  static const String msgPleaseSelectExcelFile = 'Please select an Excel file first';
  static const String msgNoValidStudentData = 'No valid student data found in Excel file';
  static const String msgValidationSuccessful = 'Validation successful! ';
  static const String msgStudentsReadyForImport = ' students are ready for import.';
  static const String msgValidationFailed = 'Validation failed. ';
  static const String msgStudentsHaveErrors = ' students have errors.';
  static const String msgErrorValidatingData = 'Error validating data: ';
  static const String msgPleaseValidateFirst = 'Please validate data first';
  static const String msgImportSuccessful = 'Import successful! ';
  static const String msgStudentsImported = ' students imported.';
  static const String msgImportCompletedWithErrors = 'Import completed with errors. ';
  static const String msgSuccessful = ' successful, ';
  static const String msgFailed = ' failed.';
  static const String msgErrorImportingData = 'Error importing data: ';
  static const String msgAndMoreErrors = '... and ';
  static const String msgMoreErrors = ' more errors';
  static const String msgAndMore = '... and ';
  static const String msgMore = ' more';
  
  // Bulk Student Import Hints
  static const String hintSchoolDomain = 'e.g., schoolname.edu';
  static const String hintEmailPrefix = '@';
  
  // Bulk Student Import Validation Messages
  static const String validationInvalidDomain = 'Please enter a valid domain (e.g., schoolname.edu)';
  
  // Bulk Student Import Info
  static const String infoAllParentEmailsRequired = '• All parent emails must be provided in the Excel file\n'
      '• Emails are used to send activation links for parent accounts\n'
      '• Invalid or missing emails will cause import to fail';
  static const String infoSendActivationToParents = 'Send activation emails to parents';
  
  // Bulk Student Import File Names
  static const String fileNameStudentTemplate = 'student_import_template.xlsx';
  
  // Class Management Labels
  static const String labelEditClass = 'Edit Class';
  static const String labelAddNewClass = 'Add New Class';
  static const String labelClassName = 'Class Name *';
  static const String labelOrder = 'Order *';
  static const String labelDescriptionOptional = 'Description (Optional)';
  static const String labelUpdateClass = 'Update Class';
  static const String labelAddClass = 'Add Class';
  static const String labelDeleteClass = 'Delete Class';
  static const String labelEdit = 'Edit';
  static const String labelDelete = 'Delete';
  
  // Class Management Hints
  static const String hintClassName = 'e.g., Nursery, KG, 1, 2';
  static const String hintClassOrder = '1, 2, 3';
  static const String hintClassDescription = 'Additional details about the class';
  
  // Class Management Messages
  static const String msgSchoolIdNotFoundLogin = 'School ID not found. Please login again.';
  static const String msgFailedToLoadClasses = 'Failed to load classes';
  static const String msgErrorLoadingClasses = 'Error loading classes: ';
  static const String msgClassUpdatedSuccessfully = 'Class updated successfully';
  static const String msgClassCreatedSuccessfully = 'Class created successfully';
  static const String msgOperationFailed = 'Operation failed';
  static const String msgDeleteConfirmation = 'Are you sure you want to delete "';
  static const String msgClassDeletedSuccessfully = 'Class deleted successfully';
  static const String msgFailedToDeleteClass = 'Failed to delete class';
  static const String msgErrorDeletingClass = 'Error deleting class: ';
  static const String msgClassStatusUpdated = 'Class status updated successfully';
  static const String msgNoClassesFound = 'No classes found.\nAdd your first class above.';
  
  // Class Management Validation Messages
  static const String validationClassNameRequired = 'Class name is required';
  static const String validationClassNameMaxLength = 'Class name cannot exceed 50 characters';
  static const String validationOrderRequired = 'Order is required';
  static const String validationEnterValidNumber = 'Enter valid number';
  
  // Create Trip Labels
  static const String labelTripName = 'Trip Name';
  static const String labelTripNumber = 'Trip Number';
  static const String labelTripType = 'Trip Type';
  // labelSelectVehicle already exists globally
  static const String labelRouteName = 'Route Name';
  static const String labelRouteDescription = 'Route Description';
  static const String labelCreatingTrip = 'Creating Trip...';
  static const String labelGoBack = 'Go Back';
  static const String labelNoVehiclesAvailable = 'No Vehicles Available';
  static const String labelStepsToAddVehicles = 'Steps to add vehicles:';
  static const String labelUnknownVehicle = 'Unknown Vehicle';
  
  // Create Trip Hints
  static const String hintTripName = 'Enter trip name';
  static const String hintTripNumber = 'Enter trip number';
  static const String hintRouteName = 'Enter route name';
  static const String hintRouteDescription = 'Enter detailed route information';
  
  // Create Trip Messages
  static const String msgFillAllRequiredFields = 'Please fill all required fields and select a vehicle';
  static const String msgSchoolIdNotFoundLoginAgain = 'School ID not found. Please login again.';
  static const String msgTripCreatedSuccessfully = 'Trip Created Successfully ✅';
  static const String msgFailedToCreateTrip = 'Failed to create trip. Check console for details.';
  static const String msgNoVehiclesInfo = 'To create a trip, you need approved vehicles assigned to your school.';
  static const String msgVehicleStepOne = '1. Vehicle Owner creates vehicles';
  static const String msgVehicleStepTwo = '2. Vehicle Owner requests school assignment';
  static const String msgVehicleStepThree = '3. School Admin approves the requests';
  
  // Create Trip Validation Messages
  static const String validationEnterTripName = 'Enter trip name';
  static const String validationEnterTripNumber = 'Enter trip number';
  static const String validationSelectTripType = 'Select trip type';
  static const String validationSelectVehicle = 'Select a vehicle';
  static const String validationEnterRouteName = 'Enter route name';
  static const String validationEnterRouteDescription = 'Enter route description';
  
  // Create Trip Debug Messages
  static const String debugLoadingVehicles = '🔹 CreateTripPage: Loading vehicles for schoolId: ';
  static const String debugLoadedVehicles = '🔹 CreateTripPage: Loaded ';
  static const String debugVehiclesText = ' vehicles';
  static const String debugNoVehiclesWarning = '⚠️ CreateTripPage: No vehicles found! Please ensure:';
  static const String debugVehicleStep1 = '   1. Vehicles are created by Vehicle Owner';
  static const String debugVehicleStep2 = '   2. Vehicle assignment requests are submitted to School Admin';
  static const String debugVehicleStep3 = '   3. School Admin has APPROVED the vehicle requests';
  static const String debugSchoolIdUserName = '🔹 CreateTripPage: schoolId=';
  static const String debugUserNameSuffix = ', userName=';
  static const String debugSelectedVehicle = '🔹 CreateTripPage: selectedVehicle=';
  static const String debugSubmittingTrip = '🔹 CreateTripPage: Submitting trip request...';
  static const String debugTripCreationException = '❌ CreateTripPage: Exception during trip creation - ';
  
  // Driver Management Labels
  static const String labelDriverManagement = 'Driver Management';
  static const String labelViewAndManageDrivers = 'View and manage all drivers';
  
  // Driver Profile Labels
  static const String labelDriverProfile = 'Driver Profile';
  static const String labelProfilePhoto = 'Profile Photo';
  static const String labelPersonalInformation = 'Personal Information';
  static const String labelContactNumber = 'Contact Number';
  static const String labelDriverID = 'Driver ID';
  static const String labelMemberSince = 'Member Since';
  static const String labelLastUpdated = 'Last Updated';
  static const String labelChangePhoto = 'Change Photo';
  static const String labelChooseFromGallery = 'Choose from Gallery';
  static const String labelTakePhoto = 'Take Photo';
  
  // Driver Profile Messages
  // msgErrorPickingImage and msgErrorTakingPhoto are already defined globally
  static const String msgFailedToUpdateProfile = 'Failed to update profile';
  
  // Driver Reports Labels
  static const String labelDriverReports = 'Driver Reports';
  static const String labelToday = 'Today';
  static const String labelThisWeek = 'This Week';
  static const String labelThisMonth = 'This Month';
  static const String labelViewing = 'Viewing: ';
  static const String labelOverallStatistics = 'Overall Statistics';
  static const String labelStudentsTransported = 'Students Transported';
  static const String labelDistanceCovered = 'Distance Covered';
  static const String labelAverageRating = 'Average Rating';
  static const String labelStatistics = ' Statistics';
  static const String labelPickups = 'Pickups';
  static const String labelDrops = 'Drops';
  static const String labelPerformanceMetrics = 'Performance Metrics';
  static const String labelTripCompletionRate = 'Trip Completion Rate';
  static const String labelPunctualityScore = 'Punctuality Score';
  static const String labelSafetyRecord = 'Safety Record';
  static const String labelRecentTrips = 'Recent Trips';
  static const String labelAttendanceRecords = 'Attendance Records';
  static const String labelKm = ' km';
  static const String labelTripsSlash = ' trips • ';
  static const String labelPickupsText = ' pickups • ';
  static const String labelDropsText = ' drops';
  static const String labelStudentsBullet = ' students';
  static const String labelCompleted = 'Completed';
  static const String labelInProgress = 'In Progress';
  static const String labelCancelled = 'Cancelled';
  
  // Enhanced Vehicle Tracking Labels
  static const String labelLiveVehicleTracking = 'Live Vehicle Tracking';
  static const String labelRefresh = 'Refresh';
  static const String labelHome = 'Home';
  static const String labelNoActiveTrip = 'No Active Trip';
  static const String labelChildNotOnTrip = 'Your child is not currently on any trip.';
  static const String labelDriverLocation = 'Driver Location';
  static const String labelCurrentLocation = 'Current location';
  static const String labelDestination = 'Destination';
  static const String labelETA = 'ETA';
  static const String labelCalculating = 'Calculating...';
  static const String labelNoLocationData = 'No location data';
  static const String labelLiveTracking = 'Live tracking';
  static const String labelRecentUpdate = 'Recent update';
  static const String labelLocationOutdated = 'Location may be outdated';
  static const String labelStudentsCount = 'Students: ';
  
  // Enhanced Vehicle Tracking Messages
  static const String msgFailedToLoadTripData = 'Failed to load trip data: ';
  static const String msgWebSocketError = 'WebSocket error: ';
  static const String msgErrorGettingAddress = 'Error getting address: ';
  static const String msgErrorLoadingTrip = 'Error loading active trip: ';
  static const String msgWebSocketInitializedVehicleTracking = '🔌 WebSocket initialized for Enhanced Vehicle Tracking';
  static const String msgReceivedNotificationVehicleTracking = '🔔 Enhanced Vehicle Tracking - Received notification: ';
  
  // Enhanced Vehicle Tracking Constants
  static const double defaultLatitude = 28.6139;
  static const double defaultLongitude = 77.2090;
  static const double schoolLatitude = 28.6139;
  static const double schoolLongitude = 77.2090;
  static const double homeLatitude = 28.6141;
  static const double homeLongitude = 77.2092;
  static const int etaUpdateSeconds = 30;
  static const double averageSpeedKmh = 30.0;
  static const int locationLiveMinutes = 2;
  static const int locationRecentMinutes = 5;
  static const double locationOpacity = 0.3;
  
  // Home Page Labels
  static const String labelWelcomeToSchoolTracker = 'Welcome to School Tracker';
  static const String labelLoginRegister = 'Login/Register';
  
  // Forgot Password Labels
  static const String labelUsernameEmailMobile = 'Username / Email / Mobile';
  static const String labelEnterOTP = 'Enter OTP';
  static const String labelNewPassword = 'New Password';
  static const String labelSendOTP = 'Send OTP';
  static const String labelResetPassword = 'Reset Password';
  
  // Forgot Password Messages
  static const String msgEnterUsernameEmailMobile = 'Enter username/email/mobile';
  static const String msgEnterOTP = 'Enter OTP';
  static const String msgMinSixChars = 'Min 6 chars';
  static const String msgPasswordsDoNotMatch = 'Passwords do not match';
  static const String msgOTPSent = 'OTP sent';
  static const String msgPasswordResetSuccessful = 'Password reset successful';
  
  // Gate Staff Dashboard Labels
  static const String labelGateStaffDashboard = 'Gate Staff Dashboard';
  static const String labelWelcome = 'Welcome, ';
  static const String labelGateStaff = 'Gate Staff';
  static const String labelGateEntry = 'Gate Entry';
  static const String labelGateExit = 'Gate Exit';
  static const String labelStudentsByTrip = 'Students by Trip';
  static const String labelNoTripsScheduled = 'No trips scheduled for today';
  static const String labelUnknownTrip = 'Unknown Trip';
  static const String labelNoDriver = 'No Driver';
  static const String labelVehiclePrefix = 'Vehicle: ';
  static const String labelDriverPrefix = 'Driver: ';
  static const String labelNoStudentsAssigned = 'No students assigned to this trip';
  static const String labelEntry = 'Entry';
  static const String labelExit = 'Exit';
  static const String labelEntryChecked = '✓ Entry';
  static const String labelExitChecked = '✓ Exit';
  static const String labelMarkGatePrefix = 'Mark Gate ';
  static const String labelAddRemarks = 'Add remarks (optional):';
  static const String labelEnterRemarks = 'Enter remarks...';
  static const String labelStudentsSuffix = ' students';
  
  // Monthly Report Page Labels
  static const String labelSelectMonthYear = 'Select Month & Year';
  static const String labelYear = 'Year:';
  static const String labelMonth = 'Month:';
  static const String labelLoadReport = 'Load Report';
  static const String labelReportSuffix = ' Report';
  static const String labelAttendanceSummary = 'Attendance Summary';
  static const String labelSchoolDays = 'School Days';
  static const String labelTripSummary = 'Trip Summary';
  static const String labelMissed = 'Missed';
  static const String labelCompletionRate = 'Completion Rate';
  static const String labelPerformanceOverview = 'Performance Overview';
  static const String labelTripCompletion = 'Trip Completion';
  static const String labelNoReportData = 'No report data found';
  static const String labelColon = ': ';
  
  // Month Names
  static const List<String> monthNames = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];
  
  // Notification Page Labels
  static const String labelClearAll = 'Clear All';
  static const String labelClearAllNotifications = 'Clear All Notifications';
  static const String labelFilterAll = 'All';
  static const String labelFilterTripUpdates = 'Trip Updates';
  static const String labelFilterArrivals = 'Arrivals';
  static const String labelFilterPickups = 'Pickups';
  static const String labelFilterDrops = 'Drops';
  static const String labelFilterSystemAlerts = 'System Alerts';
  static const String labelNoNotifications = 'No notifications';
  static const String labelNotificationsSubtitle = 'You\'ll see real-time notifications here';
  
  // Notification Filter Options
  static const List<String> notificationFilterOptions = [
    'All',
    'Trip Updates',
    'Arrivals',
    'Pickups',
    'Drops',
    'System Alerts',
  ];
  
  // Parent Management Page Labels
  static const String labelParentManagement = 'Parent Management';
  static const String labelViewManageParents = 'View and manage all parents';
  
  // Parent Profile Update Page Labels
  static const String labelUpdateProfile = 'Update Profile';
  static const String labelCurrentPassword = 'Current Password';
  static const String labelConfirmNewPassword = 'Confirm New Password';
  static const String labelChangePasswordOptional = 'Change Password (Optional)';
  static const String labelPasswordHint = 'Leave password fields empty if you don\'t want to change password';
  static const String labelUpdating = 'Updating...';
  
  // Parent Profile Update Page Messages
  static const String msgErrorLoadingUserData = 'Error loading user data: ';
  static const String msgEnterFullName = 'Please enter your full name';
  static const String msgEnterEmail = 'Please enter your email';
  static const String msgEnterValidEmail = 'Please enter a valid email';
  static const String msgEnterContactNumber = 'Please enter your contact number';
  static const String msgContactNumberMinLength = 'Contact number must be at least 10 digits';
  static const String msgPasswordMinLength = 'Password must be at least 6 characters';
  
  // Pending Vehicle Requests Page Labels
  static const String labelPendingVehicleRequests = 'Pending Vehicle Requests';
  static const String labelNoPendingRequests = 'No pending requests';
  static const String labelOwnerPrefix = 'Owner: ';
  static const String labelTypePrefix = 'Type: ';
  static const String labelReject = 'Reject';
  static const String labelApprove = 'Approve';
  static const String labelAdmin = 'Admin';
  
  // Pending Vehicle Requests Page Messages
  static const String msgRequestApproved = 'Request Approved';
  static const String msgRequestRejected = 'Request Rejected';
  static const String msgActionFailed = 'Action failed';
  
  // Privacy Policy Screen Content
  static const String privacyPolicyContent = '''
Privacy Policy & Terms & Conditions

1. We respect your privacy and protect your data.
2. Your credentials will be securely stored and never shared without consent.
3. By registering and activating your account, you agree to these terms.
4. Replace this text with your real privacy policy from your organization.
            ''';
  
  // Register Driver Screen Labels
  static const String labelRegisterDriver = 'Register Driver';
  static const String labelDriverName = 'Driver Name *';
  static const String labelDriverContactNumber = 'Driver Contact Number *';
  static const String labelDriverAddress = 'Driver Address *';
  static const String labelEmailOptional = 'Email (Optional)';
  static const String hintMobileNumber = '10-digit mobile number';
  static const String hintEmailAddress = 'driver@example.com';
  
  // Register Gate Staff Page Labels
  static const String labelRegisterGateStaff = 'Register Gate Staff';
  static const String labelStaffNameRequired = 'Staff Name *';
  static const String labelUsernameRequired = 'Username *';
  static const String labelEmailOptionalLower = 'Email (optional)';
  static const String labelDisplayNameOptional = 'Display Name (Optional)';
  static const String hintStaffName = 'Enter staff name (e.g., Sunita, Rajesh)';
  static const String hintUniqueUsername = 'Enter unique username';
  static const String hintPassword = 'Enter password (6-100 characters)';
  static const String hintEmailAddressGeneral = 'Enter email address';
  static const String hintDisplayName = 'e.g., Teacher, Staff Member, etc.';
  static const String labelGateStaffRole = 'GATE_STAFF';
  static const String labelCreateGateStaff = 'Create Gate Staff';
  static const String labelCreatingStaff = 'Creating Staff...';
  static const String labelWillBeDisplayedAs = 'Will be displayed as: ';
  
  // Register Gate Staff Page Messages
  static const String msgGateStaffRoleNotFound = 'GATE_STAFF role not found in database';
  static const String msgFailedToLoadGateStaffRole = 'Failed to load GATE_STAFF role: ';
  static const String msgSchoolNotFoundPrefs = 'School not found in preferences';
  static const String msgUsernameRequired = 'Username is required';
  static const String msgStaffCreatedSuccessfully = 'Staff Created Successfully!';
  static const String msgGateStaffCreatedSuccess = 'Gate Staff \'%s\' created successfully!';
  static const String msgFailedToCreateStaff = 'Failed to create staff';
  static const String msgEnterStaffName = 'Enter staff name';
  static const String msgNameMinChars = 'Name must be at least 2 characters';
  static const String msgNameMaxChars = 'Name must not exceed 50 characters';
  static const String msgUsernameMinChars = 'Username must be at least 3 characters';
  static const String msgUsernameMaxChars = 'Username must not exceed 50 characters';
  static const String msgPasswordMaxChars = 'Password must not exceed 100 characters';
  static const String msgEmailMaxChars = 'Email must not exceed 150 characters';
  static const String msgContactNumberMustBe10Digits = 'Contact number must be 10 digits';
  static const String msgEnterValidIndianMobile = 'Enter valid Indian mobile number';
  static const String msgDisplayNameMaxChars = 'Display name must not exceed 50 characters';
  
  // Register School Screen Labels
  static const String labelSchoolRegistration = 'School Registration';
  static const String labelSchoolName = 'School Name';
  static const String labelSchoolType = 'School Type';
  static const String labelAffiliationBoard = 'Affiliation Board';
  static const String labelDistrict = 'District';
  static const String labelGallery = 'Gallery';
  static const String labelCamera = 'Camera';
  static const String labelRegisterSchool = 'Register School';
  static const String labelRegistering = 'Registering...';
  static const String labelGoToLogin = 'Go to Login';
  static const String labelEditManually = 'Edit Manually';
  static const String labelException = 'Exception';
  static const String hintSchoolName = 'Enter school name';
  static const String hintRegistrationNumber = 'Enter school registration number';
  static const String hintPincode6Digit = 'Enter 6-digit pincode';
  static const String hintCityName = 'Enter city name';
  static const String hintSchoolEmailAddress = 'Enter school email address';
  static const String helperMultipleLocations = ' locations found for this pincode';
  static const String infoLocationAutoFilled = 'Location auto-filled from pincode';
  
  // Common Domain Values
  static const String genderMale = 'Male';
  static const String genderFemale = 'Female';
  static const String genderOther = 'Other';
  static const String relationGuardian = 'GUARDIAN';
  
  // Register Student Screen Labels
  static const String labelRegisterStudent = 'Register Student';
  static const String labelFirstNameRequired = 'First Name *';
  static const String labelMiddleNameOptional = 'Middle Name (Optional)';
  static const String labelLastNameRequired = 'Last Name *';
  static const String labelGender = 'Gender';
  static const String labelClass = 'Class';
  static const String labelSection = 'Section';
  static const String labelMotherNameRequired = 'Mother Name *';
  static const String labelFatherNameRequired = 'Father Name *';
  static const String labelPrimaryContactRequired = 'Primary Contact *';
  static const String labelAlternateContactOptional = 'Alternate Contact (Optional)';
  // labelParentEmailRequired already exists globally
  static const String labelStudentRegisteredSuccessfully = 'Student registered successfully';
  
  // Register Student Screen Hints
  static const String hintMobile10Digits = 'Enter 10-digit mobile number';
  static const String hintParentEmail = 'Enter parent email address';
  
  // Register Student Screen Messages
  static const String msgThisFieldRequired = 'This field is required';
  static const String msgNameRequired = 'Name is required';
  static const String msgNameMin2 = 'Name must be at least 2 characters';
  static const String msgNameMax50 = 'Name must not exceed 50 characters';
  static const String msgNameLettersSpaces = 'Name can only contain letters and spaces';
  static const String msgContactRequired = 'Contact number is required';
  static const String msgContactExact10 = 'Contact number must be exactly 10 digits';
  static const String msgValidIndianMobileStart6to9 = 'Enter valid Indian mobile number (starting with 6-9)';
  static const String msgEmailRequired = 'Email is required';
  static const String msgEmailMax150 = 'Email must not exceed 150 characters';
  // msgEnterValidEmail already exists globally
  static const String msgSchoolIdMissingPrefs = 'School not found in preferences';
  static const String msgPleaseSelectClass = 'Please select a class';
  static const String msgPleaseSelectSection = 'Please select a section';
  static const String msgFailedToRegisterStudent = 'Failed to register student';
  static const String msgImagePickError = 'Image pick error: ';
  static const String msgRegistrationSuccessfulTitle = 'Registration Successful!';
  static const String msgParentActivationInfo =
      'A parent activation link has been sent to the provided email address. The parent can use this link to complete their registration and access the parent dashboard.';

  // Register Vehicle Owner Screen Labels/Hints
  static const String labelRegisterVehicleOwner = 'Register Vehicle Owner';
  static const String labelOwnerName = 'Owner Name';
  static const String hintOwnerFullName = 'Enter full name';
  static const String labelOwnerEmail = 'Email Address';
  static const String hintOwnerEmail = 'Enter email address';
  static const String labelOwnerContact = 'Contact Number';
  static const String labelOwnerAddress = 'Address';
  static const String hintOwnerAddress = 'Enter complete address';
  static const String labelOwnerPhotoOptional = 'Owner Photo (Optional)';
  static const String labelAddPhoto = 'Add Photo';
  static const String labelRemovePhoto = 'Remove Photo';
  static const String labelPhotoSelectedPrefix = 'Photo selected: ';
  static const String labelSelectImageSource = 'Select Image Source';
  static const String labelChooseHowToSelect = 'Choose how you want to select the image';
  static const String labelAssociateWithSchool = 'Associate with School';
  static const String labelVehicleOwnerAlreadyExists = 'Vehicle Owner Already Exists';
  static const String labelWouldYouLikeToAssociate = 'Would you like to associate this existing owner with your school?';
  static const String labelOwnerRegisteredSuccess = 'Vehicle owner registered successfully';
  static const String labelOwnerAssociatedSuccess = 'Vehicle owner associated with school successfully';

  // Register Vehicle Owner Screen Messages
  static const String msgEnterOwnerName = 'Enter owner name';
  static const String msgOwnerNameMin3 = 'Name must be at least 3 characters';
  static const String msgOwnerNameMax150 = 'Name must not exceed 150 characters';
  static const String msgEnterEmailAddressGeneric = 'Enter email address';
  static const String msgEmailMax150Generic = 'Email must not exceed 150 characters';
  static const String msgEnterValidEmailGeneric = 'Enter valid email address';
  static const String msgEnterContactNumberGeneric = 'Enter contact number';
  static const String msgContactNumberMustBe10DigitsGeneric = 'Contact number must be 10 digits';
  static const String msgEnterValidIndianMobileGeneric = 'Enter valid Indian mobile number';
  static const String msgEnterAddressGeneric = 'Enter address';
  static const String msgAddressMin5 = 'Address must be at least 5 characters';
  static const String msgAddressMax255 = 'Address must not exceed 255 characters';
  static const String msgSelectedImageNotFound = 'Selected image file not found';
  static const String msgCapturedImageNotFound = 'Captured image file not found';
  static const String msgErrorPickingImage = 'Error picking image: ';
  static const String msgErrorTakingPhoto = 'Error taking photo: ';
  static const String msgErrorDecodingImage = 'Error decoding image: ';
  static const String msgRegistrationSuccessfulTitleGeneric = 'Registration Successful!';
  static const String msgOwnerActivationInfo = "An activation link has been sent to the vehicle owner's email. They can use this link to complete their registration.";
  static const String msgExistingOwnerWithDetails = 'A vehicle owner with this email/contact already exists:';
  static const String msgFailedToRegisterOwner = 'Failed to register vehicle owner';
  static const String msgFailedToAssociateOwner = 'Failed to associate vehicle owner with school';

  // Register Vehicle Screen Labels/Hints
  static const String labelRegisterVehicle = 'Register Vehicle';
  // labelVehicleNumber already defined globally
  static const String hintVehicleNumber = 'e.g., 28, 29, 30';
  static const String labelVehicleRegistrationNumber = 'Registration Number *';
  static const String hintVehicleRegistrationNumber = 'e.g., MH12AB1234';
  // labelVehicleType already defined globally
  static const String labelVehicleCapacity = 'Vehicle Capacity *';
  static const String hintVehicleCapacity = 'e.g., 25, 30, 40';
  static const String suffixStudents = 'students';
  static const String labelVehicleRegistered = 'Vehicle registered';
  static const String labelFailedGeneric = 'Failed';

  // Register Vehicle Screen Messages
  static const String msgVehicleNumberRequired = 'Vehicle number is required';
  static const String msgVehicleNumberMax10 = 'Vehicle number cannot exceed 10 characters';
  static const String msgRegistrationNumberRequired = 'Registration number is required';
  static const String msgRegistrationNumberMax20 = 'Registration number cannot exceed 20 characters';
  static const String msgSelectVehicleType = 'Please select vehicle type';
  static const String msgVehicleCapacityRequired = 'Vehicle capacity is required';
  static const String msgEnterValidNumber = 'Please enter a valid number';
  static const String msgCapacityMustBeGreaterThanZero = 'Capacity must be greater than 0';
  static const String msgCapacityCannotExceed100 = 'Capacity cannot exceed 100 students';

  // Register Vehicle Screen Sizes moved to AppSizes

  // Vehicle Types (UI list)
  static const List<String> vehicleTypes = ['Car', 'Auto', 'Bus', 'Van'];

  // Reports Screen Labels
  static const String labelReportsDashboard = 'Reports Dashboard';
  static const String labelAttendanceTab = 'Attendance';
  static const String labelDispatchLogsTab = 'Dispatch Logs';
  static const String labelNotificationsTab = 'Notifications';
  // labelTotalStudents/labelTotalTrips/labelNotifications already exist globally
  static const String labelTotalVehicles = 'Total Vehicles';
  static const String labelActiveVehicles = 'Active Vehicles';
  static const String labelInTransit = 'In Transit';
  static const String labelVehicleReports = 'Vehicle Reports';
  static const String labelVehicleInformation = 'Vehicle Information';
  static const String textVehicleInfoDescription = 'School Admin can view vehicle reports and statistics. Vehicle registration is managed by Vehicle Owners.';
  static const String labelViewReports = 'View Reports';
  static const String msgVehicleReportsComingSoon = 'Vehicle reports feature coming soon';
  static const String msgSchoolIdNotFoundPrefs = 'School not found in preferences';
  static const String msgErrorLoadingVehicles = 'Error loading vehicles';
  static const String labelOwner = 'Owner';
  static const String emptyStateNoVehiclesSub = 'No vehicles have been registered yet';
  static const String labelStudentWise = 'Student-wise';
  static const String labelClassWise = 'Class-wise';
  static const String labelAll = 'All';
  static const String labelTripWise = 'Trip-wise';
  static const String labelVehicleWise = 'Vehicle-wise';
  static const String labelSent = 'Sent';
  // labelFailed already exists globally
  static const String labelPending = 'Pending';
  static const String labelDownloadPDF = 'Download PDF';
  static const String labelExportCSV = 'Export CSV';
  static const String labelStoragePermissionRequired = 'Storage Permission Required';
  static const String labelGrantPermission = 'Grant Permission';

  // Reports Screen Messages
  // msgSchoolIdNotFoundLogin already exists globally
  static const String msgErrorLoadingReports = 'Error loading reports: ';
  // msgNoAttendanceData already exists globally
  static const String msgUnknown = 'Unknown';
  static const String msgNoDispatchLogs = 'No dispatch logs available';
  static const String msgNoNotificationLogs = 'No notification logs available';
  static const String msgStoragePermissionExplain = 'This app needs storage permission to download reports. Please grant permission in the next dialog.';
  static const String msgStoragePermissionDenied = 'Storage permission denied. Cannot download files.';
  static const String msgDownloadingReportPrefix = 'Downloading '; // will append type
  static const String msgReportDownloaded = 'Report downloaded successfully!';
  static const String msgDownloadError = 'Download error: ';
  static const String msgCouldNotAccessDownloads = 'Could not access downloads directory';
  static const String msgFileDownloadedTitle = 'File Downloaded Successfully!';
  static const String msgSavedTo = 'Saved to:';
  static const String msgFileSavedInfo = "File has been saved to your device's download folder.";
  static const String msgDownloadFailedTitle = 'Download Failed';
  static const String msgCheckPermissionsTryAgain = 'Please check your device permissions and try again.';

  // Reports Screen Sizes
  static const double reportsHeaderPadding = 12.0;
  static const double reportsCardWidth = 100.0;
  static const double reportsCardHeight = 80.0;
  static const double reportsCardPadding = 8.0;
  static const double reportsValueFontSize = 22.0;
  static const double reportsTitleFontSize = 12.0;
  static const double reportsIconSizeLG = 64.0;
  static const double reportsIconSizeMD = 20.0;
  static const double reportsGapSM = 8.0;
  static const double reportsGapMD = 12.0;
  static const double reportsGapLG = 16.0;
  static const int reportsSnackbarDuration = 3;

  // Request Vehicle Assignment Page Labels/Messages
  static const String labelRequestVehicleAssignment = 'Request Vehicle Assignment';
  static const String labelSelectVehicle = 'Select Vehicle';
  static const String labelSubmitRequest = 'Submit Request';
  static const String msgPleaseSelectVehicle = 'Please select vehicle';
  static const String msgMissingSchoolOrOwner = 'Missing school or owner info';
  static const String msgNoVehiclesFound = 'No vehicles found';
  static const String msgRequestSubmitted = 'Request submitted';
  static const String msgFailedToSubmitRequest = 'Failed to submit request';
  static const double requestVehiclePadding = 16.0;
  static const double requestVehicleSpacingLG = 20.0;

  // Register Vehicle Owner Sizes
  static const double registerOwnerPadding = 16.0;
  static const double registerOwnerSpacing = 12.0;
  static const double registerOwnerSpacingLG = 20.0;
  static const double registerOwnerCardPadding = 16.0;
  static const double registerOwnerAvatarRadius = 50.0;
  static const double registerOwnerAvatarIconSize = 50.0;
  static const double registerOwnerTitleFont = 18.0;
  static const int registerOwnerContactLength = 10;
  static const int registerOwnerEmailMaxLength = 150;
  static const int registerOwnerSnackDuration = 4;

  // Register Student Logs/Debug
  static const String logLoadingMasterData = 'Loading master data...';
  static const String logClassesResponse = 'Classes response: ';
  static const String logSectionsResponse = 'Sections response: ';
  static const String logLoadedClassesCount = 'Loaded '; // will append count
  static const String logLoadedSectionsCount = 'Loaded '; // will append count
  static const String logSetDefaultClass = 'Set default class: ';
  static const String logSetDefaultSection = 'Set default section: ';
  static const String logFailedToLoadClasses = 'Failed to load classes: ';
  static const String logFailedToLoadSections = 'Failed to load sections: ';
  static const String logSubmitError = 'Submit error: ';
  
  // Register School Screen School Types
  static const String schoolTypePrivate = 'Private';
  static const String schoolTypeGovernment = 'Government';
  static const String schoolTypeInternational = 'International';
  
  // Register School Screen Affiliation Boards
  static const String affiliationBoardCBSE = 'CBSE';
  static const String affiliationBoardICSE = 'ICSE';
  static const String affiliationBoardStateBoard = 'State Board';
  
  // Register School Screen Default Values
  static const String registerSchoolCreatedBy = 'SYSTEM';
  
  // Register School Screen Messages
  static const String msgRegistrationSuccessful = 'Registration Successful!';
  static const String msgSchoolRegisteredSuccess = 'Your school has been registered successfully. Please check your email for the activation link. The link is valid for 24 hours.';
  static const String msgRegistrationFailed = 'Registration failed';
  static const String msgFailedToRegisterSchool = 'Failed to register school';
  static const String msgPincodeNotFoundManual = 'Pincode not found. Please enter location manually.';
  static const String msgErrorFetchingLocation = 'Error fetching location: ';
  static const String msgFoundLocationsSelect = 'Found %d locations. Please select your city from dropdown.';
  static const String msgLocationAutoFilledPrefix = 'Location auto-filled: ';
  static const String msgEnterSchoolName = 'Enter school name';
  static const String msgSchoolNameMinChars = 'School name must be at least 2 characters';
  static const String msgSchoolNameMaxChars = 'School name must not exceed 200 characters';
  static const String msgSelectSchoolType = 'Select school type';
  static const String msgSelectAffiliationBoard = 'Select affiliation board';
  static const String msgEnterRegistrationNumber = 'Enter registration number';
  static const String msgRegistrationNumberMinChars = 'Registration number must be at least 3 characters';
  static const String msgRegistrationNumberMaxChars = 'Registration number must not exceed 100 characters';
  static const String msgEnterPincode = 'Enter pincode';
  static const String msgPincodeMustBe6Digits = 'Pincode must be 6 digits';
  static const String msgPincodeOnlyNumbers = 'Pincode must contain only numbers';
  static const String msgSelectCity = 'Select city';
  static const String msgEnterCity = 'Enter city';
  static const String msgEnterDistrict = 'Enter district';
  static const String msgEnterState = 'Enter state';
  static const String msgEnterAddress = 'Enter address';
  static const String msgContactNumberMustBe10DigitsOnly = 'Contact number must be 10 digits';
  static const String msgContactNumberOnlyNumbers = 'Contact number must contain only numbers';
  static const String msgEnterEmailAddress = 'Enter email';
  static const String msgEmailMustNotExceed150Chars = 'Email must not exceed 150 characters';
  static const String msgPleaseEnterValidEmailAddress = 'Please enter a valid email address';
  
  // Register Driver Screen Messages
  static const String msgDriverCreated = 'Driver created';
  static const String msgUserNotFoundPrefs = 'User not found in prefs';
  static const String msgDriverNameRequired = 'Driver name is required';
  static const String msgDriverNameMaxLength = 'Driver name cannot exceed 100 characters';
  static const String msgContactNumberRequired = 'Contact number is required';
  static const String msgContactNumberExactDigits = 'Contact number must be exactly 10 digits';
  static const String msgValidIndianMobile = 'Enter valid Indian mobile number (starting with 6-9)';
  static const String msgDriverAddressRequired = 'Driver address is required';
  static const String msgDriverAddressMaxLength = 'Driver address cannot exceed 255 characters';
  static const String msgEmailMaxLength = 'Email cannot exceed 150 characters';
  static const String msgEnterValidEmailAddress = 'Enter valid email address';
  
  // Monthly Report Page Messages
  static const String msgErrorLoadingReport = 'Error loading monthly report: ';
  static const String msgClearAllNotificationsConfirm = 'Are you sure you want to clear all notifications?';
  
  // Gate Staff Dashboard Messages
  static const String msgWebSocketInitializedGateStaff = '✅ WebSocket initialized for Gate Staff Dashboard';
  static const String msgGateNotificationError = 'Gate notification error: ';
  static const String msgGateEventReceived = '🚪 Gate Entry/Exit notification: ';
  static const String msgGateStaffNotification = '🔔 Gate Staff - Received notification: ';
  static const String msgUserIdNotFoundLogin = 'User ID not found. Please login again.';
  static const String msgFailedToLoadDashboard = 'Failed to load dashboard data';
  static const String msgErrorLoadingDashboard = 'Error loading dashboard: ';
  static const String msgGateEventMarkedSuccess = 'Gate ';
  static const String msgMarkedSuccessfully = ' marked successfully!';
  static const String msgErrorMarkingGateEvent = 'Error marking gate ';
  static const String msgLoggedOutSuccessfully = 'Logged out successfully';
  static const String msgLogoutFailed = 'Logout failed: ';
  
  // WebSocket Errors
  static const String errorWebSocketInitialization = 'Error initializing WebSocket';
  static const String errorWebSocketConnection = 'Error connecting to STOMP WebSocket';
  static const String errorWebSocketMessage = 'Error processing STOMP message';
  static const String errorWebSocketSubscription = 'Error subscribing to STOMP channels';
  static const String errorWebSocketUserSubscription = 'Error subscribing to user notifications';
  static const String errorWebSocketRoleSubscription = 'Error subscribing to role notifications';
  static const String errorWebSocketSchoolSubscription = 'Error subscribing to school notifications';
  static const String errorWebSocketSendNotification = 'Error sending STOMP notification';

  /// ========================================
  /// SUCCESS MESSAGES
  /// ========================================
  
  static const String successLoginCompleted = 'Login successful';
  static const String successLogoutCompleted = 'Logout successful';
  static const String successDataSaved = 'Data saved successfully';
  static const String successDataUpdated = 'Data updated successfully';
  static const String successDataDeleted = 'Data deleted successfully';
  static const String successRequestApproved = 'Request approved successfully';
  static const String successRequestRejected = 'Request rejected successfully';
  static const String successRequestSubmitted = 'Request submitted successfully';
  static const String successVehicleAdded = 'Vehicle added successfully';
  static const String successDriverAdded = 'Driver added successfully';
  static const String successStudentAdded = 'Student added successfully';

  /// ========================================
  /// API RESPONSE KEYS
  /// ========================================
  
  static const String keySuccess = 'success';
  static const String keyMessage = 'message';
  static const String keyData = 'data';
  // keyCities, keyDistrict, keyState already defined above in "Pincode API Response Keys"
  // keyToken, keyUser, keyRole already defined above in "SharedPreferences Keys"
  // keySchools, keyVehicles, keyDrivers, keyTrips already defined above
  static const String keyStudents = 'students';
  static const String keyRequests = 'requests';

  /// ========================================
  /// DATE/TIME FORMATS
  /// ========================================
  
  static const String dateFormatFull = 'dd MMM yyyy, hh:mm a';
  static const String dateFormatShort = 'dd/MM/yyyy';
  static const String timeFormat12Hour = 'hh:mm a';
  static const String timeFormat24Hour = 'HH:mm';

  /// ========================================
  /// PAGINATION
  /// ========================================
  
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;

  /// ========================================
  /// TIMEOUTS (in seconds)
  /// ========================================
  
  static const int apiTimeout = 30;
  static const int uploadTimeout = 60;
  static const int downloadTimeout = 60;

  /// ========================================
  /// FILE SIZES (in bytes)
  /// ========================================
  
  static const int maxImageSize = 5 * 1024 * 1024; // 5 MB
  static const int maxDocumentSize = 10 * 1024 * 1024; // 10 MB

  /// ========================================
  /// WEBSOCKET TOPICS
  /// ========================================
  
  static const String wsTopicSchool = '/topic/school';
  static const String wsTopicRole = '/topic/role';
  static const String wsTopicUser = '/user/queue/notifications';
  static const String wsTopicAll = '/topic/all';

  /// ========================================
  /// EMPTY STATE MESSAGES
  /// ========================================
  
  static const String emptyStateNoVehicles = 'No vehicles available';
  static const String emptyStateNoStudents = 'No students found';
  static const String emptyStateNoDrivers = 'No drivers available';
  static const String emptyStateNoTrips = 'No trips scheduled';
  static const String emptyStateNoPendingRequests = 'No pending requests';
  static const String emptyStateNoNotifications = 'No new notifications';

  /// ========================================
  /// BLOC ERROR CODES
  /// ========================================
  
  static const String errorCodeDashboardLoad = 'DASHBOARD_LOAD_ERROR';
  static const String errorCodeDashboard = 'DASHBOARD_ERROR';
  static const String errorCodeGateEntry = 'GATE_ENTRY_ERROR';
  static const String errorCodeGateExit = 'GATE_EXIT_ERROR';
  static const String msgFailedToMarkGateEvent = 'Failed to mark gate event';
  static const String errorCodeProfileLoad = 'PROFILE_LOAD_ERROR';
  static const String errorCodeUpdate = 'UPDATE_ERROR';
  static const String errorCodeSchoolsLoad = 'SCHOOLS_LOAD_ERROR';
  static const String errorCodeSchoolActivation = 'SCHOOL_ACTIVATION_ERROR';
  static const String errorCodeSchoolDates = 'SCHOOL_DATES_ERROR';
  static const String errorCodeResendActivationLink = 'RESEND_ACTIVATION_LINK_ERROR';
  static const String errorCodeReportsLoad = 'REPORTS_LOAD_ERROR';
  static const String errorCodeSystemStatsLoad = 'SYSTEM_STATS_LOAD_ERROR';
  static const String errorCodeLogin = 'LOGIN_ERROR';
  static const String errorCodeLogout = 'LOGOUT_ERROR';
  static const String errorCodeForgotPassword = 'FORGOT_PASSWORD_ERROR';
  static const String errorCodeResetPassword = 'RESET_PASSWORD_ERROR';
  static const String errorCodeTokenRefresh = 'TOKEN_REFRESH_ERROR';
  static const String errorCodeDriverDashboard = 'DASHBOARD_LOAD_ERROR';
  static const String errorCodeDriverTrips = 'TRIPS_LOAD_ERROR';
  static const String errorCodeDriverProfile = 'PROFILE_LOAD_ERROR';
  static const String errorCodeDriverProfileNotFound = 'PROFILE_NOT_FOUND';
  static const String errorCodeDriverReports = 'REPORTS_LOAD_ERROR';
  static const String errorCodeDriverReportsNotFound = 'REPORTS_NOT_FOUND';
  static const String errorCodeTripStudents = 'TRIP_STUDENTS_LOAD_ERROR';
  static const String errorCodeAttendance = 'ATTENDANCE_ERROR';
  static const String errorCodeNotification = 'NOTIFICATION_ERROR';
  static const String errorCodeLocationUpdate = 'LOCATION_UPDATE_ERROR';
  static const String errorCodeEndTrip = 'END_TRIP_ERROR';
  static const String errorCode5MinAlert = '5MIN_ALERT_ERROR';
  static const String errorCodePickupHome = 'PICKUP_HOME_ERROR';
  static const String errorCodeDropSchool = 'DROP_SCHOOL_ERROR';
  static const String errorCodePickupSchool = 'PICKUP_SCHOOL_ERROR';
  static const String errorCodeDropHome = 'DROP_HOME_ERROR';
  static const String errorCodeConnectionError = 'CONNECTION_ERROR';
  static const String errorCodeDisconnectError = 'DISCONNECT_ERROR';
  static const String errorCodeSubscribeError = 'SUBSCRIBE_ERROR';
  static const String errorCodeUnsubscribeError = 'UNSUBSCRIBE_ERROR';
  static const String errorCodeSendMessageError = 'SEND_MESSAGE_ERROR';
  static const String errorCodeParentDashboard = 'DASHBOARD_LOAD_ERROR';
  static const String errorCodeParentProfile = 'PROFILE_LOAD_ERROR';
  static const String errorCodeParentUpdate = 'UPDATE_ERROR';
  static const String errorCodeParentStudents = 'STUDENTS_LOAD_ERROR';
  static const String errorCodeParentTrips = 'TRIPS_LOAD_ERROR';
  static const String errorCodeParentNotifications = 'NOTIFICATIONS_LOAD_ERROR';
  static const String errorCodeParentAttendanceHistory = 'ATTENDANCE_HISTORY_LOAD_ERROR';
  static const String errorCodeParentMonthlyReport = 'MONTHLY_REPORT_LOAD_ERROR';
  static const String errorCodeParentVehicleTracking = 'VEHICLE_TRACKING_LOAD_ERROR';
  static const String errorCodeParentDriverLocation = 'DRIVER_LOCATION_LOAD_ERROR';
  static const String errorCodeSchoolDashboard = 'DASHBOARD_LOAD_ERROR';
  static const String errorCodeSchoolProfile = 'PROFILE_LOAD_ERROR';
  static const String errorCodeSchoolUpdate = 'UPDATE_ERROR';
  static const String errorCodeSchoolStudents = 'STUDENTS_LOAD_ERROR';
  static const String errorCodeSchoolStaff = 'STAFF_LOAD_ERROR';
  static const String errorCodeSchoolVehicles = 'VEHICLES_LOAD_ERROR';
  static const String errorCodeSchoolTrips = 'TRIPS_LOAD_ERROR';
  static const String errorCodeSchoolReports = 'REPORTS_LOAD_ERROR';
  static const String errorCodeVehicleOwnerDashboard = 'DASHBOARD_LOAD_ERROR';
  static const String errorCodeVehicleOwnerProfile = 'PROFILE_LOAD_ERROR';
  static const String errorCodeVehicleOwnerUpdate = 'UPDATE_ERROR';
  static const String errorCodeVehicleOwnerVehicles = 'VEHICLES_LOAD_ERROR';
  static const String errorCodeVehicleOwnerDrivers = 'DRIVERS_LOAD_ERROR';
  static const String errorCodeVehicleOwnerTrips = 'TRIPS_LOAD_ERROR';
  static const String errorCodeVehicleOwnerReports = 'REPORTS_LOAD_ERROR';
  static const String errorCodeAddVehicle = 'ADD_VEHICLE_ERROR';
  static const String errorCodeAddDriver = 'ADD_DRIVER_ERROR';
  static const String errorCodeAssignDriver = 'ASSIGN_DRIVER_ERROR';
  
  /// ========================================
  /// BLOC ACTION TYPES
  /// ========================================
  
  static const String actionTypeLoadDashboard = 'LOAD_DASHBOARD';
  static const String actionTypeLoadProfile = 'LOAD_PROFILE';
  static const String actionTypeUpdateProfile = 'UPDATE_PROFILE';
  static const String actionTypeLoadSchools = 'LOAD_SCHOOLS';
  static const String actionTypeSchoolActivation = 'SCHOOL_ACTIVATION';
  static const String actionTypeSchoolDates = 'SCHOOL_DATES';
  static const String actionTypeResendActivationLink = 'RESEND_ACTIVATION_LINK';
  static const String actionTypeLoadReports = 'LOAD_REPORTS';
  static const String actionTypeLoadSystemStats = 'LOAD_SYSTEM_STATS';
  static const String actionTypeLoadTrips = 'LOAD_TRIPS';
  static const String actionTypeLoadTripStudents = 'LOAD_TRIP_STUDENTS';
  static const String actionTypeMarkAttendance = 'MARK_ATTENDANCE';
  static const String actionTypeSendNotification = 'SEND_NOTIFICATION';
  static const String actionTypeUpdateLocation = 'UPDATE_LOCATION';
  static const String actionTypeEndTrip = 'END_TRIP';
  static const String actionTypeSend5MinAlert = 'SEND_5MIN_ALERT';
  static const String actionTypeMarkPickupHome = 'MARK_PICKUP_HOME';
  static const String actionTypeMarkDropSchool = 'MARK_DROP_SCHOOL';
  static const String actionTypeMarkPickupSchool = 'MARK_PICKUP_SCHOOL';
  static const String actionTypeMarkGateEntry = 'MARK_GATE_ENTRY';
  static const String actionTypeMarkGateExit = 'MARK_GATE_EXIT';
  static const String actionTypeMarkDropHome = 'MARK_DROP_HOME';
  static const String actionTypeLoadStudents = 'LOAD_STUDENTS';
  static const String actionTypeLoadNotifications = 'LOAD_NOTIFICATIONS';
  static const String actionTypeLoadAttendanceHistory = 'LOAD_ATTENDANCE_HISTORY';
  static const String actionTypeLoadMonthlyReport = 'LOAD_MONTHLY_REPORT';
  static const String actionTypeLoadVehicleTracking = 'LOAD_VEHICLE_TRACKING';
  static const String actionTypeLoadDriverLocation = 'LOAD_DRIVER_LOCATION';
  static const String actionTypeLoadStaff = 'LOAD_STAFF';
  static const String actionTypeLoadVehicles = 'LOAD_VEHICLES';
  static const String actionTypeLoadDrivers = 'LOAD_DRIVERS';
  static const String actionTypeAddVehicle = 'ADD_VEHICLE';
  static const String actionTypeAddDriver = 'ADD_DRIVER';
  static const String actionTypeAssignDriver = 'ASSIGN_DRIVER';
  
  /// ========================================
  /// BLOC SUCCESS MESSAGES
  /// ========================================
  
  static const String msgProfileUpdated = 'Profile updated successfully';
  static const String msgSchoolProfileUpdated = 'School profile updated successfully';
  static const String msgSchoolStatusUpdated = 'School status updated successfully';
  static const String msgSchoolDatesUpdated = 'School dates updated successfully';
  static const String msgActivationLinkSent = 'Activation link sent successfully';
  static const String msgOtpSentSuccessfully = 'OTP sent successfully';
  static const String msgPasswordResetSuccessfully = 'Password reset successfully';
  static const String msgNotificationSent = 'Notification sent successfully';
  static const String msgTripEnded = 'Trip ended successfully';
  static const String msg5MinuteAlert = '5-minute alert sent successfully';
  static const String msgPickupFromHome = 'Pickup from home marked successfully';
  static const String msgDropToSchool = 'Drop to school marked successfully';
  static const String msgPickupFromSchool = 'Pickup from school marked successfully';
  static const String msgDropToHome = 'Drop to home marked successfully';
  static const String msgVehicleAdded = 'Vehicle added successfully';
  static const String msgDriverAdded = 'Driver added successfully';
  static const String msgDriverAssigned = 'Driver assigned successfully';

  /// ========================================
  /// DIALOG TITLES
  /// ========================================
  
  static const String dialogTitleConfirm = 'Confirm';
  static const String dialogTitleError = 'Error';
  static const String dialogTitleSuccess = 'Success';
  static const String dialogTitleWarning = 'Warning';
  static const String dialogTitleInfo = 'Information';
  static const String dialogTitleLogout = 'Confirm Logout';
  static const String dialogTitleDelete = 'Confirm Delete';

  // School Profile Page Labels
  //static const String labelSchoolProfile = 'School Profile';
  static const String labelSchoolPhoto = 'School Photo';
 // static const String labelChangePhoto = 'Change Photo';
 // static const String labelSchoolName = 'School Name';
 // static const String labelSchoolType = 'School Type';
 // static const String labelAffiliationBoard = 'Affiliation Board';
  static const String labelContactNo = 'Contact No';
  static const String labelSchoolEmail = 'Email';
  static const String labelSchoolAddress = 'Address';
 // static const String labelUpdate = 'Update';
  static const String labelNewPhotoSelected = 'New photo selected';

  // School Profile Page Messages and Dialog Strings
  //static const String labelRequired = 'Required';
  static const String msgSchoolUpdated = 'School updated successfully';
  static const String msgUpdateFailed = 'Update failed';
  static const String msgSelectedImageFileNotFound = 'Selected image file not found';
  static const String msgCapturedImageFileNotFound = 'Captured image file not found';
  //static const String msgErrorPickingImage = 'Error picking image';
 // static const String msgErrorTakingPhoto = 'Error taking photo';
  static const String dialogTitleSelectImageSource = 'Select Image Source';
  static const String dialogContentChooseImage = 'Choose how you want to select the image';
 // static const String labelGallery = 'Gallery';
 // static const String labelCamera = 'Camera';
 // static const String labelCancel = 'Cancel';
  // School Profile Page UI Sizes and Colors (if any used)

  static const String labelAddNewSection = 'Add New Section';
  static const String labelEditSection = 'Edit Section';
  static const String labelSectionName = 'Section Name';
  static const String labelUpdateSection = 'Update Section';
  static const String labelAddSection = 'Add Section';
  static const String msgNoSectionsFoundAddFirst = 'No sections found.\nAdd your first section above.';
  static const String msgFailedToLoadSections = 'Failed to load sections';
  static const String msgErrorLoadingSections = 'Error loading sections: ';
  static const String msgSectionCreated = 'Section created successfully';
  static const String msgSectionUpdated = 'Section updated successfully';
  static const String msgSectionDeleted = 'Section deleted successfully';
  static const String msgFailedToDeleteSection = 'Failed to delete section';
  static const String msgSectionStatusUpdated = 'Section status updated successfully';
  static const String msgNameTooLong50 = 'Section name cannot exceed 50 characters';
  static const String dialogTitleDeleteSection = 'Delete Section';
  static const String msgConfirmDeleteSectionStart = 'Are you sure you want to delete "';
  static const String msgConfirmDeleteSectionEnd = '"?';
  static const String hintSectionNameExamples = 'e.g., A, B, Rose, Lily, Red, Blue';
  static const String hintSectionDescription = 'Additional details about the section';

  // Simplified Student Management Labels/Messages
  static const String labelStudentsHeader = 'Students';
  static const String msgNoStudentsAssigned = 'No students assigned to this trip';
  static const String labelPickup = 'Pickup';
  static const String labelDrop = 'Drop';
  static const String labelSendAlert = 'Send Alert';
  static const String labelPickupPrefix = 'Pickup: ';
  static const String labelDropPrefix = 'Drop: ';
  static const String labelOrderPrefix = 'Order: ';
  static const String msgTripStartedFor = 'Trip started! Location tracking enabled for ';
  static const String msgFailedToStartTrip = 'Failed to start trip: ';
  static const String msgFailedToSendAlertGeneric = 'Failed to send alert';
  static const String msgErrorSendingAlert = 'Error sending alert: ';
  static const String msgFailedToMarkAction = 'Failed to mark action';
  static const String msgErrorMarkingAction = 'Error marking action: ';
  static const String msgLocationPermissionRequiredToStartTrip = 'Location permission is required to start trip';
 // static const String msgFailedToStartTrip = 'Failed to start trip: ';
 // static const String msgNoStudentsAssigned = 'No students assigned to this trip';
 static const String msgMorningTripInfo = 'Morning Trip: Pickup from Home → Drop to School';
  static const String msgAfternoonTripInfo = 'Afternoon Trip: Pickup from School → Drop to Home';
 // static const String labelSendAlert = 'Send Alert';
 // static const String labelPickup = 'Pickup';
  //static const String labelDrop = 'Drop';
  static const String msgTripNotStartedYet = 'Trip not started yet';
  static const String msgLocationPermissionsRequesting = 'Location permissions are being requested...';
  //static const String labelOrderPrefix = 'Order: ';

  // --- Splash Page Constants ---
  static const String labelSplashTitle = 'School Tracker';
  static const String labelSplashSubtitle = 'Track your school activities seamlessly';
  static const List<Color> splashGradientColors = [Color(0xFF36D1DC), Color(0xFF5B86E5)];
  static const Color splashIconBg = const Color.fromRGBO(255, 255, 255, 0.2);
  static const double splashIconPadding = 30.0;
  static const double splashIconSize = 100.0;
  static const double splashCircleAvatarShadowBlur = 10.0;
  static const double splashTitleFontSize = 32.0;
  static const double splashSubtitleFontSize = 16.0;
  static const FontWeight splashTitleFontWeight = FontWeight.bold;
  static const Color splashTitleColor = Colors.white;
  static const Color splashSubtitleColor = Colors.white70;
  static const double splashTitleLetterSpacing = 1.2;
  static const double splashTitleShadowBlur = 5;
  static const Color splashTitleShadowColor = Colors.black38;
  static const Offset splashTitleShadowOffset = const Offset(1, 1);
  static const double splashSpacingTitleToSubtitle = 15.0;
  static const double splashSpacingIconToTitle = 30.0;
  static const double splashSpacingSubtitleToLoader = 50.0;
  static const double splashLoaderStrokeWidth = 3.0;

  // --- Staff Management Constants ---
  static const String labelStaffManagement = 'Staff Management';
  static const String labelTotalStaff = 'Total Staff';
  static const String labelActiveStaff = 'Active Staff';
  static const String labelTeachers = 'Teachers';
  static const String msgNoStaffMembers = 'No staff members found';
  static const String msgAddFirstStaff = 'Add your first staff member to get started';
  static const String labelRoleWithColon = 'Role: ';
  static const String labelContactWithColon = 'Contact: ';
 // static const String labelViewDetails = 'View Details';
 // static const String actionEdit = 'Edit';
  static const String actionActivate = 'Activate';
  static const String actionDeactivate = 'Deactivate';
  static const String msgFailedToLoadStaffData = 'Failed to load staff data';
  static const String msgEditFunctionalityNotImplemented = 'Edit functionality not implemented yet';
  static const String msgUpdatingStaffDetails = 'Updating staff details...';
  static const String msgErrorLoadingStaffData = 'Error loading staff data: ';
  static const String msgDetailsUpdated = 'details updated successfully';
  static const String msgFailedToUpdateStaffDetails = 'Failed to update staff details';
  static const String msgErrorUpdatingStaffDetails = 'Error updating staff details: ';
  static const String msgActivated = 'activated successfully';
  static const String msgDeactivated = 'deactivated successfully';
  static const String msgFailedToUpdateStaffStatus = 'Failed to update staff status';
  static const String msgErrorUpdatingStaffStatus = 'Error updating staff status: ';
  static const String labelDeleteStaffMember = 'Delete Staff Member';
  static const String labelAreYouSure = 'Are you sure you want to delete '; 
  static const String msgDeleted = 'deleted successfully';
  static const String msgErrorDeletingStaff = 'Error deleting staff: ';
  static const String labelStaffDetails = 'Staff Details';
  static const String labelEditStaffDetails = 'Edit Staff Details';
  static const String tooltipViewMode = 'View Mode';
  static const String tooltipEditMode = 'Edit Mode';
  static const String labelJoinDate = 'Join Date';

  // Student Attendance Page Labels/Messages
  static const String labelDash = ' - ';
  static const String labelEventType = 'Event Type';
  static const String labelLocationOptional = 'Location (Optional)';
  static const String labelRemarksOptional = 'Remarks (Optional)';
  static const String labelSendNotificationToParent = 'Send notification to parent';
  static const String labelNotifyParentAboutEvent = 'Notify parent about this event';
  static const String labelNotificationMessage = 'Notification Message';
  static const String labelMarkAttendance = 'Mark Attendance';
  static const String labelPicked = 'Picked';
  static const String labelDropped = 'Dropped';
  static const String msgAttendanceMarkedSuccessfully = 'Attendance marked for';
  static const String msgPickedFromHome = 'Picked up from home';
  static const String msgDroppedAtSchool = 'Dropped at school';
  static const String msgPickedFromSchool = 'Picked up from school';
  static const String msgDroppedAtHome = 'Dropped at home';
 // static const String msgDroppedAtSchool = 'Dropped at school';
 // static const String msgPickedFromSchool = 'Picked up from school';
 // static const String msgDroppedAtHome = 'Dropped at home';
 // static const String notifTypePickupFromParent = 'PICKUP_FROM_PARENT';
  static const String notifTypeDropToSchool = 'DROP_TO_SCHOOL';
  static const String notifTypePickupFromSchool = 'PICKUP_FROM_SCHOOL';
 // static const String notifTypeDropToParent = 'DROP_TO_PARENT';
  static const String labelPickupFromParent = 'Pickup from Parent';
  static const String labelDropToSchool = 'Drop to School';
  static const String labelPickupFromSchool = 'Pickup from School';
  static const String labelDropToParent = 'Drop to Parent';
  static const String labelStudentManagement = 'Student Management';
  static const String labelAllClasses = 'All Classes';
  static const String labelAllSections = 'All Sections';
  static const String msgAdjustFiltersOrAddStudents = 'Try adjusting your filters or add new students';

  // Student Profile Labels/Messages/Keys
  static const String labelStudentProfile = 'Student Profile';
  static const String labelStudentPhoto = 'Student Photo';
  static const String msgStudentUpdatedSuccess = '✅ Student updated successfully';
  // static const String keyStudentId = 'studentId';
  // static const String keyFirstName = 'firstName';
  // static const String keyLastName = 'lastName';
  // static const String keyPrimaryContact = 'primaryContactNumber';
  // static const String keyAlternateContact = 'alternateContactNumber';
  // static const String keyMotherName = 'motherName';
  // static const String keyFatherName = 'fatherName';

  // ... existing code ...
  //static const String labelVehicles = 'Vehicles';
  //static const String labelTrips = 'Trips';
  static const String labelActivatedDrivers = 'Activated Drivers';
  static const String labelAssignments = 'Assignments';
  static const String labelCurrentAssignments = 'Current Assignments';
  static const String emptyStateNoAssignments = 'No assignments found.\nAssign drivers to vehicles to get started.';
  // ... existing code ...
  //static const String labelVehicleOwnerMenu = 'Vehicle Owner Menu';
  //static const String labelDriverAssignment = 'Driver Assignment';
 // static const String labelSchoolMapping = 'School Mapping';
  static const String labelAssignDriverToVehicle = 'Assign Driver to Vehicle';
  static const String labelSelectDriver = 'Select Driver';
  static const String labelPrimaryDriver = 'Primary Driver';
  static const String labelMarkAsPrimaryDriver = 'Mark as primary driver for this vehicle';
  static const String textOnlyActivatedDriversShown = 'Only drivers who have completed user activation are shown below:';
  static const String textOnlyActivatedDriversAssign = 'Only drivers who have completed user activation can be assigned to vehicles.';
  static const String labelUnknownDriver = 'Unknown Driver';
  static const String actionAssign = 'Assign';
  static const String actionRemove = 'Remove';
  static const String actionRemoveAssignment = 'Remove Assignment';
  static const String titleRemoveAssignment = 'Remove Assignment';
  static const String msgConfirmRemoveAssignment = 'Are you sure you want to remove this driver assignment?';
  static const String msgAssignmentRemovedSuccess = 'Assignment removed successfully!';
  static const String msgFailedToRemoveAssignment = 'Failed to remove assignment';
  static const String msgNoVehiclesAvailableRegisterFirst = 'No vehicles available. Please register a vehicle first.';
  static const String msgNoDriversAvailableRegisterFirst = 'No drivers available. Please register a driver first.';
  static const String msgNoSchoolSelected = 'No school selected. Please select a school first.';
  static const String msgErrorOpeningDialog = 'Error opening dialog';
  static const String msgDriverAssignedSuccess = 'Driver assigned to vehicle successfully!';
  static const String msgFailedToAssignDriver = 'Failed to assign driver';
  static const String labelVehicleOwner = 'Vehicle Owner';
  // ... existing code ...
  //static const String keyVehicleType = 'vehicleType';
 // static const String keyVehicleCapacity = 'vehicleCapacity';
  static const String keyDriverContact = 'driverContactNumber';
  static const String keyVehicleDriverId = 'vehicleDriverId';
  static const String keyIsPrimary = 'isPrimary';
  // ... existing code ...
  static const String msgOwnerDataNotAvailable = 'Owner data not available';
  static const String msgOwnerNameTooShort = 'Owner name is too short';
  static const String emptyStateAddFirstDriver = 'Add your first driver to get started';
  static const String labelTotalDrivers = 'Total Drivers';
  static const String labelContactPrefix = 'Contact: ';
  static const String labelAddressPrefix = 'Address: ';
  static const String labelEmailPrefix = 'Email: ';
  static const String labelAssignedToPrefix = 'Assigned to ';
  static const String msgErrorLoadingDrivers = 'Error loading drivers';
  static const String msgDriverDeletedSuccess = 'Driver deleted successfully';
  static const String msgErrorDeletingDriver = 'Error deleting driver';
  static const String msgEditFunctionalityComingSoon = 'Edit functionality coming soon';
  static const String msgAssignmentFunctionalityComingSoon = 'Assignment functionality coming soon';
  static const String actionAssignToVehicle = 'Assign to Vehicle';
  static const String titleDeleteDriver = 'Delete Driver';
  static const String msgConfirmDeleteDriver = 'Are you sure you want to delete driver';
  static const String keyAssignedVehicle = 'assignedVehicle';
  static const String labelVehicleOwnerManagement = 'Vehicle Owner Management';
  static const String labelViewAndManageVehicleOwners = 'View and manage all vehicle owners';
  static const String labelVehicleOwnerProfile = 'Vehicle Owner Profile';
  static const String labelOwnerPhoto = 'Owner Photo';

  // Vehicle Owner Student-Trip Assignment
  static const String labelStudentTripAssignments = 'Student-Trip Assignments';
  static const String msgDataRefreshedSuccessfully = 'Data refreshed successfully';
  static const String msgUseSchoolSelectorHint = 'Use the school selector in the dashboard';
  static const String msgNoTripsOrStudentsAvailable = 'No trips or students available for assignment';
  static const String titleAssignStudentToTrip = 'Assign Student to Trip';
  static const String labelSelectStudent = 'Select Student';
  static const String labelPickupOrder = 'Pickup Order';
  static const String hintPickupOrder = 'Order in which student will be picked up';
  static const String labelAssignStudentToTrip = 'Assign Student to Trip';
  static const String emptyStateNoStudentTripAssignments = 'No student-trip assignments yet';
  static const String emptyStateAssignStudentsHint = 'Assign students to trips to get started';
  static const String msgStudentAssignedToTripSuccess = 'Student assigned to trip successfully';
  static const String msgFailedToAssignStudent = 'Failed to assign student';
  static const String msgErrorAssigningStudent = 'Error assigning student';
  static const String msgErrorRemovingAssignment = 'Error removing assignment';
  static const String msgConfirmRemoveStudentFromTrip = 'Are you sure you want to remove this student from the trip?';
  static const String actionEditOrder = 'Edit Order';
  static const String labelTripPrefix = 'Trip: ';
  static const String labelPickupOrderPrefix = 'Pickup Order: ';
  static const String labelAssignedOnPrefix = 'Assigned on: ';
  static const String labelCreatedByPrefix = 'Created by: ';
  static const String labelUnknownStudent = 'Unknown Student';
  static const String labelUnknownDate = 'Unknown date';
  static const String labelQuestion = '?';
  static const String labelMinutesAgoSuffix = 'm ago';
  static const String labelHoursAgoSuffix = 'h ago';

  static const String keyDriver = 'driver';
  static const String keyVehicle = 'vehicle';
 // static const String keyTripStatus = 'tripStatus';
  static const String keyTripTypeDisplay = 'tripTypeDisplay';
  static const String keyAssignedDriverName = 'assignedDriverName';
  static const String keyHasAssignedDriver = 'hasAssignedDriver';
  static const String keyIsActivated = 'isActivated';
  static const String labelAvailableVehicles = 'Available Vehicles';
  static const String labelTripAssignment = 'Trip Assignment';
  static const String labelAssignTripToVehicle = 'Assign Trip to Vehicle';
  static const String emptyStateTripsAppearOnceCreated = 'Trips will appear here once they are created';
  static const String msgSchoolOrOwnerInfoNotFound = 'School or Owner information not found';
  static const String msgFailedToLoadTrips = 'Failed to load trips';
  static const String msgErrorLoadingTrips = 'Error loading trips: ';
  static const String msgFailedToLoadVehicles = 'Failed to load vehicles';
  static const String msgErrorAssigningTrip = 'Error assigning trip';
  static const String msgTripAssignedToVehicleSuccess = 'Trip assigned to vehicle successfully!';
  static const String msgFailedToAssignTrip = 'Failed to assign trip';
  static const String labelRoutePrefix = 'Route: ';
  static const String labelUnknownRoute = 'Unknown Route';
  static const String labelUnknownType = 'Unknown Type';
  static const String labelTripNotStarted = 'not_started';
  static const String labelCurrentVehiclePrefix = 'Current Vehicle: ';
  static const String labelVehicleManagement = 'Vehicle Management';
  static const String emptyStateAddFirstVehicle = 'Add your first vehicle to get started';
  //static const String labelRegisterVehicle = 'Register Vehicle';
  static const String actionAssignToSchool = 'Assign to School';
  static const String titleDeleteVehicle = 'Delete Vehicle';
  static const String msgConfirmDeleteVehicle = 'Are you sure you want to delete vehicle';
  static const String msgVehicleDeletedSuccess = 'Vehicle deleted successfully';
  static const String msgErrorDeletingVehicle = 'Error deleting vehicle';
  static const String labelVehicleTracking = 'Vehicle Tracking';
  static const String labelTripInformation = 'Trip Information';
  static const String labelType = 'Type';
  static const String labelScheduledTime = 'Scheduled Time';
  static const String labelLocationStatus = 'Location Status';
  static const String labelLastUpdate = 'Last Update';
  static const String labelLatitude = 'Latitude';
  static const String labelLongitude = 'Longitude';
  static const String labelMapView = 'Map View';
  static const String labelRealtimeLocationHint = 'Real-time vehicle location will be shown here';
  static const String labelTripProgress = 'Trip Progress';
  static const String labelTripStarted = 'Trip Started';
  static const String labelArrivingSoon = 'Arriving Soon';
  static const String labelDriverInformation = 'Driver Information';
  static const String labelTripCompleted = 'Trip Completed';
}

/// ========================================
/// APP COLORS
/// All colors used across the application
/// ========================================

class AppColors {
  // Prevent instantiation
  AppColors._();

  /// PRIMARY COLORS
  static const primaryColor = Color(0xFF2196F3); // Blue
  static const primaryDark = Color(0xFF1976D2);
  static const primaryLight = Color(0xFF64B5F6);
  
  /// ACCENT COLORS
  static const accentColor = Color(0xFFFF9800); // Orange
  static const accentDark = Color(0xFFF57C00);
  static const accentLight = Color(0xFFFFB74D);
  
  /// BACKGROUND COLORS
  static const backgroundColor = Color(0xFFF5F5F5);
  static const cardBackground = Color(0xFFFFFFFF);
  static const drawerBackground = Color(0xFFFFFFFF);
  static const appBarBackground = Color(0xFF2196F3);
  
  /// TEXT COLORS
  static const textPrimary = Color(0xFF212121);
  static const textSecondary = Color(0xFF757575);
  static const textMuted = Color(0xFF757575); // Alias of textSecondary
  static const textHint = Color(0xFF9E9E9E);
  static const textWhite = Color(0xFFFFFFFF);
  static const textBlack = Color(0xFF000000);
  static const textLight = Color(0xFFFFFFFF); // For contrast on dark backgrounds
  
  /// STATUS COLORS
  static const successColor = Color(0xFF4CAF50); // Green
  static const errorColor = Color(0xFFF44336); // Red
  static const warningColor = Color(0xFFFF9800); // Orange
  static const infoColor = Color(0xFF2196F3); // Blue
  static const pendingColor = Color(0xFFFF9800); // Orange
  static const approvedColor = Color(0xFF4CAF50); // Green
  static const rejectedColor = Color(0xFFF44336); // Red
  
  // Aliases for dashboard notification colors
  static const statusSuccess = Color(0xFF4CAF50); // Green
  static const statusError = Color(0xFFF44336); // Red
  static const statusWarning = Color(0xFFFF9800); // Orange
  static const statusInfo = Color(0xFF2196F3); // Blue
  
  /// TRIP STATUS COLORS
  static const tripNotStarted = Color(0xFF9E9E9E); // Grey
  static const tripInProgress = Color(0xFF2196F3); // Blue
  static const tripCompleted = Color(0xFF4CAF50); // Green
  static const tripCancelled = Color(0xFFF44336); // Red
  static const tripDelayed = Color(0xFFFF9800); // Orange
  
  /// VEHICLE TYPE COLORS
  static const busColor = Color(0xFF2196F3); // Blue
  static const carColor = Color(0xFF4CAF50); // Green
  static const vanColor = Color(0xFFFF9800); // Orange
  
  /// ROLE COLORS
  static const adminColor = Color(0xFF9C27B0); // Purple
  static const schoolAdminColor = Color(0xFF3F51B5); // Indigo
  static const vehicleOwnerColor = Color(0xFF009688); // Teal
  static const driverColor = Color(0xFFFF5722); // Deep Orange
  static const parentColor = Color(0xFF8BC34A); // Light Green
  static const gateStaffColor = Color(0xFF607D8B); // Blue Grey
  
  /// CHART COLORS
  static const chartColor1 = Color(0xFF2196F3); // Blue
  static const chartColor2 = Color(0xFF4CAF50); // Green
  static const chartColor3 = Color(0xFFFF9800); // Orange
  static const chartColor4 = Color(0xFFF44336); // Red
  static const chartColor5 = Color(0xFF9C27B0); // Purple
  static const chartColor6 = Color(0xFFFFEB3B); // Yellow
  
  /// LOADING WIDGET COLORS
  static const loadingOverlayBackground = Colors.black;
  static const loadingOverlayBackgroundAlpha = 0.3;
  static const loadingContainerBackground = Colors.white;
  static const loadingIndicatorColor = Colors.white;
  static const loadingShadowColor = Colors.black;
  static const loadingShadowAlpha = 0.1;

  /// EXTRA UI COLORS
  static const grey200 = Color(0xFFEEEEEE);
  static const black54 = Color(0x8A000000);
  static const skeletonBaseColor = Colors.grey; // For grey[300]
  static const skeletonLightColor = Colors.grey; // For grey[100]
  static const shimmerColor1Alpha = 0.3; // For grey[300]
  static const shimmerColor2Alpha = 0.1; // For grey[100]
  
  /// STATE MANAGER COLORS
  static const stateErrorIconColor = Colors.red;
  static const stateErrorSnackBarColor = Colors.red;
  static const stateSuccessSnackBarColor = Colors.green;
  static const stateEmptyIconColor = Colors.grey;
  static final stateErrorTextColor = Colors.grey[600]!;
  
  /// NOTIFICATION BADGE COLORS
  static const notificationIconColor = Colors.white;
  static const notificationBadgeColor = Colors.red;
  static const notificationBadgeTextColor = Colors.white;
  
  /// NOTIFICATION CARD COLORS
  static const notificationCardDismissBackground = Colors.red;
  static const notificationCardDismissIconColor = Colors.white;
  static final notificationCardTimeColor = Colors.grey[600]!;
  static const notificationCardUnreadIndicator = Colors.blue;
  
  // Notification Type Colors
  static const notificationTypeTripUpdate = Colors.blue;
  static const notificationTypeArrival = Colors.green;
  static const notificationTypePickup = Colors.orange;
  static const notificationTypeDrop = Colors.purple;
  static const notificationTypeDelay = Colors.red;
  static const notificationTypeSystemAlert = Colors.red;
  static const notificationTypeAttendance = Colors.indigo;
  static const notificationTypeVehicleStatus = Colors.teal;
  static const notificationTypeAssignmentRequest = Colors.deepPurple;
  static const notificationTypeAssignmentApproved = Colors.teal;
  static const notificationTypeAssignmentRejected = Colors.deepOrange;
  static const notificationTypeConnectionEstablished = Colors.lightGreen;
  static const notificationTypeDefault = Colors.grey;
  
  // Notification Priority Colors
  static const notificationPriorityHigh = Colors.red;
  static const notificationPriorityMedium = Colors.orange;
  static const notificationPriorityLow = Colors.green;
  static const notificationPriorityDefault = Colors.grey;
  
  // Notification Toast Colors
  static const notificationToastBackground = Colors.white;
  static const notificationToastShadowColor = Colors.black;
  static const notificationToastTransparent = Colors.transparent;
  static const notificationToastMessageColor = Colors.grey;
  static const notificationToastActionBackground = Colors.blue;
  static const notificationToastActionIconColor = Colors.white;
  static const notificationToastCloseIconColor = Colors.grey;
  
  // School Selector Colors
  static const schoolSelectorErrorColor = Colors.red;
  static const schoolSelectorNoSchoolsColor = Colors.red;
  static const schoolSelectorEmptyTextColor = Colors.grey;
  static const schoolSelectorPrimaryColor = Colors.blue;
  static const schoolSelectorSelectedColor = Colors.blue;
  static const schoolSelectorUnselectedColor = Colors.grey;
  static const schoolSelectorTextWhite = Colors.white;
  static const schoolSelectorTextBlack = Colors.black;
  
  // Activation Screen Colors
  static const activationLinkColor = Colors.blue;
  
  // App Admin Profile Colors
  static const profileAppBarColor = Colors.deepPurple;
  static const profileAvatarBackgroundColor = Colors.white;
  static const profileTextWhite = Colors.white;
  static const profileTextBlack87 = Colors.black87;
  static const profileSuccessColor = Colors.green;
  static const profileErrorColor = Colors.red;
  static const profileCancelButtonColor = Colors.grey;
  
  // School Management Colors
  static const schoolMgmtAppBarColor = Colors.deepPurple;
  static const schoolMgmtSuccessColor = Colors.green;
  static const schoolMgmtErrorColor = Colors.red;
  static const schoolMgmtPrimaryColor = Colors.blue;
  static const schoolMgmtWarningColor = Colors.orange;
  static const schoolMgmtAccentColor = Colors.purple;
  static const schoolMgmtTextWhite = Colors.white;
  
  // Attendance History Colors
  static const attendanceErrorColor = Colors.red;
  static const attendancePrimaryColor = Colors.blue;
  static const attendancePresentColor = Colors.green;
  static const attendanceAbsentColor = Colors.red;
  static const attendanceLateColor = Colors.orange;
  static const attendanceUnknownColor = Colors.grey;
  static const attendanceTextWhite = Colors.white;
  static const attendanceExcellentColor = Colors.green;
  static const attendanceGoodColor = Colors.orange;
  static const attendancePoorColor = Colors.red;
  
  // App Admin Dashboard Colors
  static const appAdminPrimaryColor = Colors.blue;
  static const appAdminSuccessColor = Colors.green;
  static const appAdminErrorColor = Colors.red;
  static const appAdminWarningColor = Colors.orange;
  static const appAdminPurpleColor = Colors.purple;
  static const appAdminTextWhite = Colors.white;
  
  // Driver Dashboard Colors
  static const driverPrimaryColor = Colors.blue;
  static const driverSuccessColor = Colors.green;
  static const driverErrorColor = Colors.red;
  static const driverWarningColor = Colors.orange;
  static const driverPurpleColor = Colors.purple;
  static const driverGreyColor = Colors.grey;
  static const driverTextWhite = Colors.white;
  
  // Login Screen Colors
  static const loginPrimaryColor = Colors.blue;
  static const loginErrorColor = Colors.red;
  static const loginTextWhite = Colors.white;
  
  // Parent Dashboard Colors
  static const parentPrimaryColor = Colors.blue;
  static const parentSuccessColor = Colors.green;
  static const parentErrorColor = Colors.red;
  static const parentWarningColor = Colors.orange;
  static const parentPurpleColor = Colors.purple;
  static const parentTextWhite = Colors.white;
  
  // School Admin Dashboard Colors
  static const schoolAdminPrimaryColor = Colors.blue;
  static const schoolAdminSuccessColor = Colors.green;
  static const schoolAdminErrorColor = Colors.red;
  static const schoolAdminWarningColor = Colors.orange;
  static const schoolAdminPurpleColor = Colors.purple;
  static const schoolAdminTextWhite = Colors.white;
  static const schoolAdminGreyColor = Colors.grey;
  
  // Vehicle Owner Dashboard Colors
  static const vehicleOwnerPrimaryColor = Colors.blue;
  static const vehicleOwnerSuccessColor = Colors.green;
  static const vehicleOwnerErrorColor = Colors.red;
  static const vehicleOwnerWarningColor = Colors.orange;
  static const vehicleOwnerPurpleColor = Colors.purple;
  static const vehicleOwnerTextWhite = Colors.white;
  
  // Bulk Student Import Colors
  static const bulkImportPrimaryColor = Colors.blue;
  static const bulkImportSuccessColor = Colors.green;
  static const bulkImportErrorColor = Colors.red;
  static const bulkImportWarningColor = Colors.orange;
  static const bulkImportInfoColor = Colors.blue;
  static const bulkImportTextWhite = Colors.white;
  
  // Class Management Colors
  static const classMgmtSuccessColor = Colors.green;
  static const classMgmtErrorColor = Colors.red;
  static const classMgmtTextWhite = Colors.white;
  static const classMgmtGreyColor = Colors.grey;
  
  // Create Trip Colors
  static const createTripSuccessColor = Colors.green;
  static const createTripErrorColor = Colors.red;
  static const createTripGreyColor = Colors.grey;
  
  // Driver Management Colors
  static const driverMgmtGreyColor = Colors.grey;
  
  // Driver Profile Colors
  static const driverProfileSuccessColor = Colors.green;
  static const driverProfileErrorColor = Colors.red;
  static const driverProfilePrimaryColor = Colors.blue;
  static const driverProfileTextWhite = Colors.white;
  static const driverProfileGreyColor = Colors.grey;
  
  // Driver Reports Colors
  static const driverReportsBlueColor = Colors.blue;
  static const driverReportsGreenColor = Colors.green;
  static const driverReportsOrangeColor = Colors.orange;
  static const driverReportsAmberColor = Colors.amber;
  static const driverReportsPurpleColor = Colors.purple;
  static const driverReportsRedColor = Colors.red;
  static const driverReportsGreyColor = Colors.grey;
  static const driverReportsWhiteColor = Colors.white;
  static const driverReportsBackgroundColor = Color(0xFFFAFAFA);
  static const driverReportsBorderColor = Color(0xFFE0E0E0);
  
  // Enhanced Vehicle Tracking Colors
  static const vehicleTrackingGreenColor = Colors.green;
  static const vehicleTrackingRedColor = Colors.red;
  static const vehicleTrackingBlueColor = Colors.blue;
  static const vehicleTrackingOrangeColor = Colors.orange;
  static const vehicleTrackingGreyColor = Colors.grey;
  static const vehicleTrackingWhiteColor = Colors.white;
  
  /// COMMON UI COLORS
  static const dividerColor = Color(0xFFBDBDBD);
  static const borderColor = Color(0xFFE0E0E0);
  static const shadowColor = Color(0x1A000000);
  static const overlayColor = Color(0x80000000);
  static const shimmerBaseColor = Color(0xFFE0E0E0);
  static const shimmerHighlightColor = Color(0xFFF5F5F5);
  
  /// GRADIENT COLORS
  static const gradientStart = Color(0xFF2196F3);
  static const gradientEnd = Color(0xFF21CBF3);
  
  /// BUTTON COLORS
  static const buttonPrimary = Color(0xFF2196F3);
  static const buttonSecondary = Color(0xFF757575);
  static const buttonSuccess = Color(0xFF4CAF50);
  static const buttonDanger = Color(0xFFF44336);
  static const buttonWarning = Color(0xFFFF9800);
  static const buttonInfo = Color(0xFF2196F3);
  static const buttonDisabled = Color(0xFFBDBDBD);
  
  /// ICON COLORS
  static const iconPrimary = Color(0xFF2196F3);
  static const iconSecondary = Color(0xFF757575);
  static const iconWhite = Color(0xFFFFFFFF);
  static const iconGrey = Color(0xFF9E9E9E);
  
  /// NOTIFICATION COLORS
  static const notificationBadge = Color(0xFFF44336);
  static const notificationBackground = Color(0xFFE3F2FD);
  
  /// CARD COLORS
  static const cardShadow = Color(0x1A000000);
  static const cardBorder = Color(0xFFE0E0E0);
  
  /// DASHBOARD COLORS
  static const dashboardCard1 = Color(0xFF2196F3);
  static const dashboardCard2 = Color(0xFF4CAF50);
  static const dashboardCard3 = Color(0xFFFF9800);
  static const dashboardCard4 = Color(0xFFF44336);
  static const purpleColor = Colors.purple;
  // Trip themed colors for morning/afternoon
  static const morningTripBg = Color(0xFFFFF3E0); // light orange
  static const afternoonTripBg = Color(0xFFE3F2FD); // light blue
  static const morningTripIcon = Color(0xFFFF9800); // orange
  static const afternoonTripIcon = Color(0xFF2196F3); // blue
  static const morningTripInfoBg = Color(0xFFFFE0B2); // deeper light orange
  static const afternoonTripInfoBg = Color(0xFFBBDEFB); // deeper light blue
  static const morningTripInfoIcon = Color(0xFFF57C00); // dark orange
  static const afternoonTripInfoIcon = Color(0xFF1976D2); // dark blue
}

/// ========================================
/// APP SIZES
/// All dimensions used across the application
/// ========================================

class AppSizes {
  // Prevent instantiation
  AppSizes._();

  /// PADDING & MARGIN
  static const double paddingXS = 4.0;
  static const double paddingSM = 8.0;
  static const double paddingMD = 16.0;
  static const double paddingLG = 24.0;
  static const double paddingXL = 32.0;
  static const double paddingXXL = 40.0;
  
  static const double marginXS = 4.0;
  static const double marginSM = 8.0;
  static const double marginMD = 16.0;
  static const double marginLG = 24.0;
  static const double marginXL = 32.0;
  
  /// BORDER RADIUS
  static const double radiusXS = 4.0;
  static const double radiusSM = 8.0;
  static const double radiusMD = 12.0;
  static const double radiusLG = 16.0;
  static const double radiusXL = 20.0;
  static const double radiusCircle = 100.0;
  
  /// ICON SIZES
  static const double iconXS = 16.0;
  static const double iconSM = 20.0;
  static const double iconMD = 24.0;
  static const double iconLG = 32.0;
  static const double iconXL = 48.0;
  static const double iconXXL = 64.0;
  
  /// BUTTON SIZES
  static const double buttonHeightSM = 32.0;
  static const double buttonHeightMD = 40.0;
  static const double buttonHeightLG = 48.0;
  static const double buttonHeightXL = 56.0;
  
  static const double buttonWidthSM = 80.0;
  static const double buttonWidthMD = 120.0;
  static const double buttonWidthLG = 160.0;
  static const double buttonWidthFull = double.infinity;
  
  /// TEXT SIZES
  static const double textXS = 10.0;
  static const double textSM = 12.0;
  static const double textMD = 14.0;
  static const double textLG = 16.0;
  static const double textXL = 18.0;
  static const double textXXL = 20.0;
  static const double text3XL = 24.0;
  static const double text4XL = 28.0;
  static const double text5XL = 32.0;
  
  /// HEADING SIZES
  static const double headingH1 = 32.0;
  static const double headingH2 = 28.0;
  static const double headingH3 = 24.0;
  static const double headingH4 = 20.0;
  static const double headingH5 = 18.0;
  static const double headingH6 = 16.0;
  
  /// CARD SIZES
  static const double cardElevation = 2.0;
  static const double cardElevationHover = 4.0;
  static const double cardPadding = 16.0;
  static const double cardMargin = 8.0;
  
  /// APP BAR
  static const double appBarHeight = 56.0;
  static const double appBarElevation = 4.0;
  
  /// DRAWER
  static const double drawerWidth = 280.0;
  
  /// DIVIDER
  static const double dividerThickness = 1.0;
  static const double dividerIndent = 16.0;
  
  /// BORDER
  static const double borderWidthThin = 1.0;
  static const double borderWidthMedium = 2.0;
  static const double borderWidthThick = 3.0;
  
  /// AVATAR SIZES
  static const double avatarXS = 24.0;
  static const double avatarSM = 32.0;
  static const double avatarMD = 40.0;
  static const double avatarLG = 56.0;
  static const double avatarXL = 72.0;
  static const double avatarXXL = 96.0;
  
  /// SPACING
  static const double spaceXS = 4.0;
  static const double spaceSM = 8.0;
  static const double spaceMD = 16.0;
  static const double spaceLG = 24.0;
  static const double spaceXL = 32.0;
  static const double spaceXXL = 48.0;
  
  /// FORM FIELDS
  static const double inputHeight = 48.0;
  static const double inputPadding = 12.0;
  static const double inputBorderRadius = 8.0;
  
  /// CHIP SIZES
  static const double chipHeight = 32.0;
  static const double chipPadding = 12.0;
  
  /// BADGE SIZES
  static const double badgeSM = 16.0;
  
  /// LOADING WIDGET SIZES
  static const double loadingIndicatorSize = 16.0;
  static const double loadingIndicatorStrokeWidth = 2.0;
  static const double loadingOverlayPadding = 24.0;
  static const double loadingOverlayRadius = 12.0;
  static const double loadingOverlayBlurRadius = 10.0;
  static const double loadingOverlayOffset = 4.0;
  static const double skeletonAvatarSize = 50.0;
  static const double skeletonAvatarRadius = 25.0;
  static const double skeletonTitleHeight = 16.0;
  static const double skeletonSubtitleHeight = 12.0;
  static const double skeletonSubtitleWidth = 200.0;
  static const double skeletonCardTitleHeight = 20.0;
  static const double skeletonCardSubtitle1Width = 150.0;
  static const double skeletonCardSubtitle2Width = 100.0;
  static const double skeletonCardBlurRadius = 4.0;
  static const double skeletonCardOffset = 2.0;
  static const double shimmerGradientStop1 = 0.1;
  static const double shimmerGradientStop2 = 0.3;
  static const double shimmerGradientStop3 = 0.4;
  
  // State Manager Sizes
  static const double stateIconSize = 64.0;
  static const double stateIconSpacing = 16.0;
  static const double stateTextSpacing = 8.0;
  static const double stateErrorTextSize = 18.0;
  static const double stateErrorPadding = 32.0;
  static const double stateDialogSpacing = 16.0;
  
  // Notification Badge Sizes
  static const double notificationIconSize = 28.0;
  static const double notificationBadgePadding = 2.0;
  static const double notificationBadgeRadius = 10.0;
  static const double notificationBadgeMinSize = 16.0;
  static const double notificationBadgeFontSize = 10.0;
  static const int notificationMaxCount = 99;
  
  // Notification Card Sizes
  static const double notificationCardMarginHorizontal = 8.0;
  static const double notificationCardMarginVertical = 4.0;
  static const double notificationCardElevation = 2.0;
  static const double notificationCardDismissPadding = 20.0;
  static const double notificationCardTitleFontSize = 16.0;
  static const double notificationCardMessageFontSize = 14.0;
  static const double notificationCardTimeFontSize = 12.0;
  static const double notificationCardSpacing = 4.0;
  static const double notificationCardIconSize = 20.0;
  static const double notificationCardPriorityIconSize = 16.0;
  static const double notificationCardUnreadIndicatorSize = 8.0;
  static const double notificationCardIconOpacity = 0.1;
  static const int notificationCardMaxLines = 2;
  static const int notificationTimeThresholdMinutes = 1;
  static const int notificationTimeThresholdHours = 60;
  static const int notificationTimeThresholdDays = 24;
  
  // Notification Toast Sizes
  static const double notificationToastMargin = 8.0;
  static const double notificationToastRadius = 12.0;
  static const double notificationToastShadowBlur = 8.0;
  static const double notificationToastShadowOffset = 2.0;
  static const double notificationToastShadowOpacity = 0.1;
  static const double notificationToastPadding = 12.0;
  static const double notificationToastSpacingLG = 12.0;
  static const double notificationToastSpacingSM = 8.0;
  static const double notificationToastSpacingXS = 4.0;
  static const double notificationToastTitleFontSize = 14.0;
  static const double notificationToastMessageFontSize = 12.0;
  static const double notificationToastIconRadius = 20.0;
  static const double notificationToastIconSize = 20.0;
  static const double notificationToastIconOpacity = 0.1;
  static const double notificationToastPrioritySize = 8.0;
  static const double notificationToastActionPadding = 4.0;
  static const double notificationToastActionRadius = 4.0;
  static const double notificationToastActionIconSize = 12.0;
  static const double notificationToastCloseIconSize = 16.0;
  static const double notificationToastOverlayTop = 10.0;
  static const double notificationToastOverlaySide = 16.0;
  static const int notificationToastMaxLines = 2;
  static const int notificationToastAnimationMs = 300;
  static const int notificationToastAutoDismissSec = 5;
  static const double notificationToastAnimationStart = 1.0;
  static const double notificationToastAnimationEnd = 0.0;
  
  // School Selector Sizes
  static const double schoolSelectorLoadingSize = 24.0;
  static const double schoolSelectorLoadingStroke = 2.0;
  static const double schoolSelectorNoSchoolsFontSize = 12.0;
  static const double schoolSelectorModalRadius = 20.0;
  static const double schoolSelectorModalPadding = 20.0;
  static const double schoolSelectorHeaderFontSize = 20.0;
  static const double schoolSelectorSpacingMD = 16.0;
  static const double schoolSelectorSpacingSM = 8.0;
  static const double schoolSelectorSpacingXS = 6.0;
  static const double schoolSelectorSpacingXXS = 4.0;
  static const double schoolSelectorContainerRadius = 20.0;
  static const double schoolSelectorContainerPaddingH = 12.0;
  static const double schoolSelectorContainerPaddingV = 6.0;
  static const double schoolSelectorIconSize = 16.0;
  static const double schoolSelectorTextFontSize = 12.0;
  static const int schoolSelectorNameSubstringStart = 0;
  static const int schoolSelectorNameSubstringEnd = 1;
  
  // Activation Screen Sizes
  static const double activationPadding = 16.0;
  static const double activationSpacingSM = 8.0;
  static const double activationSpacingMD = 16.0;
  static const double activationSpacingLG = 20.0;
  static const double activationHeaderFontSize = 18.0;
  static const int activationPasswordMinLength = 6;
  
  // App Admin Profile Sizes
  static const double profilePadding = 16.0;
  static const double profileCardElevation = 4.0;
  static const double profileCardRadius = 15.0;
  static const double profileCardPadding = 20.0;
  static const double profileAvatarRadius = 50.0;
  static const double profileAvatarIconSize = 50.0;
  static const double profileSpacingSM = 8.0;
  static const double profileSpacingMD = 16.0;
  static const double profileSpacingLG = 24.0;
  static const double profileSpacingXL = 20.0;
  static const double profileNameFontSize = 24.0;
  static const double profileRoleFontSize = 16.0;
  static const double profileEmailFontSize = 14.0;
  static const double profileSpacingXS = 4.0;
  static const double profileDetailsCardElevation = 2.0;
  static const double profileDetailsCardRadius = 12.0;
  static const double profileHeaderFontSize = 18.0;
  static const double profileInfoRowBottomPadding = 12.0;
  static const double profileInfoLabelWidth = 120.0;
  static const double profileInfoLabelFontSize = 14.0;
  static const double profileButtonPaddingVertical = 12.0;
  static const double profileSavingIndicatorSize = 20.0;
  static const double profileSavingIndicatorStroke = 2.0;
  
  // School Management Sizes
  static const double schoolMgmtPadding = 16.0;
  static const double schoolMgmtSpacingSM = 8.0;
  static const double schoolMgmtSpacingMD = 12.0;
  static const double schoolMgmtSpacingXS = 4.0;
  static const double schoolMgmtEmptyIconSize = 64.0;
  static const double schoolMgmtEmptyTextFontSize = 18.0;
  static const double schoolMgmtStatIconSize = 24.0;
  static const double schoolMgmtStatValueFontSize = 20.0;
  static const double schoolMgmtStatTitleFontSize = 12.0;
  static const double schoolMgmtSchoolNameFontSize = 18.0;
  static const double schoolMgmtSchoolLocationFontSize = 14.0;
  static const double schoolMgmtStatusPaddingH = 8.0;
  static const double schoolMgmtStatusPaddingV = 4.0;
  static const double schoolMgmtStatusRadius = 12.0;
  static const double schoolMgmtStatusFontSize = 12.0;
  static const double schoolMgmtDateIconSize = 16.0;
  static const double schoolMgmtCardElevation = 2.0;
  static const double schoolMgmtCardMarginH = 16.0;
  static const double schoolMgmtCardMarginV = 4.0;
  
  // Attendance History Sizes
  static const double attendanceIconSize = 28.0;
  static const double attendanceSpacingSM = 8.0;
  static const double attendanceSpacingMD = 16.0;
  static const double attendanceSpacingXS = 4.0;
  static const double attendanceSpacingXXS = 10.0;
  static const double attendanceErrorFontSize = 16.0;
  static const double attendanceStatCardPadding = 12.0;
  static const double attendanceStatIconSize = 24.0;
  static const double attendanceStatValueFontSize = 20.0;
  static const double attendanceStatTitleFontSize = 12.0;
  static const double attendanceCardElevation = 3.0;
  static const double attendancePercentageCardElevation = 3.0;
  static const double attendancePercentageCardPadding = 16.0;
  static const double attendancePercentageTitleFontSize = 18.0;
  static const double attendancePercentageValueFontSize = 24.0;
  static const double attendanceDateRangeCardElevation = 2.0;
  static const double attendanceDateRangeCardPadding = 12.0;
  static const double attendanceDailyRecordsTitleFontSize = 20.0;
  static const double attendanceRecordCardMargin = 8.0;
  
  // App Admin Dashboard Sizes
  static const double appAdminPadding = 16.0;
  static const double appAdminSpacingSM = 8.0;
  static const double appAdminSpacingXS = 4.0;
  static const double appAdminMenuFontSize = 24.0;
  static const double appAdminHeaderFontSize = 18.0;
  static const double appAdminStatCardPadding = 12.0;
  static const double appAdminStatIconSize = 24.0;
  static const double appAdminStatValueFontSize = 18.0;
  static const double appAdminStatTitleFontSize = 12.0;
  static const double appAdminStatBorderRadius = 8.0;
  static const double appAdminStatBgOpacity = 0.1;
  static const double appAdminStatBorderOpacity = 0.3;
  static const double appAdminSchoolCardMargin = 8.0;
  static const double appAdminErrorIconSize = 64.0;
  static const double appAdminErrorTextSize = 16.0;
  
  // Driver Dashboard Sizes
  static const double driverPadding = 16.0;
  static const double driverSpacingSM = 8.0;
  static const double driverSpacingMD = 16.0;
  static const double driverSpacingXS = 4.0;
  static const double driverSpacingXXS = 12.0;
  static const double driverMenuFontSize = 24.0;
  static const double driverHeaderFontSize = 18.0;
  static const double driverSubheaderFontSize = 16.0;
  static const double driverStatCardPadding = 12.0;
  static const double driverStatIconSize = 24.0;
  static const double driverStatValueFontSize = 18.0;
  static const double driverStatTitleFontSize = 12.0;
  static const double driverStatBorderRadius = 8.0;
  static const double driverStatBgOpacity = 0.1;
  static const double driverStatBorderOpacity = 0.3;
  static const double driverErrorIconSize = 64.0;
  static const double driverErrorTextSize = 16.0;
  static const int driverAutoRefreshSeconds = 30;
  static const int driverLocationUpdateSeconds = 30;
  
  // Login Screen Sizes
  static const double loginPadding = 24.0;
  static const double loginLogoSize = 80.0;
  static const double loginSpacingLG = 48.0;
  static const double loginSpacingMD = 24.0;
  static const double loginSpacingSM = 16.0;
  static const double loginSpacingXS = 8.0;
  static const double loginTitleFontSize = 32.0;
  static const double loginTextFontSize = 16.0;
  static const double loginButtonPaddingV = 16.0;
  static const double loginButtonRadius = 8.0;
  static const double loginProgressSize = 20.0;
  static const double loginProgressStroke = 2.0;
  
  // Parent Dashboard Sizes
  static const double parentPadding = 16.0;
  static const double parentSpacingMD = 16.0;
  static const double parentSpacingSM = 8.0;
  static const double parentSpacingXS = 4.0;
  static const double parentMenuFontSize = 24.0;
  static const double parentHeaderFontSize = 18.0;
  static const double parentStatCardPadding = 12.0;
  static const double parentStatIconSize = 24.0;
  static const double parentStatValueFontSize = 18.0;
  static const double parentStatTitleFontSize = 12.0;
  static const double parentStatBorderRadius = 8.0;
  static const double parentStatBgOpacity = 0.1;
  static const double parentStatBorderOpacity = 0.3;
  static const double parentCardMargin = 8.0;
  static const double parentErrorIconSize = 64.0;
  static const double parentErrorTextSize = 16.0;
  static const int parentNotificationDurationSeconds = 4;
  
  // School Admin Dashboard Sizes
  static const double schoolAdminPadding = 16.0;
  static const double schoolAdminSpacingMD = 16.0;
  static const double schoolAdminSpacingSM = 8.0;
  static const double schoolAdminSpacingXS = 4.0;
  static const double schoolAdminLogoSize = 48.0;
  static const double schoolAdminMenuFontSize = 20.0;
  static const double schoolAdminHeaderFontSize = 18.0;
  static const double schoolAdminStatCardPadding = 12.0;
  static const double schoolAdminStatIconSize = 24.0;
  static const double schoolAdminStatValueFontSize = 18.0;
  static const double schoolAdminStatTitleFontSize = 12.0;
  static const double schoolAdminStatBorderRadius = 8.0;
  static const double schoolAdminStatBgOpacity = 0.1;
  static const double schoolAdminStatBorderOpacity = 0.3;
  static const double schoolAdminErrorIconSize = 64.0;
  static const double schoolAdminErrorTextSize = 16.0;
  static const double schoolAdminBadgeFontSize = 10.0;
  static const double schoolAdminBadgePaddingH = 8.0;
  static const double schoolAdminBadgePaddingV = 4.0;
  static const double schoolAdminBadgeRadius = 12.0;
  
  // Vehicle Owner Dashboard Sizes
  static const double vehicleOwnerPadding = 16.0;
  static const double vehicleOwnerSpacingMD = 16.0;
  static const double vehicleOwnerSpacingSM = 8.0;
  static const double vehicleOwnerSpacingXS = 4.0;
  static const double vehicleOwnerMenuFontSize = 24.0;
  static const double vehicleOwnerHeaderFontSize = 18.0;
  static const double vehicleOwnerStatCardPadding = 12.0;
  static const double vehicleOwnerStatIconSize = 24.0;
  static const double vehicleOwnerStatValueFontSize = 18.0;
  static const double vehicleOwnerStatTitleFontSize = 12.0;
  static const double vehicleOwnerStatBorderRadius = 8.0;
  static const double vehicleOwnerStatBgOpacity = 0.1;
  static const double vehicleOwnerStatBorderOpacity = 0.3;
  static const double vehicleOwnerErrorIconSize = 64.0;
  static const double vehicleOwnerErrorTextSize = 16.0;
  static const double vehicleOwnerTooltipPaddingRight = 8.0;
  
  // Bulk Student Import Sizes
  static const double bulkImportPadding = 16.0;
  static const double bulkImportSpacingMD = 16.0;
  static const double bulkImportSpacingSM = 8.0;
  static const double bulkImportSpacingXS = 4.0;
  static const double bulkImportHeaderFontSize = 18.0;
  static const double bulkImportInfoFontSize = 12.0;
  static const double bulkImportCardPadding = 12.0;
  static const double bulkImportBorderRadius = 8.0;
  static const double bulkImportIconSize = 20.0;
  static const double bulkImportIconSizeSM = 16.0;
  static const double bulkImportProgressSize = 16.0;
  static const double bulkImportProgressStroke = 2.0;
  static const double bulkImportSummaryValueFontSize = 24.0;
  static const double bulkImportSummaryTitleFontSize = 12.0;
  static const double bulkImportResultPadding = 12.0;
  static const double bulkImportBgOpacity = 0.1;
  
  // Class Management Sizes
  static const double classMgmtPadding = 16.0;
  static const double classMgmtSpacingMD = 16.0;
  static const double classMgmtSpacingSM = 8.0;
  static const double classMgmtCardMargin = 8.0;
  static const double classMgmtStatusPaddingH = 8.0;
  static const double classMgmtStatusPaddingV = 2.0;
  static const double classMgmtStatusRadius = 12.0;
  static const double classMgmtStatusFontSize = 12.0;
  static const double classMgmtEmptyTextSize = 16.0;
  
  // Create Trip Sizes
  static const double createTripPadding = 16.0;
  static const double createTripSpacingMD = 20.0;
  static const double createTripSpacingSM = 12.0;
  static const double createTripSpacingXS = 10.0;
  static const double createTripIconSize = 80.0;
  static const double createTripTitleFontSize = 20.0;
  static const double createTripPaddingH = 40.0;
  static const double createTripProgressSize = 20.0;
  static const double createTripProgressStroke = 2.0;
  static const double createTripButtonPaddingV = 16.0;
  
  // Driver Management Sizes
  static const double driverMgmtIconSize = 64.0;
  static const double driverMgmtSpacingMD = 16.0;
  static const double driverMgmtSpacingSM = 8.0;
  static const double driverMgmtTitleFontSize = 20.0;
  
  // Driver Profile Sizes
  static const double driverProfilePadding = 16.0;
  static const double driverProfileSpacingLG = 24.0;
  static const double driverProfileSpacingMD = 16.0;
  static const double driverProfileSpacingSM = 12.0;
  static const double driverProfileSpacingXS = 8.0;
  static const double driverProfilePhotoRadius = 60.0;
  static const double driverProfilePhotoIconSize = 60.0;
  static const double driverProfileCameraPadding = 8.0;
  static const double driverProfileCameraIconSize = 20.0;
  static const double driverProfileProgressSize = 20.0;
  static const double driverProfileProgressStroke = 2.0;
  static const double driverProfileCardElevation = 3.0;
  static const double driverProfileCardRadius = 12.0;
  static const double driverProfileCardPadding = 20.0;
  static const double driverProfileHeaderFontSize = 18.0;
  static const double driverProfileLabelWidth = 120.0;
  
  // Driver Reports Sizes
  static const double driverReportsPadding = 16.0;
  static const double driverReportsSpacingLG = 20.0;
  static const double driverReportsSpacingMD = 16.0;
  static const double driverReportsSpacingSM = 12.0;
  static const double driverReportsSpacingXS = 8.0;
  static const double driverReportsCardElevation = 3.0;
  static const double driverReportsCardRadius = 12.0;
  static const double driverReportsCardPadding = 20.0;
  static const double driverReportsSelectorPadding = 16.0;
  static const double driverReportsSelectorIconSize = 24.0;
  static const double driverReportsTitleFontSize = 18.0;
  static const double driverReportsPeriodFontSize = 16.0;
  static const double driverReportsStatPadding = 16.0;
  static const double driverReportsStatRadius = 8.0;
  static const double driverReportsStatBorder = 1.0;
  static const double driverReportsStatIconSize = 24.0;
  static const double driverReportsStatValueFontSize = 20.0;
  static const double driverReportsStatLabelFontSize = 12.0;
  static const double driverReportsPerformanceIconSize = 20.0;
  static const double driverReportsPerformanceFontSize = 14.0;
  static const double driverReportsRecentTripMargin = 12.0;
  static const double driverReportsRecentTripPadding = 12.0;
  static const double driverReportsRecentTripRadius = 8.0;
  static const double driverReportsRecentTripAvatarRadius = 20.0;
  static const double driverReportsRecentTripIconSize = 16.0;
  static const double driverReportsRecentTripFontSizeSM = 10.0;
  static const double driverReportsRecentTripBadgePaddingH = 8.0;
  static const double driverReportsRecentTripBadgePaddingV = 4.0;
  static const double driverReportsRecentTripBadgeRadius = 12.0;
  static const double driverReportsAttendanceMargin = 8.0;
  static const double driverReportsAttendancePadding = 12.0;
  static const double driverReportsAttendanceRadius = 8.0;
  static const double driverReportsAttendanceDotSize = 8.0;
  
  // Enhanced Vehicle Tracking Sizes
  static const double vehicleTrackingAppBarIconSize = 24.0;
  static const double vehicleTrackingAppBarSpacing = 8.0;
  static const double vehicleTrackingWifiIconSize = 20.0;
  static const double vehicleTrackingErrorIconSize = 64.0;
  static const double vehicleTrackingErrorSpacing = 16.0;
  static const double vehicleTrackingErrorFontSize = 16.0;
  static const double vehicleTrackingNoTripIconSize = 64.0;
  static const double vehicleTrackingNoTripSpacing = 16.0;
  static const double vehicleTrackingNoTripTitleFontSize = 20.0;
  static const double vehicleTrackingNoTripMsgFontSize = 16.0;
  static const double vehicleTrackingBarPadding = 16.0;
  static const double vehicleTrackingBarSpacing = 8.0;
  static const double vehicleTrackingAddressFontSize = 12.0;
  static const int vehicleTrackingPolylineWidth = 4;
  static const double vehicleTrackingPolylineDash = 20.0;
  static const double vehicleTrackingPolylineGap = 10.0;
  static const double vehicleTrackingPanelHeight = 120.0;
  static const double vehicleTrackingPanelPadding = 16.0;
  static const double vehicleTrackingPanelSpreadRadius = 1.0;
  static const double vehicleTrackingPanelBlurRadius = 5.0;
  static const double vehicleTrackingPanelOffsetY = -2.0;
  static const double vehicleTrackingTripIconSize = 20.0;
  static const double vehicleTrackingTripIconSpacing = 8.0;
  static const double vehicleTrackingTripTitleFontSize = 16.0;
  static const double vehicleTrackingTripInfoFontSize = 14.0;
  static const double vehicleTrackingTripInfoSpacing = 8.0;
  static const double vehicleTrackingETAIconSize = 24.0;
  static const double vehicleTrackingETASpacing = 4.0;
  static const double vehicleTrackingETALabelFontSize = 12.0;
  static const double vehicleTrackingETAValueFontSize = 16.0;
  static const double vehicleTrackingStatusDotSize = 12.0;
  static const double vehicleTrackingStatusFontSize = 12.0;
  static const double vehicleTrackingZoom = 15.0;
  
  // Home Page Sizes
  static const double homePaddingH = 24.0;
  static const double homePaddingV = 40.0;
  static const double homeIconSize = 100.0;
  static const double homeSpacing = 20.0;
  static const double homeTitleFontSize = 28.0;
  static const double homeLetterSpacing = 1.2;
  static const double homeButtonSpacing = 50.0;
  static const double homeButtonHeight = 55.0;
  static const double homeButtonRadius = 15.0;
  static const double homeButtonTextSize = 18.0;
  
  // Forgot Password Sizes
  static const double forgotPasswordPadding = 16.0;
  static const double forgotPasswordSpacing = 16.0;
  static const double forgotPasswordSpacingLG = 20.0;
  static const int forgotPasswordMinLength = 6;
  
  // Gate Staff Dashboard Sizes
  static const double gateStaffPadding = 16.0;
  static const double gateStaffPaddingOnly = 8.0;
  static const double gateStaffSpacingLG = 20.0;
  static const double gateStaffSpacingMD = 16.0;
  static const double gateStaffSpacingSM = 12.0;
  static const double gateStaffSpacingXS = 8.0;
  static const double gateStaffWifiIconSize = 20.0;
  static const double gateStaffErrorIconSize = 64.0;
  static const double gateStaffErrorTitleFontSize = 24.0;
  static const double gateStaffErrorTextFontSize = 16.0;
  static const double gateStaffWelcomeRadius = 12.0;
  static const double gateStaffWelcomeFontSize = 24.0;
  static const double gateStaffWelcomeSubFontSize = 16.0;
  static const double gateStaffStatCardIconSize = 32.0;
  static const double gateStaffStatCardValueFontSize = 24.0;
  static const double gateStaffStatCardLabelFontSize = 12.0;
  static const double gateStaffStatCardElevation = 4.0;
  static const double gateStaffTitleFontSize = 20.0;
  static const double gateStaffTripCardMargin = 16.0;
  static const double gateStaffTripCardElevation = 4.0;
  static const double gateStaffTripCardRadius = 12.0;
  static const double gateStaffTripTitleFontSize = 18.0;
  static const double gateStaffTripSubFontSize = 12.0;
  static const double gateStaffStudentCardMargin = 8.0;
  static const double gateStaffButtonPaddingH = 12.0;
  static const double gateStaffButtonPaddingV = 8.0;
  static const double gateStaffButtonRadius = 4.0;
  static const int gateStaffRemarksMaxLines = 2;
  static const double gateStaffNoTripsFontSize = 16.0;
  static const double gateStaffNoTripsPadding = 32.0;
  
  // Monthly Report Page Sizes
  static const double monthlyReportPadding = 16.0;
  static const double monthlyReportSpacing = 8.0;
  static const double monthlyReportSpacingLG = 16.0;
  static const double monthlyReportIconSize = 28.0;
  static const double monthlyReportIconSpacing = 8.0;
  static const double monthlyReportErrorFontSize = 16.0;
  static const double monthlyReportErrorSpacing = 10.0;
  static const double monthlyReportCardElevation = 3.0;
  static const double monthlyReportHeaderFontSize = 20.0;
  static const double monthlyReportSectionFontSize = 18.0;
  static const double monthlyReportPercentFontSize = 24.0;
  static const double monthlyReportStatCardElevation = 2.0;
  static const double monthlyReportStatCardPadding = 12.0;
  static const double monthlyReportStatIconSize = 24.0;
  static const double monthlyReportStatValueFontSize = 18.0;
  static const double monthlyReportStatLabelFontSize = 12.0;
  static const double monthlyReportStatSpacing = 4.0;
  static const double monthlyReportProgressSpacing = 4.0;
  static const double monthlyReportProgressSpacingLG = 12.0;
  static const double monthlyReportPercentOpacity = 0.3;
  static const int monthlyReportYearRange = 5;
  static const int monthlyReportMonthCount = 12;
  static const double monthlyReportAttendanceGood = 90.0;
  static const double monthlyReportAttendanceFair = 75.0;
  
  // Notification Page Sizes
  static const double notificationFilterHeight = 50.0;
  static const double notificationFilterPaddingV = 8.0;
  static const double notificationFilterPaddingH = 8.0;
  static const double notificationFilterChipPadding = 4.0;
  static const double notificationEmptyIconSize = 64.0;
  static const double notificationEmptySpacing = 16.0;
  static const double notificationEmptySpacingSM = 8.0;
  static const double notificationEmptyTitleFontSize = 18.0;
  static const double notificationEmptySubtitleFontSize = 14.0;
  static const double notificationFilterOpacity = 0.2;
  
  // Parent Management Page Sizes
  static const double parentManagementIconSize = 64.0;
  static const double parentManagementSpacing = 16.0;
  static const double parentManagementSpacingSM = 8.0;
  static const double parentManagementTitleFontSize = 20.0;
  static const double parentManagementSubtitleFontSize = 16.0;
  
  // Parent Profile Update Page Sizes
  static const double parentProfileIconSize = 28.0;
  static const double parentProfileIconSpacing = 8.0;
  static const double parentProfilePadding = 16.0;
  static const double parentProfileSpacing = 16.0;
  static const double parentProfileSpacingSM = 8.0;
  static const double parentProfileSpacingLG = 24.0;
  static const double parentProfileErrorSpacing = 10.0;
  static const double parentProfileErrorFontSize = 16.0;
  static const double parentProfileErrorPadding = 12.0;
  static const double parentProfileErrorRadius = 8.0;
  static const double parentProfileErrorOpacity = 0.1;
  static const double parentProfileCardElevation = 3.0;
  static const double parentProfileTitleFontSize = 18.0;
  static const double parentProfileHintFontSize = 12.0;
  static const double parentProfileButtonHeight = 50.0;
  static const double parentProfileButtonFontSize = 16.0;
  static const double parentProfileLoadingSize = 20.0;
  static const double parentProfileLoadingStroke = 2.0;
  static const double parentProfileLoadingSpacing = 12.0;
  static const int parentProfileContactMinLength = 10;
  static const int parentProfilePasswordMinLength = 6;
  
  // Pending Vehicle Requests Page Sizes
  static const double pendingRequestsPadding = 16.0;
  static const double pendingRequestsCardMargin = 16.0;
  static const double pendingRequestsCardPadding = 16.0;
  static const double pendingRequestsSpacing = 8.0;
  static const double pendingRequestsSpacingSM = 12.0;
  static const double pendingRequestsIconSize = 20.0;
  static const double pendingRequestsTitleFontSize = 16.0;
  static const double pendingRequestsTextFontSize = 14.0;
  static const double pendingRequestsBadgePaddingH = 12.0;
  static const double pendingRequestsBadgePaddingV = 4.0;
  static const double pendingRequestsBadgeRadius = 12.0;
  static const double pendingRequestsBadgeOpacity = 0.2;
  static const double pendingRequestsButtonSpacing = 8.0;
  
  // Privacy Policy Screen Sizes
  static const double privacyPolicyPadding = 16.0;
  static const double privacyPolicyFontSize = 16.0;
  
  // Register Driver Screen Sizes
  static const double registerDriverPadding = 16.0;
  static const double registerDriverAvatarRadius = 48.0;
  static const double registerDriverIconSize = 36.0;
  static const double registerDriverSpacing = 12.0;
  static const double registerDriverSpacingSM = 8.0;
  static const double registerDriverSpacingLG = 20.0;
  static const int registerDriverNameMaxLength = 100;
  static const int registerDriverAddressMaxLength = 255;
  static const int registerDriverEmailMaxLength = 150;
  static const int registerDriverContactLength = 10;
  static const int registerDriverImageQuality = 75;
  
  // Register School Screen Sizes
  static const double registerSchoolPadding = 16.0;
  static const double registerSchoolSpacing = 12.0;
  static const double registerSchoolSpacingLG = 20.0;
  static const double registerSchoolAvatarRadius = 50.0;
  static const double registerSchoolIconSize = 40.0;
  static const double registerSchoolLoaderSize = 20.0;
  static const double registerSchoolLoaderStroke = 2.0;
  static const double registerSchoolLoaderPadding = 12.0;
  static const double registerSchoolButtonPadding = 16.0;
  static const double registerSchoolInfoIconSize = 16.0;
  static const double registerSchoolInfoIconSize2 = 20.0;
  static const double registerSchoolInfoPadding = 8.0;
  static const double registerSchoolInfoFontSize = 12.0;
  static const int registerSchoolNameMinLength = 2;
  static const int registerSchoolNameMaxLength = 200;
  static const int registerSchoolRegNumberMinLength = 3;
  static const int registerSchoolRegNumberMaxLength = 100;
  static const int registerSchoolPincodeLength = 6;
  static const int registerSchoolContactLength = 10;
  static const int registerSchoolEmailMaxLength = 150;
  static const int registerSchoolSnackBarDuration = 5;
  static const int registerSchoolSnackBarDurationShort = 3;
  
  // Register Gate Staff Page Sizes
  static const double registerGateStaffPadding = 16.0;
  static const double registerGateStaffSpacing = 12.0;
  static const double registerGateStaffSpacingSM = 8.0;
  static const double registerGateStaffSpacingLG = 20.0;
  static const double registerGateStaffButtonPadding = 16.0;
  static const double registerGateStaffLoaderSize = 20.0;
  static const double registerGateStaffLoaderStroke = 2.0;
  static const double registerGateStaffBorderRadius = 4.0;
  static const double registerGateStaffBorderRadius2 = 8.0;
  static const double registerGateStaffContainerPadding = 12.0;
  static const double registerGateStaffContainerPaddingV = 16.0;
  static const double registerGateStaffIconSize = 20.0;
  static const double registerGateStaffFontSize = 16.0;
  static const double registerGateStaffOpacity = 0.1;
  static const double registerGateStaffOpacity2 = 0.3;
  static const int registerGateStaffNameMinLength = 2;
  static const int registerGateStaffNameMaxLength = 50;
  static const int registerGateStaffUsernameMinLength = 3;
  static const int registerGateStaffUsernameMaxLength = 50;
  static const int registerGateStaffPasswordMinLength = 6;
  static const int registerGateStaffPasswordMaxLength = 100;
  static const int registerGateStaffEmailMaxLength = 150;
  static const int registerGateStaffContactLength = 10;
  static const int registerGateStaffDisplayNameMaxLength = 50;
  static const int registerGateStaffErrorDuration = 4;

  // Register Student Screen Sizes
  static const double registerStudentPadding = 16.0;
  static const double registerStudentAvatarRadius = 48.0;
  static const double registerStudentIconSize = 36.0;
  static const double registerStudentSpacing = 12.0;
  static const double registerStudentSpacingSM = 8.0;
  static const double registerStudentSpacingLG = 20.0;
  static const int registerStudentNameMaxLength = 50;
  static const int registerStudentNameMinLength = 2;
  static const int registerStudentContactLength = 10;
  static const int registerStudentEmailMaxLength = 150;
  static const int registerStudentImageQuality = 75;
  static const int registerStudentErrorDuration = 4;
  
  // Register Vehicle Screen Sizes
  static const double registerVehiclePadding = 16.0;
  static const double registerVehicleSpacing = 12.0;
  static const double registerVehicleSpacingLG = 20.0;
  static const double registerVehicleAvatarRadius = 48.0;
  static const double registerVehicleAvatarIcon = 36.0;

  // Register Vehicle Owner Screen Sizes
  static const double registerOwnerPadding = 16.0;
  static const double registerOwnerSpacing = 12.0;
  static const double registerOwnerSpacingLG = 20.0;
  static const double registerOwnerCardPadding = 16.0;
  static const double registerOwnerAvatarRadius = 50.0;
  static const double registerOwnerAvatarIconSize = 50.0;
  static const double registerOwnerTitleFont = 18.0;
  
  static const double badgeMD = 20.0;
  static const double badgeLG = 24.0;
  
  /// BOTTOM NAVIGATION
  static const double bottomNavHeight = 56.0;
  static const double bottomNavIconSize = 24.0;
  
  /// TAB BAR
  static const double tabBarHeight = 48.0;
  
  /// LIST TILE
  static const double listTileHeight = 56.0;
  static const double listTilePadding = 16.0;
  
  /// IMAGE SIZES
  static const double imageXS = 32.0;
  static const double imageSM = 64.0;
  static const double imageMD = 128.0;
  static const double imageLG = 256.0;
  static const double imageXL = 512.0;
  
  /// LOADING INDICATOR
  static const double loaderSM = 16.0;
  static const double loaderMD = 24.0;
  static const double loaderLG = 32.0;
  
  /// DIALOG
  static const double dialogPadding = 24.0;
  static const double dialogRadius = 16.0;
  static const double dialogMaxWidth = 400.0;
  
  /// SNACKBAR
  static const double snackbarHeight = 48.0;
  static const double snackbarPadding = 16.0;
  
  /// DASHBOARD CARD
  static const double dashboardCardHeight = 120.0;
  static const double dashboardCardPadding = 16.0;
  static const double dashboardCardMargin = 8.0;
  
  /// SCREEN BREAKPOINTS
  static const double breakpointMobile = 600.0;
  static const double breakpointTablet = 900.0;
  static const double breakpointDesktop = 1200.0;

  // Image Picker Defaults
  static const double imageMaxWidth = 512.0;
  static const double imageMaxHeight = 512.0;
  static const int imageQuality = 80;
}

/// ========================================
/// APP DURATIONS
/// All animation durations
/// ========================================

class AppDurations {
  // Prevent instantiation
  AppDurations._();

  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 500);
  static const Duration verySlow = Duration(milliseconds: 1000);
  
  static const Duration snackbarShort = Duration(seconds: 2);
  static const Duration snackbarMedium = Duration(seconds: 4);
  static const Duration snackbarLong = Duration(seconds: 6);
  static const Duration snackbarDefault = Duration(seconds: 3);

  static const Duration splashScreen = Duration(seconds: 3);
  static const Duration debounce = Duration(milliseconds: 500);
  static const Duration autoRefresh = Duration(seconds: 30);
  static const Duration refreshData = Duration(seconds: 5);
  static const Duration autoRefreshDashboard = Duration(minutes: 10);
  static const Duration autoRefreshParent = Duration(minutes: 2);
  static const Duration autoRefreshSchool = Duration(minutes: 5);
  static const Duration autoRefreshVehicleOwner = Duration(minutes: 5);
}

