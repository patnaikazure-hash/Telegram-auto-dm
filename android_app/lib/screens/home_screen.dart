import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/telegram_service.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _messageController = TextEditingController();
  List<Map<String, dynamic>> _contacts = [];
  bool _isLoading = false;
  bool _isSending = false;
  String _status = '';
  int _sentCount = 0;
  int _failCount = 0;
  int _totalCount = 0;
  late TelegramService _service;

  @override
  void initState() {
    super.initState();
    _initService();
  }

  Future<void> _initService() async {
    final prefs = await SharedPreferences.getInstance();
    final apiId = prefs.getInt('api_id') ?? 0;
    final apiHash = prefs.getString('api_hash') ?? '';
    final session = prefs.getString('session') ?? '';
    _service = TelegramService(apiId: apiId, apiHash: apiHash, session: session);
    _fetchContacts();
  }

  Future<void> _fetchContacts() async {
    setState(() {
      _isLoading = true;
      _status = 'Fetching your DM contacts...';
    });

    final result = await _service.getDialogs();

    setState(() {
      _isLoading = false;
      if (result['ok'] == true) {
        _contacts = List<Map<String, dynamic>>.from(result['contacts'] ?? []);
        _status = 'Found ${_contacts.length} contacts';
      } else {
        _status = 'Error: ${result['error']}';
      }
    });
  }

  Future<void> _sendToAll() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a message first')),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF232E3C),
        title: const Text('Confirm', style: TextStyle(color: Colors.white)),
        content: Text(
          'Send to all ${_contacts.length} contacts?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2AABEE)),
            child: const Text('Send', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      _isSending = true;
      _sentCount = 0;
      _failCount = 0;
      _totalCount = _contacts.length;
    });

    for (int i = 0; i < _contacts.length; i++) {
      final contact = _contacts[i];
      final result = await _service.sendMessage(
        userId: contact['id'],
        message: message,
      );

      setState(() {
        if (result['ok'] == true) {
          _sentCount++;
          _status = 'Sending... $_sentCount/${_contacts.length}';
        } else {
          _failCount++;
        }
      });

      await Future.delayed(const Duration(seconds: 2));
    }

    setState(() {
      _isSending = false;
      _status = '✓ Done! Sent: $_sentCount | Failed: $_failCount';
    });
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF17212B),
      appBar: AppBar(
        backgroundColor: const Color(0xFF232E3C),
        title: const Text('Telegram Auto DM',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white70),
            onPressed: _isLoading ? null : _fetchContacts,
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white70),
            onPressed: _logout,
          ),
        ],
      ),
      body: Column(
        children: [
          // Status bar
          if (_status.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
              color: const Color(0xFF2AABEE).withOpacity(0.15),
              child: Text(
                _status,
                style: const TextStyle(color: Color(0xFF2AABEE), fontSize: 13),
              ),
            ),

          // Progress bar while sending
          if (_isSending && _totalCount > 0)
            LinearProgressIndicator(
              value: (_sentCount + _failCount) / _totalCount,
              backgroundColor: const Color(0xFF232E3C),
              valueColor:
                  const AlwaysStoppedAnimation<Color>(Color(0xFF2AABEE)),
            ),

          // Contact list
          Expanded(
            child: _isLoading
                ? const Center(
                    child:
                        CircularProgressIndicator(color: Color(0xFF2AABEE)))
                : _contacts.isEmpty
                    ? const Center(
                        child: Text('No DM contacts found',
                            style: TextStyle(color: Colors.white54)))
                    : ListView.builder(
                        itemCount: _contacts.length,
                        itemBuilder: (ctx, i) {
                          final c = _contacts[i];
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: const Color(0xFF2AABEE),
                              child: Text(
                                (c['name'] as String? ?? '?')
                                    .substring(0, 1)
                                    .toUpperCase(),
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                            title: Text(c['name'] ?? 'Unknown',
                                style: const TextStyle(color: Colors.white)),
                            subtitle: Text(
                              c['username'] != null
                                  ? '@${c['username']}'
                                  : 'ID: ${c['id']}',
                              style: const TextStyle(color: Colors.white38),
                            ),
                          );
                        },
                      ),
          ),

          // Message input + send button
          Container(
            padding: const EdgeInsets.all(16),
            color: const Color(0xFF232E3C),
            child: Column(
              children: [
                TextField(
                  controller: _messageController,
                  maxLines: 3,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Type your message...',
                    hintStyle: const TextStyle(color: Colors.white38),
                    filled: true,
                    fillColor: const Color(0xFF17212B),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.all(14),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: (_isSending || _contacts.isEmpty)
                        ? null
                        : _sendToAll,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2AABEE),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: _isSending
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.send_rounded),
                    label: Text(
                      _isSending
                          ? 'Sending $_sentCount/${_contacts.length}...'
                          : 'Send to All ${_contacts.length} DMs',
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
