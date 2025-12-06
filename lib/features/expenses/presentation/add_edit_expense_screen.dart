import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/widgets/app_loading.dart';
import '../../members/providers/member_providers.dart';
import '../../mess/providers/mess_providers.dart';
import '../data/expense_repository.dart';
import '../models/expense.dart';

class AddEditExpenseScreen extends ConsumerStatefulWidget {
  const AddEditExpenseScreen({super.key, this.expenseId});

  final String? expenseId;

  @override
  ConsumerState<AddEditExpenseScreen> createState() => _AddEditExpenseScreenState();
}

class _AddEditExpenseScreenState extends ConsumerState<AddEditExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  String _date = DateFormatter.dayString(DateTime.now());
  final _dateCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  String _category = expenseCategories.first;
  String? _paidByMemberId;
  String? _billUrl;
  bool _loading = false;
  Expense? _existing;

  @override
  void dispose() {
    _dateCtrl.dispose();
    _amountCtrl.dispose();
    _descriptionCtrl.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_dateCtrl.text.isEmpty) _dateCtrl.text = _date;
    _loadExisting();
  }

  Future<void> _loadExisting() async {
    if (widget.expenseId == null || _existing != null) return;
    final expense = await ref.read(expenseRepositoryProvider).fetchExpense(widget.expenseId!);
    if (expense != null && mounted) {
      setState(() {
        _existing = expense;
        _date = expense.date;
        _dateCtrl.text = expense.date;
        _amountCtrl.text = expense.amount.toString();
        _descriptionCtrl.text = expense.description ?? '';
        _category = expense.category;
        _paidByMemberId = expense.paidByMemberId;
        _billUrl = expense.billImageUrl;
      });
    }
  }

  Future<void> _pickDate() async {
    final initial = DateTime.tryParse(_date) ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _date = DateFormatter.dayString(picked);
        _dateCtrl.text = _date;
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final mess = ref.read(currentMessProvider).value;
    if (mess == null) return;
    setState(() => _loading = true);
    final expense = Expense(
      id: _existing?.id ?? '',
      messId: mess.id,
      date: _date,
      amount: double.tryParse(_amountCtrl.text) ?? 0,
      category: _category,
      paidByMemberId: _paidByMemberId,
      description: _descriptionCtrl.text.trim().isEmpty ? null : _descriptionCtrl.text.trim(),
      billImageUrl: _billUrl,
      createdAt: _existing?.createdAt,
    );
    try {
      await ref.read(expenseRepositoryProvider).upsertExpense(expense);
      if (mounted) context.pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final mess = ref.watch(currentMessProvider).value;
    if (mess == null) {
      return const Scaffold(body: Center(child: Text('Select a mess first.')));
    }
    final members = ref.watch(membersProvider(mess.id));

    return Scaffold(
      appBar: AppBar(title: Text(widget.expenseId == null ? 'Add Expense' : 'Edit Expense')),
      body: members.when(
        data: (items) {
          _paidByMemberId ??= items.isNotEmpty ? items.first.userId : null;
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: ListView(
                children: [
                  DropdownButtonFormField<String>(
                    value: _category,
                    decoration: const InputDecoration(labelText: 'Category'),
                    items: expenseCategories
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (v) => setState(() => _category = v ?? _category),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _amountCtrl,
                    decoration: const InputDecoration(labelText: 'Amount'),
                    keyboardType: TextInputType.number,
                    validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _paidByMemberId,
                    decoration: const InputDecoration(labelText: 'Paid by'),
                    items: items
                        .map((m) => DropdownMenuItem(value: m.userId, child: Text(m.name)))
                        .toList(),
                    onChanged: (v) => setState(() => _paidByMemberId = v),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _dateCtrl,
                    readOnly: true,
                    decoration: InputDecoration(
                      labelText: 'Date',
                      suffixIcon: IconButton(
                        onPressed: _pickDate,
                        icon: const Icon(Icons.calendar_month),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _descriptionCtrl,
                    decoration: const InputDecoration(labelText: 'Description'),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    initialValue: _billUrl,
                    decoration: const InputDecoration(
                      labelText: 'Bill image URL (optional)',
                      helperText: 'Upload to Firebase Storage and paste the URL',
                    ),
                    onChanged: (v) => _billUrl = v,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _loading ? null : _submit,
                    child: Text(_loading ? 'Saving...' : 'Save expense'),
                  )
                ],
              ),
            ),
          );
        },
        loading: () => const AppLoading(),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}
