class ReportFilter {
  final String? academyId;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? subscriptionStatus; // 'active' | 'expired' | null (all)

  const ReportFilter({
    this.academyId,
    this.startDate,
    this.endDate,
    this.subscriptionStatus,
  });

  ReportFilter copyWith({
    Object? academyId = _sentinel,
    Object? startDate = _sentinel,
    Object? endDate = _sentinel,
    Object? subscriptionStatus = _sentinel,
  }) {
    return ReportFilter(
      academyId:
          academyId == _sentinel ? this.academyId : academyId as String?,
      startDate:
          startDate == _sentinel ? this.startDate : startDate as DateTime?,
      endDate: endDate == _sentinel ? this.endDate : endDate as DateTime?,
      subscriptionStatus: subscriptionStatus == _sentinel
          ? this.subscriptionStatus
          : subscriptionStatus as String?,
    );
  }
}

const _sentinel = Object();
