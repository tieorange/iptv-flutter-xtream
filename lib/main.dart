import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:media_kit/media_kit.dart';
import 'package:talker_bloc_logger/talker_bloc_logger.dart';

import 'core/cast/cast_bootstrap.dart';
import 'core/di/injection.dart';
import 'core/logging/app_talker.dart';
import 'core/router/app_router.dart';
import 'features/auth/presentation/cubit/auth_cubit.dart';

void main() {
  FlutterError.onError = (details) {
    appTalker.handle(details.exception, details.stack);
    FlutterError.presentError(details);
  };

  runZonedGuarded(() {
    WidgetsFlutterBinding.ensureInitialized();
    MediaKit.ensureInitialized();
    configureDependencies();
    Bloc.observer = TalkerBlocObserver(talker: appTalker);
    getIt<AuthCubit>().restoreActiveProfile();
    unawaited(
      initializeCasting().catchError(
        (error, stack) => appTalker.handle(error, stack),
      ),
    );
    runApp(const IptvApp());
  }, (error, stack) => appTalker.handle(error, stack));
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
