import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/pet.dart';
import '../../models/weight_record.dart';
import '../../providers/app_state.dart';
import 'sheet_widgets.dart';

const _avatars = [
  '🐶',
  '🐱',
  '🐰',
  '🐹',
  '🐦',
  '🐢',
  '🐠',
  '🦊',
  '🐼',
  '🐷',
  '🐴',
  '🐑',
];

void showPetSheet(BuildContext context, WidgetRef ref, Pet? pet) {
  showCupertinoModalPopup(
    context: context,
    barrierColor: const Color(0x6B0C0F19), // rgba(12,15,25,.42)
    builder: (_) => PetSheet(pet: pet),
  );
}

class PetSheet extends ConsumerStatefulWidget {
  final Pet? pet;
  const PetSheet({super.key, this.pet});
  @override
  ConsumerState<PetSheet> createState() => _PetSheetState();
}

class _PetSheetState extends ConsumerState<PetSheet> {
  late TextEditingController _nameCtrl;
  late TextEditingController _breedCtrl;
  late TextEditingController _weightCtrl;
  String _avatar = '🐶';
  String _gender = '公';
  DateTime _birthday = DateTime.now();

  @override
  void initState() {
    super.initState();
    final p = widget.pet;
    _nameCtrl = TextEditingController(text: p?.name ?? '');
    _breedCtrl = TextEditingController(text: p?.breed ?? '');
    _weightCtrl = TextEditingController();
    _avatar = p?.avatar ?? '🐶';
    _gender = p?.gender ?? '公';

    // if (p != null && p.birthday.isNotEmpty) {
    //   _birthday = DateTime.tryParse(p.birthday) ?? DateTime.now();
    // }
    // ★ 生日默认：编辑时用原值；新建时用今天
    if (p != null && p.birthday.isNotEmpty) {
      _birthday = DateTime.tryParse(p.birthday) ?? DateTime.now();
    } else {
      _birthday = DateTime.now();
    }

    // ★ 编辑时预填当前体重
    if (p != null) {
      final state = ref.read(appStateProvider);
      final records = state.weights.where((w) => w.petId == p.id).toList()
        ..sort((a, b) => a.date.compareTo(b.date));
      if (records.isNotEmpty) {
        _weightCtrl.text = records.last.value.toString();
      }
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _breedCtrl.dispose();
    _weightCtrl.dispose();
    super.dispose();
  }

  // ---------------- 删除确认框 ----------------
  void _confirmDelete(BuildContext context) {
    final pet = widget.pet;
    if (pet == null) return;

    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('删除宠物档案'),
        content: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            '确定要删除「${pet.name}」吗？\n'
            '该宠物的所有提醒和体重记录也会一起删除。',
            style: const TextStyle(fontSize: 13, height: 1.5),
          ),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () {
              Navigator.pop(ctx); // 先关确认框
              HapticFeedback.mediumImpact();
              ref.read(appStateProvider.notifier).deletePet(pet.id);
              Navigator.pop(context); // 再关弹层
            },
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }

  void _save() {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;

    final notifier = ref.read(appStateProvider.notifier);
    final data = Pet(
      id: widget.pet?.id ?? uid(),
      name: name,
      avatar: _avatar,
      breed: _breedCtrl.text.trim(),
      gender: _gender,
      birthday: fmtDate(_birthday),
    );

    if (widget.pet != null) {
      notifier.updatePet(data);
    } else {
      notifier.addPet(data);
    }
    // ★ 处理体重：如果改了，更新最新那条记录；没有记录就新增
    final w = double.tryParse(_weightCtrl.text);
    if (w != null && w > 0) {
      final state = ref.read(appStateProvider);
      final records =
          state.weights.where((rec) => rec.petId == data.id).toList()
            ..sort((a, b) => a.date.compareTo(b.date));

      if (records.isEmpty) {
        // 无记录 → 加今天这条
        notifier.upsertWeight(
          WeightRecord(id: uid(), petId: data.id, date: todayStr(), value: w),
        );
      } else {
        // 有记录 → 更新【最新那条】
        final latest = records.last;
        notifier.upsertWeight(
          WeightRecord(
            id: latest.id,
            petId: data.id,
            date: latest.date,
            value: w,
          ),
        );
      }
    }

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.pet != null ? '编辑宠物档案' : '添加宠物档案';

    return SheetShell(
      title: title,
      children: [
        SheetField(
          label: '选择头像',
          child: EmojiPicker(
            options: _avatars,
            value: _avatar,
            onChanged: (v) => setState(() => _avatar = v),
          ),
        ),
        SheetField(
          label: '名字',
          child: SheetTextField(controller: _nameCtrl, placeholder: '比如：豆豆'),
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: SheetField(
                label: '品种',
                child: SheetTextField(
                  controller: _breedCtrl,
                  placeholder: '柯基 / 英短…',
                ),
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: SheetField(
                label: '性别',
                child: SegControl<String>(
                  value: _gender,
                  options: const [MapEntry('公', '公'), MapEntry('母', '母')],
                  onChanged: (v) => setState(() => _gender = v),
                ),
              ),
            ),
          ],
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: SheetField(
                label: '生日',
                child: SheetDateField(
                  value: _birthday,
                  maximumDate: DateTime.now(),
                  onChanged: (d) => setState(() => _birthday = d),
                ),
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: SheetField(
                label: '当前体重 (kg)',
                child: SheetTextField(
                  controller: _weightCtrl,
                  placeholder: '12.4',
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                ),
              ),
            ),
          ],
        ),
        PrimaryButton(text: '保存档案', onTap: _save),
        if (widget.pet != null)
          GhostButton(
            text: '删除这只宠物',
            danger: true,
            onTap: () => _confirmDelete(context),
          ),
      ],
    );
  }
}
