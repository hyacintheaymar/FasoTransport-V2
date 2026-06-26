import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/api_client.dart';
import '../../services/session.dart';
import '../../widgets/common_widgets.dart';
import '../../theme/app_theme.dart';
import '../ticket_screen.dart';

class ResultsScreen extends StatefulWidget {
  const ResultsScreen({super.key});

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  final ApiClient _apiClient = ApiClient();
  final SessionStore _sessionStore = SessionStore();
  List<dynamic> _filtered = [];
  bool _loading = true;
  String _status = 'Recherche des trajets...';
  bool _argsReady = false;
  String _fromFilter = '';
  String _toFilter = '';
  DateTime? _dateFilter;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_argsReady) return;
    _argsReady = true;
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map) {
      _fromFilter = args['from']?.toString().trim() ?? '';
      _toFilter = args['to']?.toString().trim() ?? '';
      final dateRaw = args['date']?.toString();
      if (dateRaw != null && dateRaw.isNotEmpty) {
        try {
          _dateFilter = DateTime.parse(dateRaw).toLocal();
        } catch (_) {
          _dateFilter = null;
        }
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _status = 'Recherche des trajets...';
    });
    try {
      final token = await _sessionStore.getToken();
      final schedules = await _apiClient.getSchedules(token: token);
      final filtered = schedules.where((item) {
        final trip = item as Map<String, dynamic>;
        final from = _routeFrom(trip).toLowerCase();
        final to = _routeTo(trip).toLowerCase();

        final fromOk = _fromFilter.trim().isEmpty || from.contains(_fromFilter.toLowerCase());
        final toOk = _toFilter.trim().isEmpty || to.contains(_toFilter.toLowerCase());

        bool dateOk = true;
        if (_dateFilter != null) {
          final dep = _parseDate(trip['departureTime']);
          dateOk = dep != null && dep.year == _dateFilter!.year && dep.month == _dateFilter!.month && dep.day == _dateFilter!.day;
        }
        return fromOk && toOk && dateOk;
      }).toList();

      if (!mounted) return;
      setState(() {
        _filtered = filtered;
        _status = filtered.isEmpty ? 'Aucun trajet trouvé' : 'Résultats disponibles';
      });
    } catch (e) {
      if (!mounted) return;
      final errStr = e.toString();
      if (errStr.contains('401')) {
        await _sessionStore.clearToken();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
        });
        return;
      }
      setState(() => _status = errStr.replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final count = _filtered.length;
    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            Text(
              'Résultats de trajets',
              style: GoogleFonts.syne(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white),
            ),
            Text(
              '$count disponibilité(s)',
              style: GoogleFonts.dmSans(fontSize: 10, color: Colors.white.withValues(alpha: 0.6)),
            ),
          ],
        ),
        backgroundColor: AppColors.navy,
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            Text(_status, style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.textSub)),
            const SizedBox(height: 10),
            if (_loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(child: CircularProgressIndicator()),
              )
            else ...[
              for (int i = 0; i < _filtered.length; i++)
                _TripResultCard(
                  trip: _filtered[i] as Map<String, dynamic>,
                  featured: i == 0,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => SeatSelectionScreen(schedule: _filtered[i] as Map<String, dynamic>)),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  DateTime? _parseDate(dynamic value) {
    try {
      if (value == null) return null;
      return DateTime.parse(value.toString()).toLocal();
    } catch (_) {
      return null;
    }
  }

  String _routeFrom(Map<String, dynamic> map) =>
      map['from']?.toString() ?? map['origin']?.toString() ?? map['departCity']?.toString() ?? 'Départ';

  String _routeTo(Map<String, dynamic> map) =>
      map['to']?.toString() ?? map['destination']?.toString() ?? map['arrivalCity']?.toString() ?? 'Arrivée';
}

class _TripResultCard extends StatelessWidget {
  final Map<String, dynamic> trip;
  final bool featured;
  final VoidCallback onTap;

