import 'package:basketball_academy/core/di/injection_container.dart';
import 'package:basketball_academy/features/payroll/domain/entities/payroll_entity.dart';
import 'package:basketball_academy/features/payroll/domain/repositories/payroll_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PayrollState {
  final List<PayrollEntity> records;
  final String? month;
  final String? academyId;
  const PayrollState({this.records = const [], this.month, this.academyId});
}

class PayrollNotifier extends AsyncNotifier<PayrollState> {
  PayrollRepository get _repo => sl<PayrollRepository>();

  @override
  Future<PayrollState> build() async => const PayrollState();

  Future<void> load({required String academyId, required String month}) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final result = await _repo.getPayrollList(academyId: academyId, month: month);
      return result.fold((failure) => throw Exception(failure.message), (data) => PayrollState(records: data, month: month, academyId: academyId));
    });
  }

  Future<void> refresh() async {
    final month = state.valueOrNull?.month;
    final academyId = state.valueOrNull?.academyId;
    if (month != null && academyId != null) await load(academyId: academyId, month: month);
  }

  Future<String?> generate({required String academyId, required String month}) async {
    final result = await _repo.generatePayroll(academyId: academyId, month: month);
    return result.fold((failure) => failure.message, (_) {
      load(academyId: academyId, month: month);
      return null;
    });
  }

  Future<String?> markPaid(String id) async {
    final result = await _repo.markPaid(id);
    return result.fold((failure) => failure.message, (_) {
      refresh();
      return null;
    });
  }
}

final payrollProvider = AsyncNotifierProvider<PayrollNotifier, PayrollState>(PayrollNotifier.new);

class PayrollReportNotifier extends AsyncNotifier<({List<PayrollReportRow> report, double totalBaseSalary, double totalDeductions, double totalNetSalary})> {
  PayrollRepository get _repo => sl<PayrollRepository>();

  @override
  Future<({List<PayrollReportRow> report, double totalBaseSalary, double totalDeductions, double totalNetSalary})> build() async =>
      (report: const <PayrollReportRow>[], totalBaseSalary: 0.0, totalDeductions: 0.0, totalNetSalary: 0.0);

  Future<void> load(String academyId, String month) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final result = await _repo.getPayrollReport(academyId, month);
      return result.fold((failure) => throw Exception(failure.message), (data) => data);
    });
  }
}

final payrollReportProvider = AsyncNotifierProvider<PayrollReportNotifier,
    ({List<PayrollReportRow> report, double totalBaseSalary, double totalDeductions, double totalNetSalary})>(PayrollReportNotifier.new);
