import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

Future<void> openReportBytes(
  Uint8List bytes,
  String filename, {
  String? mimeType,
}) async {
  final dir = await getTemporaryDirectory();
  final safeName = filename.replaceAll(RegExp(r'[^\w.\-]'), '_');
  final path = '${dir.path}/$safeName';
  final file = File(path);
  await file.writeAsBytes(bytes);
  final uri = Uri.file(path);
  if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
    throw Exception('Could not open report');
  }
}
