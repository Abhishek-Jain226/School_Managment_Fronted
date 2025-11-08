# Local Testing Setup Guide

## 🎯 Testing Backend and Frontend on Local Chrome Browser

This guide will help you set up and test your application locally on Chrome.

---

## ✅ Prerequisites

1. **Backend Server (Spring Boot)** - Must be running locally
2. **Flutter App** - Running on Chrome browser
3. **Same Machine** - Both backend and frontend on the same computer

---

## 📝 Step-by-Step Setup

### Step 1: Start Backend Server

1. Open your Spring Boot project in your IDE (Eclipse/IntelliJ)
2. Run the application:
   - **Eclipse**: Right-click project → Run As → Spring Boot App
   - **IntelliJ**: Click the green play button or Run → Run 'Application'
3. Wait for the console to show:
   ```
   Started Application in X.XXX seconds
   ```
4. Verify backend is running:
   - Open browser: `http://localhost:9001`
   - You should see some response (even if it's an error page)

---

### Step 2: Update Frontend Configuration

The frontend is already configured to use `localhost:9001` for local testing.

**Current Configuration:**
- `baseUrl`: `http://localhost:9001`
- `wsUrl`: `ws://localhost:9001/ws/websocket`

**No changes needed** - it's already set for local testing!

---

### Step 3: Run Flutter App on Chrome

1. Open terminal in your Flutter project directory:
   ```bash
   cd "E:\School Tracker App\school_tracker"
   ```

2. Run Flutter app on Chrome:
   ```bash
   flutter run -d chrome
   ```

3. Wait for Chrome to open automatically with your app

---

### Step 4: Test the Application

1. **Login** to your application
2. **Navigate** to School Admin Dashboard
3. **Check** if data loads correctly

---

## 🔍 Troubleshooting

### Issue 1: "Failed to fetch" Error

**Cause:** Backend server is not running or not accessible

**Solution:**
1. Check if backend is running:
   - Look for "Started Application" in backend console
   - Test: `http://localhost:9001/api/school-admin/dashboard/1` in browser
   
2. If backend is not running:
   - Start your Spring Boot application
   - Wait for it to fully start

3. If backend is running but still fails:
   - Check backend console for errors
   - Verify port 9001 is not blocked by firewall
   - Try accessing: `http://localhost:9001` directly in browser

---

### Issue 2: CORS Error

**Error:** "CORS policy: No 'Access-Control-Allow-Origin' header"

**Solution:**
- Backend CORS is already configured to allow `localhost:*`
- If you still get CORS errors:
  1. Restart backend server
  2. Check `WebConfig.java` - should allow `http://localhost:*`
  3. Clear browser cache (Ctrl+Shift+Delete)

---

### Issue 3: Port 9001 Already in Use

**Error:** "Port 9001 is already in use"

**Solution:**
1. Find what's using port 9001:
   ```bash
   # Windows
   netstat -ano | findstr :9001
   ```
2. Kill the process or change backend port:
   - In `application.properties`: `server.port=9002`
   - Update frontend `baseUrl` to match new port

---

### Issue 4: Authentication Token Issues

**Error:** "401 Unauthorized" or "Token expired"

**Solution:**
1. Logout and login again
2. Check browser DevTools → Application → Local Storage
3. Verify `jwt_token` exists and is valid

---

## 🔧 Quick Diagnostic Commands

### Test Backend Connectivity:
```bash
# Windows PowerShell
Test-NetConnection -ComputerName localhost -Port 9001

# Or in browser
http://localhost:9001
```

### Check Flutter App:
```bash
# Run with verbose logging
flutter run -d chrome --verbose
```

### Check Backend Logs:
- Look at Spring Boot console output
- Check for any exceptions or errors
- Verify incoming requests are being received

---

## 📊 Expected Behavior

### ✅ When Everything Works:

1. **Backend Console:**
   - Shows "Started Application"
   - Shows incoming HTTP requests
   - No errors

2. **Chrome Browser:**
   - App loads successfully
   - Login works
   - Dashboard loads data
   - No console errors (check F12)

3. **Network Tab (F12):**
   - API calls show status 200
   - Responses contain JSON data
   - No failed requests

---

## 🎯 Quick Test Checklist

- [ ] Backend server is running (check console)
- [ ] Backend accessible at `http://localhost:9001`
- [ ] Flutter app running on Chrome
- [ ] Can login successfully
- [ ] Dashboard loads without errors
- [ ] No errors in browser console (F12)
- [ ] No errors in backend console

---

## 🔄 Switching Between Local and Network Testing

### For Local Testing (Current Setup):
```dart
static const String baseUrl = 'http://localhost:9001';
static const String wsUrl = 'ws://localhost:9001/ws/websocket';
```

### For Network Testing (Other Devices):
```dart
static const String baseUrl = 'http://10.183.28.208:9001';
static const String wsUrl = 'ws://10.183.28.208:9001/ws/websocket';
```

**To switch:**
1. Edit `lib/utils/constants.dart`
2. Change `baseUrl` and `wsUrl`
3. Restart Flutter app

---

## 💡 Pro Tips

1. **Keep Backend Console Open:** Monitor for errors in real-time
2. **Use Chrome DevTools:** Press F12 to see console and network logs
3. **Clear Cache:** If things seem stuck, clear browser cache
4. **Check Both Logs:** Check both Flutter console and backend console
5. **Test Endpoint Directly:** Test backend endpoints in browser first

---

## 🆘 Still Having Issues?

1. **Check Backend Console:**
   - Look for any exceptions
   - Verify database connection
   - Check if port 9001 is available

2. **Check Browser Console (F12):**
   - Look for JavaScript errors
   - Check Network tab for failed requests
   - Verify API calls are being made

3. **Verify Configuration:**
   - Backend: `application.properties` - port 9001
   - Frontend: `constants.dart` - `localhost:9001`
   - CORS: `WebConfig.java` - allows `localhost:*`

---

**You're all set! Start your backend, run Flutter on Chrome, and test your application locally! 🚀**


