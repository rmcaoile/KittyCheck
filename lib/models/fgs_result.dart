class FGSResult {
  final int? id;
  final String catName;
  final DateTime dateTime;
  final int totalFgsScore;
  final int earScore;
  final int eyesScore;
  final int muzzleScore;
  final int whiskersScore;
  final int headPositionScore;
  final String originalImagePath;
  final String? earImagePath;
  final String? eyesImagePath;
  final String? muzzleImagePath;
  final String? whiskersImagePath;
  final String? headPositionImagePath;

  FGSResult({
    this.id,
    required this.catName,
    required this.dateTime,
    required this.totalFgsScore,
    required this.earScore,
    required this.eyesScore,
    required this.muzzleScore,
    required this.whiskersScore,
    required this.headPositionScore,
    required this.originalImagePath,
    this.earImagePath,
    this.eyesImagePath,
    this.muzzleImagePath,
    this.whiskersImagePath,
    this.headPositionImagePath,
  });

  // Create from JSON
  factory FGSResult.fromJson(Map<String, dynamic> json) {
    return FGSResult(
      id: json['id'] as int?,
      catName: json['catName'] as String,
      dateTime: DateTime.parse(json['dateTime'] as String),
      totalFgsScore: (json['totalFgsScore'] as num).toInt(),
      earScore: (json['earScore'] as num).toInt(),
      eyesScore: (json['eyesScore'] as num).toInt(),
      muzzleScore: (json['muzzleScore'] as num).toInt(),
      whiskersScore: (json['whiskersScore'] as num).toInt(),
      headPositionScore: (json['headPositionScore'] as num).toInt(),
      originalImagePath: json['originalImagePath'] as String,
      earImagePath: json['earImagePath'] as String?,
      eyesImagePath: json['eyesImagePath'] as String?,
      muzzleImagePath: json['muzzleImagePath'] as String?,
      whiskersImagePath: json['whiskersImagePath'] as String?,
      headPositionImagePath: json['headPositionImagePath'] as String?,
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'catName': catName,
      'dateTime': dateTime.toIso8601String(),
      'totalFgsScore': totalFgsScore,
      'earScore': earScore,
      'eyesScore': eyesScore,
      'muzzleScore': muzzleScore,
      'whiskersScore': whiskersScore,
      'headPositionScore': headPositionScore,
      'originalImagePath': originalImagePath,
      'earImagePath': earImagePath,
      'eyesImagePath': eyesImagePath,
      'muzzleImagePath': muzzleImagePath,
      'whiskersImagePath': whiskersImagePath,
      'headPositionImagePath': headPositionImagePath,
    };
  }

  // Create copy with updated fields
  FGSResult copyWith({
    int? id,
    String? catName,
    DateTime? dateTime,
    int? totalFgsScore,
    int? earScore,
    int? eyesScore,
    int? muzzleScore,
    int? whiskersScore,
    int? headPositionScore,
    String? originalImagePath,
    String? earImagePath,
    String? eyesImagePath,
    String? muzzleImagePath,
    String? whiskersImagePath,
    String? headPositionImagePath,
  }) {
    return FGSResult(
      id: id ?? this.id,
      catName: catName ?? this.catName,
      dateTime: dateTime ?? this.dateTime,
      totalFgsScore: totalFgsScore ?? this.totalFgsScore,
      earScore: earScore ?? this.earScore,
      eyesScore: eyesScore ?? this.eyesScore,
      muzzleScore: muzzleScore ?? this.muzzleScore,
      whiskersScore: whiskersScore ?? this.whiskersScore,
      headPositionScore: headPositionScore ?? this.headPositionScore,
      originalImagePath: originalImagePath ?? this.originalImagePath,
      earImagePath: earImagePath ?? this.earImagePath,
      eyesImagePath: eyesImagePath ?? this.eyesImagePath,
      muzzleImagePath: muzzleImagePath ?? this.muzzleImagePath,
      whiskersImagePath: whiskersImagePath ?? this.whiskersImagePath,
      headPositionImagePath: headPositionImagePath ?? this.headPositionImagePath,
    );
  }
}