import 'package:flutter/material.dart';
import '../services/supabase_service.dart';
import '../theme/app_colors.dart';
import 'home_screen.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  final String userName;
  final String userEmail;

  const ProfileScreen({
    super.key,
    this.userName = 'Swapit User',
    this.userEmail = 'user@swapit.app',
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isSigningOut = false;

  String get _resolvedName {
    final user = SwapitSupabaseService.currentUser;
    final metaName = user?.userMetadata?['full_name']?.toString().trim();
    if (metaName != null && metaName.isNotEmpty) return metaName;
    if (widget.userName.trim().isNotEmpty) return widget.userName.trim();
    final email = _resolvedEmail;
    if (email.contains('@')) return email.split('@').first;
    return 'Swapit User';
  }

  String get _resolvedEmail {
    final sessionEmail = SwapitSupabaseService.currentUser?.email?.trim();
    if (sessionEmail != null && sessionEmail.isNotEmpty) return sessionEmail;
    return widget.userEmail.trim();
  }

  Future<void> _handleSignOut() async {
    if (_isSigningOut) return;
    setState(() => _isSigningOut = true);

    try {
      await SwapitSupabaseService.signOut();
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تعذر تسجيل الخروج، حاولي مرة أخرى.'),
          backgroundColor: AppColors.error,
        ),
      );
      setState(() => _isSigningOut = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayName = _resolvedName;
    final displayEmail = _resolvedEmail;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text(
          'Profile',
          style: TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: AppColors.primary),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.softBox,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 36,
                      backgroundColor: AppColors.secondary,
                      child: Text(
                        displayName.isNotEmpty
                            ? displayName[0].toUpperCase()
                            : 'S',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      displayName,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      displayEmail,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Go to Market button
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => HomeScreen(
                        userName: displayName,
                        userEmail: displayEmail,
                      ),
                    ),
                  );
                },
                icon: const Icon(
                  Icons.storefront_outlined,
                  color: AppColors.primary,
                ),
                label: const Text(
                  'Go to Market',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: const BorderSide(color: AppColors.border),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),

              const Spacer(),

              // Log Out button
              ElevatedButton.icon(
                onPressed: _isSigningOut ? null : _handleSignOut,
                icon: _isSigningOut
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.logout, color: Colors.white),
                label: Text(
                  _isSigningOut ? 'Signing Out...' : 'Log Out',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}