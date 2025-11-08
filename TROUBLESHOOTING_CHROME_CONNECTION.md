# Troubleshooting Chrome Connection Issues

## Problem
Getting `ClientException: Failed to fetch` error when running Flutter app on Chrome.

Error: `Failed to load school dashboard: ClientException: Failed to fetch, uri=http://10.183.28.208:9001/api/school-admin/dashboard/1`

---

## ✅ Quick Fixes to Try

### 1. Verify Backend Server is Running
```bash
# Open browser and test backend directly
http://10.183.28.208:9001/api/school-admin/dashboard/1
```

**Expected:** You should see a JSON response (even if it's an error, at least you'll know the server is running)

**If you get "Connection refused" or "Site can't be reached":**
- Backend server is NOT running
- Start your Spring Boot application
- Wait for it to fully start (check console for "Started Application")

---

### 2. Check Backend CORS Configuration

The backend must allow requests from Chrome's origin. Check your backend CORS configuration:

**Common CORS Configuration Location:**
- `WebMvcConfigurer` or `CorsConfig` class
- Should allow: `http://localhost:*` or `http://10.183.28.208:*`

**Example CORS Configuration:**
```java
@Configuration
public class CorsConfig implements WebMvcConfigurer {
    @Override
    public void addCorsMappings(CorsRegistry registry) {
        registry.addMapping("/api/**")
            .allowedOrigins("http://localhost:*", "http://10.183.28.208:*")
            .allowedMethods("GET", "POST", "PUT", "DELETE", "OPTIONS")
            .allowedHeaders("*")
            .allowCredentials(true);
    }
}
```

---

### 3. Test Backend Connectivity

Open Chrome DevTools (F12) and check:
1. **Console Tab**: Look for CORS errors
2. **Network Tab**: 
   - Try the request manually
   - Check if request is being blocked
   - Look at response headers

**Test in Browser Console:**
```javascript
fetch('http://10.183.28.208:9001/api/school-admin/dashboard/1', {
  method: 'GET',
  headers: {
    'Authorization': 'Bearer YOUR_TOKEN_HERE'
  }
})
.then(r => r.json())
.then(console.log)
.catch(console.error);
```

---

### 4. Verify Authentication Token

The error might be due to missing/invalid token:

1. Check if you're logged in
2. Check browser's Application/Storage → Local Storage → Look for `jwt_token`
3. Verify token is not expired

---

### 5. Check Network Connectivity

**From Chrome:**
- Open DevTools (F12)
- Go to Network tab
- Try refreshing the page
- Check if request shows as "Failed" or "Blocked"

**Common Issues:**
- Firewall blocking connection
- Backend server not accessible from browser's network
- VPN/proxy interfering

---

### 6. Use Chrome Flags (If CORS Issue)

If you're testing locally and getting CORS errors, you can temporarily disable CORS in Chrome:

**⚠️ WARNING: Only for development/testing!**

```bash
# Windows
chrome.exe --user-data-dir="C:/Chrome dev session" --disable-web-security --disable-features=VizDisplayCompositor

# Or use this command
flutter run -d chrome --web-browser-flag="--disable-web-security"
```

**⚠️ DO NOT use this in production!**

---

## 🔧 Backend Checklist

### Verify Backend is Running:
- [ ] Spring Boot application started successfully
- [ ] Console shows "Started Application"
- [ ] No port conflicts (port 9001 is free)
- [ ] Backend is accessible at `http://10.183.28.208:9001`

### Verify CORS Configuration:
- [ ] CORS allows `http://localhost:*`
- [ ] CORS allows `http://10.183.28.208:*`
- [ ] CORS allows all necessary HTTP methods
- [ ] CORS allows credentials (if using cookies/auth)

### Verify Endpoint:
- [ ] Endpoint exists: `/api/school-admin/dashboard/{schoolId}`
- [ ] Endpoint accepts GET requests
- [ ] Endpoint requires authentication (verify token is valid)

---

## 🔍 Debugging Steps

### Step 1: Check Backend Logs
Look at your Spring Boot console for:
- Incoming requests
- CORS errors
- Authentication errors
- Any exceptions

### Step 2: Check Frontend Console
Open Chrome DevTools (F12) → Console tab:
- Look for error messages
- Check for CORS errors
- Verify API calls are being made

### Step 3: Check Network Tab
Open Chrome DevTools (F12) → Network tab:
- Filter by "Fetch/XHR"
- Look for the failed request
- Check request headers
- Check response (if any)

### Step 4: Test with Postman/curl
```bash
# Test backend directly
curl -X GET "http://10.183.28.208:9001/api/school-admin/dashboard/1" \
  -H "Authorization: Bearer YOUR_TOKEN"
```

If this works but Chrome doesn't → **CORS issue**
If this doesn't work → **Backend issue**

---

## 🐛 Common Errors and Solutions

### Error: "Failed to fetch"
**Possible Causes:**
1. Backend server not running
2. Network connectivity issue
3. CORS blocking the request
4. Firewall blocking connection

**Solutions:**
- Verify backend is running
- Check network connectivity
- Verify CORS configuration
- Check firewall settings

### Error: "CORS policy: No 'Access-Control-Allow-Origin' header"
**Solution:**
- Update backend CORS configuration
- Add your browser's origin to allowed origins

### Error: "Connection refused"
**Solution:**
- Backend server is not running
- Start backend server
- Check if port 9001 is in use

### Error: "401 Unauthorized"
**Solution:**
- Token is missing or invalid
- Re-login to get new token
- Check token expiration

---

## ✅ Quick Test Commands

### Test Backend Accessibility:
```bash
# Windows PowerShell
Test-NetConnection -ComputerName 10.183.28.208 -Port 9001

# Or use curl
curl http://10.183.28.208:9001/api/school-admin/dashboard/1
```

### Check Flutter App Configuration:
```bash
# Print current configuration
flutter run -d chrome --verbose
```

---

## 📝 Next Steps

1. **First, verify backend is running:**
   - Check backend console
   - Test backend URL in browser
   - Verify port 9001 is accessible

2. **Then, check CORS:**
   - Review backend CORS configuration
   - Ensure Chrome's origin is allowed
   - Test with Postman to verify endpoint works

3. **Finally, check authentication:**
   - Verify you're logged in
   - Check token in browser storage
   - Try logging out and logging back in

---

## 💡 Alternative: Use IP Address Instead of localhost

If `localhost` doesn't work, you can also try:
- Use your machine's IP address: `http://YOUR_IP:9001`
- Or use the backend server's IP: `http://10.183.28.208:9001`

---

**If none of these work, check the backend console logs for specific error messages!**


