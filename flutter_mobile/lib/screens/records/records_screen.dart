import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/app_colors.dart';
import '../../utils/theme_context.dart';
import '../../providers/auth_provider.dart';
import '../../providers/health_record_provider.dart';
import '../../providers/service_providers.dart';
import '../../services/health_record_service.dart';
import '../../widgets/common/app_loader.dart';
import '../../utils/report_file_opener.dart';
import '../../widgets/animations/upload_progress_button.dart';
import '../../widgets/common/app_snackbar.dart';

/// Health records + upload — styled to match MediChain+ (Poppins, teal/navy).
class RecordsScreen extends ConsumerStatefulWidget {
  const RecordsScreen({super.key});

  @override
  ConsumerState<RecordsScreen> createState() => _RecordsScreenState();
}

class _RecordsScreenState extends ConsumerState<RecordsScreen> {
  final _title = TextEditingController();
  String _recordType = 'lab_report';
  bool _uploading = false;
  bool _uploadSuccess = false;
  bool _openingReport = false;

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  String _reportFileName(HealthRecordItem record) {
    if (record.files.isNotEmpty) {
      final name = record.files.first['fileName']?.toString();
      if (name != null && name.isNotEmpty) return name;
    }
    return 'report.pdf';
  }

  String? _reportMimeType(String fileName) {
    final lower = fileName.toLowerCase();
    if (lower.endsWith('.pdf')) return 'application/pdf';
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return 'image/jpeg';
    return null;
  }

  Future<void> _viewReport(HealthRecordItem record) async {
    if (record.files.isEmpty) {
      AppSnackbar.show(context, 'No file attached to this report');
      return;
    }
    if (record.id.isEmpty) {
      AppSnackbar.show(context, 'Report id missing — refresh and try again');
      return;
    }
    if (_openingReport) return;

    setState(() => _openingReport = true);
    try {
      final bytes = await ref
          .read(healthRecordServiceProvider)
          .downloadReportFile(record.id);
      final fileName = _reportFileName(record);
      await openReportBytes(
        bytes,
        fileName,
        mimeType: _reportMimeType(fileName),
      );
    } catch (e) {
      if (mounted) {
        AppSnackbar.show(context, e.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _openingReport = false);
    }
  }

  Future<void> _pickAndUpload() async {
    final user = ref.read(authProvider).user;
    if (user == null) {
      AppSnackbar.show(context, 'Please log in');
      return;
    }
    if (_title.text.trim().isEmpty) {
      AppSnackbar.show(context, 'Enter a report title');
      return;
    }

    final picked = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'doc', 'docx'],
    );
    if (picked == null || picked.files.isEmpty) return;

