import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/date_formatter.dart';
import '../../../core/widgets/app_loading.dart';
import '../../members/providers/member_providers.dart';
import '../../mess/providers/mess_providers.dart';
import '../data/meal_repository.dart';
import '../models/meal.dart';

class AddEditMealScreen extends ConsumerStatefulWidget {
  const AddEditMealScreen({super.key, this.mealId});

  final String? mealId;

  @override
  ConsumerState<AddEditMealScreen> createState() => _AddEditMealScreenState();
}

class _AddEditMealScreenState extends ConsumerState<AddEditMealScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _memberId;
  String _date = DateFormatter.dayString(DateTime.now());
  final _dateCtrl = TextEditingController();
  final _breakfastCtrl = TextEditingController(text: '1');
  final _lunchCtrl = TextEditingController(text: '1');
  final _dinnerCtrl = TextEditingController(text: '1');
  bool _loading = false;
  Meal? _existing;

  @override
  void dispose() {
    _dateCtrl.dispose();
    _breakfastCtrl.dispose();
    _lunchCtrl.dispose();
    _dinnerCtrl.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_dateCtrl.text.isEmpty) _dateCtrl.text = _date;
    _loadExisting();
  }

  Future<void> _loadExisting() async {
    if (widget.mealId == null || _existing != null) return;
    final meal = await ref.read(mealRepositoryProvider).fetchMeal(widget.mealId!);
    if (meal != null && mounted) {
      setState(() {
        _existing = meal;
        _memberId = meal.memberId;
        _date = meal.date;
        _dateCtrl.text = meal.date;
        _breakfastCtrl.text = meal.breakfastCount.toString();
        _lunchCtrl.text = meal.lunchCount.toString();
        _dinnerCtrl.text = meal.dinnerCount.toString();
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
    final meal = Meal(
      id: _existing?.id ?? '',
      messId: mess.id,
      memberId: _memberId!,
      date: _date,
      breakfastCount: double.tryParse(_breakfastCtrl.text) ?? 0,
      lunchCount: double.tryParse(_lunchCtrl.text) ?? 0,
      dinnerCount: double.tryParse(_dinnerCtrl.text) ?? 0,
      createdAt: _existing?.createdAt,
    );
    try {
      await ref.read(mealRepositoryProvider).upsertMeal(meal);
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
      appBar: AppBar(title: Text(widget.mealId == null ? 'Add Meal' : 'Edit Meal')),
      body: members.when(
        data: (items) {
          if (items.isEmpty) {
            return const Center(child: Text('No members found. Add members first.'));
          }
          _memberId ??= items.first.userId;
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
                    readOnly: true,
                    decoration: InputDecoration(
                      labelText: 'Date',
                      suffixIcon: IconButton(
                        onPressed: _pickDate,
                        icon: const Icon(Icons.calendar_month),
                      ),
                    ),
                    controller: _dateCtrl,
                  ),
                  const SizedBox(height: 12),
                  _numberField(_breakfastCtrl, 'Breakfast'),
                  const SizedBox(height: 12),
                  _numberField(_lunchCtrl, 'Lunch'),
                  const SizedBox(height: 12),
                  _numberField(_dinnerCtrl, 'Dinner'),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _loading ? null : _submit,
                    child: Text(_loading ? 'Saving...' : 'Save meal'),
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

  Widget _numberField(TextEditingController controller, String label) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(labelText: label, helperText: 'Use 0.5 for half meal'),
      validator: (v) => v == null || v.isEmpty ? 'Required' : null,
    );
  }
}
