import 'dart:html' as html;
import 'dart:typed_data';

Future<void> openReportBytes(
  Uint8List bytes,
  String filename, {
  String? mimeType,
}) async {
  final type = mimeType ?? 'application/pdf';
  final blob = html.Blob([bytes], type);
  final url = html.Url.createObjectUrlFromBlob(blob);
  html.window.open(url, '_blank');
}
