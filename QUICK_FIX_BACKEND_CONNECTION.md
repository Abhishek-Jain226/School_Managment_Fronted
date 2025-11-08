# 🚨 Quick Fix: "Failed to fetch" on All Dashboards

## Most Likely Cause: Backend Server Not Running

---

## ✅ Quick Fix (3 Steps)

### Step 1: Check if Backend is Running

**Look at your Spring Boot IDE console:**
- ✅ **If you see:** `"Started Application in X.XXX seconds"` → Backend is running
- ❌ **If you DON'T see this:** → **Backend is NOT running**

---

### Step 2: Start Backend (if not running)

**In your IDE (Eclipse/IntelliJ):**
1. Open your Spring Boot project
2. Find `Application.java` (or main Spring Boot class)
3. Right-click → **Run As** → **Spring Boot App**
4. **OR** Click the green **Run** button
5. **Wait for:** `"Started Application in X.XXX seconds"`

---

### Step 3: Test Backend

**Open browser and go to:**
```
http://localhost:9001
```

**Expected:**
- ✅ You see a page (even if it's an error page) → Backend is running!
- ❌ "Connection refused" or "Can't reach" → Backend is NOT running

---

## 🔍 If Backend is Running but Still Fails

### Check Port Configuration

**Check backend `application.properties`:**
```
File: src/main/resources/application.properties
```

**Look for:**
```properties
server.port=9001
```

**If port is different (e.g., 8080, 9002):**
- Update `constants.dart` to match:
  ```dart
  static const String baseUrl = 'http://localhost:XXXX';  // Use actual port
  ```

---

### Check Port Conflict

**If backend fails to start with "Port already in use":**

**Windows PowerShell:**
```powershell
# Find what's using port 9001
netstat -ano | findstr :9001

# Kill the process (replace <PID> with actual process ID)
taskkill /PID <PID> /F
```

**OR change backend port:**
```properties
# In application.properties
server.port=9002
```

Then update `constants.dart`:
```dart
static const String baseUrl = 'http://localhost:9002';
```

---

## 🎯 Most Common Solutions

### Solution 1: Backend Not Started
**Fix:** Start your Spring Boot application in IDE

### Solution 2: Wrong Port
**Fix:** Check `application.properties` and match port in `constants.dart`

### Solution 3: Port Conflict
**Fix:** Kill process using port 9001 or change port

---

## ✅ Verification Checklist

- [ ] Backend console shows "Started Application"
- [ ] Can access `http://localhost:9001` in browser
- [ ] Backend port matches frontend configuration
- [ ] No errors in backend console

---

## 🚀 After Fixing

1. **Restart Flutter app:**
   ```bash
   flutter run -d chrome
   ```

2. **Test all dashboards** - they should work now!

---

**99% of the time, the issue is that the backend server is not running. Start it first! 🎯**


