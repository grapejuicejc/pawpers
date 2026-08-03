import 'package:flutter/material.dart';
import '../../app_theme.dart';

class AdminHomeScreen extends StatelessWidget {
  const AdminHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Home'),
        backgroundColor: AppColors.primary,
      ),
      body: const Center(child: Text('Welcome to the Admin Home Screen!')),
    );
  }
}
