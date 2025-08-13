import 'package:flutter/material.dart';
import 'features/shell/custom_nav_app.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: CustomNavApp(),
    );
  }
}