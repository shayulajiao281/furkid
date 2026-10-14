import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/weight_record.dart';
import '../../providers/app_state.dart';
import 'sheet_widgets.dart';

void showWeightSheet(BuildContext context, WidgetRef ref, String petId) {
  showCupertinoModalPopup(
    context: context,
    barrierColor: const Color(0x6B0C0F19),
    builder: (_) => WeightSheet(initialPetId: petId),
  );
}

class WeightSheet extends ConsumerStatefulWidget {
  final String initialPetId;
  const WeightSheet({super.key, required this.initialPetId});
  @override
  ConsumerState<WeightSheet> createState() => _WeightSheetState();
}

class _WeightSheetState extends ConsumerState<WeightSheet> {
  late String _petId;
  final _valueCtrl = TextEditingController();
  DateTime _date = DateTime.now();

  @override
  void initState() {
    super.initState();
    _petId = widget.initialPetId;
  }

  @override
  void dispose() {
    _valueCtrl.dispose();
    super.dispose();
  }

  void _save() {
    final v = double.tryParse(_valueCtrl.text);
    if (v == null || v <= 0) return;
    ref
        .read(appStateProvider.notifier)
        .upsertWeight(
          WeightRecord(
            id: uid(),
            petId: _petId,
            date: fmtDate(_date),
            value: v,
          ),
        );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final pets = ref.watch(appStateProvider).pets;

    return SheetShell(
      title: '记录体重',
      children: [
        SheetField(
          label: '哪只宝贝',
          child: SheetChipsRow<String>(
            value: _petId,
            options: pets
                .map((p) => MapEntry(p.id, '${p.avatar} ${p.name}'))
                .toList(),
            onChanged: (v) => setState(() => _petId = v),
          ),
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: SheetField(
                label: '体重 (kg)',
                child: SheetTextField(
                  controller: _valueCtrl,
                  placeholder: '12.4',
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: SheetField(
                label: '日期',
                child: SheetDateField(
                  value: _date,
                  maximumDate: DateTime.now(),
                  onChanged: (d) => setState(() => _date = d),
                ),
              ),
            ),
          ],
        ),
        PrimaryButton(text: '保存记录', onTap: _save),
      ],
    );
  }
}
