import 'package:flutter/material.dart';

import '../services/swapit_supabase_service.dart';
import '../theme/app_colors.dart';
import 'home_screen.dart';
import 'login_screen.dart';
import 'my_items_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({
    super.key,
    this.userName = '',
    this.userEmail = '',
  });

  final String userName;
  final String userEmail;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isSigningOut = false;

  String get _displayName {
    final String name = widget.userName.trim();
    return name.isEmpty ? 'Swapit user' : name;
  }

  String get _displayEmail {
    final String email = widget.userEmail.trim();
    if (email.isNotEmpty) return email;
    return SwapitSupabaseService.currentUser?.email ?? '';
  }

  Future<void> _logout() async {
    if (_isSigningOut) return;

    final NavigatorState navigator = Navigator.of(context);
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);

    setState(() => _isSigningOut = true);

    try {
      await SwapitSupabaseService.signOut();
      navigator.pushAndRemoveUntil(
        MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
        (Route<dynamic> route) => false,
      );
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.error,
          content: Text('Could not log out. Please try again.'),
        ),
      );
      if (mounted) {
        setState(() => _isSigningOut = false);
      }
    }
  }

  Widget _actionTile({
    required IconData icon,
    required String label,
    required VoidCallback? onTap,
    Color color = AppColors.primary,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: AppColors.softBox,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: AppColors.border),
        ),
        child: ListTile(
          onTap: onTap,
          leading: Icon(icon, color: color),
          title: Text(
            label,
            style: TextStyle(fontWeight: FontWeight.w600, color: color),
          ),
          trailing: const Icon(Icons.chevron_right, color: AppColors.muted),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String initial = _displayName.characters.first.toUpperCase();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: AppColors.primary),
        title: const Text(
          'Profile',
          style: TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: <Widget>[
            const SizedBox(height: 8),
            Center(
              child: CircleAvatar(
                radius: 42,
                backgroundColor: AppColors.primary,
                child: Text(
                  initial,
                  style: const TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Center(
              child: Text(
                _displayName,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ),
            if (_displayEmail.isNotEmpty) ...<Widget>[
              const SizedBox(height: 4),
              Center(
                child: Text(
                  _displayEmail,
                  style: const TextStyle(fontSize: 14, color: AppColors.muted),
                ),
              ),
            ],
            const SizedBox(height: 28),
            _actionTile(
              icon: Icons.inventory_2_outlined,
              label: 'My Items',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const MyItemsScreen(),
                  ),
                );
              },
            ),
            _actionTile(
              icon: Icons.home_outlined,
              label: 'Browse Items',
              onTap: () {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute<void>(
                    builder: (_) => HomeScreen(
                      userName: widget.userName,
                      userEmail: widget.userEmail,
                    ),
                  ),
                  (Route<dynamic> route) => false,
                );
              },
            ),
            _actionTile(
              icon: Icons.logout,
              label: _isSigningOut ? 'Logging out...' : 'Log out',
              color: AppColors.error,
              onTap: _isSigningOut ? null : _logout,
            ),
          ],
        ),
      ),
    );
  }
}