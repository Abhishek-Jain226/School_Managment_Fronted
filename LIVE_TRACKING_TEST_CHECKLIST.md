# Live Location Tracking - Complete Test Checklist

## Overview
This document provides a comprehensive testing guide for the live location tracking system across all dashboards (Parent, School Admin, Vehicle Owner).

---

## Prerequisites
1. ✅ Backend server is running
2. ✅ Database is accessible
3. ✅ WebSocket connection is working
4. ✅ Test accounts available:
   - Driver account
   - Parent account (with child assigned to trip)
   - School Admin account
   - Vehicle Owner account

---

## Test Flow 1: Driver Starts Trip

### Step 1.1: Driver Login & Select Trip
- [ ] Login as Driver
- [ ] Navigate to Driver Dashboard
- [ ] Select a trip from the dropdown
- [ ] Verify "Start Trip" and "View Student" buttons appear

### Step 1.2: Start Trip & Location Permission
- [ ] Click "Start Trip" button
- [ ] **Verify**: Location permission dialog appears
- [ ] Grant location permission
- [ ] **Verify**: Initial location is captured (check console logs)
- [ ] **Verify**: Backend receives POST `/drivers/{driverId}/trip/{tripId}/start` with latitude/longitude

### Step 1.3: Verify Initial Location Saved
- [ ] Check database `vehicle_locations` table:
  ```sql
  SELECT * FROM vehicle_locations 
  WHERE trip_id = {tripId} 
  ORDER BY created_date DESC 
  LIMIT 1;
  ```
- [ ] **Verify**: Record exists with:
  - `trip_id` = selected trip ID
  - `driver_id` = driver ID
  - `vehicle_id` = vehicle ID
  - `school_id` = school ID
  - `latitude` and `longitude` = initial location
  - `created_date` = current timestamp

### Step 1.4: Verify Notifications Sent
- [ ] Check backend console for WebSocket notifications
- [ ] **Verify**: Notification sent to:
  - School Admin (for the school)
  - Vehicle Owner (for the vehicle)
  - Parent (for students on trip)
- [ ] **Verify**: Notification type = `TRIP_STARTED` or `LOCATION_UPDATE`
- [ ] **Verify**: Notification contains:
  - `tripId`
  - `latitude`, `longitude`
  - `driverName`, `vehicleNumber`

---

## Test Flow 2: Location Updates (Every 10-30 seconds)

### Step 2.1: Verify Location Tracking Service Started
- [ ] Check driver app console logs
- [ ] **Verify**: Log shows "🚀 Starting location tracking for driver X, trip Y"
- [ ] **Verify**: Log shows "⏱️ Update interval: 15 seconds" (or configured interval)
- [ ] **Verify**: Initial location update sent immediately

### Step 2.2: Monitor Periodic Updates
- [ ] Wait 15-30 seconds (default interval)
- [ ] **Verify**: Console shows "✅ Location update sent successfully"
- [ ] **Verify**: Location updates continue every 15 seconds
- [ ] **Verify**: Each update includes:
  - Current latitude/longitude
  - Address (if geocoding successful)

### Step 2.3: Verify Database Records
- [ ] Check `vehicle_locations` table after 2-3 updates:
  ```sql
  SELECT COUNT(*) as total_updates,
         MIN(created_date) as first_update,
         MAX(created_date) as last_update
  FROM vehicle_locations 
  WHERE trip_id = {tripId};
  ```
- [ ] **Verify**: Multiple records exist (one per update)
- [ ] **Verify**: `created_date` timestamps are ~15 seconds apart
- [ ] **Verify**: `latitude` and `longitude` values change (if driver is moving)

### Step 2.4: Verify WebSocket Notifications
- [ ] Monitor WebSocket connection (check backend logs)
- [ ] **Verify**: `LOCATION_UPDATE` notifications sent every ~15 seconds
- [ ] **Verify**: Notification `data` contains:
  - `latitude`, `longitude`
  - `address`
  - `tripId`, `driverId`, `vehicleId`
  - `driverName`, `vehicleNumber`

---

## Test Flow 3: Parent Dashboard - Embedded Map

### Step 3.1: Parent Login & Dashboard Load
- [ ] Login as Parent (with child on active trip)
- [ ] Navigate to Parent Dashboard
- [ ] **Verify**: Dashboard loads successfully

### Step 3.2: Verify Map Appears Automatically
- [ ] **Verify**: Embedded map (300x200px) appears in top-right corner
- [ ] **Verify**: Map shows driver location marker (blue pin)
- [ ] **Verify**: Map updates automatically as driver moves
- [ ] **Verify**: Map shows driver name and vehicle number in info window

