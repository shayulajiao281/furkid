class Reminder {
  final String id;
  String petId;
  String type; // deworm | vaccine | weight | bath | checkup | other
  String title;
  String date; // yyyy-MM-dd
  int repeat; // 0=不重复, 7/30/90/180/365
  bool done;
  String note;

  Reminder({
    required this.id,
    required this.petId,
    required this.type,
    required this.title,
    required this.date,
    this.repeat = 0,
    this.done = false,
    this.note = '',
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'petId': petId,
    'type': type,
    'title': title,
    'date': date,
    'repeat': repeat,
    'done': done,
    'note': note,
  };

  factory Reminder.fromJson(Map<String, dynamic> j) => Reminder(
    id: j['id'],
    petId: j['petId'],
    type: j['type'],
    title: j['title'],
    date: j['date'],
    repeat: j['repeat'] ?? 0,
    done: j['done'] ?? false,
    note: j['note'] ?? '',
  );
}
