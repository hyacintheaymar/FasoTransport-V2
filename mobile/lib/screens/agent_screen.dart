import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_scanner/mobile_scanner.dart';
import '../config.dart';
import '../services/scan_history.dart';

class AgentScreen extends StatefulWidget {
  const AgentScreen({super.key});

  @override
  State<AgentScreen> createState() => _AgentScreenState();
}

class _AgentScreenState extends State<AgentScreen> {
  bool _processing = false;
  String _result = 'Scannez un QR billet';
  final ScanHistoryStore _scanHistoryStore = ScanHistoryStore();
  List<Map<String, dynamic>> _history = [];
  Map<String, dynamic>? _lastBooking;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final history = await _scanHistoryStore.getHistory();
    if (!mounted) return;
    setState(() => _history = history);
  }

  Future<void> _validate(String qrData) async {
    if (_processing) return;
    setState(() => _processing = true);

    final response = await http.post(
      Uri.parse('${AppConfig.apiBaseUrl}/bookings/validate-qr'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'qrData': qrData}),
    );

    if (!mounted) return;

    if (response.statusCode == 200) {
      final payload = jsonDecode(response.body) as Map<String, dynamic>;
      setState(() {
        _result = payload['message']?.toString() ?? 'Validation terminee';
        _lastBooking = payload['booking'] as Map<String, dynamic>?;
      });

      if (_lastBooking != null) {
        await _scanHistoryStore.addEntry({
          'bookingCode': _lastBooking!['bookingCode'],
          'seatNumber': _lastBooking!['seatNumber'],
          'validatedAt': DateTime.now().toIso8601String(),
          'message': _result,
        });
        await _loadHistory();
      }
    } else {
      setState(() {
        _result = 'Erreur de validation';
        _lastBooking = null;
      });
    }

    await Future.delayed(const Duration(seconds: 1));
    if (mounted) {
      setState(() => _processing = false);
    }
  }

  Future<void> _clearHistory() async {
    await _scanHistoryStore.clear();
    if (!mounted) return;
    setState(() => _history = []);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Agent - Scan QR')),
      body: Column(
        children: [
          Expanded(
            child: MobileScanner(
              onDetect: (capture) {
                final value = capture.barcodes.first.rawValue;
                if (value != null && value.isNotEmpty) {
                  _validate(value);
                }
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(_result),
                if (_lastBooking != null) ...[
                  const SizedBox(height: 8),
                  Text('Code: ${_lastBooking!['bookingCode']}'),
                  Text('Place: ${_lastBooking!['seatNumber']}'),
                  Text('Etat: ${_lastBooking!['validatedAt'] != null ? 'Valide' : 'Non valide'}'),
                ],
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Historique local', style: TextStyle(fontWeight: FontWeight.bold)),
                    TextButton(onPressed: _clearHistory, child: const Text('Vider')),
                  ],
                ),
                const SizedBox(height: 8),
                ..._history.map(
                  (entry) => Card(
                    child: ListTile(
                      title: Text(entry['bookingCode']?.toString() ?? 'Billet'),
                      subtitle: Text('Place ${entry['seatNumber']} - ${entry['message']}'),
                      trailing: Text(
                        DateTime.tryParse(entry['validatedAt']?.toString() ?? '')?.toLocal().toString().split('.').first ?? '',
                        style: const TextStyle(fontSize: 11),
                      ),
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
