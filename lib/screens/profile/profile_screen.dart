import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../auth/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _notifQueue = true;
  bool _notifComplete = true;
  bool _darkMode = false;

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildCard(
            'Profile Settings',
            Column(
              children: [
                _buildProfileField('Name', user?.username ?? 'Gautham'),
                _buildProfileField('Car Model', user?.carModel ?? 'Tesla Model 3'),
                _buildProfileField('Parking Spot', user?.parkingSlot ?? 'A-12'),
                const SizedBox(height: 16),
                ElevatedButton(onPressed: () {}, child: const Text('Save Changes')),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildCard(
            'Notifications',
            Column(
              children: [
                SwitchListTile(
                  title: const Text('Queue Position Changes'),
                  value: _notifQueue,
                  onChanged: (v) => setState(() => _notifQueue = v),
                ),
                SwitchListTile(
                  title: const Text('Charging Complete'),
                  value: _notifComplete,
                  onChanged: (v) => setState(() => _notifComplete = v),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildCard(
            'Theme',
            SwitchListTile(
              title: const Text('Dark Mode'),
              value: _darkMode,
              onChanged: (v) => setState(() => _darkMode = v),
            ),
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
            icon: const Icon(Icons.logout, color: Colors.red),
            label: const Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(String title, Widget child) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildProfileField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        decoration: InputDecoration(
          labelText: label,
          border: const UnderlineInputBorder(),
        ),
        controller: TextEditingController(text: value),
      ),
    );
  }
}
