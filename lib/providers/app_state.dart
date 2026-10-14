import 'dart:convert';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/pet.dart';
import '../models/reminder.dart';
import '../models/weight_record.dart';
// 通知
import '../services/notification_service.dart';

// ====================== 状态 ======================
class AppState {
  final List<Pet> pets;
  final List<Reminder> reminders;
  final List<WeightRecord> weights;

  AppState({
    List<Pet>? pets,
    List<Reminder>? reminders,
    List<WeightRecord>? weights,
  }) : pets = pets ?? [],
       reminders = reminders ?? [],
       weights = weights ?? [];

  Map<String, dynamic> toJson() => {
    'pets': pets.map((e) => e.toJson()).toList(),
    'reminders': reminders.map((e) => e.toJson()).toList(),
    'weights': weights.map((e) => e.toJson()).toList(),
  };

  factory AppState.fromJson(Map<String, dynamic> j) => AppState(
    pets: (j['pets'] as List? ?? [])
        .map((e) => Pet.fromJson(e as Map<String, dynamic>))
        .toList(),
    reminders: (j['reminders'] as List? ?? [])
        .map((e) => Reminder.fromJson(e as Map<String, dynamic>))
        .toList(),
    weights: (j['weights'] as List? ?? [])
        .map((e) => WeightRecord.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
}

// ====================== 工具函数 ======================
String _uid() =>
    DateTime.now().microsecondsSinceEpoch.toString() +
    (100 + (DateTime.now().millisecond % 900)).toString();

String _fmt(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

String _plusDays(int n) {
  final d = DateTime.now().add(Duration(days: n));
  return _fmt(d);
}

int _daysUntil(String date) {
  if (date.isEmpty) return 9999;
  final t = DateTime.now();
  final today = DateTime(t.year, t.month, t.day);
  final d = DateTime.parse(date);
  return d.difference(today).inDays;
}

int daysUntil(String date) => _daysUntil(date);
String fmtDate(DateTime d) => _fmt(d);
String todayStr() => _fmt(DateTime.now());
String uid() => _uid();

// ====================== Notifier ======================
const _kStorageKey = 'furkid_state_v1';

// SharedPreferences Provider（在 main 里被 override）
final sharedPrefsProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('必须在 main.dart 里 override');
});

class AppStateNotifier extends Notifier<AppState> {
  late final SharedPreferences _prefs;

  @override
  AppState build() {
    _prefs = ref.read(sharedPrefsProvider);

    // 同步读取磁盘数据
    final raw = _prefs.getString(_kStorageKey);
    AppState loaded;
    if (raw != null && raw.isNotEmpty) {
      try {
        final map = jsonDecode(raw) as Map<String, dynamic>;
        loaded = AppState.fromJson(map);
      } catch (_) {
        loaded = _defaultState();
      }
    } else {
      loaded = _defaultState();
    }

    // ★ 启动时重建所有提醒的通知
    // 放在 build 里，确保每次 App 启动都重新调度
    Future.microtask(() async {
      await NotificationService.cancelAll();
      for (final r in loaded.reminders) {
        if (!r.done) {
          await _syncReminderNotification(r);
        }
      }
    });

    return loaded;
  }

  // ---------- 默认数据 ----------
  AppState _defaultState() {
    return AppState(pets: [], reminders: [], weights: []);
  }

  // ---------- 写入磁盘 ----------
  void _persist() {
    _prefs.setString(_kStorageKey, jsonEncode(state.toJson()));
  }

  // ====================== 宠物 ======================
  void addPet(Pet p) {
    state = AppState(
      pets: [...state.pets, p],
      reminders: state.reminders,
      weights: state.weights,
    );
    _persist();
  }

  void updatePet(Pet p) {
    state = AppState(
      pets: state.pets.map((e) => e.id == p.id ? p : e).toList(),
      reminders: state.reminders,
      weights: state.weights,
    );
    _persist();
  }

  // void deletePet(String id) {
  //   // ★ 先取消该宠物所有提醒的通知
  //   for (final r in state.reminders.where((r) => r.petId == id)) {
  //     NotificationService.cancel(_notifId(r.id));
  //   }

  //   state = AppState(
  //     pets: state.pets.where((e) => e.id != id).toList(),
  //     reminders: state.reminders.where((r) => r.petId != id).toList(),
  //     weights: state.weights.where((w) => w.petId != id).toList(),
  //   );
  //   _persist();
  // }

  void deletePet(String id) {
    // ① 删除头像图片文件（如果是图片路径）
    final pets = state.pets.where((p) => p.id == id).toList();
    if (pets.isNotEmpty) {
      final avatar = pets.first.avatar;
      // 判断是不是文件路径（含 / 或 \）
      if (avatar.isNotEmpty &&
          (avatar.contains('/') || avatar.contains('\\'))) {
        try {
          final f = File(avatar);
          if (f.existsSync()) f.deleteSync();
        } catch (_) {
          // 删除失败忽略，不影响数据删除
        }
      }
    }

    // ② 取消该宠物所有提醒的通知
    for (final r in state.reminders.where((r) => r.petId == id)) {
      NotificationService.cancel(_notifId(r.id));
    }

    // ③ 从 state 里移除数据
    state = AppState(
      pets: state.pets.where((e) => e.id != id).toList(),
      reminders: state.reminders.where((r) => r.petId != id).toList(),
      weights: state.weights.where((w) => w.petId != id).toList(),
    );
    _persist();
  }

