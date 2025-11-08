# Location Tracking Issue - Analysis & Fix

## 🔍 Problem

When driver starts trip and allows location tracking, **14 records** are being inserted into `vehicle_locations` table instead of expected behavior.

## 🔎 Root Cause Analysis

### Current Flow:

1. **Driver clicks "Start Trip"** → `_startTrip()` in `bloc_driver_dashboard.dart`
2. **Backend `startTrip` API called** → Updates trip status to "IN_PROGRESS"
3. **On success, `LocationTrackingService.startLocationTracking()` is called**:
   - Sends **initial location update immediately** (line 144)
   - Sets up **periodic timer** every 15 seconds (line 147)

### Potential Issues:

#### Issue 1: Multiple Timer Instances
- The `LocationTrackingService` is a singleton, but if `startLocationTracking()` is called multiple times:
  - First call: Sets `_isTracking = true`, sends initial update, creates timer
  - Second call (before timer is created): Check `if (_isTracking)` might pass if called in quick succession
  - Result: Multiple timers running simultaneously

#### Issue 2: Race Condition
- The check `if (_isTracking)` happens at the start, but `_isTracking` is set to `true` before the timer is created
- If `startLocationTracking()` is called multiple times quickly, multiple timers could be created

#### Issue 3: No Debouncing
- The initial location update is sent immediately, but if the service is called multiple times, multiple initial updates could be sent

#### Issue 4: Timer Not Cancelled Properly
- If `startLocationTracking()` is called again before the previous timer is cancelled, multiple timers could run

## 💡 Solution

### Fix 1: Add Proper Guard with Timer Check
- Check if timer already exists before creating a new one
- Cancel existing timer before creating a new one

### Fix 2: Add Debouncing for Initial Update
- Only send initial update if not already tracking
- Add a flag to track if initial update was sent

### Fix 3: Make Timer Creation Atomic
- Set `_isTracking = true` only after timer is successfully created
- Or use a lock/mutex to prevent concurrent calls

### Fix 4: Add Logging
- Log when location updates are sent to identify duplicate calls

## 🛠️ Implementation

Let me fix the `LocationTrackingService` to prevent multiple timers and duplicate updates.

