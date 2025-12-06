import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/date_formatter.dart';
import '../../../core/widgets/app_loading.dart';
import '../../members/providers/member_providers.dart';
import '../../mess/providers/mess_providers.dart';
import '../data/deposit_repository.dart';
import '../models/deposit.dart';

class AddEditDepositScreen extends ConsumerStatefulWidget {
  const AddEditDepositScreen({super.key, this.depositId});

  final String? depositId;

  @override
  ConsumerState<AddEditDepositScreen> createState() => _AddEditDepositScreenState();
}

class _AddEditDepositScreenState extends ConsumerState<AddEditDepositScreen> {
  final _formKey = GlobalKey<FormState>();
  String _date = DateFormatter.dayString(DateTime.now());
  final _dateCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  String? _memberId;
  bool _loading = false;
  Deposit? _existing;

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
    if (widget.depositId == null || _existing != null) return;
    final deposit = await ref.read(depositRepositoryProvider).fetchDeposit(widget.depositId!);
    if (deposit != null && mounted) {
      setState(() {
        _existing = deposit;
        _date = deposit.date;
        _dateCtrl.text = deposit.date;
        _amountCtrl.text = deposit.amount.toString();
        _descriptionCtrl.text = deposit.description ?? '';
        _memberId = deposit.memberId;
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
    if (mess == null || _memberId == null) return;
    setState(() => _loading = true);
    final deposit = Deposit(
      id: _existing?.id ?? '',
      messId: mess.id,
      memberId: _memberId!,
      date: _date,
      amount: double.tryParse(_amountCtrl.text) ?? 0,
      description: _descriptionCtrl.text.trim().isEmpty ? null : _descriptionCtrl.text.trim(),
      createdAt: _existing?.createdAt,
    );
    try {
      await ref.read(depositRepositoryProvider).upsertDeposit(deposit);
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
      appBar: AppBar(title: Text(widget.depositId == null ? 'Add Deposit' : 'Edit Deposit')),
      body: members.when(
        data: (items) {
          _memberId ??= items.isNotEmpty ? items.first.userId : null;
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: ListView(
                children: [
                  DropdownButtonFormField<String>(
                    value: _memberId,
                    decoration: const InputDecoration(labelText: 'Member'),
                    items: items
                        .map((m) => DropdownMenuItem(value: m.userId, child: Text(m.name)))
                        .toList(),
                    onChanged: (v) => setState(() => _memberId = v),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _amountCtrl,
                    decoration: const InputDecoration(labelText: 'Amount'),
                    keyboardType: TextInputType.number,
                    validator: (v) => v == null || v.isEmpty ? 'Required' : null,
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
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _loading ? null : _submit,
                    child: Text(_loading ? 'Saving...' : 'Save deposit'),
                  ),
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
