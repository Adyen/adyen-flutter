class SessionResponse {
  final String id;
  final String sessionData;

  const SessionResponse({
    required this.id,
    required this.sessionData,
  });

  factory SessionResponse.fromJson(Map<String, dynamic> json) =>
      SessionResponse(
        id: json['id'] as String,
        sessionData: json['sessionData'] as String,
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'sessionData': sessionData,
      };
}
