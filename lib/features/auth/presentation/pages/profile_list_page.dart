import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../domain/entities/provider_profile.dart';
import '../../domain/usecases/delete_profile_usecase.dart';
import '../../domain/usecases/get_saved_profiles_usecase.dart';
import '../cubit/auth_cubit.dart';

class ProfileListPage extends StatefulWidget {
  const ProfileListPage({super.key});

  @override
  State<ProfileListPage> createState() => _ProfileListPageState();
}

class _ProfileListPageState extends State<ProfileListPage> {
  List<ProviderProfile> _profiles = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadProfiles();
  }

  Future<void> _loadProfiles() async {
    setState(() => _loading = true);
    final result = await getIt<GetSavedProfilesUseCase>()().run();
    result.fold(
      (failure) => setState(() {
        _profiles = [];
        _loading = false;
      }),
      (profiles) => setState(() {
        _profiles = profiles;
        _loading = false;
      }),
    );
  }

  Future<void> _delete(ProviderProfile profile) async {
    await getIt<DeleteProfileUseCase>()(profile.id).run();
    _loadProfiles();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profiles'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => context.pushNamed('profilesAdd'),
          ),
        ],
      ),
      body: BlocConsumer<AuthCubit, AuthState>(
        listener: (context, state) {
          if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
        },
        builder: (context, authState) {
          if (_loading) return const Center(child: CircularProgressIndicator());

          if (_profiles.isEmpty) {
            return const Center(child: Text('No profiles yet. Tap + to add one.'));
          }

          return ListView.builder(
            itemCount: _profiles.length,
            itemBuilder: (context, index) {
              final profile = _profiles[index];
              return ListTile(
                leading: authState is AuthLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.dns_outlined),
                title: Text(profile.name),
                subtitle: Text(profile.baseUrl),
                onTap: authState is AuthLoading
                    ? null
                    : () => context.read<AuthCubit>().login(profile),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => _delete(profile),
                ),
                onLongPress: () => context.pushNamed(
                  'profilesEdit',
                  pathParameters: {'profileId': profile.id},
                ),
              );
            },
          );
        },
      ),
    );
  }
}