  // ====================== 提醒 ======================
  void addReminder(Reminder r) {
    state = AppState(
      pets: state.pets,
      reminders: [...state.reminders, r],
      weights: state.weights,
    );
    _persist();
    _syncReminderNotification(r); // ★ 加：同步通知
  }

  void updateReminder(Reminder r) {
    state = AppState(
      pets: state.pets,
      reminders: state.reminders.map((e) => e.id == r.id ? r : e).toList(),
      weights: state.weights,
    );
    _persist();
    _syncReminderNotification(r); // ★ 加：同步通知
  }

  void deleteReminder(String id) {
    state = AppState(
      pets: state.pets,
      reminders: state.reminders.where((e) => e.id != id).toList(),
      weights: state.weights,
    );
    _persist();
    NotificationService.cancel(_notifId(id)); // ★ 加：取消通知
  }

  /// 切换提醒完成状态，返回提示文字
  String toggleReminder(String id) {
    String msg = '';
    Reminder? target;

    final list = state.reminders.map((r) {
      if (r.id != id) return r;
      if (r.done) {
        r.done = false;
        msg = '已取消完成';
      } else if (r.repeat > 0) {
        final d = DateTime.parse(r.date).add(Duration(days: r.repeat));
        r.date = _fmt(d);
        msg = '已完成 ✓ 下次 ${r.date}';
      } else {
        r.done = true;
        msg = '已完成 ✓';
      }
      target = r;
      return r;
    }).toList();

    state = AppState(pets: state.pets, reminders: list, weights: state.weights);
    _persist();

    // ★ 加：同步通知
    if (target != null) {
      _syncReminderNotification(target!);
    }

    return msg;
  }

  // ====================== 体重 ======================
  void upsertWeight(WeightRecord w) {
    final exist = state.weights.indexWhere(
      (e) => e.petId == w.petId && e.date == w.date,
    );
    final list = [...state.weights];
    if (exist >= 0) {
      list[exist] = w;
    } else {
      list.add(w);
    }
    state = AppState(
      pets: state.pets,
      reminders: state.reminders,
      weights: list,
    );
    _persist();
  }

  void deleteWeight(String id) {
    state = AppState(
      pets: state.pets,
      reminders: state.reminders,
      weights: state.weights.where((e) => e.id != id).toList(),
    );
    _persist();
  }

  // ====================== 工具 ======================
  WeightRecord? latestWeightOf(String petId) {
    final list = state.weights.where((w) => w.petId == petId).toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    return list.isEmpty ? null : list.last;
  }

  Reminder? nextReminderOf(String petId) {
    final list =
        state.reminders
            .where((r) => r.petId == petId && !r.done)
            .map((r) => MapEntry(r, _daysUntil(r.date)))
            .toList()
          ..sort((a, b) => a.value.compareTo(b.value));
    return list.isEmpty ? null : list.first.key;
  }

  // ====================== 通知相关 ======================

  /// 提醒 ID → 通知 ID（int，哈希取正）
  int _notifId(String reminderId) => reminderId.hashCode & 0x7fffffff;

  /// 同步一条提醒的通知（固定 9:00）
  Future<void> _syncReminderNotification(Reminder r) async {
    final id = _notifId(r.id);

    // 已完成 → 取消
    if (r.done) {
      await NotificationService.cancel(id);
      return;
    }

    // 解析日期 + 固定 9:00
    final d = DateTime.parse(r.date);
    var when = DateTime(
      d.year,
      d.month,
      d.day,
      NotificationService.reminderHour,
      NotificationService.reminderMinute,
    );

    // 只响一次 + 已过 → 取消
    if (r.repeat == 0 && when.isBefore(DateTime.now())) {
      await NotificationService.cancel(id);
      return;
    }

    // 重复提醒 + 已过 → 日期往后推到未来
    if (r.repeat > 0 && when.isBefore(DateTime.now())) {
      var dd = DateTime.parse(r.date);
      while (DateTime(
        dd.year,
        dd.month,
        dd.day,
        NotificationService.reminderHour,
        NotificationService.reminderMinute,
      ).isBefore(DateTime.now())) {
        dd = dd.add(Duration(days: r.repeat));
      }
      when = DateTime(
        dd.year,
        dd.month,
        dd.day,
        NotificationService.reminderHour,
        NotificationService.reminderMinute,
      );
    }

    await NotificationService.schedule(
      id: id,
      title: r.title,
      body: r.note.isEmpty ? '别忘记啦' : r.note,
      when: when,
      repeatDays: r.repeat,
    );
  }
}

// ====================== Provider ======================
final appStateProvider = NotifierProvider<AppStateNotifier, AppState>(
  AppStateNotifier.new,
);

final petsProvider = Provider((ref) => ref.watch(appStateProvider).pets);
final remindersProvider = Provider(
  (ref) => ref.watch(appStateProvider).reminders,
);
final weightsProvider = Provider((ref) => ref.watch(appStateProvider).weights);
