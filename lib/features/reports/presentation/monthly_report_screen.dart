import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/date_formatter.dart';
import '../../../core/widgets/app_loading.dart';
import '../../mess/providers/mess_providers.dart';
import '../data/report_service.dart';
import '../models/monthly_member_report.dart';

class MonthlyReportScreen extends ConsumerStatefulWidget {
  const MonthlyReportScreen({super.key});

  @override
  ConsumerState<MonthlyReportScreen> createState() => _MonthlyReportScreenState();
}

class _MonthlyReportScreenState extends ConsumerState<MonthlyReportScreen> {
  late TextEditingController _monthCtrl;

  @override
  void initState() {
    super.initState();
    _monthCtrl = TextEditingController(text: DateFormatter.monthString(DateTime.now()));
  }

  @override
  void dispose() {
    _monthCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mess = ref.watch(currentMessProvider).value;
    if (mess == null) {
      return const Scaffold(body: Center(child: Text('Select a mess first.')));
    }
    final report = ref.watch(_reportProvider((messId: mess.id, month: _monthCtrl.text)));

    return Scaffold(
      appBar: AppBar(title: const Text('Monthly Report')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _monthCtrl,
                    decoration: const InputDecoration(labelText: 'Month (YYYY-MM)'),
                    onSubmitted: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () => setState(() {}),
                  child: const Text('Load'),
                )
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: report.when(
                data: (data) => _ReportTable(data: data),
                loading: () => const AppLoading(),
                error: (e, _) => Center(child: Text('Error: $e')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReportTable extends StatelessWidget {
  const _ReportTable({required this.data});

  final _ReportData data;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        Card(
          child: ListTile(
            title: Text('Totals for ${data.month}'),
            subtitle: Text(
                'Meals: ${data.totalMeals.toStringAsFixed(1)} • Expenses: ${data.totalExpenses.toStringAsFixed(0)} • Meal rate: ${data.mealRate.toStringAsFixed(2)}'),
          ),
        ),
        const SizedBox(height: 12),
        DataTable(
          columns: const [
            DataColumn(label: Text('Member')),
            DataColumn(label: Text('Meals')),
            DataColumn(label: Text('Deposits')),
            DataColumn(label: Text('Cost')),
            DataColumn(label: Text('Balance')),
          ],
          rows: data.members
              .map(
                (row) => DataRow(
                  cells: [
                    DataCell(Text(row.memberName)),
                    DataCell(Text(row.totalMeals.toStringAsFixed(1))),
                    DataCell(Text(row.totalDeposits.toStringAsFixed(0))),
                    DataCell(Text(row.cost.toStringAsFixed(0))),
                    DataCell(Text(
                      row.balance.toStringAsFixed(0),
                      style: TextStyle(
                        color: row.balance >= 0 ? Colors.green : Colors.red,
                      ),
                    )),
                  ],
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 16),
        Text(
          data.exportText,
          style: const TextStyle(fontFamily: 'monospace'),
        )
      ],
    );
  }
}

class _ReportData {
  _ReportData({
    required this.month,
    required this.totalMeals,
    required this.totalExpenses,
    required this.mealRate,
    required this.members,
  });

  final String month;
  final double totalMeals;
  final double totalExpenses;
  final double mealRate;
  final List<MonthlyMemberReport> members;

  String get exportText {
    final buffer = StringBuffer('Member,Meals,Deposits,Cost,Balance\n');
    for (final row in members) {
      buffer.writeln(
          '${row.memberName},${row.totalMeals.toStringAsFixed(1)},${row.totalDeposits.toStringAsFixed(0)},${row.cost.toStringAsFixed(0)},${row.balance.toStringAsFixed(0)}');
    }
    return buffer.toString();
  }
}

final _reportProvider = FutureProvider.family<_ReportData, ({String messId, String month})>((ref, args) async {
  final service = ref.read(reportServiceProvider);
  final members = await service.monthlyBreakdown(args.messId, args.month);
  final totalMeals = await service.totalMealsForMess(args.messId, args.month);
  final totalExpenses = await service.totalExpensesForMess(args.messId, args.month);
  final mealRate = await service.mealRateForMess(args.messId, args.month);
  return _ReportData(
    month: args.month,
    totalMeals: totalMeals,
    totalExpenses: totalExpenses,
    mealRate: mealRate,
    members: members,
  );
});
