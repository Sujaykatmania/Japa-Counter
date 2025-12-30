class Mantra {
  final String id;
  final String name;
  final int count;
  final int malaCount;
  final int goal;
  final int color; // Store as int (0xAARRGGBB)
  final String? backgroundPath; // Path to local image file
  final double overlayOpacity; // 0.0 to 1.0 (Darkness layer)
  final String? chantText; // The text to display (e.g., "Om Namah Shivaya")

  const Mantra({
    required this.id,
    required this.name,
    this.count = 0,
    this.malaCount = 0,
    this.goal = 108,
    required this.color,
    this.backgroundPath,
    this.overlayOpacity = 0.5,
    this.chantText,
  });

  Mantra copyWith({
    String? name,
    int? count,
    int? malaCount,
    int? goal,
    int? color,
    String? backgroundPath,
    double? overlayOpacity,
    String? chantText,
  }) {
    return Mantra(
      id: id,
      name: name ?? this.name,
      count: count ?? this.count,
      malaCount: malaCount ?? this.malaCount,
      goal: goal ?? this.goal,
      color: color ?? this.color,
      backgroundPath: backgroundPath ?? this.backgroundPath,
      overlayOpacity: overlayOpacity ?? this.overlayOpacity,
      chantText: chantText ?? this.chantText,
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
      'backgroundPath': backgroundPath,
      'overlayOpacity': overlayOpacity,
      'chantText': chantText,
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
      backgroundPath: json['backgroundPath'] as String?,
      overlayOpacity: (json['overlayOpacity'] as num?)?.toDouble() ?? 0.5,
      chantText: json['chantText'] as String?,
    );
  }
}
