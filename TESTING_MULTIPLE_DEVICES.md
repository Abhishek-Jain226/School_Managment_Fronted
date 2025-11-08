# Testing Multiple Dashboards Simultaneously

## Overview
This guide explains how to test the Parent Dashboard and Driver Dashboard side-by-side before deployment.

---

## ✅ Option 1: Phone + Chrome (Recommended for Real-World Testing)

### Prerequisites
- Physical Android/iOS phone connected via USB (or WiFi debugging)
- Chrome browser installed on laptop
- Flutter development environment set up
- Backend server running

### Steps:

#### 1. Start Backend Server
```bash
# Navigate to backend directory
cd "E:\Kids-Tracker Project\Kids-Vehicle-Tracking_Application"

# Start Spring Boot application
# (Use your IDE or command line)
```

#### 2. Run Flutter App on Phone
```bash
# Navigate to Flutter project
cd "E:\School Tracker App\school_tracker"

# Check connected devices
flutter devices

# Run on phone (replace with your device ID)
flutter run -d <device-id>
# OR
flutter run -d <phone-name>
```

**Alternative: Use your IDE**
- In VS Code/Android Studio, select your phone from the device dropdown
- Click Run/Debug
- App will install and launch on your phone

#### 3. Run Flutter App on Chrome (Separate Terminal/Window)
```bash
# Open a NEW terminal/command prompt window
# Navigate to Flutter project
cd "E:\School Tracker App\school_tracker"

# Run on Chrome
flutter run -d chrome

# OR specify a specific port to avoid conflicts
flutter run -d chrome --web-port=8080
```

**Alternative: Use your IDE**
- Open a second instance of your IDE, OR
- Stop the current run, change device to Chrome, and run again
- Or use VS Code's "Run and Debug" with multiple configurations

---

## ✅ Option 2: Multiple Chrome Instances (Quick Testing)

### Steps:

#### 1. Run First Instance (Driver Dashboard)
```bash
flutter run -d chrome --web-port=8080
```
- Login as Driver
- Keep this window open

#### 2. Run Second Instance (Parent Dashboard)
```bash
# Open new terminal
flutter run -d chrome --web-port=8081
```
- Login as Parent in this new window
- Now you have both dashboards side-by-side

**Note:** You may need to configure your backend CORS to allow multiple origins, or use the same origin for both.

---

## ✅ Option 3: Phone + Emulator (Android/iOS)

### Steps:

#### 1. Start Android Emulator
```bash
# Start Android emulator from Android Studio
# OR
emulator -avd <emulator-name>
```

#### 2. Run on Phone (Driver)
```bash
flutter run -d <phone-device-id>
# Login as Driver
```

#### 3. Run on Emulator (Parent)
```bash
# In new terminal
flutter run -d <emulator-device-id>
# Login as Parent
```

---

## ✅ Option 4: Multiple Physical Devices (Best for Production Testing)

If you have multiple phones:
- Connect both phones via USB
- Run `flutter devices` to see both
- Run `flutter run -d <device1-id>` for Driver
- Run `flutter run -d <device2-id>` for Parent (in new terminal)

---

## 🔧 Configuration Tips

### 1. Backend CORS Configuration
If you encounter CORS errors, ensure your backend allows multiple origins:

```java
// In your Spring Boot configuration
@CrossOrigin(origins = {"http://localhost:8080", "http://localhost:8081", "http://10.183.28.208:9001"})
```

### 2. Different User Accounts
- **Driver Account**: Use a driver account (username/password for driver)
- **Parent Account**: Use a parent account (username/password for parent)
- Ensure both accounts are linked to the same school/trip for testing

### 3. WebSocket Connection
- Both devices will connect to the same WebSocket server
- Notifications will be sent to both if they're subscribed to the same events
- This is perfect for testing real-time notifications!

---

## 📱 Recommended Testing Workflow

### Test Scenario: Driver Starts Trip → Parent Sees Notification

1. **Setup:**
   - Phone: Login as Driver
   - Chrome: Login as Parent
   - Ensure both are viewing the same school/trip

2. **On Driver Dashboard (Phone):**
   - Select a trip
   - Click "Start Trip"
   - Grant location permission
   - Verify location tracking starts

