import 'data_utils.dart';
import 'payment_method.dart';

class StoredPaymentMethod extends PaymentMethod {
  final String id;
  final List<String> supportedShopperInteractions;

  StoredPaymentMethod({
    required super.type,
    required super.name,
    required this.id,
    List<String> supportedShopperInteractions = const [],
    Map<String, dynamic>? data,
  })  : supportedShopperInteractions = List<String>.unmodifiable(
          supportedShopperInteractions,
        ),
        super(
          data: {
            ...?data,
            'type': type,
            'name': name,
            'id': id,
            if (supportedShopperInteractions.isNotEmpty)
              'supportedShopperInteractions': supportedShopperInteractions,
          },
        );

  factory StoredPaymentMethod.fromJson(Map<String, dynamic> json) {
    final source = Map<String, dynamic>.from(json);
    final interactions = source['supportedShopperInteractions'];
    return StoredPaymentMethod(
      type: requireString(source['type'], 'StoredPaymentMethod.type'),
      name: requireString(source['name'], 'StoredPaymentMethod.name'),
      id: requireString(source['id'], 'StoredPaymentMethod.id'),
      supportedShopperInteractions: interactions is List
          ? interactions.whereType<String>().toList()
          : const [],
      data: source,
    );
  }

  @override
  String toString() => 'StoredPaymentMethod(type: $type, name: $name, id: $id)';
}
