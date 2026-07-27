class SyncMessage {
  final String action; // e.g., 'upsert', 'delete'
  final Map<String, dynamic> payload;
  final String deviceId; // Prevents echoing messages back to the sender

  SyncMessage({
    required this.action,
    required this.payload,
    required this.deviceId,
  });

  Map<String, dynamic> toJson() => {
    'action': action,
    'payload': payload,
    'deviceId': deviceId,
  };

  factory SyncMessage.fromJson(Map<String, dynamic> json) {
    return SyncMessage(
      action: json['action'],
      payload: json['payload'],
      deviceId: json['deviceId'],
    );
  }
}