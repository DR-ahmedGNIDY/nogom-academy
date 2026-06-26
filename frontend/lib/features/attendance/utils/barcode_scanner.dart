import 'barcode_scan_result.dart';
import 'barcode_scanner_io.dart' if (dart.library.js_interop) 'barcode_scanner_web.dart' as impl;

Future<BarcodeScanResult> scanAttendanceBarcode() => impl.scanBarcode();
