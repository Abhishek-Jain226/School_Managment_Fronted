# Quick Fix: Chrome Connection Error

## Error You're Seeing:
```
Failed to load school dashboard: ClientException: Failed to fetch, 
uri=http://10.183.28.208:9001/api/school-admin/dashboard/1
```

---

## ✅ Most Likely Causes:

### 1. **Backend Server Not Running** (90% of cases)
**Solution:**
- Check if your Spring Boot backend is running
- Look for console message: "Started Application in X seconds"
- If not running, start it from your IDE or command line

### 2. **Backend Not Accessible from Browser**
**Solution:**
- Open browser and test: `http://10.183.28.208:9001/api/school-admin/dashboard/1`
- If you get "Connection refused" or "Site can't be reached" → Backend is not running or not accessible
- Check firewall settings

### 3. **CORS Issue** (Less likely - config looks correct)
**Solution:**
- Backend CORS is already configured to allow `http://localhost:*`
- If you still get CORS errors, restart backend after checking WebConfig.java

---

## 🔍 Quick Diagnostic Steps:

### Step 1: Test Backend Directly
Open your browser and go to:
```
http://10.183.28.208:9001/api/school-admin/dashboard/1
```

**If you see JSON (even error JSON):** → Backend is running ✅
**If you get "Connection refused":** → Backend is NOT running ❌

### Step 2: Check Backend Console
Look at your Spring Boot console for:
- "Started Application" message
- Any errors or exceptions
- Incoming request logs

### Step 3: Check Chrome DevTools
1. Open Chrome DevTools (F12)
2. Go to **Console** tab
3. Look for error messages
4. Go to **Network** tab
5. Refresh the page
6. Look for the failed request
7. Click on it to see details

---

## 🛠️ Immediate Actions:

### Action 1: Verify Backend is Running
```bash
# Check if port 9001 is in use (Windows)
netstat -ano | findstr :9001

# Or check Spring Boot console for "Started Application"
```

### Action 2: Restart Backend
1. Stop your Spring Boot application
2. Start it again
3. Wait for "Started Application" message
4. Try Flutter app again

### Action 3: Clear Browser Cache
1. Open Chrome DevTools (F12)
2. Right-click refresh button
3. Select "Empty Cache and Hard Reload"
4. Or clear browser cache manually

### Action 4: Check Network
- Ensure both laptop and backend server are on same network
- If backend is on different machine, ensure network connectivity
- Try pinging: `ping 10.183.28.208`

---

## 📝 What I've Fixed:

1. ✅ Updated `baseUrl` to use IP address: `http://10.183.28.208:9001`
2. ✅ Updated WebSocket URL to use IP address
3. ✅ Added better error handling with timeout and detailed error messages
4. ✅ Added debug logging to help identify the issue

---

## 🎯 Next Steps:

1. **Restart your backend server** (if not running)
2. **Restart your Flutter app** in Chrome
3. **Check browser console** (F12) for detailed error messages
4. **Check backend console** for any errors

---

## 💡 If Still Not Working:

1. **Check backend logs** for any exceptions
2. **Verify authentication token** - try logging out and back in
3. **Test with Postman** to verify backend endpoint works
4. **Check firewall** - ensure port 9001 is open

---

**The error message should now be more helpful. Check the browser console (F12) for detailed debug information!**


