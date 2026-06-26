enum BarcodeScanOutcome { success, cancelled, error }

class BarcodeScanResult {
  final BarcodeScanOutcome outcome;
  final String rawContent;

  const BarcodeScanResult(this.outcome, this.rawContent);
}
