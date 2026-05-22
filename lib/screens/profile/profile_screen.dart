import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../auth/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late TextEditingController _nameController;
  late TextEditingController _carController;
  late TextEditingController _slotController;

  bool _notifQueue = true;
  bool _notifComplete = true;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user;
    _nameController = TextEditingController(text: user?.username ?? 'gautham');
    _carController = TextEditingController(text: user?.carModel ?? 'Tesla');
    _slotController = TextEditingController(text: user?.parkingSlot ?? 'B2');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _carController.dispose();
    _slotController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    try {
      await context.read<AuthProvider>().updateUser(
        _nameController.text,
        _carController.text,
        _slotController.text,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Changes saved successfully!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<AuthProvider>().isLoading;
    final themeProvider = context.watch<ThemeProvider>();

    return Scaffold(
      backgroundColor: themeProvider.isDarkMode ? null : const Color(0xFFF9FAF7),
      appBar: AppBar(
        title: const Text('Profile', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: themeProvider.isDarkMode ? Colors.white : Colors.black87,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        children: [
          _buildCard(
            'Profile Settings',
            Column(
              children: [
                _buildField('Name', _nameController, themeProvider.isDarkMode),
                _buildField('Car Model', _carController, themeProvider.isDarkMode),
                _buildField('Parking Spot', _slotController, themeProvider.isDarkMode),
                const SizedBox(height: 20),
                Center(
                  child: OutlinedButton(
                    onPressed: isLoading ? null : _handleSave,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.green,
                      side: BorderSide(color: themeProvider.isDarkMode ? Colors.white24 : const Color(0xFFE0E0E0)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                    ),
                    child: isLoading 
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Save Changes'),
                  ),
                ),
              ],
            ),
            themeProvider.isDarkMode,
          ),
          const SizedBox(height: 16),
          _buildCard(
            'Notifications',
            Column(
              children: [
                _buildSwitchRow('Queue Position Changes', _notifQueue, (v) => setState(() => _notifQueue = v), themeProvider.isDarkMode),
                _buildSwitchRow('Charging Complete', _notifComplete, (v) => setState(() => _notifComplete = v), themeProvider.isDarkMode),
              ],
            ),
            themeProvider.isDarkMode,
          ),
          const SizedBox(height: 16),
          _buildCard(
            'Theme',
            _buildSwitchRow('Dark Mode', themeProvider.isDarkMode, (v) => themeProvider.toggleTheme(v), themeProvider.isDarkMode),
            themeProvider.isDarkMode,
          ),
          const SizedBox(height: 32),
          TextButton.icon(
            onPressed: () async {
              await context.read<AuthProvider>().logout();
              if (mounted) {
                Navigator.of(context, rootNavigator: true).pushReplacement(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              }
            },
            icon: const Icon(Icons.logout, color: Colors.redAccent, size: 18),
            label: const Text('Logout', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(String title, Widget child, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : const Color(0xFFF1F4ED),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isDark ? Colors.white : Colors.black87)),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildField(String label, TextEditingController controller, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600], fontSize: 12)),
          TextField(
            controller: controller,
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 8),
              border: UnderlineInputBorder(borderSide: BorderSide(color: isDark ? Colors.white12 : Colors.black12)),
              enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: isDark ? Colors.white12 : Colors.black12)),
            ),
            style: TextStyle(fontSize: 15, color: isDark ? Colors.white : Colors.black87),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchRow(String title, bool value, ValueChanged<bool> onChanged, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: TextStyle(fontSize: 14, color: isDark ? Colors.white : Colors.black87)),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: Colors.green,
            activeTrackColor: Colors.green.withAlpha(76),
          ),
        ],
      ),
    );
  }
}
