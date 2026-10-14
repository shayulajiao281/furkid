import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/weight_record.dart';
import '../../providers/app_state.dart';
import 'sheet_widgets.dart';
import '../../widgets/pet_avatar.dart';

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

    // ★ 预填当前体重（该宠物最新一条记录的值）
    final state = ref.read(appStateProvider);
    final records = state.weights.where((w) => w.petId == _petId).toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    if (records.isNotEmpty) {
      _valueCtrl.text = records.last.value.toString();
    }
  }

  @override
  void dispose() {
    _valueCtrl.dispose();
    super.dispose();
  }

  // ═══════════ 通用提示弹窗 ═══════════
  void _alert(String message) {
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        content: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            message,
            style: const TextStyle(fontSize: 14, height: 1.5),
          ),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('好的'),
          ),
        ],
      ),
    );
  }

  void _save() {
    // ① 空输入 → 弹提示
    final text = _valueCtrl.text.trim();
    if (text.isEmpty) {
      HapticFeedback.lightImpact();
      _alert('请输入体重');
      return;
    }

    // ② 非法输入 → 弹提示
    final v = double.tryParse(text);
    if (v == null || v <= 0) {
      HapticFeedback.lightImpact();
      _alert('请输入有效的体重');
      return;
    }

    // ③ 检查当天是否已有记录
    final state = ref.read(appStateProvider);
    final dateStr = fmtDate(_date);
    final existing = state.weights
        .where((w) => w.petId == _petId && w.date == dateStr)
        .toList();

    if (existing.isNotEmpty) {
      // 已有 → 弹覆盖确认框
      _confirmOverwrite(v, dateStr, existing.first);
    } else {
      // 没有 → 直接保存
      _doSave(v, dateStr, isOverwrite: false);
    }
  }

  // 覆盖确认框
  void _confirmOverwrite(double v, String dateStr, WeightRecord old) {
    HapticFeedback.mediumImpact();
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('当天已有记录'),
        content: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            '$dateStr 已经记录了 ${old.value} kg\n是否覆盖为 ${v.toStringAsFixed(1)} kg？',
            style: const TextStyle(fontSize: 13, height: 1.5),
          ),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          CupertinoDialogAction(
            onPressed: () {
              Navigator.pop(ctx);
              _doSave(v, dateStr, isOverwrite: true);
            },
            child: const Text('覆盖'),
          ),
        ],
      ),
    );
  }

  // 真正保存
  void _doSave(double v, String dateStr, {required bool isOverwrite}) {
    final notifier = ref.read(appStateProvider.notifier);

    // 覆盖时，先删除已有的
    if (isOverwrite) {
      final state = ref.read(appStateProvider);
      final olds = state.weights
          .where((w) => w.petId == _petId && w.date == dateStr)
          .toList();
      for (final old in olds) {
        notifier.deleteWeight(old.id);
      }
    }

    // 加新记录
    notifier.upsertWeight(
      WeightRecord(id: uid(), petId: _petId, date: dateStr, value: v),
    );

    // 关弹层
    Navigator.pop(context);

    // 弹层关闭后延迟一点弹提示（此时用 context 应该没问题，
    // 因为 State 还在，只是弹层被 pop 了）
    // Future.delayed(const Duration(milliseconds: 250), () {
    //   if (!mounted) return;
    //   showCupertinoDialog(
    //     context: context,
    //     builder: (ctx) => CupertinoAlertDialog(
    //       content: Padding(
    //         padding: const EdgeInsets.only(top: 8),
    //         child: Text(
    //           isOverwrite ? '已覆盖当天记录' : '已保存 ✓',
    //           style: const TextStyle(fontSize: 14),
    //         ),
    //       ),
    //       actions: [
    //         CupertinoDialogAction(
    //           onPressed: () => Navigator.pop(ctx),
    //           child: const Text('好的'),
    //         ),
    //       ],
    //     ),
    //   );
    // });
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
                .map(
                  (p) => MapEntry(
                    p.id,
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        PetAvatar(avatar: p.avatar, size: 20, radius: 6),
                        const SizedBox(width: 6),
                        Text(p.name),
                      ],
                    ),
                  ),
                )
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
