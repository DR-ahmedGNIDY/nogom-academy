import 'package:barcode_scan2/barcode_scan2.dart' as scan2;

import 'barcode_scan_result.dart';

Future<BarcodeScanResult> scanBarcode() async {
  final result = await scan2.BarcodeScanner.scan();
  if (result.type == scan2.ResultType.Barcode) {
    return BarcodeScanResult(BarcodeScanOutcome.success, result.rawContent);
  }
  if (result.type == scan2.ResultType.Cancelled) {
    return const BarcodeScanResult(BarcodeScanOutcome.cancelled, '');
  }
  return const BarcodeScanResult(BarcodeScanOutcome.error, '');
}
