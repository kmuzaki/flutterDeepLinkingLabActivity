import 'package:flutter/material.dart';
import 'package:app_links/app_links.dart';
import 'dart:async';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;
  String _status = 'Waiting for link...';
  // Keys allow navigation and SnackBar access from anywhere in this State,
  // including before a BuildContext below MaterialApp is available.
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

  @override
  void initState() {
    super.initState();
    initDeepLinks();
  }

  Future<void> initDeepLinks() async {
    _appLinks = AppLinks();

    // 1. Handle initial link if app was launched by a deep link
    final initialUri = await _appLinks.getInitialLink();
    if (initialUri != null) _handleIncomingLink(initialUri);

    // 2. Handle links while app is running
    _linkSubscription = _appLinks.uriLinkStream.listen((Uri  uri) {
      _handleIncomingLink(uri);
    }, onError: (err) {
      setState(() => _status = 'Failed to receive link: $err');
    });
  }

  void _handleIncomingLink(Uri uri) {
    final linkText = 'Received link: ${uri.toString()}';
    // Debug log for adb logcat
    print('DeepLink received: ${uri.toString()}');
    // Update visible status
    setState(() => _status = linkText);

    // Ensure navigation runs after current frame to avoid navigator/route issues
    if (uri.host == 'details') {
      final id = uri.pathSegments.isNotEmpty ? uri.pathSegments[0] : 'unknown';
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // show a SnackBar for immediate feedback using the scaffold key
        final messengerState = _scaffoldMessengerKey.currentState;
        messengerState?.showSnackBar(SnackBar(content: Text('Opening details: $id')));

        // navigate using the navigator key
        _navigatorKey.currentState?.push(MaterialPageRoute(builder: (_) => DetailScreen(id: id)));
      });
    }
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navigatorKey,
      scaffoldMessengerKey: _scaffoldMessengerKey,
      title: 'Deep Link Demo',
      home: Scaffold(
        appBar: AppBar(title: Text('Home')),
        body: Center(
          child: Text(_status),
        ),
      ),
    );
  }
}

class DetailScreen extends StatelessWidget {
  final String id;
  const DetailScreen({required this.id});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Details')),
      body: Center(child: Text('You opened item ID: $id')),
    );
  }
}