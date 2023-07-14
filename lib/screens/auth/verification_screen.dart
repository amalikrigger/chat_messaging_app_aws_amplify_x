import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:chat/constants.dart';
import 'package:chat/providers/user_provider.dart';
import 'package:chat/screens/messages/message_screen.dart';
import 'package:chat/shared/extensions.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'components/logo_with_title.dart';

class VerificationScreen extends StatefulWidget {
  const VerificationScreen(
      {Key? key, required this.username, required this.password})
      : super(key: key);

  final String username;
  final String password;

  @override
  _VerificationScreenState createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  final _formKey = GlobalKey<FormState>();
  late String _otpCode;

  void signIn({required String username, required String password}) async {
    final signInResponse = await context
        .read<UserProvider>()
        .signIn(username: username, password: password);

    signInResponse.fold(
      (error) => context.showError(error),
      (signInResult) {
        if (signInResult.nextStep.signInStep == AuthSignInStep.done) {
          Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const MessagesScreen()),
              (route) => false);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LogoWithTitle(
        title: 'Verification',
        subText: "Verification code has been sent to your mail",
        children: [
          const SizedBox(height: defaultPadding),
          Form(
            key: _formKey,
            child: TextFormField(
              onSaved: (otpCode) {
                _otpCode = otpCode!;
              },
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.send,
              decoration: const InputDecoration(hintText: "Enter OTP"),
            ),
          ),
          const SizedBox(height: defaultPadding),
          ElevatedButton(
            onPressed: () async {
              if (_formKey.currentState!.validate()) {
                _formKey.currentState!.save();
                final result = await context.read<UserProvider>().confirmSignUp(
                    username: widget.username,
                    code: _otpCode,
                    password: widget.password);
                result.fold(
                  (error) => context.showError(error),
                  (_) => signIn(
                      username: widget.username, password: widget.password),
                );
              }
            },
            child: context.watch<UserProvider>().isLoading
                ? const CircularProgressIndicator(
                    color: Colors.white,
                  )
                : const Text("Validate"),
          ),
        ],
      ),
    );
  }
}
