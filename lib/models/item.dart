class Item {
  final int? id;
  final int cycleId;
  final String content;
  final double orderPosition; 

  Item({
    this.id,
    required this.cycleId,
    required this.content,
    required this.orderPosition,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'cycle_id': cycleId,
      'content': content,
      'order_position': orderPosition,
    };
  }

  static Item fromMap(Map<String, dynamic> map) {
    return Item(
      id: map['id'],
      cycleId: map['cycle_id'],
      content: map['content'],
      orderPosition: (map['order_position'] as num).toDouble(),
    );
  }

  Item copy({
    int? id,
    int? cycleId,
    String? content,
    double? orderPosition,
  }) => 
  Item(
    id: id ?? this.id,
    cycleId: cycleId ?? this.cycleId,
    content: content ?? this.content,
    orderPosition: orderPosition ?? this.orderPosition,
  );
}

