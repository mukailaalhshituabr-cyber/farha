// lib/data/models/measurement_model.dart

class MeasurementModel {
  final String  id;
  final String  userId;
  final String  profileName;
  final String  garmentType;
  final double? chest;
  final double? waist;
  final double? hips;
  final double? shoulderWidth;
  final double? sleeveLength;
  final double? totalLength;
  final double? neck;
  final double? armhole;
  final String  unit;        // 'cm' | 'inches'
  final String? notes;
  final DateTime updatedAt;

  const MeasurementModel({
    required this.id,
    required this.userId,
    required this.profileName,
    required this.garmentType,
    this.chest, this.waist, this.hips,
    this.shoulderWidth, this.sleeveLength, this.totalLength,
    this.neck, this.armhole,
    this.unit       = 'cm',
    this.notes,
    required this.updatedAt,
  });

  factory MeasurementModel.fromJson(Map<String, dynamic> j) => MeasurementModel(
    id:            j['id'].toString(),
    userId:        j['user_id'].toString(),
    profileName:   j['profile_name'] as String,
    garmentType:   j['garment_type'] as String,
    chest:         j['chest'] != null ? double.tryParse(j['chest'].toString()) : null,
    waist:         j['waist'] != null ? double.tryParse(j['waist'].toString()) : null,
    hips:          j['hips'] != null ? double.tryParse(j['hips'].toString()) : null,
    shoulderWidth: j['shoulder_width'] != null ? double.tryParse(j['shoulder_width'].toString()) : null,
    sleeveLength:  j['sleeve_length'] != null ? double.tryParse(j['sleeve_length'].toString()) : null,
    totalLength:   j['total_length'] != null ? double.tryParse(j['total_length'].toString()) : null,
    neck:          j['neck'] != null ? double.tryParse(j['neck'].toString()) : null,
    armhole:       j['armhole'] != null ? double.tryParse(j['armhole'].toString()) : null,
    unit:          j['unit'] as String? ?? 'cm',
    notes:         j['notes'] as String?,
    updatedAt:     DateTime.parse(j['updated_at'] as String),
  );

  Map<String, dynamic> toJson() => {
    'profile_name':   profileName,
    'garment_type':   garmentType,
    'unit':           unit,
    if (chest != null)         'chest':          chest,
    if (waist != null)         'waist':          waist,
    if (hips != null)          'hips':           hips,
    if (shoulderWidth != null) 'shoulder_width': shoulderWidth,
    if (sleeveLength != null)  'sleeve_length':  sleeveLength,
    if (totalLength != null)   'total_length':   totalLength,
    if (neck != null)          'neck':           neck,
    if (armhole != null)       'armhole':        armhole,
    if (notes != null)         'notes':          notes,
  };
}
