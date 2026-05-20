class User {
  final String id;
  final String username;
  final String? carModel;
  final String? parkingSlot;

  User({
    required this.id,
    required this.username,
    this.carModel,
    this.parkingSlot,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      username: json['username'] ?? '',
      carModel: json['carModel'],
      parkingSlot: json['parkingSlot'],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'username': username,
    'carModel': carModel,
    'parkingSlot': parkingSlot,
  };
}

class ChargingSession {
  final String id;
  final String userId;
  final String userName;
  final String carModel;
  final DateTime startTime;
  final DateTime? estimatedEndTime;
  final double currentCharge;
  final double desiredCharge;
  final double batteryCapacity;
  final double chargerPower;

  ChargingSession({
    required this.id,
    required this.userId,
    required this.userName,
    required this.carModel,
    required this.startTime,
    this.estimatedEndTime,
    required this.currentCharge,
    required this.desiredCharge,
    required this.batteryCapacity,
    required this.chargerPower,
  });

  factory ChargingSession.fromJson(Map<String, dynamic> json) {
    return ChargingSession(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      userName: json['userName'] ?? '',
      carModel: json['carModel'] ?? '',
      startTime: DateTime.parse(json['startTime']),
      estimatedEndTime: json['estimatedEndTime'] != null 
          ? DateTime.parse(json['estimatedEndTime']) 
          : null,
      currentCharge: (json['currentCharge'] as num).toDouble(),
      desiredCharge: (json['desiredCharge'] as num).toDouble(),
      batteryCapacity: (json['batteryCapacity'] as num).toDouble(),
      chargerPower: (json['chargerPower'] as num).toDouble(),
    );
  }
}

class QueueEntry {
  final String userId;
  final String userName;
  final String carModel;
  final int position;
  final DateTime joinedAt;
  final int estimatedWaitMinutes;

  QueueEntry({
    required this.userId,
    required this.userName,
    required this.carModel,
    required this.position,
    required this.joinedAt,
    required this.estimatedWaitMinutes,
  });

  factory QueueEntry.fromJson(Map<String, dynamic> json) {
    return QueueEntry(
      userId: json['userId'] ?? '',
      userName: json['userName'] ?? '',
      carModel: json['carModel'] ?? '',
      position: json['position'] ?? 0,
      joinedAt: DateTime.parse(json['joinedAt']),
      estimatedWaitMinutes: json['estimatedWaitMinutes'] ?? 0,
    );
  }
}
