import 'package:flutter/material.dart';
import '../services/api_client.dart';
import '../services/session.dart';
import 'ticket_screen.dart';

class PassengerScreen extends StatefulWidget {
  const PassengerScreen({super.key});

  @override
  State<PassengerScreen> createState() => _PassengerScreenState();
}

class _PassengerScreenState extends State<PassengerScreen> {
  final ApiClient _apiClient = ApiClient();
  final SessionStore _sessionStore = SessionStore();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  List<dynamic> _schedules = [];
  String? _token;
  String _message = 'Connectez-vous pour reserver un trajet';
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _restoreSession();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _restoreSession() async {
    final token = await _sessionStore.getToken();
    if (!mounted) return;
    if (token != null) {
      setState(() => _token = token);
      await _loadSchedules(token);
    }
  }

  Future<void> _login() async {
    setState(() {
      _loading = true;
      _message = 'Connexion en cours...';
    });

    try {
      final response = await _apiClient.login(
        _emailController.text.trim(),
        _passwordController.text,
      );
      final token = response['accessToken'] as String;
      await _sessionStore.saveToken(token);
      if (!mounted) return;
      setState(() => _token = token);
      setState(() => _message = 'Connexion réussie. Chargement des horaires...');
      await _loadSchedules(token);
    } catch (e) {
      if (!mounted) return;
      setState(() => _message = 'Echec de connexion: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _logout() async {
    await _sessionStore.clearToken();
    if (!mounted) return;
    setState(() {
      _token = null;
      _schedules = [];
      _message = 'Connectez-vous pour reserver un trajet';
    });
  }

  Future<void> _loadSchedules(String token) async {
    setState(() => _loading = true);
    try {
      final schedules = await _apiClient.getSchedules(token: token);
      if (!mounted) return;
      setState(() {
        _schedules = schedules;
        _message = schedules.isEmpty ? 'Aucun horaire disponible' : 'Choisissez un trajet';
      });
    } catch (e) {
      if (!mounted) return;
      final errStr = e.toString();
      if (errStr.contains('401')) {
        await _sessionStore.clearToken();
        setState(() {
          _token = null;
          _schedules = [];
          _message = 'Session expirée. Veuillez vous reconnecter.';
        });
        return;
      }
      setState(() => _message = 'Connexion réussie, mais chargement des horaires impossible: $errStr');
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _book(String scheduleId) async {
    final token = _token;
    if (token == null) return;

    setState(() => _loading = true);
    try {
      final booking = await _apiClient.book(scheduleId, token);
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => TicketScreen(booking: booking)),
      );
      await _loadSchedules(token);
    } catch (e) {
      if (!mounted) return;
      setState(() => _message = e.toString());
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final loggedIn = _token != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Passager'),
        actions: [
          if (loggedIn)
            TextButton(
              onPressed: _logout,
              child: const Text('Deconnexion'),
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!loggedIn) ...[
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Mot de passe'),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _loading ? null : _login,
                child: Text(_loading ? 'Connexion...' : 'Se connecter'),
              ),
            ] else ...[
              ElevatedButton(
                onPressed: _loading ? null : () => _loadSchedules(_token!),
                child: const Text('Actualiser les horaires'),
              ),
              const SizedBox(height: 12),
            ],
            const SizedBox(height: 12),
            Text(_message),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.builder(
                itemCount: _schedules.length,
                itemBuilder: (_, index) {
                  final item = _schedules[index] as Map<String, dynamic>;
                  final scheduleId = item['_id']?.toString() ?? item['id']?.toString() ?? '';
                  return Card(
                    child: ListTile(
                      title: Text(item['busLabel']?.toString() ?? 'Bus'),
                      subtitle: Text(
                        'Prix: ${item['price']} FCFA - Places: ${item['availableSeats']}',
                      ),
                      trailing: loggedIn
                          ? ElevatedButton(
                              onPressed: _loading ? null : () => _book(scheduleId),
                              child: const Text('Reserver'),
                            )
                          : null,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
