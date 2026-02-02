import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class DebugAuthWidget extends StatelessWidget {
  const DebugAuthWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final user = authProvider.currentUser;
        
        return Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.black87,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'DEBUG AUTH INFO',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Authenticated: ${authProvider.isAuthenticated}',
                style: const TextStyle(color: Colors.white, fontSize: 10),
              ),
              Text(
                'Loading: ${authProvider.isLoading}',
                style: const TextStyle(color: Colors.white, fontSize: 10),
              ),
              Text(
                'User: ${user?.name ?? 'null'}',
                style: const TextStyle(color: Colors.white, fontSize: 10),
              ),
              Text(
                'Email: ${user?.email ?? 'null'}',
                style: const TextStyle(color: Colors.white, fontSize: 10),
              ),
              Text(
                'Is Guest: ${user?.isGuest ?? 'null'}',
                style: const TextStyle(color: Colors.white, fontSize: 10),
              ),
              Text(
                'User ID: ${user?.id ?? 'null'}',
                style: const TextStyle(color: Colors.white, fontSize: 10),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  ElevatedButton(
                    onPressed: () async {
                      await authProvider.forceRefreshUser();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    ),
                    child: const Text(
                      'Refresh',
                      style: TextStyle(fontSize: 10, color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () async {
                      await authProvider.signOut();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    ),
                    child: const Text(
                      'Sign Out',
                      style: TextStyle(fontSize: 10, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
