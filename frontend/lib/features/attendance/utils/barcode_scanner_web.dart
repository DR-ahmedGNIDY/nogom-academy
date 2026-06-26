import 'barcode_scan_result.dart';

/// QR camera scanning is Android-only in this app; the web build never
/// shows the camera button, so this implementation is never invoked.
Future<BarcodeScanResult> scanBarcode() async {
  return const BarcodeScanResult(BarcodeScanOutcome.error, '');
}
