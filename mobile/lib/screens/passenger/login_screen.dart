import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/api_client.dart';
import '../../services/session.dart';
import '../../widgets/common_widgets.dart';
import '../../theme/app_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final ApiClient _apiClient = ApiClient();
  final SessionStore _sessionStore = SessionStore();
  final TextEditingController _emailController = TextEditingController(text: 'passager@fasotransport.bf');
  final TextEditingController _passwordController = TextEditingController(text: 'Password123!');
  bool _obscure = true;
  bool _loading = false;
  String _error = '';

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    setState(() {
      _loading = true;
      _error = '';
    });
    try {
      final response = await _apiClient.login(_emailController.text.trim(), _passwordController.text);
      final accessToken = response['accessToken']?.toString() ?? '';
      if (accessToken.isEmpty) {
        throw Exception('Réponse de connexion invalide');
      }
      await _sessionStore.saveToken(accessToken);
      final refreshToken = response['refreshToken']?.toString();
      if (refreshToken != null && refreshToken.isNotEmpty) {
        await _sessionStore.saveRefreshToken(refreshToken);
      }
      final user = response['user'];
      if (user is Map<String, dynamic>) {
        await _sessionStore.saveUser(user);
        final role = user['role']?.toString().toUpperCase() ?? '';
        if (role.isNotEmpty && role != 'PASSENGER') {
          await _sessionStore.clearToken();
          if (!mounted) return;
          setState(() {
            _error = 'Ce compte n\'est pas un profil passager. Utilisez l\'interface agent.';
          });
          return;
        }
      }
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/home');
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const SizedBox(height: 20),
            Text(
              'Bon retour 👋',
              style: GoogleFonts.syne(fontSize: 26, fontWeight: FontWeight.w700, color: AppColors.textMain),
            ),
            const SizedBox(height: 6),
            Text(
              'Connectez-vous à votre compte',
              style: GoogleFonts.dmSans(fontSize: 13, color: AppColors.textSub),
            ),
            const SizedBox(height: 32),
            LabeledInput(
              label: 'Email',
              hint: 'passager@fasotransport.bf',
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                'Mot de passe',
                style: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSub),
              ),
              const SizedBox(height: 5),
              TextFormField(
                controller: _passwordController,
                obscureText: _obscure,
                decoration: InputDecoration(
                  hintText: '••••••••',
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      size: 18,
                      color: AppColors.gray4,
                    ),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
              ),
            ]),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                'Mot de passe oublié ?',
                style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.navy2, fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 16),
            if (_error.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.redLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.red.withValues(alpha: 0.2)),
                ),
                child: Text(_error, style: const TextStyle(color: AppColors.red)),
              ),
            if (_error.isNotEmpty) const SizedBox(height: 12),
            _loading
                ? const Center(child: CircularProgressIndicator(color: AppColors.navy))
                : AppButton(label: 'Se connecter', onTap: _login),
            const SizedBox(height: 16),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Container(width: 60, height: 1, color: AppColors.gray2),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Text('ou', style: GoogleFonts.dmSans(color: AppColors.textSub, fontSize: 12)),
              ),
              Container(width: 60, height: 1, color: AppColors.gray2),
            ]),
            const SizedBox(height: 16),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text('Profil agent ? ', style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.textSub)),
              GestureDetector(
                onTap: () => Navigator.pushNamed(context, '/agent/login'),
                child: Text(
                  'Se connecter ici',
                  style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.orange, fontWeight: FontWeight.w700),
                ),
              ),
            ]),
          ]),
        ),
      ),
    );
  }
}
