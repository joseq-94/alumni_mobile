import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/alumni_model.dart';
import '../services/api_datasource.dart';
import 'widgets/section_card.dart';
import 'widgets/status_message.dart';

// Collect credentials and ask AlumniModel to sign in; Laravel checks API passwords.
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  late final bool _usesApi;
  late final TextEditingController _email;
  late final TextEditingController _password;

  @override
  void initState() {
    super.initState();
    // Real API login starts blank; only local demo mode prefills sample credentials.
    _usesApi = context.read<AlumniModel>().dataSource is ApiDataSource;
    _email = TextEditingController(text: _usesApi ? '' : 'admin');
    _password = TextEditingController(text: _usesApi ? '' : 'Password1');
  }

  void _signIn() {
    if (!_formKey.currentState!.validate()) return;
    Provider.of<AlumniModel>(
      context,
      listen: false,
    ).signIn(_email.text, _password.text);
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Consumer<AlumniModel>(
                builder: (context, model, child) {
                  if (model.restoringSession) {
                    return const Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Checking your session...'),
                      ],
                    );
                  }

                  return Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Icon(
                          Icons.school_outlined,
                          size: 48,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'NMTAFE Alumni',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Stay connected with your alumni community.',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        SectionCard(
                          title: 'Sign in',
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              if (model.sessionRestoreError case final message?)
                                StatusMessage(
                                  message: message,
                                  onRetry: model.restoreSession,
                                ),
                              TextFormField(
                                controller: _email,
                                enabled: !model.signingIn,
                                keyboardType: TextInputType.emailAddress,
                                autocorrect: false,
                                decoration: InputDecoration(
                                  labelText: _usesApi
                                      ? 'Email'
                                      : 'Username or email',
                                ),
                                validator: (value) {
                                  final email = value?.trim() ?? '';
                                  if (email.isEmpty) {
                                    return _usesApi
                                        ? 'Enter your email.'
                                        : 'Enter your username or email.';
                                  }
                                  if (_usesApi &&
                                      !RegExp(
                                        r'^[^\s@]+@[^\s@]+\.[^\s@]+$',
                                      ).hasMatch(email)) {
                                    return 'Enter a valid email address.';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _password,
                                enabled: !model.signingIn,
                                obscureText: true,
                                decoration: const InputDecoration(
                                  labelText: 'Password',
                                ),
                                onFieldSubmitted: (_) => _signIn(),
                                validator: (value) =>
                                    value == null || value.isEmpty
                                    ? 'Enter your password.'
                                    : null,
                              ),
                              if (model.signInError != null)
                                StatusMessage(message: model.signInError!),
                              const SizedBox(height: 20),
                              FilledButton(
                                onPressed: model.signingIn ? null : _signIn,
                                child: Text(
                                  model.signingIn ? 'Signing in...' : 'Sign in',
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          _usesApi
                              ? 'Use your Alumni Platform email and password.\nVerify your email on the website before signing in.'
                              : 'Prototype demo accounts\nadmin or sam@example.com\nPassword: Password1',
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
