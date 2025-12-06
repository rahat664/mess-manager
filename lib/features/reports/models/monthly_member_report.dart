class MonthlyMemberReport {
  const MonthlyMemberReport({
    required this.memberId,
    required this.memberName,
    required this.totalMeals,
    required this.totalDeposits,
    required this.cost,
    required this.balance,
  });

  final String memberId;
  final String memberName;
  final double totalMeals;
  final double totalDeposits;
  final double cost;
  final double balance;
}
