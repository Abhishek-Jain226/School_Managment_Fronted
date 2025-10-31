# BLoC Testing Guide

This guide explains how to test the BLoC implementation in your Flutter application.

## 📋 Table of Contents

1. [Overview](#overview)
2. [Testing Dependencies](#testing-dependencies)
3. [Unit Testing BLoCs](#unit-testing-blocs)
4. [Widget Testing with BLoCs](#widget-testing-with-blocs)
5. [Integration Testing](#integration-testing)
6. [Best Practices](#best-practices)
7. [Example Test Cases](#example-test-cases)

## 🎯 Overview

BLoC (Business Logic Component) testing involves testing the business logic separately from the UI. This ensures that your application's core functionality works correctly regardless of UI changes.

## 📦 Testing Dependencies

The following dependencies are already added to your `pubspec.yaml`:

```yaml
dev_dependencies:
  flutter_test:
    sdk: flutter
  bloc_test: ^9.1.5
  mockito: ^5.4.2
  build_runner: ^2.4.7
```

## 🧪 Unit Testing BLoCs

### 1. Create Test Files

Create test files in the `test/` directory:

```
test/
├── bloc/
│   ├── auth/
│   │   └── auth_bloc_test.dart
│   ├── driver/
│   │   └── driver_bloc_test.dart
│   ├── school/
│   │   └── school_bloc_test.dart
│   └── ...
```

### 2. Basic BLoC Test Structure

```dart
// test/bloc/auth/auth_bloc_test.dart
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import 'package:school_tracker/bloc/auth/auth_bloc.dart';
import 'package:school_tracker/bloc/auth/auth_event.dart';
import 'package:school_tracker/bloc/auth/auth_state.dart';
import 'package:school_tracker/services/auth_service.dart';

// Generate mocks
@GenerateMocks([AuthService])
import 'auth_bloc_test.mocks.dart';

void main() {
  group('AuthBloc', () {
    late AuthBloc authBloc;
    late MockAuthService mockAuthService;

    setUp(() {
      mockAuthService = MockAuthService();
      authBloc = AuthBloc(authService: mockAuthService);
    });

    tearDown(() {
      authBloc.close();
    });

    test('initial state is AuthInitial', () {
      expect(authBloc.state, equals(const AuthInitial()));
    });

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, AuthAuthenticated] when login is successful',
      build: () {
        when(mockAuthService.login('test@example.com', 'password'))
            .thenAnswer((_) async => {
                  'success': true,
                  'data': {
                    'token': 'test_token',
                    'roles': ['DRIVER'],
                    'userId': 1,
                    'driverId': 1,
                  }
                });
        return authBloc;
      },
      act: (bloc) => bloc.add(
        const AuthLoginRequested(
          loginId: 'test@example.com',
          password: 'password',
        ),
      ),
      expect: () => [
        const AuthLoading(),
        isA<AuthAuthenticated>()
            .having((s) => s.token, 'token', 'test_token')
            .having((s) => s.roles, 'roles', ['DRIVER']),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, AuthError] when login fails',
      build: () {
        when(mockAuthService.login('test@example.com', 'wrong_password'))
            .thenAnswer((_) async => {
                  'success': false,
                  'message': 'Invalid credentials',
                });
        return authBloc;
      },
      act: (bloc) => bloc.add(
        const AuthLoginRequested(
          loginId: 'test@example.com',
          password: 'wrong_password',
        ),
      ),
      expect: () => [
        const AuthLoading(),
        isA<AuthError>().having((s) => s.message, 'message', 'Invalid credentials'),
      ],
    );
  });
}
```

### 3. Generate Mocks

Run the following command to generate mock classes:

```bash
flutter packages pub run build_runner build
```

## 🎨 Widget Testing with BLoCs

### 1. Test Widget with BLoC

```dart
// test/presentation/pages/bloc_login_screen_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mockito/mockito.dart';

import 'package:school_tracker/presentation/pages/bloc_login_screen.dart';
import 'package:school_tracker/bloc/auth/auth_bloc.dart';
import 'package:school_tracker/bloc/auth/auth_state.dart';
import 'package:school_tracker/services/auth_service.dart';

@GenerateMocks([AuthService])
import 'bloc_login_screen_test.mocks.dart';

void main() {
  group('BlocLoginScreen', () {
    late MockAuthService mockAuthService;
    late AuthBloc authBloc;

    setUp(() {
      mockAuthService = MockAuthService();
      authBloc = AuthBloc(authService: mockAuthService);
    });

    tearDown(() {
      authBloc.close();
    });

    Widget createWidgetUnderTest() {
      return MaterialApp(
        home: BlocProvider<AuthBloc>(
          create: (context) => authBloc,
          child: const BlocLoginScreen(),
        ),
      );
    }

    testWidgets('displays login form', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text('School Tracker'), findsOneWidget);
      expect(find.byType(TextFormField), findsNWidgets(2));
      expect(find.text('Login'), findsOneWidget);
    });

    testWidgets('shows loading indicator when login is in progress',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      // Enter credentials
      await tester.enterText(find.byType(TextFormField).first, 'test@example.com');
      await tester.enterText(find.byType(TextFormField).last, 'password');

      // Tap login button
      await tester.tap(find.text('Login'));
      await tester.pump();

      // Emit loading state
      authBloc.emit(const AuthLoading());
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows error message when login fails',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      // Emit error state
      authBloc.emit(const AuthError(message: 'Login failed'));
      await tester.pump();

      expect(find.text('Login failed'), findsOneWidget);
    });
  });
}
```

## 🔧 Integration Testing

### 1. Test Complete User Flow

```dart
// integration_test/app_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:school_tracker/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Driver Login Flow', () {
    testWidgets('driver can login and access dashboard', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Navigate to login
      await tester.tap(find.text('Login'));
      await tester.pumpAndSettle();

      // Enter credentials
      await tester.enterText(find.byType(TextFormField).first, 'driver@test.com');
      await tester.enterText(find.byType(TextFormField).last, 'password');

      // Tap login
      await tester.tap(find.text('Login'));
      await tester.pumpAndSettle();

      // Verify navigation to driver dashboard
      expect(find.text('Driver Dashboard'), findsOneWidget);
    });
  });
}
```

## 📝 Best Practices

### 1. Test Structure

- **Arrange**: Set up test data and mocks
- **Act**: Trigger the event or action
- **Assert**: Verify the expected outcome

### 2. Mocking Services

```dart
// Always mock external dependencies
@GenerateMocks([AuthService, DriverService, SchoolService])
```

### 3. Test Coverage

- Test all events and states
- Test error scenarios
- Test edge cases
- Test async operations

### 4. Naming Conventions

```dart
// Good test names
test('emits [AuthLoading, AuthAuthenticated] when login is successful')
test('emits [AuthLoading, AuthError] when login fails')
test('initial state is AuthInitial')

// Bad test names
test('test login')
test('works')
test('should work')
```

## 🎯 Example Test Cases

### 1. AuthBloc Tests

```dart
group('AuthBloc', () {
  blocTest<AuthBloc, AuthState>(
    'emits [AuthLoading, AuthAuthenticated] when login is successful',
    build: () => authBloc,
    act: (bloc) => bloc.add(AuthLoginRequested(loginId: 'test', password: 'test')),
    expect: () => [AuthLoading(), AuthAuthenticated(...)],
  );

  blocTest<AuthBloc, AuthState>(
    'emits [AuthLoading, AuthError] when login fails',
    build: () => authBloc,
    act: (bloc) => bloc.add(AuthLoginRequested(loginId: 'test', password: 'wrong')),
    expect: () => [AuthLoading(), AuthError(...)],
  );

  blocTest<AuthBloc, AuthState>(
    'emits [AuthLoading, AuthUnauthenticated] when logout is successful',
    build: () => authBloc,
    act: (bloc) => bloc.add(AuthLogoutRequested()),
    expect: () => [AuthLoading(), AuthUnauthenticated()],
  );
});
```

### 2. DriverBloc Tests

```dart
group('DriverBloc', () {
  blocTest<DriverBloc, DriverState>(
    'emits [DriverLoading, DriverDashboardLoaded] when dashboard is requested',
    build: () => driverBloc,
    act: (bloc) => bloc.add(DriverDashboardRequested(driverId: 1)),
    expect: () => [DriverLoading(), DriverDashboardLoaded(...)],
  );

  blocTest<DriverBloc, DriverState>(
    'emits [DriverActionSuccess] when attendance is marked',
    build: () => driverBloc,
    act: (bloc) => bloc.add(DriverMarkAttendanceRequested(...)),
    expect: () => [DriverActionSuccess(...)],
  );
});
```

## 🚀 Running Tests

### 1. Run All Tests

```bash
flutter test
```

### 2. Run Specific Test File

```bash
flutter test test/bloc/auth/auth_bloc_test.dart
```

### 3. Run Tests with Coverage

```bash
flutter test --coverage
```

### 4. Generate Coverage Report

```bash
genhtml coverage/lcov.info -o coverage/html
```

## 📊 Test Coverage Goals

- **Unit Tests**: 80%+ coverage for BLoCs
- **Widget Tests**: 70%+ coverage for UI components
- **Integration Tests**: Cover main user flows

## 🔍 Debugging Tests

### 1. Print Debug Information

```dart
blocTest<AuthBloc, AuthState>(
  'test name',
  build: () => authBloc,
  act: (bloc) => bloc.add(event),
  expect: () => [state1, state2],
  verify: (bloc) {
    print('Final state: ${bloc.state}');
  },
);
```

### 2. Use `pumpAndSettle()` for Async Operations

```dart
await tester.pumpAndSettle(); // Wait for all animations and async operations
```

## 📚 Additional Resources

- [BLoC Testing Documentation](https://bloclibrary.dev/#/testing)
- [Flutter Testing Guide](https://docs.flutter.dev/testing)
- [Mockito Documentation](https://pub.dev/packages/mockito)

## 🎉 Conclusion

This testing guide provides a comprehensive approach to testing your BLoC implementation. Start with unit tests for your BLoCs, then add widget tests for your UI components, and finally integration tests for complete user flows.

Remember to:
- Write tests before or alongside your code
- Keep tests simple and focused
- Mock external dependencies
- Test both success and failure scenarios
- Maintain good test coverage
