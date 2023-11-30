import 'dart:convert';

class SessionResponseNetworkModel {
  final String id;

  final String sessionData;

  SessionResponseNetworkModel({
    required this.id,
    required this.sessionData,
  });

  factory SessionResponseNetworkModel.fromRawJson(String str) =>
      SessionResponseNetworkModel.fromJson(json.decode(str));

  factory SessionResponseNetworkModel.fromJson(Map<String, dynamic> json) =>
      SessionResponseNetworkModel(
        id: json["id"],
        sessionData: json["sessionData"],
      );

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sessionData': sessionData,
    };
  }
}
