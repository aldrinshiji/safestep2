class EmergencyModel {
  final String id;
  final DateTime timestamp;
  final String? localVideoPath;
  final String? publicVideoUrl;
  final double latitude;
  final double longitude;
  final String address;
  final String googleMapsUrl;
  final String deviceModel;
  final int batteryPercentage;
  final String internetStatus;
  final String uploadStatus; // 'pending', 'uploaded', 'failed'
  final String guardianStatus; // 'pending', 'sent', 'failed'

  EmergencyModel({
    required this.id,
    required this.timestamp,
    this.localVideoPath,
    this.publicVideoUrl,
    required this.latitude,
    required this.longitude,
    required this.address,
    required this.googleMapsUrl,
    required this.deviceModel,
    required this.batteryPercentage,
    required this.internetStatus,
    required this.uploadStatus,
    required this.guardianStatus,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'local_video_path': localVideoPath,
      'public_video_url': publicVideoUrl,
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'google_maps_url': googleMapsUrl,
      'device_model': deviceModel,
      'battery_percentage': batteryPercentage,
      'internet_status': internetStatus,
      'upload_status': uploadStatus,
      'guardian_status': guardianStatus,
    };
  }

  factory EmergencyModel.fromJson(Map<String, dynamic> json) {
    return EmergencyModel(
      id: json['id'] as String? ?? '',
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'] as String)
          : DateTime.now(),
      localVideoPath: json['local_video_path'] as String?,
      publicVideoUrl: json['public_video_url'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      address: json['address'] as String? ?? 'Unknown Location',
      googleMapsUrl: json['google_maps_url'] as String? ?? '',
      deviceModel: json['device_model'] as String? ?? 'Mobile Device',
      batteryPercentage: (json['battery_percentage'] as num?)?.toInt() ?? 100,
      internetStatus: json['internet_status'] as String? ?? 'Unknown',
      uploadStatus: json['upload_status'] as String? ?? 'pending',
      guardianStatus: json['guardian_status'] as String? ?? 'pending',
    );
  }

  EmergencyModel copyWith({
    String? id,
    DateTime? timestamp,
    String? localVideoPath,
    String? publicVideoUrl,
    double? latitude,
    double? longitude,
    String? address,
    String? googleMapsUrl,
    String? deviceModel,
    int? batteryPercentage,
    String? internetStatus,
    String? uploadStatus,
    String? guardianStatus,
  }) {
    return EmergencyModel(
      id: id ?? this.id,
      timestamp: timestamp ?? this.timestamp,
      localVideoPath: localVideoPath ?? this.localVideoPath,
      publicVideoUrl: publicVideoUrl ?? this.publicVideoUrl,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      address: address ?? this.address,
      googleMapsUrl: googleMapsUrl ?? this.googleMapsUrl,
      deviceModel: deviceModel ?? this.deviceModel,
      batteryPercentage: batteryPercentage ?? this.batteryPercentage,
      internetStatus: internetStatus ?? this.internetStatus,
      uploadStatus: uploadStatus ?? this.uploadStatus,
      guardianStatus: guardianStatus ?? this.guardianStatus,
    );
  }
}
