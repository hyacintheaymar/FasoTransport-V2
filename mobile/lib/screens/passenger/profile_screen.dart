import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/api_client.dart';
import '../../services/avatar_image_utils.dart';
import '../../services/session.dart';
import '../../theme/app_theme.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final SessionStore _sessionStore = SessionStore();
  final ApiClient _apiClient = ApiClient();
  final ImagePicker _imagePicker = ImagePicker();
  Map<String, dynamic>? _user;
  bool _loading = true;
  bool _avatarSaving = false;
  String _error = '';

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

  void _redirectToLogin() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, '/role', (route) => false);
    });
  }

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _loading = true;
      _error = '';
    });

    try {
      final token = await _sessionStore.getToken();
      if (token == null || token.isEmpty) {
        _redirectToLogin();
        return;
      }

      final cached = await _sessionStore.getUser();
      if (cached != null && mounted) {
        setState(() => _user = cached);
      }

      final me = await _apiClient.me(token);
      await _sessionStore.saveUser(me);
      if (!mounted) return;
      setState(() => _user = me);
    } catch (e) {
      if (!mounted) return;
      final errStr = e.toString();
      if (errStr.contains('401')) {
        await _sessionStore.clearToken();
        _redirectToLogin();
        return;
      }
      setState(() => _error = errStr.replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _logout() async {
    await _sessionStore.clearToken();
    _redirectToLogin();
  }

  Future<void> _updateAvatar(String? avatarUrl) async {
    setState(() {
      _avatarSaving = true;
      _error = '';
    });

    try {
      final token = await _sessionStore.getToken();
      if (token == null || token.isEmpty) {
        _redirectToLogin();
        return;
      }

      final updated = await _apiClient.updateMyAvatar(token: token, avatarUrl: avatarUrl);
      await _sessionStore.saveUser(updated);
      if (!mounted) return;
      setState(() => _user = updated);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(avatarUrl == null ? 'Photo supprimée' : 'Photo de profil mise à jour')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() => _avatarSaving = false);
      }
    }
  }

  Future<bool> _confirmAvatarPreview(Uint8List imageBytes) async {
    if (!mounted) return false;
    return await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Aperçu de la photo'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipOval(
                  child: Image.memory(
                    imageBytes,
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

      final normalized = normalizeAvatarImage(bytes);
      final confirmed = await _confirmAvatarPreview(normalized);
      if (!confirmed) return;

      final dataUrl = 'data:image/jpeg;base64,${base64Encode(normalized)}';
      await _updateAvatar(dataUrl);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    }
  }

  @override
  Widget build(BuildContext context) {
    final fullName = _user?['fullName']?.toString().trim();
    final email = _user?['email']?.toString() ?? '--';
    final phone = _user?['phone']?.toString() ?? '--';
    final role = _user?['role']?.toString() ?? '--';
    final avatar = _avatarBytes(_user?['avatarUrl']?.toString());

    return Scaffold(
      backgroundColor: AppColors.gray1,
      appBar: AppBar(
        title: Text('Profil', style: GoogleFonts.syne(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(18),
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: CircleAvatar(
                            radius: 40,
                            backgroundColor: AppColors.gray2,
                            backgroundImage: avatar == null ? null : MemoryImage(avatar),
                            child: avatar == null
                                ? Text(
                                    (fullName != null && fullName.isNotEmpty) ? fullName.substring(0, 1).toUpperCase() : 'U',
                                    style: GoogleFonts.syne(fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.navy),
                                  )
                                : null,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _avatarSaving ? null : _pickAndUploadAvatar,
                                child: Text(_avatarSaving ? 'Chargement...' : 'Choisir une photo'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _avatarSaving || avatar == null ? null : () => _updateAvatar(null),
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.grey.shade600),
                                child: const Text('Supprimer'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          (fullName != null && fullName.isNotEmpty) ? fullName : 'Utilisateur',
                          style: GoogleFonts.syne(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textMain),
                        ),
                        const SizedBox(height: 8),
                        Text('Email: $email', style: GoogleFonts.dmSans(fontSize: 13, color: AppColors.textMain)),
                        const SizedBox(height: 4),
                        Text('Téléphone: $phone', style: GoogleFonts.dmSans(fontSize: 13, color: AppColors.textMain)),
                        const SizedBox(height: 4),
                        Text('Rôle: $role', style: GoogleFonts.dmSans(fontSize: 13, color: AppColors.textMain)),
                      ],
                    ),
                  ),
                  if (_error.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(_error, style: GoogleFonts.dmSans(fontSize: 12, color: Colors.red.shade700)),
                  ],
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _loadProfile,
                      child: const Text('Actualiser le profil'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _logout,
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.orange),
                      child: const Text('Se déconnecter'),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
