import 'package:flutter/material.dart';
import 'app_routes.dart';
import 'bloc/bloc_providers.dart';

// Global navigator key so non-UI services (e.g., deep links) can navigate
final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProviders(
      child: MaterialApp(
        title: 'School Tracker',
        debugShowCheckedModeBanner: false,
        navigatorKey: rootNavigatorKey,
        initialRoute: AppRoutes.splash,
        routes: AppRoutes.routes, // simple static routes
      ),
    );
  }
}
