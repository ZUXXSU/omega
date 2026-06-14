import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'router.dart';
import 'theme/app_theme.dart';
import '../core/deep_link/app_links_service.dart';
import '../core/platform/connectivity_service.dart';

class OmegaApp extends ConsumerStatefulWidget {
  const OmegaApp({super.key});

  @override
  ConsumerState<OmegaApp> createState() => _OmegaAppState();
}

class _OmegaAppState extends ConsumerState<OmegaApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AppLinksService.instance.initialize(context, ref);
    });
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);

    return OmegaConnectivityWrapper(
      child: MaterialApp.router(
        title: 'Omega',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: ThemeMode.system,
        routerConfig: router,
      ),
    );
  }
}
