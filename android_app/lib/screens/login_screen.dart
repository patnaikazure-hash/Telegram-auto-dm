import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/telegram_service.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _apiIdController = TextEditingController();
  final _apiHashController = TextEditingController();
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();

  bool _isLoading = false;
  bool _otpSent = false;
  String _phoneCodeHash = '';
  String _error = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF17212B),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 48),
              const Icon(Icons.send_rounded, color: Color(0xFF2AABEE), size: 56),
              const SizedBox(height: 24),
              const Text(
                'Telegram Auto DM',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Log in to send messages to all your DMs',
                style: TextStyle(color: Colors.white54, fontSize: 15),
              ),
              const SizedBox(height: 40),

              // API ID
              _buildLabel('API ID'),
              _buildTextField(
                controller: _apiIdController,
                hint: 'e.g. 12345678',
                keyboardType: TextInputType.number,
                enabled: !_otpSent,
              ),
              const SizedBox(height: 16),

              // API HASH
              _buildLabel('API HASH'),
              _buildTextField(
                controller: _apiHashController,
                hint: 'e.g. abc123def456...',
                enabled: !_otpSent,
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () {},
                child: const Text(
                  'Get API credentials from my.telegram.org',
                  style: TextStyle(color: Color(0xFF2AABEE), fontSize: 13),
                ),
              ),
              const SizedBox(height: 20),

              // Phone
              _buildLabel('Phone Number'),
              _buildTextField(
                controller: _phoneController,
                hint: '+91 9876543210',
                keyboardType: TextInputType.phone,
                enabled: !_otpSent,
              ),
              const SizedBox(height: 20),

              if (_otpSent) ...[
                _buildLabel('OTP Code'),
                _buildTextField(
                  controller: _otpController,
                  hint: '12345',
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 20),
              ],

              if (_error.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _error,
                    style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                  ),
                ),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : (_otpSent ? _verifyOtp : _sendOtp),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2AABEE),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          _otpSent ? 'Verify OTP' : 'Send OTP',
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              ),

              if (_otpSent)
                TextButton(
                  onPressed: () => setState(() {
                    _otpSent = false;
                    _error = '';
                  }),
                  child: const Text('← Change number',
                      style: TextStyle(color: Colors.white54)),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text,
            style: const TextStyle(
                color: Colors.white70,
                fontSize: 13,
                fontWeight: FontWeight.w500)),
      );

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    bool enabled = true,
  }) =>
      TextField(
        controller: controller,
        keyboardType: keyboardType,
        enabled: enabled,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.white38),
          filled: true,
          fillColor: const Color(0xFF232E3C),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      );

  Future<void> _sendOtp() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    final apiId = int.tryParse(_apiIdController.text.trim());
    final apiHash = _apiHashController.text.trim();
    final phone = _phoneController.text.trim();

    if (apiId == null || apiHash.isEmpty || phone.isEmpty) {
      setState(() {
        _error = 'Please fill all fields.';
        _isLoading = false;
      });
      return;
    }

    final service = TelegramService(apiId: apiId, apiHash: apiHash);
    final result = await service.sendCode(phone);

    setState(() {
      _isLoading = false;
      if (result['ok'] == true) {
        _otpSent = true;
        _phoneCodeHash = result['phone_code_hash'] ?? '';
      } else {
        _error = result['error'] ?? 'Failed to send OTP.';
      }
    });
  }

  Future<void> _verifyOtp() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    final apiId = int.tryParse(_apiIdController.text.trim())!;
    final apiHash = _apiHashController.text.trim();
    final phone = _phoneController.text.trim();
    final otp = _otpController.text.trim();

    final service = TelegramService(apiId: apiId, apiHash: apiHash);
    final result = await service.signIn(
      phone: phone,
      phoneCodeHash: _phoneCodeHash,
      code: otp,
    );

    if (result['ok'] == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_logged_in', true);
      await prefs.setInt('api_id', apiId);
      await prefs.setString('api_hash', apiHash);
      await prefs.setString('session', result['session'] ?? '');

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    } else {
      setState(() {
        _error = result['error'] ?? 'Invalid OTP.';
        _isLoading = false;
      });
    }
  }
}
