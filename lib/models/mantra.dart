class Mantra {
  final String id;
  final String name;
  final int count;
  final int malaCount;
  final int goal;
  final int color; // Store as int (0xAARRGGBB)

  const Mantra({
    required this.id,
    required this.name,
    this.count = 0,
    this.malaCount = 0,
    this.goal = 108,
    required this.color,
  });

  Mantra copyWith({
    String? name,
    int? count,
    int? malaCount,
    int? goal,
    int? color,
  }) {
    return Mantra(
      id: this.id,
      name: name ?? this.name,
      count: count ?? this.count,
      malaCount: malaCount ?? this.malaCount,
      goal: goal ?? this.goal,
      color: color ?? this.color,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'count': count,
      'malaCount': malaCount,
      'goal': goal,
      'color': color,
    };
  }

  factory Mantra.fromJson(Map<String, dynamic> json) {
    return Mantra(
      id: json['id'] as String,
      name: json['name'] as String,
      count: json['count'] as int,
      malaCount: json['malaCount'] as int,
      goal: json['goal'] as int,
      color: json['color'] as int,
    );
  }
}
