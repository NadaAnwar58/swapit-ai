import 'package:flutter/material.dart';

import '../services/swapit_supabase_service.dart';
import '../theme/app_colors.dart';
import 'home_screen.dart';
import 'login_screen.dart';
import 'my_items_screen.dart';
import 'swap_requests_screen.dart';

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
  final TextEditingController _whatsappController = TextEditingController();

  bool _isSigningOut = false;
  bool _isSavingWhatsapp = false;

  @override
  void initState() {
    super.initState();
    _loadWhatsapp();
  }

  @override
  void dispose() {
    _whatsappController.dispose();
    super.dispose();
  }

  String get _displayName {
    final String name = widget.userName.trim();
    return name.isEmpty ? 'Swapit user' : name;
  }

  String get _displayEmail {
    final String email = widget.userEmail.trim();
    if (email.isNotEmpty) return email;
    return SwapitSupabaseService.currentUser?.email ?? '';
  }

  Future<void> _loadWhatsapp() async {
    final user = SwapitSupabaseService.currentUser;
    if (user == null) return;

    try {
      final Map<String, dynamic>? profile =
          await SwapitSupabaseService.fetchProfile(user.id);
      if (!mounted) return;
      _whatsappController.text = (profile?['whatsapp'] ?? '').toString();
    } catch (_) {
      // Leave the field empty if loading fails.
    }
  }

  Future<void> _saveWhatsapp() async {
    if (_isSavingWhatsapp) return;

    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final String number = _whatsappController.text.trim();
    final String digits = number.replaceAll(RegExp(r'[^0-9]'), '');

    if (digits.length < 10) {
      messenger.showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.error,
          content: Text('Please enter a valid WhatsApp number.'),
        ),
      );
      return;
    }

    setState(() => _isSavingWhatsapp = true);

    try {
      await SwapitSupabaseService.saveMyWhatsapp(number);
      messenger.showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.secondary,
          content: Text('WhatsApp number saved.'),
        ),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          backgroundColor: AppColors.error,
          content: Text('Could not save the number: $e'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSavingWhatsapp = false);
      }
    }
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

  Widget _whatsappCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            'WhatsApp number',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Shown to the other person only after a swap is accepted.',
            style: TextStyle(fontSize: 12, color: AppColors.muted),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _whatsappController,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              hintText: '01012345678',
              filled: true,
              fillColor: AppColors.softBox,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.border),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _isSavingWhatsapp ? null : _saveWhatsapp,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.secondary,
              ),
              child: _isSavingWhatsapp
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Save number'),
            ),
          ),
        ],
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
            const SizedBox(height: 24),
            _whatsappCard(),
            _actionTile(
              icon: Icons.swap_horiz,
              label: 'Swap Requests',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const SwapRequestsScreen(),
                  ),
                );
              },
            ),
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