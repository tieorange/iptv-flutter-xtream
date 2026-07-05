import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:media_kit/media_kit.dart';

import 'core/di/injection.dart';
import 'core/router/app_router.dart';
import 'features/auth/presentation/cubit/auth_cubit.dart';

void main() {
  MediaKit.ensureInitialized();
  configureDependencies();
  getIt<AuthCubit>().restoreActiveProfile();
  runApp(const IptvApp());
}

class IptvApp extends StatelessWidget {
  const IptvApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: getIt<AuthCubit>(),
      child: MaterialApp.router(
        title: 'IPTV',
        routerConfig: buildAppRouter(),
      ),
    );
  }
}