  const _TripResultCard({required this.trip, required this.featured, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final from = trip['from']?.toString() ?? trip['origin']?.toString() ?? trip['departCity']?.toString() ?? 'Départ';
    final to = trip['to']?.toString() ?? trip['destination']?.toString() ?? trip['arrivalCity']?.toString() ?? 'Arrivée';
    final departure = _formatDateTime(trip['departureTime']);
    final price = trip['price']?.toString() ?? '--';
    final seats = trip['availableSeats']?.toString() ?? '--';
    final bus = trip['busLabel']?.toString() ?? 'Bus FasoTransport';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: featured ? AppColors.navy : AppColors.gray2, width: featured ? 1.5 : 0.5),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(
            '$from → $to',
            style: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w700, color: featured ? AppColors.navy : AppColors.textMain),
          ),
          Text('$price ₣', style: GoogleFonts.syne(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.navy)),
        ]),
        const SizedBox(height: 6),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('$departure · $bus', style: GoogleFonts.dmSans(fontSize: 10, color: AppColors.textSub)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(color: AppColors.greenLight, borderRadius: BorderRadius.circular(20)),
            child: Text('$seats places', style: GoogleFonts.dmSans(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.green)),
          ),
        ]),
        if (featured) ...[
          const SizedBox(height: 10),
          GestureDetector(
            onTap: onTap,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(color: AppColors.navy, borderRadius: BorderRadius.circular(10)),
              child: Text('Réserver →', textAlign: TextAlign.center, style: GoogleFonts.syne(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
            ),
          ),
        ] else ...[
          const SizedBox(height: 10),
          AppButton(label: 'Choisir ce trajet', onTap: onTap),
        ],
      ]),
    );
  }

  String _formatDateTime(dynamic value) {
    if (value == null) return '--:--';
    try {
      final dt = DateTime.parse(value.toString()).toLocal();
      final hh = dt.hour.toString().padLeft(2, '0');
      final mm = dt.minute.toString().padLeft(2, '0');
      final dd = dt.day.toString().padLeft(2, '0');
      final mo = dt.month.toString().padLeft(2, '0');
      return '$dd/$mo $hh:$mm';
    } catch (_) {
      return value.toString();
    }
  }
}

class SeatSelectionScreen extends StatefulWidget {
  final Map<String, dynamic>? schedule;
  const SeatSelectionScreen({super.key, this.schedule});

  @override
  State<SeatSelectionScreen> createState() => _SeatSelectionScreenState();
}

class _SeatSelectionScreenState extends State<SeatSelectionScreen> {
  final _taken = const [2, 4, 6, 8, 12, 14, 16, 18, 22, 24, 26, 28, 32, 34];
  int? _selectedSeat = 1;

  @override
  Widget build(BuildContext context) {
    final schedule = widget.schedule ?? const <String, dynamic>{};
    final from = schedule['from'] ?? schedule['origin'] ?? schedule['departCity'] ?? 'Départ';
    final to = schedule['to'] ?? schedule['destination'] ?? schedule['arrivalCity'] ?? 'Arrivée';
    return Scaffold(
      appBar: AppBar(
        title: Text('Choisir un siège', style: GoogleFonts.syne(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
      ),
      body: Column(children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(children: [
              AppCard(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('$from → $to', style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text('${schedule['departureTime'] ?? 'Horaire'}', style: GoogleFonts.dmSans(fontSize: 11, color: AppColors.textSub)),
                ]),
              ),
              const SizedBox(height: 14),
              BusSeatMap(takenSeats: _taken, selectedSeat: _selectedSeat, onSeatTap: (n) => setState(() => _selectedSeat = n)),
              const SizedBox(height: 14),
              AppCard(
                child: Column(children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text('Siège sélectionné', style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.textSub)),
                    Text(_selectedSeat != null ? 'Siège $_selectedSeat' : '—', style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.orange)),
                  ]),
                  const Divider(height: 16, color: AppColors.gray2),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text('Total', style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.textSub)),
                    Text('${schedule['price'] ?? '--'} ₣', style: GoogleFonts.syne(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.navy)),
                  ]),
                ]),
              ),
            ]),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: AppButton(
            label: 'Passer au paiement',
            bg: AppColors.orange,
            onTap: _selectedSeat == null
                ? null
                : () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => PaymentScreen(schedule: schedule, seatNumber: _selectedSeat!)),
                    ),
          ),
        ),
      ]),
    );
  }
}

