class WeightRecord {
  final String id;
  String petId;
  String date;
  double value;

  WeightRecord({
    required this.id,
    required this.petId,
    required this.date,
    required this.value,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'petId': petId,
    'date': date,
    'value': value,
  };

  factory WeightRecord.fromJson(Map<String, dynamic> j) => WeightRecord(
    id: j['id'],
    petId: j['petId'],
    date: j['date'],
    value: (j['value'] as num).toDouble(),
  );
}
