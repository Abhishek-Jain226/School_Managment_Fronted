# Test Backend Connection

## 🎯 Quick Test to Verify Backend is Running

### Test 1: Open in Browser
```
http://localhost:9001
```

**Expected:**
- ✅ **Any page loads** (even error page) → Backend is running!
- ❌ **"Connection refused"** or **"Can't reach"** → Backend is NOT running

---

### Test 2: Test API Endpoint
```
http://localhost:9001/api/school-admin/dashboard/1
```

**Expected:**
- ✅ **JSON response** (even if 401/403) → Backend is running!
- ❌ **"Connection refused"** → Backend is NOT running

---

### Test 3: Check Backend Console

**In your Spring Boot IDE console, look for:**
```
Started Kids-Vehicle-Tracking_Application in X.XXX seconds
```

**If you see this:** ✅ Backend is running  
**If you DON'T:** ❌ Backend is NOT running

---

## 🚨 If Backend is NOT Running

### Start Backend:

1. **Open your Spring Boot project in IDE**
2. **Find main class:** `Application.java` or similar
3. **Right-click → Run As → Spring Boot App**
4. **OR click the green Run button**
5. **Wait for:** `"Started Application in X.XXX seconds"`

---

## ✅ Configuration is Correct

**Backend Configuration:**
- Port: `9001` ✅
- Address: `0.0.0.0` ✅ (accepts localhost connections)

**Frontend Configuration:**
- baseUrl: `http://localhost:9001` ✅

**Everything is configured correctly!** The issue is likely that the backend server is not running.

---

## 🔧 After Starting Backend

1. **Verify backend is running:**
   - Test: `http://localhost:9001` in browser
   - Should see a page (even if error)

2. **Restart Flutter app:**
   ```bash
   flutter run -d chrome
   ```

3. **Test all dashboards** - they should work now!

---

**Most likely issue: Backend server is not running. Start it first! 🚀**