class PaymentScreen extends StatefulWidget {
  final Map<String, dynamic>? schedule;
  final int seatNumber;
  const PaymentScreen({super.key, this.schedule, required this.seatNumber});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  int _method = 0;
  bool _loading = false;
  final ApiClient apiClient = ApiClient();
  final SessionStore sessionStore = SessionStore();
  final TextEditingController _phoneController = TextEditingController();

  Future<void> _pay() async {
    setState(() => _loading = true);
    try {
      final token = await sessionStore.getToken();
      if (token == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Veuillez vous connecter.')));
        }
        return;
      }
      final scheduleId = widget.schedule?['_id']?.toString();
      final fallbackScheduleId = widget.schedule?['id']?.toString();
      final resolvedScheduleId = (scheduleId != null && scheduleId.isNotEmpty)
          ? scheduleId
          : (fallbackScheduleId != null && fallbackScheduleId.isNotEmpty ? fallbackScheduleId : null);

      if (resolvedScheduleId == null || resolvedScheduleId.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Trajet invalide.')));
        }
        return;
      }
      final booking = await apiClient.book(resolvedScheduleId, token, widget.seatNumber);
      if (mounted) {
        final Map<String, dynamic> scheduleData = widget.schedule ?? const <String, dynamic>{};
        final from = scheduleData['from'] ?? scheduleData['origin'] ?? scheduleData['departCity'] ?? 'Depart';
        final to = scheduleData['to'] ?? scheduleData['destination'] ?? scheduleData['arrivalCity'] ?? 'Arrivee';
        final enrichedBooking = <String, dynamic>{
          ...booking,
          'origin': scheduleData['origin'] ?? scheduleData['from'] ?? scheduleData['departCity'],
          'destination': scheduleData['destination'] ?? scheduleData['to'] ?? scheduleData['arrivalCity'],
          'departureTime': scheduleData['departureTime'],
          'routeLabel': '$from-$to',
        };
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => TicketScreen(booking: enrichedBooking)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))));
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic> scheduleData = widget.schedule ?? const <String, dynamic>{};
    final from = scheduleData['from'] ?? scheduleData['origin'] ?? scheduleData['departCity'] ?? 'Départ';
    final to = scheduleData['to'] ?? scheduleData['destination'] ?? scheduleData['arrivalCity'] ?? 'Arrivée';
    final methodLabel = _method == 0 ? 'Orange Money' : 'Moov Money';
    final price = scheduleData['price']?.toString() ?? '--';

    return Scaffold(
      appBar: AppBar(title: Text('Paiement', style: GoogleFonts.syne(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white))),
      body: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Mode de paiement', style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSub)),
          const SizedBox(height: 10),
          _PaymentOption(
            icon: '📱',
            label: 'Orange Money',
            iconBg: const Color(0xFFFF6600),
            selected: _method == 0,
            onTap: () => setState(() => _method = 0),
          ),
          const SizedBox(height: 8),
          _PaymentOption(
            icon: '📱',
            label: 'Moov Money',
            iconBg: const Color(0xFF009EE3),
            selected: _method == 1,
            onTap: () => setState(() => _method = 1),
          ),
          const SizedBox(height: 14),
          LabeledInput(
            label: 'Numéro $methodLabel',
            hint: '7X XX XX XX',
            keyboardType: TextInputType.phone,
            controller: _phoneController,
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppColors.navyLight, borderRadius: BorderRadius.circular(12)),
            child: Column(children: [
              Text('Récapitulatif', style: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.navy2)),
              const SizedBox(height: 6),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text(
                  '$from → $to · Siège ${widget.seatNumber}',
                  style: GoogleFonts.dmSans(fontSize: 11, color: AppColors.textSub),
                ),
                Text('$price ₣', style: GoogleFonts.syne(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.navy)),
              ]),
            ]),
          ),
          const Spacer(),
          _loading
              ? const Center(child: CircularProgressIndicator(color: AppColors.orange))
              : AppButton(label: 'Confirmer le paiement', bg: AppColors.orange, onTap: _pay),
          const SizedBox(height: 8),
          Text('Vous recevrez un OTP par SMS pour confirmer', textAlign: TextAlign.center, style: GoogleFonts.dmSans(fontSize: 10, color: AppColors.textSub)),
        ]),
      ),
    );
  }
}

