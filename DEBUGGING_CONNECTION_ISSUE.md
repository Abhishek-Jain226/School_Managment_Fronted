# 🔍 Debugging Connection Issue - Step by Step

## Issue: "Failed to fetch" on All Dashboards (Even After Restart)

I've added **comprehensive error handling and debugging** to help identify the exact issue.

---

## ✅ What I've Fixed

### 1. **Enhanced Error Handling**
- Added timeout (30 seconds) to all requests
- Added proper `ClientException` catching
- Added detailed debug logging
- Better error messages

### 2. **Updated Services**
- ✅ `school_service.dart` - Enhanced error handling
- ✅ `base_http_service.dart` - Enhanced error handling for all HTTP methods
- ✅ `parent_service.dart` - Enhanced error handling

---

## 🔍 How to Debug

### Step 1: Check Browser Console (F12)

**Open Chrome DevTools (F12) → Console Tab**

**Look for debug messages like:**
```
🔍 [School Dashboard] URL: http://localhost:9001/api/school-admin/dashboard/1
🔍 [School Dashboard] Base URL: http://localhost:9001
🔍 [School Dashboard] Token available: eyJhbGciOiJIUzI1NiIsIn...
🔍 [School Dashboard] Making GET request...
```

**If you see:**
- ✅ These messages → Request is being made
- ❌ No messages → Request not being made

**Error messages to look for:**
- `❌ [School Dashboard] ClientException: ...` → Connection issue
- `❌ [School Dashboard] Request timeout` → Backend not responding
- `❌ [School Dashboard] No authentication token found` → Auth issue

---

### Step 2: Check Network Tab (F12)

**Open Chrome DevTools (F12) → Network Tab**

1. **Refresh the page**
2. **Look for the failed request:**
   - Name: `/api/school-admin/dashboard/1` (or similar)
   - Status: Check what status code it shows
   - Type: `fetch` or `xhr`

3. **Click on the failed request:**
   - **Headers tab:** Check if request is being sent correctly
   - **Response tab:** Check if there's any response
   - **Preview tab:** Check response data

**Common Status Codes:**
- `(failed) net::ERR_CONNECTION_REFUSED` → Backend not running
- `(failed) net::ERR_TIMED_OUT` → Backend not responding
- `0` or `CORS error` → CORS issue
- `401` → Authentication issue
- `500` → Backend error

---

### Step 3: Check Backend Console

**Look at your Spring Boot console for:**

**✅ Good Signs:**
- `Started Application in X.XXX seconds`
- Incoming HTTP requests being logged
- No exceptions

**❌ Bad Signs:**
- `Port 9001 is already in use`
- Database connection errors
- Any exceptions or stack traces
- No incoming requests (backend not receiving requests)

---

### Step 4: Test Backend Directly

**Open browser and test:**
```
http://localhost:9001
```

**Expected:**
- ✅ Any page loads (even error page) → Backend is running
- ❌ "Connection refused" → Backend is NOT running

**Test API endpoint:**
```
http://localhost:9001/api/school-admin/dashboard/1
```

**Expected:**
- ✅ JSON response (even if 401/403) → Backend is running
- ❌ "Connection refused" → Backend is NOT running

---

## 🎯 Common Issues and Solutions

### Issue 1: Backend Not Running
**Symptom:** `ClientException: Connection refused` or `net::ERR_CONNECTION_REFUSED`

**Solution:**
1. Check Spring Boot console
2. Start backend if not running
3. Wait for "Started Application" message

---

### Issue 2: Backend Running But Not Receiving Requests
**Symptom:** Backend console shows no incoming requests

**Possible Causes:**
1. **Port mismatch:** Backend on different port
   - Check `application.properties` → `server.port=XXXX`
   - Update `constants.dart` to match

2. **Firewall blocking:** Windows Firewall blocking port 9001
   - Add exception for port 9001
   - Or temporarily disable firewall for testing

3. **Backend binding issue:** Backend not binding to `localhost`
   - Check `application.properties` → `server.address=0.0.0.0` (should be OK)

---

### Issue 3: CORS Issue
**Symptom:** CORS error in browser console

**Solution:**
1. Check `WebConfig.java` - should allow `localhost:*`
2. Restart backend (to apply CORS changes)
3. Clear browser cache
4. Check browser console for CORS error details

---

### Issue 4: Authentication Token Issue
**Symptom:** `No authentication token found` in console

**Solution:**
1. Logout and login again
2. Check browser DevTools → Application → Local Storage
3. Verify `jwt_token` exists

---

## 📋 Diagnostic Checklist

Run through this checklist:

- [ ] Backend console shows "Started Application"
- [ ] Can access `http://localhost:9001` in browser
- [ ] Browser console (F12) shows debug messages
- [ ] Network tab shows requests being made
- [ ] Backend console shows incoming requests
- [ ] No CORS errors in browser console
- [ ] No port conflicts
- [ ] Authentication token exists

---

## 🆘 Next Steps

1. **Run the app again** with the new error handling
2. **Check browser console (F12)** for detailed debug messages
3. **Share the console output** - it will show exactly what's happening:
   - What URL is being called
   - What error is occurring
   - Whether backend is reachable

---

## 💡 What the New Error Handling Will Show

The enhanced error handling will now show:

1. **Detailed Debug Messages:**
   - What URL is being called
   - Whether token exists
   - Response status codes
   - Specific error messages

2. **Better Error Messages:**
   - Connection refused → "Backend not running"
   - Timeout → "Backend not responding"
   - CORS error → "CORS issue"
   - Auth error → "Authentication required"

---

**Run the app again and check the browser console (F12) - you'll see detailed debug information that will help identify the exact issue! 🔍**


