import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../domain/entities/provider_profile.dart';
import '../../domain/usecases/add_profile_usecase.dart';
import '../../domain/usecases/get_saved_profiles_usecase.dart';
import '../cubit/auth_cubit.dart';

class AddEditProfilePage extends StatefulWidget {
  const AddEditProfilePage({super.key, this.profileId});

  final String? profileId;

  @override
  State<AddEditProfilePage> createState() => _AddEditProfilePageState();
}

class _AddEditProfilePageState extends State<AddEditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _urlController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  ProviderProfile? _existingProfile;
  bool _loadingExisting = false;

  bool get _isEditing => widget.profileId != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) _loadExisting();
  }

  Future<void> _loadExisting() async {
    setState(() => _loadingExisting = true);
    final result = await getIt<GetSavedProfilesUseCase>()().run();
    result.fold(
      (_) => setState(() => _loadingExisting = false),
      (profiles) {
        final match = profiles.where((p) => p.id == widget.profileId);
        if (match.isNotEmpty) {
          _existingProfile = match.first;
          _nameController.text = _existingProfile!.name;
          _urlController.text = _existingProfile!.baseUrl;
          _usernameController.text = _existingProfile!.username;
          _passwordController.text = _existingProfile!.password;
        }
        setState(() => _loadingExisting = false);
      },
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _urlController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final profile = ProviderProfile(
      id: _existingProfile?.id ?? DateTime.now().microsecondsSinceEpoch.toString(),
      name: _nameController.text.trim(),
      baseUrl: _urlController.text.trim(),
      username: _usernameController.text.trim(),
      password: _passwordController.text,
      createdAt: _existingProfile?.createdAt ?? DateTime.now(),
    );

    if (_isEditing) {
      await getIt<AddProfileUseCase>()(profile).run();
      if (mounted) context.pop();
    } else {
      // Creating a profile logs in immediately to validate credentials
      // against the real panel per PLAN.md's M1 acceptance criterion; the
      // router's auth-redirect bridge takes it from here on success.
      await context.read<AuthCubit>().login(profile);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Edit profile' : 'Add profile')),
      body: _loadingExisting
          ? const Center(child: CircularProgressIndicator())
          : BlocConsumer<AuthCubit, AuthState>(
              listener: (context, state) {
                if (state is AuthError) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(state.message)),
                  );
                }
              },
              builder: (context, authState) {
                final submitting = authState is AuthLoading;
                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: _formKey,
                    child: ListView(
                      children: [
                        TextFormField(
                          controller: _nameController,
                          decoration: const InputDecoration(labelText: 'Profile name'),
                          validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                        ),
                        TextFormField(
                          controller: _urlController,
                          decoration: const InputDecoration(labelText: 'Server URL'),
                          keyboardType: TextInputType.url,
                          validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                        ),
                        TextFormField(
                          controller: _usernameController,
                          decoration: const InputDecoration(labelText: 'Username'),
                          validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                        ),
                        TextFormField(
                          controller: _passwordController,
                          decoration: const InputDecoration(labelText: 'Password'),
                          obscureText: true,
                          validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                        ),
                        const SizedBox(height: 24),
                        FilledButton(
                          onPressed: submitting ? null : _submit,
                          child: submitting
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : Text(_isEditing ? 'Save' : 'Add & sign in'),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