class _PaymentOption extends StatelessWidget {
  final String icon;
  final String label;
  final Color iconBg;
  final bool selected;
  final VoidCallback onTap;
  const _PaymentOption({required this.icon, required this.label, required this.iconBg, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: AppCard(
          borderColor: selected ? AppColors.orange : AppColors.gray2,
          borderWidth: selected ? 1.5 : 0.5,
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Row(children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(10)),
                child: Center(child: Text(icon, style: const TextStyle(fontSize: 16))),
              ),
              const SizedBox(width: 10),
              Text(
                label,
                style: GoogleFonts.dmSans(
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected ? AppColors.textMain : AppColors.textSub,
                ),
              ),
            ]),
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? AppColors.orange : Colors.transparent,
                border: Border.all(color: selected ? AppColors.orange : AppColors.gray3, width: selected ? 4.5 : 1.5),
              ),
            ),
          ]),
        ),
      );
}

class MyTicketsScreen extends StatefulWidget {
  const MyTicketsScreen({super.key});

  @override
  State<MyTicketsScreen> createState() => _MyTicketsScreenState();
}

class _MyTicketsScreenState extends State<MyTicketsScreen> {
  final ApiClient _apiClient = ApiClient();
  final SessionStore _sessionStore = SessionStore();
  bool _loading = true;
  String _status = 'Chargement de vos billets...';
  List<Map<String, dynamic>> _tickets = [];

  void _redirectToLogin() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/login');
    });
  }

  @override
  void initState() {
    super.initState();
    _loadTickets();
  }

  Future<void> _loadTickets() async {
    setState(() {
      _loading = true;
      _status = 'Chargement de vos billets...';
    });
    try {
      final token = await _sessionStore.getToken();
      if (token == null || token.isEmpty) {
        _redirectToLogin();
        return;
      }
      final list = await _apiClient.getMyBookings(token);
      if (!mounted) return;

      final mapped = list.map((item) {
        final b = item as Map<String, dynamic>;
        final created = _formatDate(b['createdAt']);
        final status = (b['validatedAt'] != null)
            ? {'label': 'VALIDÉ', 'type': PillType.green}
            : {'label': 'CONFIRMÉ', 'type': PillType.blue};

        return {
          'booking': b,
          'route': b['scheduleId']?.toString() ?? b['id']?.toString() ?? 'Trajet réservé',
          'date': created,
          'seat': 'Siège ${b['seatNumber'] ?? '--'}',
          'status': status['label'] as String,
          'type': status['type'] as PillType,
        };
      }).toList();

      setState(() {
        _tickets = mapped;
        _status = mapped.isEmpty ? 'Aucun billet pour le moment.' : 'Mes billets';
      });
    } catch (e) {
      if (!mounted) return;
      final errStr = e.toString();
      if (errStr.contains('401')) {
        await _sessionStore.clearToken();
        _redirectToLogin();
        return;
      }
      setState(() => _status = errStr.replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  String _formatDate(dynamic raw) {
    if (raw == null) return 'Date inconnue';
    try {
      final dt = DateTime.parse(raw.toString()).toLocal();
      final hh = dt.hour.toString().padLeft(2, '0');
      final mm = dt.minute.toString().padLeft(2, '0');
      final dd = dt.day.toString().padLeft(2, '0');
      final mo = dt.month.toString().padLeft(2, '0');
      return '$dd/$mo · $hh:$mm';
    } catch (_) {
      return raw.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Mes billets', style: GoogleFonts.syne(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white))),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Text(_status, style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.textSub)),
          const SizedBox(height: 10),
          if (_loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: CircularProgressIndicator()),
            )
          else
            for (final t in _tickets)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: AppCard(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(t['route'] as String, style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 3),
                        Text('${t['date']} · ${t['seat']}', style: GoogleFonts.dmSans(fontSize: 10, color: AppColors.textSub)),
                      ],
                    ),
                    StatusPill(label: t['status'] as String, type: t['type'] as PillType),
                  ],
                ),
              ),
            ),
          if (!_loading && _tickets.isNotEmpty) ...[
            const SizedBox(height: 10),
            AppButton(
              label: 'Voir mon dernier billet',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => TicketScreen(booking: _tickets.first['booking'] as Map<String, dynamic>)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
