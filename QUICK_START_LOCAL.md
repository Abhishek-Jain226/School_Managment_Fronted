# 🚀 Quick Start: Local Testing

## 3 Simple Steps to Test Locally

### Step 1: Start Backend ⚙️
```bash
# In your Spring Boot IDE (Eclipse/IntelliJ)
# Run the application and wait for:
"Started Application in X.XXX seconds"
```

**Verify:** Open browser → `http://localhost:9001` (should show some response)

---

### Step 2: Run Flutter App 🌐
```bash
cd "E:\School Tracker App\school_tracker"
flutter run -d chrome
```

**Wait for:** Chrome to open automatically with your app

---

### Step 3: Test ✅
1. Login to your application
2. Navigate to dashboard
3. Check if data loads

---

## ❌ If "Failed to fetch" Error:

### Quick Fix:
1. **Check backend is running:**
   - Look at Spring Boot console
   - Should see "Started Application"
   - Test: `http://localhost:9001` in browser

2. **If backend not running:**
   - Start your Spring Boot application
   - Wait for it to fully start

3. **If still fails:**
   - Check browser console (F12) for detailed errors
   - Check backend console for exceptions
   - Verify port 9001 is not blocked

---

## 🔍 Debugging:

### Check Backend:
- Spring Boot console showing "Started Application" ✅
- Can access: `http://localhost:9001` ✅

### Check Frontend:
- Press F12 in Chrome
- Check Console tab for errors
- Check Network tab for failed requests

---

**That's it! Your app is configured for local testing with `localhost:9001`** 🎉


