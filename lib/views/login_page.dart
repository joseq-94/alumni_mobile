import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/alumni_model.dart';
import 'widgets/section_card.dart';
import 'widgets/status_message.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController(text: 'admin');
  final _password = TextEditingController(text: 'Password1');
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
                              TextFormField(
                                controller: _email,
                                enabled: !model.signingIn,
                                keyboardType: TextInputType.emailAddress,
                                decoration: const InputDecoration(
                                  labelText: 'Username or email',
                                ),
                                validator: (value) =>
                                    value == null || value.trim().isEmpty
                                    ? 'Enter your username or email.'
                                    : null,
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
                        const Text(
                          'Prototype demo accounts\nadmin or sam@example.com\nPassword: Password1',
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
