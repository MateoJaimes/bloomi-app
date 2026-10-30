import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import 'app_shell.dart';

class BloomiApp extends StatelessWidget {
  const BloomiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bloomi',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const AppShell(),
    );
  }
}