3. **On Parent Dashboard (Chrome):**
   - Watch for notification: "Your child's trip has started"
   - Verify embedded map appears automatically
   - Watch for live location updates

4. **On Driver Dashboard (Phone):**
   - Mark student as "Picked Up"
   - Send "5-minute alert"
   - Mark student as "Dropped to School"

5. **On Parent Dashboard (Chrome):**
   - Verify notifications appear:
     - "Your child has been picked up"
     - "School Vehicle is coming in next 5 minutes"
     - "Your child has been dropped to school"
   - Verify map updates in real-time

6. **On Driver Dashboard (Phone):**
   - Click "End Trip"

7. **On Parent Dashboard (Chrome):**
   - Verify "Trip Completed" message
   - Verify map disappears

---

## 🐛 Troubleshooting

### Issue: "Port already in use"
**Solution:**
```bash
# Use different ports
flutter run -d chrome --web-port=8080
flutter run -d chrome --web-port=8081
```

### Issue: "Multiple devices connected"
**Solution:**
```bash
# List all devices
flutter devices

# Specify device explicitly
flutter run -d <device-id>
```

### Issue: "WebSocket connection failed"
**Solution:**
- Check backend is running
- Verify WebSocket URL in `constants.dart`
- Check firewall/network settings
- Ensure both devices are on same network (for phone)

### Issue: "Cannot login on second device"
**Solution:**
- Use different user accounts for each device
- Clear app data/cache if needed
- Check backend authentication allows multiple sessions

---

## 💡 Pro Tips

1. **Use VS Code/Android Studio Multiple Windows:**
   - Open project in two IDE windows
   - Run different instances in each window
   - Easy to switch between devices

2. **Use Flutter DevTools:**
   - Run `flutter pub global activate devtools`
   - Use `flutter pub global run devtools`
   - Inspect both running instances

3. **Check Backend Logs:**
   - Monitor backend console for API calls
   - Verify WebSocket connections
   - Check for errors in real-time

4. **Database Verification:**
   - Have database query tool open
   - Verify `vehicle_locations` table updates
   - Check `dispatch_logs` and `notifications` tables

5. **Network Testing:**
   - Test on same WiFi network (for phone)
   - Test with different network conditions
   - Verify offline handling

---

## ✅ Quick Start Commands

### Terminal 1 (Driver - Phone):
```bash
cd "E:\School Tracker App\school_tracker"
flutter devices
flutter run -d <phone-device-id>
```

### Terminal 2 (Parent - Chrome):
```bash
cd "E:\School Tracker App\school_tracker"
flutter run -d chrome --web-port=8080
```

---

## 📋 Testing Checklist

- [ ] Backend server is running
- [ ] Driver logged in on Phone
- [ ] Parent logged in on Chrome
- [ ] Both dashboards loaded successfully
- [ ] Driver can start trip
- [ ] Parent receives "Trip Started" notification
- [ ] Parent sees embedded map
- [ ] Location updates appear on parent dashboard
- [ ] Driver actions trigger notifications
- [ ] Parent sees all notification messages correctly
- [ ] Driver can end trip
- [ ] Parent sees "Trip Completed" message
- [ ] Map disappears on parent dashboard
- [ ] WebSocket connections stable
- [ ] No errors in console/logs

---

## 🎯 Best Practices

1. **Test in stages:**
   - First test individually (Driver only, then Parent only)
   - Then test together (both simultaneously)

2. **Test different scenarios:**
   - Morning pickup trip
   - Afternoon drop trip
   - Multiple students
   - Trip with delays

3. **Monitor performance:**
   - Check CPU/memory usage
   - Monitor network traffic
   - Verify smooth animations

4. **Test edge cases:**
   - Network disconnection
   - App backgrounding
   - Multiple notifications
   - Concurrent trips

---

## 📞 Need Help?

If you encounter issues:
1. Check Flutter doctor: `flutter doctor`
2. Verify devices: `flutter devices`
3. Check backend logs
4. Verify network connectivity
5. Clear Flutter cache: `flutter clean && flutter pub get`

---

**Happy Testing! 🚀**


