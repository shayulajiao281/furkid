import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/pet.dart';
import '../models/reminder.dart';
import '../models/weight_record.dart';

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
}

String _uid() =>
    DateTime.now().microsecondsSinceEpoch.toString() +
    (100 + (DateTime.now().millisecond % 900)).toString();

String _fmt(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

String _plusDays(int n) {
  final d = DateTime.now().add(Duration(days: n));
  return _fmt(d);
}

class AppStateNotifier extends Notifier<AppState> {
  @override
  AppState build() {
    // 初始数据（对应 HTML 里的 DEFAULT_STATE）
    final p1 = Pet(
      id: 'p1',
      name: '豆豆',
      avatar: '🐶',
      breed: '柯基',
      gender: '公',
      birthday: '2023-05-12',
    );
    final p2 = Pet(
      id: 'p2',
      name: '咪咪',
      avatar: '🐱',
      breed: '英短蓝猫',
      gender: '母',
      birthday: '2024-02-20',
    );

    return AppState(
      pets: [p1, p2],
      reminders: [
        Reminder(
          id: 'r1',
          petId: 'p1',
          type: 'deworm',
          title: '体内驱虫',
          date: _plusDays(2),
          repeat: 90,
          note: '拜宠清 1 粒',
        ),
        Reminder(
          id: 'r2',
          petId: 'p1',
          type: 'vaccine',
          title: '狂犬疫苗',
          date: _plusDays(12),
          repeat: 365,
        ),
        Reminder(
          id: 'r3',
          petId: 'p2',
          type: 'vaccine',
          title: '猫三联加强',
          date: _plusDays(-1),
          repeat: 365,
        ),
        Reminder(
          id: 'r4',
          petId: 'p2',
          type: 'weight',
          title: '称体重',
          date: _plusDays(5),
          repeat: 30,
        ),
      ],
      weights: [
        WeightRecord(id: 'w1', petId: 'p1', date: _plusDays(-60), value: 11.2),
        WeightRecord(id: 'w2', petId: 'p1', date: _plusDays(-40), value: 11.8),
        WeightRecord(id: 'w3', petId: 'p1', date: _plusDays(-20), value: 12.1),
        WeightRecord(id: 'w4', petId: 'p1', date: _plusDays(-3), value: 12.4),
        WeightRecord(id: 'w5', petId: 'p2', date: _plusDays(-30), value: 4.1),
        WeightRecord(id: 'w6', petId: 'p2', date: _plusDays(-5), value: 4.3),
      ],
    );
  }

  // ---------- 宠物 ----------
  void addPet(Pet p) => state = AppState(
    pets: [...state.pets, p],
    reminders: state.reminders,
    weights: state.weights,
  );

  void updatePet(Pet p) => state = AppState(
    pets: state.pets.map((e) => e.id == p.id ? p : e).toList(),
    reminders: state.reminders,
    weights: state.weights,
  );

  void deletePet(String id) => state = AppState(
    pets: state.pets.where((e) => e.id != id).toList(),
    reminders: state.reminders.where((r) => r.petId != id).toList(),
    weights: state.weights.where((w) => w.petId != id).toList(),
  );

  // ---------- 提醒 ----------
  void addReminder(Reminder r) => state = AppState(
    pets: state.pets,
    reminders: [...state.reminders, r],
    weights: state.weights,
  );

  void updateReminder(Reminder r) => state = AppState(
    pets: state.pets,
    reminders: state.reminders.map((e) => e.id == r.id ? r : e).toList(),
    weights: state.weights,
  );

  void deleteReminder(String id) => state = AppState(
    pets: state.pets,
    reminders: state.reminders.where((e) => e.id != id).toList(),
    weights: state.weights,
  );

  void toggleReminder(String id) {
    final list = state.reminders.map((r) {
      if (r.id != id) return r;
      if (r.done) {
        r.done = false;
      } else if (r.repeat > 0) {
        final d = DateTime.parse(r.date).add(Duration(days: r.repeat));
        r.date = _fmt(d);
      } else {
        r.done = true;
      }
      return r;
    }).toList();
    state = AppState(pets: state.pets, reminders: list, weights: state.weights);
  }

  // ---------- 体重 ----------
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
  }

  void deleteWeight(String id) => state = AppState(
    pets: state.pets,
    reminders: state.reminders,
    weights: state.weights.where((e) => e.id != id).toList(),
  );

  // 工具
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
}

// 工具函数
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

// providers
final appStateProvider = NotifierProvider<AppStateNotifier, AppState>(
  AppStateNotifier.new,
);

final petsProvider = Provider((ref) => ref.watch(appStateProvider).pets);
final remindersProvider = Provider(
  (ref) => ref.watch(appStateProvider).reminders,
);
final weightsProvider = Provider((ref) => ref.watch(appStateProvider).weights);
