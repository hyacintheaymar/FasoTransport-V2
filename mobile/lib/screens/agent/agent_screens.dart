import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/avatar_image_utils.dart';
import '../../services/session.dart';
import '../../services/api_client.dart';
import '../../theme/app_theme.dart';

class AgentLoginScreen extends StatefulWidget {
  const AgentLoginScreen({super.key});

  @override
  State<AgentLoginScreen> createState() => _AgentLoginScreenState();
}

class _AgentLoginScreenState extends State<AgentLoginScreen> {
  final ApiClient _apiClient = ApiClient();
  final SessionStore _sessionStore = SessionStore();
  final TextEditingController _emailController = TextEditingController(text: 'i.kone@faso.bf');
  final TextEditingController _passwordController = TextEditingController(text: 'Password123!');
  bool _loading = false;
  String _error = '';
  bool _obscure = true;

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
        if (role != 'AGENT' && role != 'ADMIN') {
          await _sessionStore.clearToken();
          if (!mounted) return;
          setState(() {
            _error = 'Ce compte n\'est pas autorise pour l\'interface agent.';
          });
          return;
        }
      }
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/agent/trips');
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
      body: Column(
        children: [
          Container(
            width: double.infinity,
            color: const Color(0xFFE87722),
            padding: const EdgeInsets.fromLTRB(20, 60, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Agent FasoTransport',
                  style: GoogleFonts.syne(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Validation des billets terrain',
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.65),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFDE9D4),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, size: 16, color: Color(0xFFE87722)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Ce compte est réservé aux agents terrain autorisés.',
                            style: GoogleFonts.dmSans(
                              fontSize: 12,
                              color: const Color(0xFFE87722),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Email agent',
                    style: GoogleFonts.dmSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF5A6A8A),
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      hintText: 'agent@faso.bf',
                      filled: true,
                      fillColor: const Color(0xFFEEF1F7),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Mot de passe',
                    style: GoogleFonts.dmSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF5A6A8A),
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscure,
                    decoration: InputDecoration(
                      hintText: '••••••••',
                      filled: true,
                      fillColor: const Color(0xFFEEF1F7),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                          size: 18,
                          color: const Color(0xFF8896B3),
                        ),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  if (_error.isNotEmpty) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.red.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.red.withValues(alpha: 0.18)),
                      ),
                      child: Text(
                        _error,
                        style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.red),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  _loading
                      ? const Center(child: CircularProgressIndicator(color: Color(0xFFE87722)))
                      : GestureDetector(
                          onTap: _login,
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE87722),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Se connecter',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.syne(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                  const SizedBox(height: 20),
                  Text(
                    'Identifiants fournis par votre administrateur.\nProblème ? Contactez le siège.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.dmSans(
                      fontSize: 11,
                      color: const Color(0xFF5A6A8A),
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Profil passager ? ',
                        style: GoogleFonts.dmSans(fontSize: 12, color: const Color(0xFF5A6A8A)),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pushReplacementNamed(context, '/login'),
                        child: Text(
                          'Se connecter ici',
                          style: GoogleFonts.dmSans(
                            fontSize: 12,
                            color: const Color(0xFFE87722),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AgentTripsScreen extends StatefulWidget {
  const AgentTripsScreen({super.key});

  @override
  State<AgentTripsScreen> createState() => _AgentTripsScreenState();
}

class _AgentTripsScreenState extends State<AgentTripsScreen> {
  final SessionStore _sessionStore = SessionStore();
  final ApiClient _apiClient = ApiClient();
  final ImagePicker _imagePicker = ImagePicker();
  Map<String, dynamic>? _user;
  bool _avatarSaving = false;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final user = await _sessionStore.getUser();
    if (!mounted) return;
    setState(() => _user = user);
  }

  Uint8List? _avatarBytes(String? raw) {
    if (raw == null || raw.trim().isEmpty) {
      return null;
    }
    try {
      final payload = raw.contains(',') ? raw.split(',').last : raw;
      return base64Decode(payload);
    } catch (_) {
      return null;
    }
  }

  String _initials(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'AG';
    }
    final parts = value.trim().split(RegExp(r'\s+')).where((part) => part.isNotEmpty).toList();
    if (parts.isEmpty) {
      return 'AG';
    }
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }
    return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'.toUpperCase();
  }

  Future<void> _pickAndUploadAvatar() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choisir dans la galerie'),
              onTap: () => Navigator.pop(sheetContext, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Prendre une photo'),
              onTap: () => Navigator.pop(sheetContext, ImageSource.camera),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (source == null) return;

    try {
      final image = await _imagePicker.pickImage(source: source, imageQuality: 85, maxWidth: 1200);
      if (image == null) return;

      final bytes = await image.readAsBytes();
      if (bytes.length > 2 * 1024 * 1024) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Image trop grande (max 2 MB).')),
        );
        return;
      }

      final token = await _sessionStore.getToken();
      if (token == null || token.isEmpty) {
        await _changeProfile();
        return;
      }

      final normalized = normalizeAvatarImage(bytes);
      if (!mounted) return;
      final confirmed = await showDialog<bool>(
            context: context,
            builder: (dialogContext) => AlertDialog(
              title: const Text('Aperçu de la photo'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ClipOval(
                    child: Image.memory(
                      normalized,
                      width: 160,
                      height: 160,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text('Voulez-vous utiliser cette photo de profil ?'),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: const Text('Annuler'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(dialogContext, true),
                  child: const Text('Confirmer'),
                ),
              ],
            ),
          ) ??
          false;
      if (!confirmed) return;

      final dataUrl = 'data:image/jpeg;base64,${base64Encode(normalized)}';

      if (mounted) {
        setState(() => _avatarSaving = true);
      }

      final updated = await _apiClient.updateMyAvatar(token: token, avatarUrl: dataUrl);
      await _sessionStore.saveUser(updated);
      if (!mounted) return;

      setState(() => _user = updated);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Photo de profil mise à jour')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) {
        setState(() => _avatarSaving = false);
      }
    }
  }

  Future<void> _changeProfile() async {
    await _sessionStore.clearToken();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/role', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final fullName = _user?['fullName']?.toString().trim();
    final avatar = _avatarBytes(_user?['avatarUrl']?.toString());

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FC),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            color: const Color(0xFFE87722),
            padding: const EdgeInsets.fromLTRB(18, 52, 18, 18),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      (fullName != null && fullName.isNotEmpty) ? fullName : 'Agent FasoTransport',
                      style: GoogleFonts.syne(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Agent terrain · Lun 20 Avr',
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    GestureDetector(
                      onTap: _avatarSaving ? null : _pickAndUploadAvatar,
                      child: CircleAvatar(
                        radius: 20,
                        backgroundColor: Colors.white.withValues(alpha: 0.2),
                        backgroundImage: avatar == null ? null : MemoryImage(avatar),
                        child: avatar == null
                            ? Text(
                                _initials(fullName),
                                style: GoogleFonts.syne(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              )
                            : null,
                      ),
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      onPressed: _changeProfile,
                      icon: const Icon(Icons.logout, color: Colors.white, size: 19),
                      tooltip: 'Changer de profil',
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(18),
              children: [
                Text(
                  "Voyages assignés aujourd'hui",
                  style: GoogleFonts.dmSans(fontSize: 12, color: const Color(0xFF5A6A8A)),
                ),
                const SizedBox(height: 12),
                _TripCard(
                  route: 'Ouaga → Bobo',
                  busInfo: 'BUS-07 · 06:00 → 11:30',
                  booked: 38,
                  total: 42,
                  statusLabel: 'EN COURS',
                  statusColor: const Color(0xFFE87722),
                  statusBg: const Color(0xFFFDE9D4),
                  countColor: const Color(0xFF1D9E75),
                  barColor: const Color(0xFFE87722),
                  highlighted: true,
                  onScanTap: () => Navigator.pushNamed(context, '/agent/scanner'),
                ),
                const SizedBox(height: 12),
                _TripCard(
                  route: 'Ouaga → Bobo',
                  busInfo: 'BUS-03 · 14:00 → 19:30',
                  booked: 25,
                  total: 42,
                  statusLabel: 'À VENIR',
                  statusColor: const Color(0xFF1A56A0),
                  statusBg: const Color(0xFFD6E4F7),
                  countColor: const Color(0xFF1A56A0),
                  barColor: const Color(0xFF0D3A6E),
                  highlighted: false,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TripCard extends StatelessWidget {
  final String route;
  final String busInfo;
  final String statusLabel;
  final Color statusColor;
  final Color statusBg;
  final Color countColor;
  final Color barColor;
  final int booked;
  final int total;
  final bool highlighted;
  final VoidCallback? onScanTap;

  const _TripCard({
    required this.route,
    required this.busInfo,
    required this.booked,
    required this.total,
    required this.statusLabel,
    required this.statusColor,
    required this.statusBg,
    required this.countColor,
    required this.barColor,
    required this.highlighted,
    this.onScanTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: highlighted ? const Color(0xFFE87722) : const Color(0xFFEEF1F7),
          width: highlighted ? 1.5 : 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                route,
                style: GoogleFonts.dmSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1A2340),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  statusLabel,
                  style: GoogleFonts.dmSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                busInfo,
                style: GoogleFonts.dmSans(fontSize: 11, color: const Color(0xFF5A6A8A)),
              ),
              Text(
                '$booked/$total',
                style: GoogleFonts.syne(fontSize: 13, fontWeight: FontWeight.w700, color: countColor),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: booked / total,
              minHeight: 5,
              backgroundColor: const Color(0xFFEEF1F7),
              valueColor: AlwaysStoppedAnimation(barColor),
            ),
          ),
          if (onScanTap != null) ...[
            const SizedBox(height: 14),
            GestureDetector(
              onTap: onScanTap,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFE87722),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Scanner les billets',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.syne(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  final MobileScannerController _ctrl = MobileScannerController();
  final ApiClient _apiClient = ApiClient();
  final SessionStore _sessionStore = SessionStore();
  bool _processing = false;
  int _validatedCount = 0;
  int _pendingCount = 0;
  final int _totalCount = 42;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _validate(String qrData) async {
    if (_processing) return;
    setState(() => _processing = true);

    try {
      final token = await _sessionStore.getToken();
      if (token == null || token.isEmpty) {
        if (!mounted) return;
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const AgentScanResultScreen(
              valid: false,
              title: 'Session expirée',
              subtitle: 'Reconnectez-vous pour continuer',
              primaryLabel: 'Scanner un autre',
            ),
          ),
        );
        return;
      }

      await _ctrl.stop();
      final payload = await _apiClient.validateQr(qrData: qrData, token: token);
      if (!mounted) return;
      final valid = payload['valid'] == true;
      final booking = payload['booking'] as Map<String, dynamic>?;

      if (valid) {
        _validatedCount += 1;
      } else {
        _pendingCount += 1;
      }

      final ticketCode = booking?['bookingCode']?.toString() ?? '--';
      final passenger = booking?['passengerName']?.toString() ?? booking?['fullName']?.toString() ?? 'Passager';
      final seat = booking?['seatNumber']?.toString() ?? '--';
      final message = payload['message']?.toString() ?? (valid ? 'Billet valide' : 'Billet invalide');
      final scannedAt = DateTime.now();

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AgentScanResultScreen(
            valid: valid,
            title: valid ? 'BILLET VALIDE' : 'BILLET INVALIDE',
            subtitle: valid ? passenger : message,
            details: valid
              ? 'Siège $seat · Ouaga → Bobo'
              : (payload['message']?.toString() ?? message),
            payment: valid ? 'Paiement : Orange Money ✓' : null,
            primaryLabel: valid ? 'Scanner le suivant' : 'Scanner un autre',
            secondaryLabel: valid ? null : 'Signaler au superviseur',
            footer: valid
                ? 'Validé à ${scannedAt.hour.toString().padLeft(2, '0')}:${scannedAt.minute.toString().padLeft(2, '0')} · #$ticketCode'
                : null,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      _pendingCount += 1;
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AgentScanResultScreen(
            valid: false,
            title: 'BILLET INVALIDE',
            subtitle: 'Validation impossible',
            details: e.toString().replaceFirst('Exception: ', ''),
            primaryLabel: 'Scanner un autre',
            secondaryLabel: 'Signaler au superviseur',
          ),
        ),
      );
    }

    if (mounted) {
      setState(() => _processing = false);
      await _ctrl.start();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.orange,
        leading: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: CircleAvatar(
            radius: 16,
            backgroundColor: Colors.white.withValues(alpha: 0.18),
            child: IconButton(
              padding: EdgeInsets.zero,
              icon: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 18),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
        title: Text('Scanner QR', style: GoogleFonts.syne(fontSize: 22, fontWeight: FontWeight.w700, color: Colors.white)),
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              color: const Color(0xFF070A0F),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned.fill(
                    child: MobileScanner(
                      controller: _ctrl,
                      onDetect: (capture) {
                        if (capture.barcodes.isEmpty) return;
                        final value = capture.barcodes.first.rawValue;
                        if (value != null && value.isNotEmpty) {
                          _validate(value);
                        }
                      },
                    ),
                  ),
                  Container(color: Colors.black.withValues(alpha: 0.45)),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 180,
                        height: 180,
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: Container(
                                decoration: BoxDecoration(border: Border.all(color: Colors.transparent)),
                              ),
                            ),
                            Positioned(top: 0, left: 0, child: _cornerFrame(top: true, left: true)),
                            Positioned(top: 0, right: 0, child: _cornerFrame(top: true, left: false)),
                            Positioned(bottom: 0, left: 0, child: _cornerFrame(top: false, left: true)),
                            Positioned(bottom: 0, right: 0, child: _cornerFrame(top: false, left: false)),
                            Positioned(
                              top: 90,
                              left: 14,
                              right: 14,
                              child: Container(height: 2, color: AppColors.orange),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        _processing ? 'Validation en cours...' : 'Pointez vers le QR Code du billet',
                        style: GoogleFonts.dmSans(fontSize: 12, color: Colors.white.withValues(alpha: 0.75)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 12),
            child: Column(
              children: [
                Text(
                  'Ouaga → Bobo · BUS-07 · 06:00',
                  style: GoogleFonts.dmSans(fontSize: 12, color: const Color(0xFF5A6A8A)),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: _statItem('$_validatedCount', 'Validés', AppColors.green)),
                    Expanded(child: _statItem('$_pendingCount', 'En attente', AppColors.orange)),
                    Expanded(child: _statItem('$_totalCount', 'Total', AppColors.navy2)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _cornerFrame({required bool top, required bool left}) {
    return SizedBox(
      width: 26,
      height: 26,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(
            top: top ? const BorderSide(color: Colors.white, width: 3) : BorderSide.none,
            left: left ? const BorderSide(color: Colors.white, width: 3) : BorderSide.none,
            right: !left ? const BorderSide(color: Colors.white, width: 3) : BorderSide.none,
            bottom: !top ? const BorderSide(color: Colors.white, width: 3) : BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _statItem(String value, String label, Color color) {
    return Column(
      children: [
        Text(value, style: GoogleFonts.syne(fontSize: 24, fontWeight: FontWeight.w700, color: color)),
        const SizedBox(height: 2),
        Text(label, style: GoogleFonts.dmSans(fontSize: 11, color: const Color(0xFF5A6A8A))),
      ],
    );
  }
}

class AgentScanResultScreen extends StatelessWidget {
  final bool valid;
  final String title;
  final String subtitle;
  final String? details;
  final String? payment;
  final String primaryLabel;
  final String? secondaryLabel;
  final String? footer;

  const AgentScanResultScreen({
    super.key,
    required this.valid,
    required this.title,
    required this.subtitle,
    this.details,
    this.payment,
    required this.primaryLabel,
    this.secondaryLabel,
    this.footer,
  });

  @override
  Widget build(BuildContext context) {
    final accent = valid ? const Color(0xFF1FA37C) : const Color(0xFFE34848);
    final soft = valid ? const Color(0xFFD8F0E8) : const Color(0xFFF8DEDE);
    final titleColor = valid ? const Color(0xFF00584C) : const Color(0xFF8A1919);
    final subtitleColor = valid ? const Color(0xFF0F5A50) : const Color(0xFFC62828);
    final detailsColor = valid ? const Color(0xFF157767) : const Color(0xFFD44343);

    return Scaffold(
      backgroundColor: AppColors.gray1,
      appBar: AppBar(
        backgroundColor: AppColors.orange,
        leading: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: CircleAvatar(
            radius: 16,
            backgroundColor: Colors.white.withValues(alpha: 0.18),
            child: IconButton(
              padding: EdgeInsets.zero,
              icon: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 18),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
        title: Text('Résultat', style: GoogleFonts.syne(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: soft,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 35,
                      backgroundColor: accent,
                      child: Icon(valid ? Icons.check_rounded : Icons.close_rounded, size: 38, color: Colors.white),
                    ),
                    const SizedBox(height: 20),
                    Text(title, textAlign: TextAlign.center, style: GoogleFonts.syne(fontSize: 22, fontWeight: FontWeight.w700, color: titleColor)),
                    const SizedBox(height: 14),
                    Container(height: 1, width: 100, color: valid ? const Color(0xFF9FE1CB) : const Color(0xFFF7C1C1)),
                    const SizedBox(height: 12),
                    Text(subtitle, textAlign: TextAlign.center, style: GoogleFonts.dmSans(fontSize: 16, fontWeight: FontWeight.w700, color: subtitleColor)),
                    if (details != null) ...[
                      const SizedBox(height: 10),
                      Text(details!, textAlign: TextAlign.center, style: GoogleFonts.dmSans(fontSize: 12, color: detailsColor, height: 1.5)),
                    ],
                    if (payment != null) ...[
                      const SizedBox(height: 10),
                      Text(payment!, textAlign: TextAlign.center, style: GoogleFonts.dmSans(fontSize: 11, color: const Color(0xFF157767))),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: accent,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: Text(primaryLabel, style: GoogleFonts.syne(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
              ),
            ),
            if (secondaryLabel != null) ...[
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: AppColors.gray3),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text(secondaryLabel!, style: GoogleFonts.syne(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.navy2)),
                ),
              ),
            ],
            if (footer != null) ...[
              const SizedBox(height: 10),
              Text(footer!, style: GoogleFonts.dmSans(fontSize: 11, color: AppColors.textSub)),
            ],
          ],
        ),
      ),
    );
  }
}
