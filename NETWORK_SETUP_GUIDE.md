# 🌐 Network Setup Guide - Mobile Testing

## Problem
When running the Flutter app on a mobile device, you may get errors like:
- `No route to host`
- `Connection refused`
- `Failed to connect`

This happens because the mobile device cannot reach the backend server.

---

## ✅ Solution Steps

### Step 1: Find Your Computer's IP Address

#### On Windows:
1. Open **Command Prompt** (cmd) or **PowerShell**
2. Run one of these commands:
   ```cmd
   ipconfig
   ```
   or
   ```cmd
   ipconfig /all
   ```
3. Look for **"IPv4 Address"** under your active network adapter:
   - If connected via **WiFi**: Look under "Wireless LAN adapter Wi-Fi"
   - If connected via **Ethernet**: Look under "Ethernet adapter"
4. Note the IP address (e.g., `192.168.1.100` or `10.0.0.50`)

#### On Mac/Linux:
```bash
ifconfig
```
or
```bash
ip addr show
```
Look for your network interface (usually `en0` or `wlan0`) and find the `inet` address.

---

### Step 2: Ensure Backend Server is Running

1. Make sure your Spring Boot backend is running on port `9001`
2. Check if it's accessible by opening in a browser:
   - `http://localhost:9001` (on your computer)
   - Or `http://YOUR_IP_ADDRESS:9001` (from your computer)

---

### Step 3: Ensure Same Network

**IMPORTANT**: Your phone and computer must be on the **SAME Wi-Fi network**.

1. Check your computer's Wi-Fi network name
2. Connect your phone to the **same Wi-Fi network**
3. Do NOT use mobile data on your phone

---

### Step 4: Update Base URL in Code

1. Open `lib/utils/constants.dart`
2. Find the `baseUrl` constant (around line 20)
3. Update it with your computer's IP address:

```dart
static const String baseUrl = 'http://YOUR_IP_ADDRESS:9001';
```

**Example:**
```dart
static const String baseUrl = 'http://192.168.1.100:9001';
```

4. Also update the WebSocket URL (around line 71):

```dart
static const String wsUrl = 'ws://YOUR_IP_ADDRESS:9001/ws/websocket';
```

**Example:**
```dart
static const String wsUrl = 'ws://192.168.1.100:9001/ws/websocket';
```

5. Save the file
6. **Hot Restart** the app (not just hot reload)

---

### Step 5: Configure Backend CORS (If Needed)

If you still get CORS errors, ensure your Spring Boot backend allows connections from your IP.

Check your backend `CorsConfiguration` or `WebMvcConfigurer` to ensure it allows:
- Your computer's IP address
- Or use `allowedOrigins("*")` for development (not recommended for production)

---

### Step 6: Check Firewall

#### On Windows:
1. Open **Windows Defender Firewall**
2. Go to **Advanced Settings**
3. Check **Inbound Rules**
4. Ensure port `9001` is allowed, or temporarily disable firewall for testing

#### On Mac:
1. Go to **System Settings** > **Network** > **Firewall**
2. Ensure your backend application is allowed through the firewall

---

### Step 7: Test Connection

1. On your phone's browser, try to access:
   ```
   http://YOUR_IP_ADDRESS:9001
   ```
2. If you see a response (even an error page), the connection works
3. If you get "Cannot connect", check:
   - IP address is correct
   - Backend is running
   - Same Wi-Fi network
   - Firewall settings

---

## 🔧 Quick Fix Steps Summary

1. **Find IP**: Run `ipconfig` (Windows) or `ifconfig` (Mac/Linux)
2. **Update Code**: Change `baseUrl` in `constants.dart` to your IP
3. **Same Network**: Connect phone to same Wi-Fi as computer
4. **Test**: Try accessing `http://YOUR_IP:9001` from phone browser
5. **Restart App**: Hot restart the Flutter app

---

## 🐛 Common Issues

### Issue 1: IP Address Changes
**Problem**: IP address changes when you reconnect to Wi-Fi
**Solution**: 
- Set a static IP on your computer, OR
- Check IP address each time before testing

### Issue 2: Backend Not Accessible
**Problem**: Backend runs on `localhost` only
**Solution**: 
- Ensure Spring Boot is configured to accept connections from all interfaces
- Check `application.properties`:
  ```properties
  server.address=0.0.0.0
  ```

### Issue 3: Port Blocked
**Problem**: Port 9001 is blocked by firewall
**Solution**: 
- Add firewall rule to allow port 9001
- Or temporarily disable firewall for testing

### Issue 4: Different Networks
**Problem**: Phone on mobile data, computer on Wi-Fi
**Solution**: 
- Connect phone to same Wi-Fi network as computer
- Cannot use mobile data for local testing

---

## 📝 Example Configuration

After finding your IP address (e.g., `192.168.1.100`):

**File: `lib/utils/constants.dart`**
```dart
// Base URLs
static const String baseUrl = 'http://192.168.1.100:9001';
static const String apiBase = '$baseUrl/api';

// WebSocket
static const String wsUrl = 'ws://192.168.1.100:9001/ws/websocket';
```

---

## ✅ Verification Checklist

- [ ] Backend server is running on port 9001
- [ ] Found computer's IP address
- [ ] Updated `baseUrl` in `constants.dart`
- [ ] Updated `wsUrl` in `constants.dart`
- [ ] Phone and computer on same Wi-Fi network
- [ ] Can access `http://YOUR_IP:9001` from phone browser
- [ ] Firewall allows port 9001
- [ ] Hot restarted Flutter app

---

## 🚀 Next Steps

After fixing the network issue:
1. Test login from phone
2. Verify API calls work
3. Test WebSocket connections
4. Verify all features work correctly

---

**Last Updated**: Current implementation
**Version**: 1.0