### Step 3.3: Verify Map Controls
- [ ] **Verify**: "Expand" button (fullscreen icon) visible
- [ ] **Verify**: "Close" button (X icon) visible
- [ ] **Verify**: Map is draggable and zoomable

---

## Test Flow 4: Parent Dashboard - Expand to Full Screen

### Step 4.1: Click Expand Button
- [ ] Click "Expand" button on embedded map
- [ ] **Verify**: Map expands to full-screen overlay
- [ ] **Verify**: Map covers entire screen with dark background
- [ ] **Verify**: Driver location marker still visible

### Step 4.2: Verify Full-Screen Controls
- [ ] **Verify**: "Minimize" button visible (top-left)
- [ ] **Verify**: "Close" button visible (top-right)
- [ ] **Verify**: Map is fully interactive (zoom, pan, rotate)

### Step 4.3: Verify Route Polyline (if implemented)
- [ ] **Verify**: Polyline shows route from start to current location
- [ ] **Verify**: Polyline updates as driver moves
- [ ] **Verify**: Polyline color/style is visible

---

## Test Flow 5: Parent Dashboard - Minimize Map

### Step 5.1: Click Minimize Button
- [ ] Click "Minimize" button on full-screen map
- [ ] **Verify**: Map returns to embedded view (300x200px)
- [ ] **Verify**: Map positioned in top-right corner
- [ ] **Verify**: Dashboard content is visible again

### Step 5.2: Verify Map Still Updates
- [ ] **Verify**: Location updates continue in embedded view
- [ ] **Verify**: Marker position updates automatically
- [ ] **Verify**: All controls (Expand, Close) still functional

---

## Test Flow 6: Driver Ends Trip

### Step 6.1: End Trip from Driver Dashboard
- [ ] Navigate to trip details page (or use "End Trip" button)
- [ ] Click "End Trip" or "Stop Trip" button
- [ ] **Verify**: Location tracking service stops
- [ ] **Verify**: Console shows "🛑 Stopping location tracking"
- [ ] **Verify**: No more location updates sent

### Step 6.2: Verify Backend Trip End
- [ ] Check backend receives POST `/drivers/{driverId}/trip/{tripId}/end`
- [ ] **Verify**: `trip_status` updated to "COMPLETED" or "ENDED" in database
- [ ] **Verify**: No more `LOCATION_UPDATE` notifications sent

### Step 6.3: Verify Trip Completed Notification
- [ ] Check backend console for `TRIP_COMPLETED` notification
- [ ] **Verify**: Notification sent to:
  - School Admin
  - Vehicle Owner
  - Parent

---

## Test Flow 7: Parent Dashboard - Trip Completed

### Step 7.1: Verify "Trip Completed" Message
- [ ] On Parent Dashboard, **Verify**: Green banner appears saying "Trip Completed"
- [ ] **Verify**: Message appears in embedded map (bottom overlay)
- [ ] **Verify**: SnackBar notification appears (if implemented)

### Step 7.2: Verify Map Auto-Hides
- [ ] Wait 5 seconds after trip completion
- [ ] **Verify**: Embedded map automatically disappears
- [ ] **Verify**: Dashboard returns to normal view (no map overlay)

### Step 7.3: Manual Close (if needed)
- [ ] If map still visible, click "Close" button
- [ ] **Verify**: Map disappears immediately
- [ ] **Verify**: Map does not reappear

---

## Test Flow 8: School Admin Dashboard

### Step 8.1: Login & Verify Map Appears
- [ ] Login as School Admin
- [ ] Navigate to School Admin Dashboard
- [ ] **Verify**: If trip is active, embedded map appears automatically
- [ ] **Verify**: Map shows location for trips in their school

### Step 8.2: Test Expand/Minimize/Close
- [ ] **Verify**: Expand button works → full-screen map
- [ ] **Verify**: Minimize button works → embedded view
- [ ] **Verify**: Close button works → map disappears
- [ ] **Verify**: Location updates work in both views

### Step 8.3: Verify Trip Completed
- [ ] When driver ends trip, **Verify**: "Trip Completed" message appears
- [ ] **Verify**: Map auto-hides after 5 seconds

---

## Test Flow 9: Vehicle Owner Dashboard

### Step 9.1: Login & Verify Map Appears
- [ ] Login as Vehicle Owner
- [ ] Navigate to Vehicle Owner Dashboard
- [ ] **Verify**: If trip is active for their vehicles, embedded map appears
- [ ] **Verify**: Map shows location for trips using their vehicles

### Step 9.2: Test Expand/Minimize/Close
- [ ] **Verify**: Expand button works → full-screen map
- [ ] **Verify**: Minimize button works → embedded view
- [ ] **Verify**: Close button works → map disappears
- [ ] **Verify**: Location updates work in both views

