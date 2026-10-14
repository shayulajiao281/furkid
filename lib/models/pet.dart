class Pet {
  final String id;
  String name;
  String avatar;
  String breed;
  String gender; // '公' | '母'
  String birthday; // yyyy-MM-dd

  Pet({
    required this.id,
    required this.name,
    this.avatar = '🐶',
    this.breed = '',
    this.gender = '公',
    this.birthday = '',
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'avatar': avatar,
    'breed': breed,
    'gender': gender,
    'birthday': birthday,
  };

  factory Pet.fromJson(Map<String, dynamic> j) => Pet(
    id: j['id'],
    name: j['name'],
    avatar: j['avatar'] ?? '🐶',
    breed: j['breed'] ?? '',
    gender: j['gender'] ?? '公',
    birthday: j['birthday'] ?? '',
  );
}
