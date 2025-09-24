import 'dart:async';
import 'package:flutter/material.dart';
import 'package:app_links/app_links.dart';
import 'package:school_tracker/presentation/pages/activation_screen.dart';
import 'app.dart';
import 'app_routes.dart';

void main() {
  runApp(const _Bootstrap());
}

class _Bootstrap extends StatefulWidget {
  const _Bootstrap({super.key});

  @override
  State<_Bootstrap> createState() => _BootstrapState();
}

class _BootstrapState extends State<_Bootstrap> {
  StreamSubscription<Uri>? _sub;
  AppLinks? _appLinks;

  @override
  void initState() {
    super.initState();
    _initDeepLinks();
  }

  Future<void> _initDeepLinks() async {
    _appLinks = AppLinks();
    try {
      final initial = await _appLinks!.getInitialLink();
      if (initial != null) _handleIncomingLink(initial);
    } catch (_) {}
    _sub = _appLinks!.uriLinkStream.listen(_handleIncomingLink, onError: (_) {});
  }

  // void _handleIncomingLink(Uri uri) {
  //   if (uri.scheme == 'kidsvt' && uri.host == 'activate') {
  //     final token = uri.queryParameters['token'];
  //     if (token != null && token.isNotEmpty) {
  //       rootNavigatorKey.currentState?.push(
  //         MaterialPageRoute(builder: (_) => ActivationScreen(token: token)),
  //       );
  //     }
  //   }
  // }
  // In the _handleIncomingLink method, replace the direct navigation with:
void _handleIncomingLink(Uri uri) {
  if (uri.scheme == 'kidsvt' && uri.host == 'activate') {
    final token = uri.queryParameters['token'];
    if (token != null && token.isNotEmpty) {
      rootNavigatorKey.currentState?.pushNamed(
        AppRoutes.activation,
        arguments: {'token': token},
      );
    }
  }
}

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Render your real app, which defines splash + routes
    return const App();
  }
}
