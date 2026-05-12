
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:noteit/core/routing/routing.dart';
import 'package:noteit/shared/snack_bar_manager.dart';

import 'core/theme/app_theme.dart';

void main()
{
  runApp(ProviderScope(child: _MyApp(),));
}

class _MyApp extends ConsumerWidget {
  const _MyApp({super.key});

  @override
  Widget build(BuildContext context, ref) {
    
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      scaffoldMessengerKey: scaffoldMessengerKey,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
      title: 'NoteIt',

      theme: Themes.lightThemeData,
      darkTheme: Themes.darkThemeData,
      // themeMode: ThemeMode.system,
      themeMode: ThemeMode.light,
    );
  }
}



