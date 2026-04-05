import 'package:flutter/material.dart';
import '../config/app_config.dart';

Future<bool> showPasswordDialog(BuildContext context) async {
  final controller = TextEditingController();
  bool valid = false;

  await showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('Enter Password'),
      content: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        obscureText: true,
        decoration: const InputDecoration(
          hintText: 'Password',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            valid = controller.text.trim() == AppConfig.deletePassword;
            Navigator.pop(context);
          },
          child: const Text('Verify'),
        ),
      ],
    ),
  );

  return valid;
}