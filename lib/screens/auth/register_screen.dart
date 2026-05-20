import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _carModelController = TextEditingController();
  final _parkingSlotController = TextEditingController();
  bool _obscurePassword = true;

  final Map<String, bool> _requirements = {
    '8+ characters': false,
    'Uppercase letter': false,
    'Lowercase letter': false,
    'One number': false,
    'One symbol': false,
    'No spaces at ends': true,
  };

  void _validatePassword(String password) {
    setState(() {
      _requirements['8+ characters'] = password.length >= 8;
      _requirements['Uppercase letter'] = password.contains(RegExp(r'[A-Z]'));
      _requirements['Lowercase letter'] = password.contains(RegExp(r'[a-z]'));
      _requirements['One number'] = password.contains(RegExp(r'[0-9]'));
      _requirements['One symbol'] = password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
      _requirements['No spaces at ends'] = !password.startsWith(' ') && !password.endsWith(' ');
    });
  }

  bool get _isPasswordValid => !_requirements.values.contains(false);

  Future<void> _handleRegister() async {
    if (!_isPasswordValid || _usernameController.text.isEmpty) return;

    try {
      final success = await context.read<AuthProvider>().register({
        'username': _usernameController.text,
        'password': _passwordController.text,
        'carModel': _carModelController.text,
        'parkingSlot': _parkingSlotController.text,
      });
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Registration successful! Please login.')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<AuthProvider>().isLoading;

    return Scaffold(
      appBar: AppBar(title: const Text('Create Account')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              TextField(
                controller: _usernameController,
                decoration: InputDecoration(
                  labelText: 'Username',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                onChanged: _validatePassword,
                decoration: InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              ..._requirements.entries.map((req) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Icon(
                      req.value ? Icons.check_circle : Icons.cancel,
                      size: 16,
                      color: req.value ? Colors.green : Colors.red,
                    ),
                    const SizedBox(width: 8),
                    Text(req.key, style: TextStyle(color: req.value ? Colors.green : Colors.red, fontSize: 12)),
                  ],
                ),
              )),
              const SizedBox(height: 16),
              TextField(
                controller: _carModelController,
                decoration: InputDecoration(
                  labelText: 'Car Model (e.g. Tesla Model 3)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _parkingSlotController,
                decoration: InputDecoration(
                  labelText: 'Parking Slot (e.g. A-12)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: (isLoading || !_isPasswordValid) ? null : _handleRegister,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2DBE44),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: isLoading 
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Create Account', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
