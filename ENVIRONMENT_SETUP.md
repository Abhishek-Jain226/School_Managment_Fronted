# Environment Configuration Guide

## 🔧 Overview
This project now uses a centralized configuration system to manage different environments (development, production, local) without hardcoding IP addresses.

## 🚀 How to Use

### **Frontend (Flutter)**

#### **Method 1: Build Arguments (Recommended)**
```bash
# For Development
flutter run --dart-define=ENV=development

# For Production
flutter run --dart-define=ENV=production

# For Local
flutter run --dart-define=ENV=local
```

#### **Method 2: Environment Variables**
```bash
# Set environment variable
export ENV=production
flutter run
```

#### **Method 3: Default (Development)**
```bash
# If no environment is specified, defaults to development
flutter run
```

### **Backend (Spring Boot)**

#### **Method 1: Profile-based Configuration**
```bash
# For Development
java -jar app.jar --spring.profiles.active=dev

# For Production
java -jar app.jar --spring.profiles.active=prod

# For Local (default)
java -jar app.jar
```

#### **Method 2: Environment Variables**
```bash
# Set environment variable
export FRONTEND_ACTIVATION_URL=http://10.14.247.208:9001/activation
java -jar app.jar
```

## 📁 Configuration Files

### **Frontend Configuration**
- `lib/config/app_config.dart` - Main configuration class
- `lib/config/environment.dart` - Environment-specific settings
- `lib/config.dart` - Backward compatibility (deprecated)

### **Backend Configuration**
- `src/main/resources/application.properties` - Main configuration
- `src/main/resources/application-dev.properties` - Development settings
- `src/main/resources/application-prod.properties` - Production settings

## 🔄 Environment Settings

### **Development Environment**
- **Base URL**: `http://192.168.29.254:9001`
- **Database**: Local MySQL
- **Debug Mode**: Enabled
- **Logging**: DEBUG level

### **Production Environment**
- **Base URL**: `http://10.14.247.208:9001`
- **Database**: Production MySQL
- **Debug Mode**: Disabled
- **Logging**: INFO level

### **Local Environment**
- **Base URL**: `http://127.0.0.1:9001`
- **Database**: Local MySQL
- **Debug Mode**: Enabled
- **Logging**: DEBUG level

## 🛠️ Adding New Environments

### **Frontend**
1. Add new environment to `lib/config/environment.dart`:
```dart
static const Map<String, Map<String, String>> configs = {
  'staging': {
    'baseUrl': 'http://staging-server:9001',
    'apiTimeout': '20000',
    'debugMode': 'true',
  },
  // ... other environments
};
```

2. Use the new environment:
```bash
flutter run --dart-define=ENV=staging
```

### **Backend**
1. Create new profile file: `src/main/resources/application-staging.properties`
2. Add environment-specific settings
3. Use the new profile:
```bash
java -jar app.jar --spring.profiles.active=staging
```

## 🔍 Debugging Configuration

### **Frontend**
Add this to your main.dart to see current configuration:
```dart
import 'package:your_app/config/app_config.dart';

void main() {
  AppConfig.printConfig(); // Prints current configuration
  runApp(MyApp());
}
```

### **Backend**
Check logs for active profile and configuration:
```bash
# Look for these lines in the logs:
# Active profiles: dev
# Frontend activation URL: http://192.168.29.254:9001/activation
```

## ⚡ Quick Commands

### **Development Setup**
```bash
# Frontend
flutter run --dart-define=ENV=development

# Backend
java -jar app.jar --spring.profiles.active=dev
```

### **Production Setup**
```bash
# Frontend
flutter run --dart-define=ENV=production

# Backend
java -jar app.jar --spring.profiles.active=prod
```

### **Local Testing**
```bash
# Frontend
flutter run --dart-define=ENV=local

# Backend
java -jar app.jar
```

## 🎯 Benefits

1. **No More Hardcoded IPs**: All URLs are managed centrally
2. **Environment Switching**: Easy switching between environments
3. **Build-time Configuration**: Different builds for different environments
4. **Maintainability**: Single place to update URLs
5. **Team Collaboration**: Everyone uses the same configuration system
6. **Deployment Flexibility**: Easy deployment to different environments

## 🔧 Troubleshooting

### **Frontend Issues**
- Check if `ENV` environment variable is set correctly
- Verify `lib/config/environment.dart` has the correct URLs
- Use `AppConfig.printConfig()` to debug configuration

### **Backend Issues**
- Check if `spring.profiles.active` is set correctly
- Verify `application-{profile}.properties` files exist
- Check logs for active profile information

### **Network Issues**
- Ensure the IP addresses in configuration are accessible
- Check firewall settings
- Verify backend server is running on the correct port