### Step 9.3: Verify Trip Completed
- [ ] When driver ends trip, **Verify**: "Trip Completed" message appears
- [ ] **Verify**: Map auto-hides after 5 seconds

---

## Database Verification

### Check All Location Records
```sql
-- Count total location updates for a trip
SELECT COUNT(*) as total_locations,
       MIN(created_date) as first_location,
       MAX(created_date) as last_location,
       AVG(EXTRACT(EPOCH FROM (updated_date - created_date))) as avg_interval_seconds
FROM vehicle_locations 
WHERE trip_id = {tripId};

-- View all location records with details
SELECT 
    location_id,
    trip_id,
    driver_id,
    vehicle_id,
    school_id,
    latitude,
    longitude,
    address,
    created_date,
    updated_date
FROM vehicle_locations 
WHERE trip_id = {tripId}
ORDER BY created_date ASC;
```

### Verify Trip Status
```sql
SELECT trip_id, trip_name, trip_status, trip_type
FROM trips 
WHERE trip_id = {tripId};
```

### Verify Notifications
```sql
SELECT 
    notification_id,
    type,
    title,
    message,
    trip_id,
    school_id,
    vehicle_id,
    created_date
FROM notifications 
WHERE trip_id = {tripId}
ORDER BY created_date DESC;
```

---

## Common Issues & Troubleshooting

### Issue: Map doesn't appear on Parent Dashboard
**Check:**
- [ ] Trip status is "IN_PROGRESS" or "STARTED"
- [ ] WebSocket connection is active
- [ ] `_checkActiveTrip()` is called after dashboard loads
- [ ] `_isMapVisible` is set to `true`
- [ ] `_activeTripId` is not null

### Issue: Location updates not happening
**Check:**
- [ ] Location permission is granted
- [ ] Location services are enabled
- [ ] `LocationTrackingService.startLocationTracking()` was called
- [ ] Backend `/location` endpoint is working
- [ ] Trip status is "IN_PROGRESS"

### Issue: WebSocket notifications not received
**Check:**
- [ ] WebSocket connection is established
- [ ] Notification subscription is active
- [ ] Backend is sending notifications
- [ ] Notification `tripId` matches widget `tripId`

### Issue: Map doesn't update in real-time
**Check:**
- [ ] WebSocket `LOCATION_UPDATE` notifications are received
- [ ] `_handleLocationUpdate()` is called
- [ ] `_updateMapMarkers()` updates marker position
- [ ] `_updateCameraPosition()` animates camera

### Issue: "Trip Completed" message not showing
**Check:**
- [ ] Backend sends `TRIP_COMPLETED` notification
- [ ] Notification `tripId` matches active trip
- [ ] `_handleTripCompleted()` is called
- [ ] Auto-hide timer is set (5 seconds)

---

## Performance Checks

### Location Update Frequency
- [ ] Verify updates occur every 10-30 seconds (configurable)
- [ ] Check database for consistent intervals
- [ ] Verify no duplicate records

### WebSocket Performance
- [ ] Monitor WebSocket message delivery time
- [ ] Verify no message loss
- [ ] Check connection stability

### Map Performance
- [ ] Verify smooth marker animation
- [ ] Check camera animation smoothness
- [ ] Verify no UI freezing during updates

---

## Test Completion Checklist

- [ ] Driver starts trip successfully
- [ ] Initial location saved to database
- [ ] Notifications sent to all users
- [ ] Location updates every 15 seconds
- [ ] All location records in database
- [ ] Parent dashboard shows embedded map
- [ ] Expand/minimize/close work correctly
- [ ] Full-screen map shows route polyline
- [ ] Driver ends trip successfully
- [ ] "Trip Completed" message appears
- [ ] Map auto-hides after completion
- [ ] School Admin dashboard works correctly
- [ ] Vehicle Owner dashboard works correctly
- [ ] All database records verified

---

## Notes

1. **Location Update Interval**: Default is 15 seconds, can be configured in `LocationTrackingService.startLocationTracking(updateInterval: Duration(seconds: X))`

2. **Map Visibility**: Map only appears when:
   - Trip status is "IN_PROGRESS" or "STARTED"
   - User has access to the trip (Parent: student on trip, School Admin: trip in school, Vehicle Owner: trip uses their vehicle)

3. **WebSocket Notifications**: All notifications are sent via WebSocket, not polling. Ensure WebSocket connection is stable.

4. **Database Records**: All location updates are persisted in `vehicle_locations` table for historical tracking.

5. **Error Handling**: If location permission is denied or location services disabled, tracking will not start and user will see appropriate error messages.

