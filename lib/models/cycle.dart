class Cycle {
  final int? id;
  final String name;

  Cycle({this.id, required this.name});

  Map<String, dynamic> toMap() {
    return {'id': id, 'name': name};
  }

  static Cycle fromMap(Map<String, dynamic> map) {
    return Cycle(id: map['id'], name: map['name']);
  }

  Cycle copy({int? id, String? name}) =>
      Cycle(id: id ?? this.id, name: name ?? this.name);
}
