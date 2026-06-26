import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config.dart';
import '../../services/api_client.dart';
import '../../services/session.dart';
import '../../theme/app_theme.dart';
import '../../widgets/search_card.dart';
import '../../widgets/filter_pill.dart';
import '../../widgets/route_card.dart';
import '../../widgets/custom_bottom_nav_bar.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiClient _apiClient = ApiClient();
  final SessionStore _sessionStore = SessionStore();
  int _navIndex = 0;
  String _greetingName = 'Voyageur';
  String _initials = 'FT';
  String? _avatarUrl;
  bool _loadingTrips = true;
  String _loadError = '';
  String _from = 'Ouagadougou';
  String _to = '';
  DateTime? _selectedDate;
  int _selectedFilterIndex = 0;

  List<Map<String, dynamic>> _popularTrips = const [];

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  void _redirectToLogin() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/login');
    });
  }

  Future<void> _bootstrap() async {
    try {
      if (mounted) {
        setState(() {
          _loadingTrips = true;
          _loadError = '';
        });
      }

      final token = await _sessionStore.getToken();
      if (token == null || token.isEmpty) {
        _redirectToLogin();
        return;
      }

      final cachedUser = await _sessionStore.getUser();
      if (cachedUser != null) {
        final cachedName = (cachedUser['fullName']?.toString() ?? '').trim();
        if (cachedName.isNotEmpty && mounted) {
          setState(() {
            _greetingName = cachedName;
            _initials = _buildInitials(cachedName);
            _avatarUrl = cachedUser['avatarUrl']?.toString();
          });
        }
      }

      final me = await _apiClient.me(token);
      await _sessionStore.saveUser(me);

      final schedules = await _apiClient.getSchedules(token: token);
      final sortedSchedules = List<Map<String, dynamic>>.from(
        schedules.map((item) => item as Map<String, dynamic>),
      )
        ..sort((a, b) {
          final aDate =
              _parseDate(a['createdAt']) ?? _parseDate(a['departureTime']) ?? DateTime.fromMillisecondsSinceEpoch(0);
          final bDate =
              _parseDate(b['createdAt']) ?? _parseDate(b['departureTime']) ?? DateTime.fromMillisecondsSinceEpoch(0);
          return bDate.compareTo(aDate);
        });

      final trips = sortedSchedules.take(8).map((map) {
        return {
          'from': _routeFrom(map),
          'to': _routeTo(map),
          'duration': _formatDuration(map['departureTime'], map['arrivalTime']),
          'price': '${map['price'] ?? '--'} ₣',
        };
      }).toList();

      if (!mounted) return;
      setState(() {
        final name = (me['fullName']?.toString() ?? '').trim();
        if (name.isNotEmpty) {
          _greetingName = name;
          _initials = _buildInitials(name);
        }
        _avatarUrl = me['avatarUrl']?.toString();
        _popularTrips = trips;
        _loadError = '';
      });
    } catch (e) {
      if (!mounted) return;
      final errStr = e.toString();
      if (errStr.contains('401')) {
        await _sessionStore.clearToken();
        _redirectToLogin();
        return;
      }
      setState(() {
        _loadError = errStr.replaceFirst('Exception: ', '');
        _popularTrips = const [];
      });
    } finally {
      if (mounted) {
        setState(() => _loadingTrips = false);
      }
    }
  }

  String _buildInitials(String fullName) {
    final parts = fullName.split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();
    if (parts.isEmpty) {
      return 'FT';
    }
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }
    return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'.toUpperCase();
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

  Future<void> _pickFrom() async {
    final value = await _askText('Ville de départ', _from);
    if (value == null) return;
    setState(() => _from = value);
  }

  Future<void> _pickTo() async {
    final value = await _askText('Ville d\'arrivée', _to);
    if (value == null) return;
    setState(() => _to = value);
  }

  Future<String?> _askText(String title, String current) async {
    final ctrl = TextEditingController(text: current);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: TextField(controller: ctrl, autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
          TextButton(onPressed: () => Navigator.pop(ctx, ctrl.text.trim()), child: const Text('Valider')),
        ],
      ),
    );
    ctrl.dispose();
    return result;
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      initialDate: _selectedDate ?? now,
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  String _formatDate(DateTime? dt) {
    if (dt == null) return 'Sélectionner la date';
    final dd = dt.day.toString().padLeft(2, '0');
    final mm = dt.month.toString().padLeft(2, '0');
    final yy = dt.year;
    return '$dd/$mm/$yy';
  }

  String _routeFrom(Map<String, dynamic> map) =>
      map['from']?.toString() ?? map['origin']?.toString() ?? map['departCity']?.toString() ?? 'Départ';

  String _routeTo(Map<String, dynamic> map) =>
      map['to']?.toString() ?? map['destination']?.toString() ?? map['arrivalCity']?.toString() ?? 'Arrivée';

  String _formatDuration(dynamic departureRaw, dynamic arrivalRaw) {
    DateTime? departure;
    DateTime? arrival;
    try {
      if (departureRaw != null) departure = DateTime.parse(departureRaw.toString()).toLocal();
      if (arrivalRaw != null) arrival = DateTime.parse(arrivalRaw.toString()).toLocal();
    } catch (_) {
      return 'Horaire disponible';
    }
    if (departure == null || arrival == null) {
      return 'Horaire disponible';
    }
    final diff = arrival.difference(departure);
    final hours = diff.inHours;
    final mins = diff.inMinutes.remainder(60);
    return '${hours}h${mins.toString().padLeft(2, '0')}';
  }

  DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    try {
      return DateTime.parse(value.toString()).toLocal();
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.gray1,
      body: Stack(
        children: [
          Column(
            children: [
              // Header with navy background
              Container(
                color: AppColors.navy,
                padding: const EdgeInsets.fromLTRB(16, 52, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Greeting and Avatar
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Bonjour,',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w400,
                                color: Colors.white.withValues(alpha: 0.6),
                              ),
                            ),
                            Text(
                              '$_greetingName 👋',
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: AppColors.orange,
                          backgroundImage: _avatarBytes(_avatarUrl) != null
                              ? MemoryImage(_avatarBytes(_avatarUrl)!)
                              : null,
                          child: _avatarBytes(_avatarUrl) == null
                              ? Text(
                                  _initials,
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                )
                              : null,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // SearchCard
                    SearchCard(
                      departureValue: _from,
                      destinationValue: _to.isEmpty ? 'Destination' : _to,
                      dateValue: _formatDate(_selectedDate),
                      onDeparturePressed: _pickFrom,
                      onDestinationPressed: _pickTo,
                      onDatePressed: _pickDate,
                      onSwap: () {
                        setState(() {
                          final temp = _from;
                          _from = _to;
                          _to = temp;
                        });
                      },
                      onSearchPressed: () => Navigator.pushNamed(
                        context,
                        '/results',
                        arguments: {
                          'from': _from,
                          'to': _to,
                          'date': _selectedDate?.toIso8601String(),
                        },
                      ),
                    ),
                  ],
                ),
              ),
              // Content
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _bootstrap,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Filter Pills
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: FilterPillRow(
                          labels: const ['Tous', 'Bus', 'Minibus', 'Express'],
                          initialIndex: _selectedFilterIndex,
                          onFilterChanged: (index) {
                            setState(() => _selectedFilterIndex = index);
                          },
                        ),
                      ),
                      // Popular Trips Section
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(
                          'Trajets populaires',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textMain,
                          ),
                        ),
                      ),
                      if (_loadingTrips)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 32),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      else if (_loadError.isNotEmpty)
                        Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.redLight,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.red.withValues(alpha: 0.35)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Impossible de charger les trajets',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.red,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _loadError,
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  color: AppColors.textSub,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'API mobile: ${AppConfig.apiBaseUrl}',
                                style: GoogleFonts.poppins(
                                  fontSize: 10,
                                  color: AppColors.textSub,
                                ),
                              ),
                              const SizedBox(height: 8),
                              GestureDetector(
                                onTap: _bootstrap,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                                  decoration: BoxDecoration(
                                    color: AppColors.navy,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'Reessayer',
                                    style: GoogleFonts.poppins(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      else if (_popularTrips.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 32),
                          child: Center(
                            child: Text(
                              'Aucun trajet disponible',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: AppColors.textSub,
                              ),
                            ),
                          ),
                        )
                      else
                        for (int i = 0; i < _popularTrips.length; i++)
                          Padding(
                            padding: EdgeInsets.only(bottom: i < _popularTrips.length - 1 ? 12 : 0),
                            child: RouteCard(
                              departureCity: _popularTrips[i]['from'] ?? 'Départ',
                              arrivalCity: _popularTrips[i]['to'] ?? 'Arrivée',
                              price: _popularTrips[i]['price']?.toString().replaceAll(' ₣', '').replaceAll(' F', '').trim() ?? '0',
                              departureTime: '08h00',
                              journeyDuration: _popularTrips[i]['duration'] ?? '6h',
                              onTap: () => Navigator.pushNamed(context, '/results'),
                            ),
                          ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          // Chat Floating Button
          Positioned(
            bottom: 80,
            right: 16,
            child: FloatingActionButton(
              onPressed: () => Navigator.pushNamed(context, '/chat'),
              backgroundColor: AppColors.orange,
              child: const Icon(Icons.chat_bubble_outline, color: Colors.white),
            ),
          ),
        ],
      ),
      // Custom Bottom Navigation Bar
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _navIndex,
        onTap: (index) {
          setState(() => _navIndex = index);
          if (index == 1) {
            Navigator.pushNamed(
              context,
              '/results',
              arguments: {
                'from': _from,
                'to': _to,
                'date': _selectedDate?.toIso8601String(),
              },
            );
          } else if (index == 2) {
            Navigator.pushNamed(context, '/tickets');
          } else if (index == 3) {
            Navigator.pushNamed(context, '/profile');
          }
        },
      ),
    );
  }

}
