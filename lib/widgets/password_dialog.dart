import 'package:flutter/material.dart';
import '../config/app_config.dart';

Future<bool> showPasswordDialog(BuildContext context) async {
  final controller = TextEditingController();
  bool valid = false;

  await showDialog(
    context: context,
    builder: (_) => AlertDialog(
      backgroundColor: const Color(0xFF000000),
      title: const Text('Enter Password', style: TextStyle(color: Colors.white)),
      content: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        obscureText: true,
        style: const TextStyle(color: Colors.white),
        decoration: const InputDecoration(
          hintText: 'Fill Password',
          hintStyle: TextStyle(color: Colors.white),
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