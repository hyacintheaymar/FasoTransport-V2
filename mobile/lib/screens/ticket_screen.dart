import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart' as pdf;
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';

class TicketScreen extends StatefulWidget {
  final Map<String, dynamic>? booking;

  const TicketScreen({super.key, this.booking});

  @override
  State<TicketScreen> createState() => _TicketScreenState();
}

class _TicketScreenState extends State<TicketScreen> {
  bool _busy = false;

  Map<String, dynamic> get _data => widget.booking ?? const <String, dynamic>{
        'bookingCode': 'TEMP-000',
        'seatNumber': '--',
        'amount': '--',
        'qrImageBase64': '',
      };

  Uint8List? _qrBytes(String rawBase64) {
    if (rawBase64.trim().isEmpty) return null;
    try {
      return base64Decode(rawBase64.split(',').last);
    } catch (_) {
      return null;
    }
  }

  String _safeSegment(String value, {String fallback = 'na'}) {
    final cleaned = value
        .toLowerCase()
        .replaceAll(RegExp(r'\s+'), '_')
        .replaceAll(RegExp(r'[^a-z0-9_-]'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
    if (cleaned.isEmpty) {
      return fallback;
    }
    return cleaned.length > 32 ? cleaned.substring(0, 32) : cleaned;
  }

  String _routeSegment() {
    final data = _data;
    final from = data['from']?.toString() ?? data['origin']?.toString() ?? data['departCity']?.toString() ?? '';
    final to = data['to']?.toString() ?? data['destination']?.toString() ?? data['arrivalCity']?.toString() ?? '';

    if (from.trim().isNotEmpty && to.trim().isNotEmpty) {
      return '${_safeSegment(from)}-${_safeSegment(to)}';
    }

    final routeLabel = data['routeLabel']?.toString() ?? data['route']?.toString() ?? '';
    if (routeLabel.trim().isNotEmpty) {
      return _safeSegment(routeLabel);
    }

    return 'trajet';
  }

  String _dateSegment() {
    final data = _data;
    final raw = data['departureTime'] ?? data['createdAt'];
    if (raw == null) {
      final now = DateTime.now();
      return '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
    }

    try {
      final dt = DateTime.parse(raw.toString()).toLocal();
      return '${dt.year}${dt.month.toString().padLeft(2, '0')}${dt.day.toString().padLeft(2, '0')}';
    } catch (_) {
      final now = DateTime.now();
      return '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
    }
  }

  Future<File> _buildTicketPdf() async {
    final data = _data;
    final document = pw.Document();
    final qr = _qrBytes(data['qrImageBase64']?.toString() ?? '');
    final qrImage = qr == null ? null : pw.MemoryImage(qr);
    final ticketCode = data['bookingCode']?.toString() ?? 'TEMP-000';
    final seat = data['seatNumber']?.toString() ?? '--';
    final amount = data['amount']?.toString() ?? '--';
    final generatedAt = DateTime.now();

    document.addPage(
      pw.MultiPage(
        build: (context) => [
          pw.Container(
            padding: const pw.EdgeInsets.all(14),
            color: const pdf.PdfColor.fromInt(0xFF0D3A6E),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'FasoTransport',
                  style: pw.TextStyle(
                    color: pdf.PdfColors.white,
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  'Billet electronique',
                  style: pw.TextStyle(color: pdf.PdfColors.white, fontSize: 11),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 14),
          pw.Text('Code billet: $ticketCode', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          pw.Text('Place: $seat'),
          pw.Text('Montant: $amount FCFA'),
          pw.Text(
            'Genere le: ${generatedAt.day.toString().padLeft(2, '0')}/${generatedAt.month.toString().padLeft(2, '0')}/${generatedAt.year} ${generatedAt.hour.toString().padLeft(2, '0')}:${generatedAt.minute.toString().padLeft(2, '0')}',
          ),
          pw.SizedBox(height: 18),
          pw.Text('QR de controle', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          if (qrImage != null)
            pw.Center(
              child: pw.Container(
                width: 180,
                height: 180,
                decoration: pw.BoxDecoration(border: pw.Border.all(color: pdf.PdfColors.grey400)),
                padding: const pw.EdgeInsets.all(6),
                child: pw.Image(qrImage),
              ),
            )
          else
            pw.Text('QR indisponible'),
        ],
      ),
    );

    final safeCode = _safeSegment(ticketCode, fallback: 'code');
    final route = _routeSegment();
    final date = _dateSegment();
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/billet_${route}_${date}_$safeCode.pdf');
    await file.writeAsBytes(await document.save(), flush: true);
    return file;
  }

  Future<void> _downloadPdf() async {
    setState(() => _busy = true);
    try {
      final file = await _buildTicketPdf();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Billet PDF enregistré: $file.path')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur génération PDF: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _sharePdf({required String channelLabel}) async {
    setState(() => _busy = true);
    try {
      final file = await _buildTicketPdf();
      final code = _data['bookingCode']?.toString() ?? '--';
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'Billet FasoTransport - $code',
        text: 'Mon billet FasoTransport ($code). Partage via $channelLabel.',
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur partage: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = _data;
    final qrBytes = _qrBytes(data['qrImageBase64']?.toString() ?? '');

    return Scaffold(
      appBar: AppBar(title: Text('Mon billet', style: GoogleFonts.syne(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white))),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.navy,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('FasoTransport', style: GoogleFonts.syne(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
                const SizedBox(height: 4),
                Text('Billet électronique', style: GoogleFonts.dmSans(fontSize: 11, color: Colors.white.withValues(alpha: 0.75))),
              ],
            ),
          ),
          const SizedBox(height: 10),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const StatusPill(label: 'Billet confirmé', type: PillType.green),
                const SizedBox(height: 10),
                Text('Code: ${data['bookingCode']}', style: GoogleFonts.syne(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.navy)),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text('Place: ${data['seatNumber']}', style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.textSub)),
                  Text('Montant: ${data['amount']} FCFA', style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textMain)),
                ]),
              ],
            ),
          ),
          const SizedBox(height: 10),
          AppCard(
            child: Column(
              children: [
                Text('QR de contrôle', style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.textSub)),
                const SizedBox(height: 8),
                if (qrBytes != null)
                  Container(
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.gray2, width: 0.8)),
                    clipBehavior: Clip.antiAlias,
                    child: Image.memory(
                      qrBytes,
                      height: 200,
                      width: 200,
                      fit: BoxFit.cover,
                    ),
                  )
                else
                  const Padding(
                    padding: EdgeInsets.all(32),
                    child: Icon(Icons.qr_code_2_rounded, size: 72, color: AppColors.gray3),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          if (_busy)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Center(child: CircularProgressIndicator()),
            ),
          AppButton(
            label: 'Télécharger le billet PDF',
            onTap: () {
              if (_busy) return;
              _downloadPdf();
            },
          ),
          const SizedBox(height: 8),
          AppButton(
            label: 'Envoyer via WhatsApp',
            onTap: () {
              if (_busy) return;
              _sharePdf(channelLabel: 'WhatsApp');
            },
          ),
          const SizedBox(height: 8),
          AppButton(
            label: 'Envoyer par Email',
            onTap: () {
              if (_busy) return;
              _sharePdf(channelLabel: 'Email');
            },
          ),
          const SizedBox(height: 10),
          AppButton(label: 'Retour à l\'accueil', onTap: () => Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false)),
        ],
      ),
    );
  }
}