    setState(() {
      _uploading = true;
      _uploadSuccess = false;
    });
    try {
      await ref.read(healthRecordServiceProvider).upload(
            userId: user.id,
            docId: '0',
            doctorName: 'General',
            title: _title.text.trim(),
            recordType: _recordType,
            files: picked.files,
          );
      ref.invalidate(healthRecordsProvider);
      if (mounted) {
        setState(() {
          _uploading = false;
          _uploadSuccess = true;
        });
        AppSnackbar.show(context, 'Reports uploaded successfully', success: true);
        _title.clear();
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) setState(() => _uploadSuccess = false);
        });
      }
    } catch (e) {
      if (mounted) AppSnackbar.show(context, e.toString());
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final records = ref.watch(healthRecordsProvider);

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.logoTeal,
          onRefresh: () async => ref.invalidate(healthRecordsProvider),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            children: [
              Text(
                'Records',
                style: GoogleFonts.poppins(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: context.primaryText,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Store and share your medical documents securely',
                style: GoogleFonts.poppins(fontSize: 14, color: context.secondaryText),
              ),
              const SizedBox(height: 24),
              _card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.logoTeal.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.cloud_upload_outlined, color: AppColors.logoTeal, size: 24),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Upload Report',
                          style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _title,
                      style: GoogleFonts.poppins(fontSize: 15),
                      decoration: InputDecoration(
                        labelText: 'Title',
                        hintText: 'e.g. Blood test results',
                        labelStyle: GoogleFonts.poppins(color: context.secondaryText),
                        hintStyle: GoogleFonts.poppins(color: context.hintText, fontSize: 14),
                      ),
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      value: _recordType,
                      style: GoogleFonts.poppins(fontSize: 15, color: context.primaryText),
                      decoration: InputDecoration(
                        labelText: 'Type',
                        labelStyle: GoogleFonts.poppins(color: context.secondaryText),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'lab_report', child: Text('Lab report')),
                        DropdownMenuItem(value: 'prescription', child: Text('Prescription')),
                        DropdownMenuItem(value: 'xray', child: Text('X-Ray / Scan')),
                        DropdownMenuItem(value: 'other', child: Text('Other')),
                      ],
                      onChanged: (v) => setState(() => _recordType = v ?? 'lab_report'),
                    ),
                    const SizedBox(height: 20),
                    UploadProgressButton(
                      state: _uploadSuccess
                          ? UploadButtonState.success
                          : _uploading
                              ? UploadButtonState.uploading
                              : UploadButtonState.idle,
                      onPressed: _pickAndUpload,
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Icon(Icons.info_outline, size: 16, color: context.secondaryText.withValues(alpha: 0.8)),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'PDF, images, DOCX (max 10MB each)',
                            style: GoogleFonts.poppins(fontSize: 12, color: context.secondaryText),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Your reports',
                style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              records.when(
                loading: () => const Padding(padding: EdgeInsets.all(32), child: AppLoader()),
                error: (e, _) => _emptyState(
                  icon: Icons.error_outline,
                  message: e.toString(),
                ),
                data: (list) {
                  if (list.isEmpty) {
                    return _emptyState(
                      icon: Icons.folder_open_outlined,
                      message: 'No reports uploaded yet',
                      subtitle: 'Upload lab results, prescriptions, or scans above',
                    );
                  }
                  return Column(
                    children: list.map((r) => _reportTile(r)).toList(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _reportTile(HealthRecordItem r) {
    final hasFile = r.files.isNotEmpty;
    final fileName = r.files.isNotEmpty
        ? (r.files.first['fileName'] ?? 'Report file').toString()
        : r.title;
    final dateStr = r.date != null ? _formatRecordDate(r.date!) : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: context.cardDecoration(radius: 14),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: hasFile ? () => _viewReport(r) : null,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: context.highlightBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.description_outlined, color: Color(0xFF2563EB), size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        r.title,
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 15),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        fileName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(fontSize: 12, color: context.secondaryText),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${_formatType(r.recordType)}${dateStr != null ? ' · $dateStr' : ''}',
                        style: GoogleFonts.poppins(fontSize: 11, color: context.hintText),
                      ),
                      if (hasFile) ...[
                        const SizedBox(height: 10),
                        Text(
                          'View report',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryBlue,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Icon(
                  hasFile ? Icons.open_in_new : Icons.check_circle,
                  color: hasFile ? AppColors.primaryBlue : const Color(0xFF16A34A),
                  size: 22,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String? _formatRecordDate(String raw) {
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return raw.length > 10 ? raw.substring(0, 10) : raw;
    return '${parsed.year}-${parsed.month.toString().padLeft(2, '0')}-${parsed.day.toString().padLeft(2, '0')}';
  }

  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: context.cardDecoration(radius: 20),
      child: child,
    );
  }

  Widget _emptyState({required IconData icon, required String message, String? subtitle}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.borderColor),
      ),
      child: Column(
        children: [
          Icon(icon, size: 48, color: context.secondaryText.withValues(alpha: 0.5)),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(fontSize: 15, color: context.secondaryText, fontWeight: FontWeight.w500),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(fontSize: 13, color: context.secondaryText),
            ),
          ],
        ],
      ),
    );
  }

  String _formatType(String type) {
    switch (type) {
      case 'lab_report':
        return 'Lab report';
      case 'prescription':
        return 'Prescription';
      case 'xray':
        return 'X-Ray / Scan';
      default:
        return 'Other';
    }
  }
}
